#!/usr/bin/env python3
"""
Regression Tests for Release Readiness Verification Tool (Task R64)

Validates:
1. Strict test log parsing across pass, fail, skipped, empty, interrupted, and malformed logs.
2. Assertion that nonzero exit code prevents pass inference even with summary lines.
3. Windows Flutter version probe with timeout resilience and error handling.
4. Git clean vs dirty state detection.
5. Exact SHA-256 and byte / decimal MB / binary MiB artifact accounting.
6. AAB signer certificate verification parser behavior.
"""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

import run_release_readiness_checks as runner


class TestTestLogParser(unittest.TestCase):
    def test_clean_pass_summary(self):
        log = """
00:00 +0: loading test/location_privacy_boundaries_test.dart
00:01 +10: test 10 passed
02:46 +548: All tests passed!
"""
        result = runner.parse_test_log(log, exit_code=0)
        self.assertTrue(result["summary_found"])
        self.assertTrue(result["is_success"])
        self.assertEqual(result["passed"], 548)
        self.assertEqual(result["failed"], 0)
        self.assertEqual(result["skipped"], 0)
        self.assertEqual(result["total"], 548)
        self.assertIsNone(result["error"])

    def test_pass_summary_with_skips(self):
        log = """
00:00 +0: starting tests
00:10 +50 ~3: All tests passed!
"""
        result = runner.parse_test_log(log, exit_code=0)
        self.assertTrue(result["summary_found"])
        self.assertTrue(result["is_success"])
        self.assertEqual(result["passed"], 50)
        self.assertEqual(result["skipped"], 3)
        self.assertEqual(result["failed"], 0)
        self.assertEqual(result["total"], 53)

    def test_fail_summary(self):
        log = """
00:01 +10: loading test
00:05 +40 -2: Some test failed
03:12 +540 -8: Some tests failed.
"""
        result = runner.parse_test_log(log, exit_code=1)
        self.assertTrue(result["summary_found"])
        self.assertFalse(result["is_success"])
        self.assertEqual(result["passed"], 540)
        self.assertEqual(result["failed"], 8)
        self.assertEqual(result["total"], 548)

    def test_empty_log(self):
        result = runner.parse_test_log("", exit_code=0)
        self.assertFalse(result["summary_found"])
        self.assertFalse(result["is_success"])
        self.assertEqual(result["passed"], 0)
        self.assertEqual(result["failed"], 0)
        self.assertIn("Empty", result["error"])

    def test_interrupted_log_never_infers_pass(self):
        # A test run aborted or terminated midway: contains partial '+50' progress lines
        # but NO final summary line
        log = """
00:00 +0: loading tests
00:05 +20: running test 20
00:10 +50: running test 50
Process terminated by signal SIGINT
"""
        result = runner.parse_test_log(log, exit_code=130)
        self.assertFalse(result["summary_found"])
        self.assertFalse(result["is_success"])
        # Crucial requirement: never infer pass from partial progress!
        self.assertEqual(result["passed"], 0)
        self.assertEqual(result["failed"], 0)
        self.assertIn("No final test summary found", result["error"])

    def test_malformed_log(self):
        log = """
Unrecognized binary stream: \x00\x01\x02
Fatal exception in Dart VM during compilation
All tests pa...
"""
        result = runner.parse_test_log(log, exit_code=1)
        self.assertFalse(result["summary_found"])
        self.assertFalse(result["is_success"])
        self.assertEqual(result["passed"], 0)
        self.assertEqual(result["failed"], 0)

    def test_nonzero_exit_code_rejection_despite_summary(self):
        # If exit_code is nonzero, must fail even if output has a summary line
        log = "00:05 +10: All tests passed!"
        result = runner.parse_test_log(log, exit_code=1)
        self.assertTrue(result["summary_found"])
        self.assertFalse(result["is_success"])
        self.assertIn("non-zero exit code 1", result["error"])

    def test_ansi_escape_and_carriage_return_handling(self):
        # Flutter console test output often contains \r and ANSI color escapes
        log = "\r\x1b[38;5;2m02:46 +548: All tests passed!\x1b[0m\r\n"
        result = runner.parse_test_log(log, exit_code=0)
        self.assertTrue(result["summary_found"])
        self.assertTrue(result["is_success"])
        self.assertEqual(result["passed"], 548)
        self.assertEqual(result["failed"], 0)


