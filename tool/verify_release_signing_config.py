#!/usr/bin/env python3
"""
Android Release Signing Safety Verification (Tasks R55 & R61)

Validates Android release signing safety without modifying, overwriting,
or deleting any owner credentials or repository files:
1. Verifies release build is rejected with an actionable exception when signing is unconfigured.
2. Verifies debug build succeeds without release credentials.
3. Provisions a uniquely named temporary test keystore inside an isolated temp directory.
4. Builds release APK using environment variables and verifies signature certificate with apksigner.
5. Strictly cleans up ONLY the unique temporary directory created for the test.
"""

import glob
import os
import shutil
import subprocess
import sys
import tempfile
import uuid

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANDROID_DIR = os.path.join(REPO_ROOT, "android")


def find_apksigner():
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    candidates = glob.glob(os.path.join(local_app_data, "Android", "Sdk", "build-tools", "*", "apksigner.bat"))
    if candidates:
        candidates.sort(reverse=True)
        return candidates[0]
    return "apksigner"


def run_cmd(cmd, cwd=REPO_ROOT, env=None):
    print(f"Running: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    res = subprocess.run(
        cmd,
        cwd=cwd,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        env=env
    )
    return res


class SafeSigningVerifier:
    def __init__(self):
        self.temp_dir = tempfile.mkdtemp(prefix="talib_ilm_signing_test_")
        self.tracked_files = []
        self.empty_props = os.path.join(self.temp_dir, "empty.properties")
        with open(self.empty_props, "w", encoding="utf-8") as f:
            f.write("# Isolated empty properties for signing test seam\n")
        self.tracked_files.append(self.empty_props)

    def get_isolated_env(self, extra_vars=None):
        """Constructs an isolated environment isolating from any local android/key.properties."""
        env = os.environ.copy()
        # Override to point to the empty properties file inside temp_dir
        env["KEY_PROPERTIES_PATH"] = self.empty_props
        # Clear signing environment variables by default
        for k in ["KEYSTORE_PATH", "KEYSTORE_PASSWORD", "KEY_ALIAS", "KEY_PASSWORD"]:
            env.pop(k, None)
        if extra_vars:
            env.update(extra_vars)
        return env

    def test_missing_credentials_refusal(self):
        print("\n--- Test 1: Verify release build fails cleanly without signing secrets ---")
        env = self.get_isolated_env()
        res = run_cmd("flutter build apk --release", env=env)
        if res.returncode == 0:
            raise RuntimeError("FAIL: Release build succeeded without release signing config! Must refuse.")
        if "Release build rejected: release signing is not configured" not in res.stdout:
            raise RuntimeError(f"FAIL: Expected actionable rejection message not found in output:\n{res.stdout}")
        print("PASS: Release build refused missing secrets with actionable error message.")

    def test_debug_build_succeeds(self):
        print("\n--- Test 2: Verify debug build succeeds without release secrets ---")
        env = self.get_isolated_env()
        res = run_cmd("flutter build apk --debug", env=env)
        if res.returncode != 0:
            raise RuntimeError(f"FAIL: Debug build failed without release secrets:\n{res.stdout}")
        print("PASS: Debug build succeeded without release signing secrets.")

    def test_release_build_with_test_key(self):
        print("\n--- Test 3: Create isolated test keystore and verify signed release build ---")
        unique_keystore_name = f"test-upload-{uuid.uuid4().hex[:8]}.jks"
        temp_keystore = os.path.join(self.temp_dir, unique_keystore_name)
        self.tracked_files.append(temp_keystore)

        dname = "CN=TestUpload, OU=ReleaseAudit, O=TalibIlm, C=DZ"
        keytool_cmd = [
            "keytool", "-genkeypair",
            "-alias", "testupload",
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "1",
            "-keystore", f'"{temp_keystore}"',
            "-storepass", "testpass123",
            "-keypass", "testpass123",
            "-dname", f'"{dname}"'
        ]
        res_kt = subprocess.run(
            " ".join(keytool_cmd),
            cwd=self.temp_dir,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        if res_kt.returncode != 0 or not os.path.exists(temp_keystore):
            raise RuntimeError(f"FAIL: Failed to create temporary keystore:\n{res_kt.stdout}")

        env = self.get_isolated_env({
            "KEYSTORE_PATH": temp_keystore,
            "KEYSTORE_PASSWORD": "testpass123",
            "KEY_ALIAS": "testupload",
            "KEY_PASSWORD": "testpass123",
        })

        res_build = run_cmd("flutter build apk --release", env=env)
        if res_build.returncode != 0:
            raise RuntimeError(f"FAIL: Release build failed with configured test keystore:\n{res_build.stdout}")
        print("PASS: Release build succeeded with test release keystore.")

        print("\n--- Test 4: Verify APK certificate via apksigner ---")
        apksigner_bin = find_apksigner()
        apk_path = os.path.join(REPO_ROOT, "build", "app", "outputs", "flutter-apk", "app-release.apk")
        res_sign = run_cmd(f'"{apksigner_bin}" verify --print-certs "{apk_path}"')
        print(res_sign.stdout)

        if "CN=TestUpload" not in res_sign.stdout:
            raise RuntimeError("FAIL: APK certificate does NOT match test release key!")
        if "CN=Android Debug" in res_sign.stdout:
            raise RuntimeError("FAIL: APK is signed with Android Debug certificate!")
        print("PASS: APK is legitimately signed with the test release key (NOT Android Debug).")

    def cleanup(self):
        """Safely cleans up ONLY paths inside self.temp_dir."""
        temp_dir_canonical = os.path.realpath(self.temp_dir)
        for p in self.tracked_files:
            p_canonical = os.path.realpath(p)
            if not p_canonical.startswith(temp_dir_canonical):
                print(f"[SECURITY ALERT] Refusing to delete path outside temp root: {p}")
                continue

        if os.path.exists(self.temp_dir):
            try:
                shutil.rmtree(self.temp_dir, ignore_errors=True)
                print(f"[CLEANUP] Safely removed test temporary directory: {self.temp_dir}")
            except Exception as e:
                print(f"[WARN] Error removing temp dir {self.temp_dir}: {e}")


def main():
    print("=== Task R61: Safe Android Release Signing Verification ===")
    verifier = SafeSigningVerifier()
    try:
        verifier.test_missing_credentials_refusal()
        verifier.test_debug_build_succeeds()
        verifier.test_release_build_with_test_key()
        print("\n=== Task R61 Verification PASSED (All tests passed safely) ===")
    finally:
        verifier.cleanup()


if __name__ == "__main__":
    main()
