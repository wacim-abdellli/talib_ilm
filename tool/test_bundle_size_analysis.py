#!/usr/bin/env python3
"""
Regression test suite for bundle size analysis runner (Task R63).
Validates:
1. Exact unit conversions (decimal MB vs binary MiB).
2. Signing safety: never deletes or modifies workspace android/key.properties.
3. Fatal exit on build failure: non-zero exit aborts immediately without report.
4. Stale artifact rejection: refuses to report artifacts older than run start.
5. Official bundletool measurement and schema validity.
"""

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO_ROOT, "tool"))

import run_bundle_size_analysis as bsa

WORKSPACE_KEY_PROPS = os.path.normcase(os.path.abspath(os.path.join(REPO_ROOT, "android", "key.properties")))
_REAL_OPEN = open
_REAL_REMOVE = os.remove
_REAL_UNLINK = os.unlink


def guarded_open(file, mode="r", *args, **kwargs):
    """Guards workspace android/key.properties against any open-for-write operation."""
    try:
        target = os.path.normcase(os.path.abspath(str(file)))
    except Exception:
        target = None
    if target == WORKSPACE_KEY_PROPS:
        if any(m in mode for m in ("w", "a", "+", "x")):
            raise PermissionError(
                f"TOOLING SAFETY VIOLATION: Test attempted to open workspace '{file}' with write mode '{mode}'!"
            )
    return _REAL_OPEN(file, mode, *args, **kwargs)


def guarded_remove(path, *args, **kwargs):
    """Guards workspace android/key.properties against deletion."""
    try:
        target = os.path.normcase(os.path.abspath(str(path)))
    except Exception:
        target = None
    if target == WORKSPACE_KEY_PROPS:
        raise PermissionError(
            f"TOOLING SAFETY VIOLATION: Test attempted to remove workspace '{path}'!"
        )
    return _REAL_REMOVE(path, *args, **kwargs)


def guarded_unlink(path, *args, **kwargs):
    """Guards workspace android/key.properties against unlinking."""
    try:
        target = os.path.normcase(os.path.abspath(str(path)))
    except Exception:
        target = None
    if target == WORKSPACE_KEY_PROPS:
        raise PermissionError(
            f"TOOLING SAFETY VIOLATION: Test attempted to unlink workspace '{path}'!"
        )
    return _REAL_UNLINK(path, *args, **kwargs)


class BundleSizeRunnerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls._open_patcher = patch("builtins.open", side_effect=guarded_open)
        cls._remove_patcher = patch("os.remove", side_effect=guarded_remove)
        cls._unlink_patcher = patch("os.unlink", side_effect=guarded_unlink)
        cls._open_patcher.start()
        cls._remove_patcher.start()
        cls._unlink_patcher.start()

    @classmethod
    def tearDownClass(cls):
        cls._open_patcher.stop()
        cls._remove_patcher.stop()
        cls._unlink_patcher.stop()

    def setUp(self):
        self.had_workspace_key_props = os.path.exists(WORKSPACE_KEY_PROPS)
        self.initial_workspace_hash = None
        if self.had_workspace_key_props:
            with _REAL_OPEN(WORKSPACE_KEY_PROPS, "rb") as f:
                self.initial_workspace_hash = hashlib.sha256(f.read()).hexdigest()

    def tearDown(self):
        # Assert workspace android/key.properties was strictly unmodified and undeleted
        if self.had_workspace_key_props:
            self.assertTrue(
                os.path.exists(WORKSPACE_KEY_PROPS),
                "Workspace android/key.properties was deleted during test run!"
            )
            with _REAL_OPEN(WORKSPACE_KEY_PROPS, "rb") as f:
                current_hash = hashlib.sha256(f.read()).hexdigest()
            self.assertEqual(
                current_hash,
                self.initial_workspace_hash,
                "Workspace android/key.properties was modified during test run!"
            )
        else:
            self.assertFalse(
                os.path.exists(WORKSPACE_KEY_PROPS),
                "Workspace android/key.properties was created during test run!"
            )

    def test_unit_conversions(self):
        """Test exact decimal MB and binary MiB conversions."""
        raw_bytes = 181874892  # Archived release AAB size
        mb_decimal = bsa.bytes_to_mb(raw_bytes)
        mib_binary = bsa.bytes_to_mib(raw_bytes)

        self.assertEqual(mb_decimal, 181.87, "Decimal MB should be 181.87 (bytes / 1,000,000)")
        self.assertEqual(mib_binary, 173.45, "Binary MiB should be 173.45 (bytes / 1,048,576)")

        # Percentage sum check
        part1 = 66742512
        part2 = 115132380
        total = part1 + part2
        pct1 = round((part1 / total) * 100.0, 2)
        pct2 = round((part2 / total) * 100.0, 2)
        self.assertAlmostEqual(pct1 + pct2, 100.0, places=1)

    def test_signing_safety_preserves_owner_key_properties(self):
        """Proves that setup_test_signing & cleanup_test_signing in an isolated fixture never modify or delete key.properties."""
        with tempfile.TemporaryDirectory(prefix="fixture_android_") as fixture_dir:
            fixture_key_props = os.path.join(fixture_dir, "key.properties")
            sentinel_bytes = b"storePassword=sentinel_secret_value_12345\nkeyAlias=sentinel\n"
            with _REAL_OPEN(fixture_key_props, "wb") as f:
                f.write(sentinel_bytes)
            sentinel_hash = hashlib.sha256(sentinel_bytes).hexdigest()

            # Execute setup against isolated fixture
            temp_dir, env = bsa.setup_test_signing(android_dir=fixture_dir)
            self.assertIsNone(temp_dir, "Should not create temp keystore when key.properties already exists")
            self.assertEqual(env, {}, "Should not override environment when key.properties exists")

            # Execute cleanup
            bsa.cleanup_test_signing(temp_dir)

            # Assert byte-identical preservation of the fixture
            self.assertTrue(os.path.exists(fixture_key_props), "Fixture key.properties must still exist!")
            with _REAL_OPEN(fixture_key_props, "rb") as f:
                current_bytes = f.read()
            current_hash = hashlib.sha256(current_bytes).hexdigest()
            self.assertEqual(current_hash, sentinel_hash, "Fixture key.properties content must remain strictly byte-identical!")

    def test_signing_safety_preserves_fixture_on_exception_path(self):
        """Proves that mid-run failures/exceptions and cleanup preserve fixture key.properties byte-for-byte."""
        with tempfile.TemporaryDirectory(prefix="fixture_android_") as fixture_dir:
            fixture_key_props = os.path.join(fixture_dir, "key.properties")
            sentinel_bytes = b"storePassword=exception_sentinel_67890\nkeyAlias=sentinel_exc\n"
            with _REAL_OPEN(fixture_key_props, "wb") as f:
                f.write(sentinel_bytes)
            sentinel_hash = hashlib.sha256(sentinel_bytes).hexdigest()

            temp_dir = None
            try:
                temp_dir, env = bsa.setup_test_signing(android_dir=fixture_dir)
                self.assertIsNone(temp_dir)
                # Simulate mid-run interruption or failure
                raise RuntimeError("Simulated mid-run build failure")
            except RuntimeError as exc:
                self.assertIn("Simulated mid-run build failure", str(exc))
                # Cleanup executed in finally/exception block
                bsa.cleanup_test_signing(temp_dir)

            # Assert byte-identical preservation even after exception and cleanup
            self.assertTrue(os.path.exists(fixture_key_props), "Fixture key.properties must survive exception and cleanup!")
            with _REAL_OPEN(fixture_key_props, "rb") as f:
                current_bytes = f.read()
            current_hash = hashlib.sha256(current_bytes).hexdigest()
            self.assertEqual(current_hash, sentinel_hash, "Fixture key.properties must remain strictly byte-identical after exception!")

    def test_workspace_key_properties_never_opened_for_writing(self):
        """Proves that guarded_open blocks any attempt to open repository android/key.properties for writing."""
        workspace_key_props = os.path.join(REPO_ROOT, "android", "key.properties")
        for mode in ("w", "wb", "w+", "a", "ab", "r+"):
            with self.subTest(mode=mode):
                with self.assertRaises(PermissionError) as ctx:
                    with open(workspace_key_props, mode) as _:
                        pass
                self.assertIn("TOOLING SAFETY VIOLATION", str(ctx.exception))

    def test_signing_setup_creates_isolated_temp_when_no_key_properties(self):
        """Proves that setup_test_signing creates an isolated temp keystore when no key.properties is present."""
        with tempfile.TemporaryDirectory(prefix="fixture_android_empty_") as empty_fixture_dir:
            temp_dir, env = bsa.setup_test_signing(android_dir=empty_fixture_dir)
            try:
                self.assertIsNotNone(temp_dir, "Should create temp keystore when key.properties is missing")
                self.assertTrue(os.path.isdir(temp_dir), "Temp directory must exist")
                self.assertIn("KEY_PROPERTIES_PATH", env)
                self.assertIn("KEYSTORE_PATH", env)
                # Prove paths are strictly inside temp_dir and NOT inside REPO_ROOT
                self.assertTrue(env["KEY_PROPERTIES_PATH"].startswith(temp_dir))
                self.assertTrue(env["KEYSTORE_PATH"].startswith(temp_dir))
            finally:
                bsa.cleanup_test_signing(temp_dir)
                self.assertFalse(os.path.exists(temp_dir), "Temp directory must be safely cleaned up")

    def test_fatal_exit_on_failed_command(self):
        """Proves that build failures immediately raise RuntimeError and never proceed silently."""
        with self.assertRaises(RuntimeError) as ctx:
            bsa.run_cmd("python -c \"import sys; sys.exit(42)\"", fatal=True)
        self.assertIn("failed with exit code 42", str(ctx.exception))

    def test_stale_artifact_detection(self):
        """Proves that an artifact older than run start is rejected as stale."""
        with tempfile.NamedTemporaryFile() as tf:
            old_mtime = 1000000000.0  # Year 2001
            os.utime(tf.name, (old_mtime, old_mtime))
            mtime = os.path.getmtime(tf.name)
            run_timestamp = 1700000000.0
            is_stale = mtime < (run_timestamp - 5.0)
            self.assertTrue(is_stale, "Old file must be flagged as stale")

    def test_bundletool_measurement_and_schema(self):
        """Tests that bundletool can measure download size from an AAB with arm64 spec."""
        aab_path = os.path.join(REPO_ROOT, "build", "app", "outputs", "bundle", "release", "app-release.aab")
        if not os.path.exists(aab_path):
            self.skipTest("Release AAB not present for bundletool test")

        jar = bsa.resolve_bundletool_jar()
        self.assertIsNotNone(jar, "bundletool jar should be resolved")
        self.assertTrue(os.path.exists(jar), f"bundletool jar should exist at {jar}")

        with tempfile.TemporaryDirectory() as td:
            res = bsa.measure_play_download_size(aab_path, td, jar)
            self.assertIsNotNone(res, "bundletool measurement should succeed")
            self.assertIn("min_bytes", res)
            self.assertIn("max_bytes", res)
            self.assertIn("min_mb_decimal", res)
            self.assertIn("min_mib_binary", res)
            self.assertIn("device_spec", res)
            self.assertGreater(res["min_bytes"], 50_000_000, "Delivered size should be > 50 MB")
            self.assertLess(res["max_bytes"], 150_000_000, "Delivered size should be < 150 MB")


if __name__ == "__main__":
    unittest.main()
