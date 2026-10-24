#!/usr/bin/env python3
"""
Unit and regression tests for Task R61:
Validates that release signing verification is completely isolated,
never deletes or alters owner files, and strictly bounds cleanup to temporary roots.
"""

import hashlib
import os
import shutil
import sys
import tempfile
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANDROID_DIR = os.path.join(REPO_ROOT, "android")
KEY_PROPERTIES = os.path.join(ANDROID_DIR, "key.properties")
SENTINEL_CONTENT = "storeFile=my_production_vault.jks\nstorePassword=secret123\nkeyAlias=prod_alias\nkeyPassword=secret456\n# SENTINEL_TEST_R61\n"

sys.path.insert(0, os.path.join(REPO_ROOT, "tool"))
import verify_release_signing_config as vsc


class TestSigningVerifierSafety(unittest.TestCase):
    def setUp(self):
        self.backup_path = None
        if os.path.exists(KEY_PROPERTIES):
            self.backup_path = KEY_PROPERTIES + ".bak_r61_test"
            shutil.copy2(KEY_PROPERTIES, self.backup_path)

        with open(KEY_PROPERTIES, "w", encoding="utf-8") as f:
            f.write(SENTINEL_CONTENT)
        self.sentinel_hash = hashlib.sha256(SENTINEL_CONTENT.encode("utf-8")).hexdigest()

    def tearDown(self):
        if self.backup_path and os.path.exists(self.backup_path):
            shutil.copy2(self.backup_path, KEY_PROPERTIES)
            os.remove(self.backup_path)
        elif os.path.exists(KEY_PROPERTIES):
            os.remove(KEY_PROPERTIES)

    def test_cleanup_never_deletes_or_modifies_key_properties(self):
        """Verify that SafeSigningVerifier instantiation and cleanup never alter android/key.properties."""
        verifier = vsc.SafeSigningVerifier()
        self.assertTrue(os.path.exists(verifier.temp_dir))
        self.assertTrue(os.path.exists(KEY_PROPERTIES))

        verifier.cleanup()

        self.assertTrue(os.path.exists(KEY_PROPERTIES), "android/key.properties was deleted!")
        with open(KEY_PROPERTIES, "r", encoding="utf-8") as f:
            current_content = f.read()
        current_hash = hashlib.sha256(current_content.encode("utf-8")).hexdigest()
        self.assertEqual(current_hash, self.sentinel_hash, "android/key.properties was altered!")

    def test_cleanup_bounds_enforcement(self):
        """Verify that cleanup strictly refuses to delete paths outside the temporary root."""
        verifier = vsc.SafeSigningVerifier()
        try:
            # Simulate a rogue path outside temp_dir
            rogue_path = os.path.abspath(os.path.join(REPO_ROOT, "tool", "dummy_outside.txt"))
            with open(rogue_path, "w", encoding="utf-8") as f:
                f.write("sensitive file")
            verifier.tracked_files.append(rogue_path)

            verifier.cleanup()

            # The rogue path outside temp root must NOT have been deleted
            self.assertTrue(os.path.exists(rogue_path), "Cleanup deleted a path outside temp root!")
            os.remove(rogue_path)
        finally:
            verifier.cleanup()

    def test_isolated_env_configuration(self):
        """Verify that get_isolated_env isolates from local key.properties and clears signing variables."""
        verifier = vsc.SafeSigningVerifier()
        try:
            env = verifier.get_isolated_env({"CUSTOM_VAR": "1"})
            self.assertEqual(env.get("KEY_PROPERTIES_PATH"), verifier.empty_props)
            self.assertNotIn("KEYSTORE_PATH", env)
            self.assertNotIn("KEYSTORE_PASSWORD", env)
            self.assertNotIn("KEY_ALIAS", env)
            self.assertNotIn("KEY_PASSWORD", env)
            self.assertEqual(env.get("CUSTOM_VAR"), "1")
        finally:
            verifier.cleanup()


if __name__ == "__main__":
    unittest.main()