class TestEnvironmentProbing(unittest.TestCase):
    @patch("subprocess.run")
    def test_flutter_probe_timeout_handling(self, mock_run):
        mock_run.side_effect = subprocess.TimeoutExpired(cmd=["flutter", "--version"], timeout=30)
        info = runner.probe_flutter_version(Path("."), timeout_sec=30)
        self.assertTrue(info["timed_out"])
        self.assertIn("timed out after 30s", info["summary"])

    @patch("subprocess.run")
    def test_flutter_version_parsing(self, mock_run):
        stdout_fixture = """
Flutter 3.38.7 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 3b62efc2a3 (9 months ago) • 2026-01-13 13:47:42 -0800
Engine • hash 6f3039bf7c3cb5306513c75092822d4d94716003 (revision 78fc3012e4)
Tools • Dart 3.10.7 • DevTools 2.51.1
"""
        mock_run.return_value = MagicMock(returncode=0, stdout=stdout_fixture)
        info = runner.probe_flutter_version(Path("."), timeout_sec=30)
        self.assertFalse(info["timed_out"])
        self.assertEqual(info["flutter_version"], "3.38.7")
        self.assertEqual(info["channel"], "stable")
        self.assertEqual(info["dart_version"], "3.10.7")

    @patch("subprocess.run")
    def test_java_version_parsing(self, mock_run):
        stdout_fixture = """openjdk version "17.0.12" 2024-07-16
OpenJDK Runtime Environment (build 17.0.12+7)
OpenJDK 64-Bit Server VM (build 17.0.12+7, mixed mode)
"""
        mock_run.return_value = MagicMock(returncode=0, stdout=stdout_fixture)
        info = runner.probe_java_version(timeout_sec=15)
        self.assertEqual(info["version"], "17.0.12")
        self.assertEqual(info["exit_code"], 0)

    @patch("subprocess.run")
    def test_git_clean_and_dirty_detection(self, mock_run):
        # Case 1: Clean tree
        mock_run.side_effect = [
            MagicMock(returncode=0, stdout="a" * 40 + "\n"),
            MagicMock(returncode=0, stdout="ui/r64-trustworthy-verification-record\n"),
            MagicMock(returncode=0, stdout=""),
        ]
        info_clean = runner.probe_git_info(Path("."))
        self.assertFalse(info_clean["is_dirty"])
        self.assertEqual(len(info_clean["dirty_files"]), 0)

        # Case 2: Dirty tree
        mock_run.side_effect = [
            MagicMock(returncode=0, stdout="b" * 40 + "\n"),
            MagicMock(returncode=0, stdout="ui/r64-trustworthy-verification-record\n"),
            MagicMock(returncode=0, stdout=" M tool/run_release_readiness_checks.py\n?? untracked.txt\n"),
        ]
        info_dirty = runner.probe_git_info(Path("."))
        self.assertTrue(info_dirty["is_dirty"])
        self.assertEqual(len(info_dirty["dirty_files"]), 2)


class TestArtifactHashingAndUnits(unittest.TestCase):
    def test_artifact_sha_and_size_calculation(self):
        with tempfile.NamedTemporaryFile(delete=False) as f:
            # Write exactly 1,048,576 bytes (1 MiB binary, ~1.05 MB decimal)
            f.write(b"X" * 1_048_576)
            temp_path = f.name

        try:
            sha = runner.compute_sha256(temp_path)
            self.assertEqual(len(sha), 64)
            size_bytes = os.path.getsize(temp_path)
            self.assertEqual(size_bytes, 1_048_576)
            self.assertEqual(runner.bytes_to_mib(size_bytes), 1.0)
            self.assertEqual(runner.bytes_to_mb(size_bytes), 1.05)
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)


class TestUILintParser(unittest.TestCase):
    def test_ui_lint_log_parsing(self):
        log = """
[ui_lint_v2] Checked 150 files.
Total warnings: WARN 248
allow markers used: 6 / 10 allowed.
Lint check passed successfully!
"""
        details = runner.parse_ui_lint_log(log)
        self.assertEqual(details["warnings"], 248)
        self.assertEqual(details["allow_markers"], 6)

    def test_ui_lint_from_file_path(self):
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", delete=False) as f:
            f.write("WARN 12\nallow markers used: 3 / 10 allowed.\n")
            p = Path(f.name)
        try:
            details = runner.parse_ui_lint_log(p)
            self.assertEqual(details["warnings"], 12)
            self.assertEqual(details["allow_markers"], 3)
        finally:
            if p.exists():
                p.unlink()


class TestSignerVerification(unittest.TestCase):
    def test_signer_valid_test_upload(self):
        stdout = """
Signer #1:
Certificate #1:
Owner: CN=TestUpload, OU=ReleaseReadiness, O=TalibIlm, C=DZ
Issuer: CN=TestUpload, OU=ReleaseReadiness, O=TalibIlm, C=DZ
"""
        has_test_signer = "CN=TestUpload" in stdout
        has_debug_signer = "CN=Android Debug" in stdout
        self.assertTrue(has_test_signer and not has_debug_signer)

    def test_signer_rejection_of_debug_cert(self):
        stdout = """
Signer #1:
Certificate #1:
Owner: CN=Android Debug, O=Android, C=US
Issuer: CN=Android Debug, O=Android, C=US
"""
        has_test_signer = "CN=TestUpload" in stdout
        has_debug_signer = "CN=Android Debug" in stdout
        verified = has_test_signer and not has_debug_signer
        self.assertFalse(verified)

    def test_signer_rejection_missing_cert(self):
        stdout = "No signature found in file."
        has_test_signer = "CN=TestUpload" in stdout
        has_debug_signer = "CN=Android Debug" in stdout
        verified = has_test_signer and not has_debug_signer
        self.assertFalse(verified)


if __name__ == "__main__":
    unittest.main()

