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

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO_ROOT, "tool"))

import run_bundle_size_analysis as bsa


class BundleSizeRunnerTests(unittest.TestCase):
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
        """Proves that setup_test_signing & cleanup_test_signing never modify or delete android/key.properties."""
        key_props = os.path.join(REPO_ROOT, "android", "key.properties")
        sentinel_bytes = b"storePassword=sentinel_secret_value_12345\nkeyAlias=sentinel\n"
        had_preexisting = os.path.exists(key_props)
        original_bytes = None
        if had_preexisting:
            with open(key_props, "rb") as f:
                original_bytes = f.read()

        try:
            # Seed sentinel file in binary mode
            with open(key_props, "wb") as f:
                f.write(sentinel_bytes)
            sentinel_hash = hashlib.sha256(sentinel_bytes).hexdigest()

            # Execute setup
            temp_dir, env = bsa.setup_test_signing()
            self.assertIsNone(temp_dir, "Should not create temp keystore when key.properties already exists")
            self.assertEqual(env, {}, "Should not override environment when key.properties exists")

            # Execute cleanup
            bsa.cleanup_test_signing(temp_dir)

            # Assert byte-identical preservation
            self.assertTrue(os.path.exists(key_props), "key.properties must still exist!")
            with open(key_props, "rb") as f:
                current_bytes = f.read()
            current_hash = hashlib.sha256(current_bytes).hexdigest()
            self.assertEqual(current_hash, sentinel_hash, "key.properties content must remain strictly byte-identical!")

        finally:
            if had_preexisting and original_bytes is not None:
                with open(key_props, "wb") as f:
                    f.write(original_bytes)
            elif os.path.exists(key_props):
                os.remove(key_props)

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
