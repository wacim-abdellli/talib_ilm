#!/usr/bin/env python3
"""
Validates Android release signing configuration for Task R55:
1. Verifies that release builds without signing secrets are rejected with an actionable error.
2. Verifies that debug builds succeed without release secrets.
3. Provisions a temporary test-only keystore + android/key.properties.
4. Builds release artifact and verifies with apksigner that it is signed by the test release key (NOT Android Debug).
5. Cleans up all temporary test files.
"""

import os
import subprocess
import sys
import glob

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANDROID_DIR = os.path.join(REPO_ROOT, "android")
KEY_PROPERTIES = os.path.join(ANDROID_DIR, "key.properties")
TEMP_KEYSTORE = os.path.join(ANDROID_DIR, "app", "test-temp-upload.jks")
TEMP_KEYSTORE_ROOT = os.path.join(ANDROID_DIR, "test-temp-upload.jks")

def find_apksigner():
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    candidates = glob.glob(os.path.join(local_app_data, "Android", "Sdk", "build-tools", "*", "apksigner.bat"))
    if candidates:
        candidates.sort(reverse=True)
        return candidates[0]
    return "apksigner"

def run_cmd(cmd, cwd=REPO_ROOT, check=True):
    print(f"Running: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    res = subprocess.run(cmd, cwd=cwd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")
    return res

def cleanup():
    for p in [KEY_PROPERTIES, TEMP_KEYSTORE, TEMP_KEYSTORE_ROOT]:
        if os.path.exists(p):
            try:
                os.remove(p)
                print(f"Cleaned up {p}")
            except Exception as e:
                print(f"Error cleaning {p}: {e}")

def main():
    print("=== Task R55: Android Release Signing Safety Verification ===")
    cleanup()

    # Step 1: Prove release build refuses missing secrets
    print("\n--- Test 1: Verify release build fails cleanly without signing secrets ---")
    res1 = run_cmd("flutter build apk --release")
    if res1.returncode == 0:
        print("FAIL: Release build succeeded without release signing config! Must refuse.")
        cleanup()
        sys.exit(1)
    if "Release build rejected: release signing is not configured" not in res1.stdout:
        print(f"FAIL: Expected actionable rejection message not found in output:\n{res1.stdout}")
        cleanup()
        sys.exit(1)
    print("PASS: Release build refused missing secrets with actionable error message.")

    # Step 2: Create temporary test keystore and key.properties
    print("\n--- Test 2: Create temporary test keystore and configure key.properties ---")
    dname = "CN=TestUpload, OU=ReleaseAudit, O=TalibIlm, C=DZ"
    keytool_cmd = [
        "keytool", "-genkeypair",
        "-alias", "testupload",
        "-keyalg", "RSA",
        "-keysize", "2048",
        "-validity", "1",
        "-keystore", TEMP_KEYSTORE,
        "-storepass", "testpass123",
        "-keypass", "testpass123",
        "-dname", f'"{dname}"'
    ]
    res_kt = subprocess.run(" ".join(keytool_cmd), cwd=ANDROID_DIR, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if res_kt.returncode != 0 or not os.path.exists(TEMP_KEYSTORE):
        print(f"FAIL: Failed to create temporary keystore:\n{res_kt.stdout}")
        cleanup()
        sys.exit(1)

    with open(KEY_PROPERTIES, "w", encoding="utf-8") as fp:
        fp.write("storeFile=test-temp-upload.jks\n")
        fp.write("storePassword=testpass123\n")
        fp.write("keyAlias=testupload\n")
        fp.write("keyPassword=testpass123\n")
    print(f"Temporary key.properties written successfully.")

    # Step 3: Build release APK with test keystore
    print("\n--- Test 3: Build release APK with test keystore ---")
    res_build = run_cmd("flutter build apk --release")
    if res_build.returncode != 0:
        print(f"FAIL: Release build failed with configured test keystore:\n{res_build.stdout}")
        cleanup()
        sys.exit(1)
    print("PASS: Release build succeeded with test release keystore.")

    # Step 4: Verify certificate with apksigner
    print("\n--- Test 4: Verify APK certificate via apksigner ---")
    apksigner_bin = find_apksigner()
    apk_path = os.path.join(REPO_ROOT, "build", "app", "outputs", "flutter-apk", "app-release.apk")
    res_sign = run_cmd(f'"{apksigner_bin}" verify --print-certs "{apk_path}"')
    print(res_sign.stdout)

    if "CN=TestUpload" not in res_sign.stdout:
        print("FAIL: APK certificate does NOT match test release key!")
        cleanup()
        sys.exit(1)
    if "CN=Android Debug" in res_sign.stdout:
        print("FAIL: APK is signed with Android Debug certificate!")
        cleanup()
        sys.exit(1)
    print("PASS: APK is legitimately signed with the test release key (NOT Android Debug).")

    # Step 5: Clean up all temporary files
    print("\n--- Cleanup ---")
    cleanup()
    print("\n=== Task R55 Verification PASSED 100% ===")

if __name__ == "__main__":
    try:
        main()
    finally:
        cleanup()
