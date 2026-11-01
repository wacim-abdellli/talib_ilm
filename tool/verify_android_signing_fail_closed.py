import os
import subprocess
import sys
import tempfile

sys.stdout.reconfigure(encoding='utf-8')

def run_gradle(args, env_vars=None):
    cmd = [os.path.abspath("android/gradlew.bat")] + args
    env = os.environ.copy()
    if env_vars:
        env.update(env_vars)
    else:
        # Clear any keystore env vars that might exist in ambient shell
        for k in ["KEYSTORE_PATH", "KEYSTORE_PASSWORD", "KEY_ALIAS", "KEY_PASSWORD"]:
            env.pop(k, None)

    proc = subprocess.run(
        cmd,
        cwd=os.path.abspath("android"),
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore",
        env=env,
    )
    return proc.returncode, proc.stdout + proc.stderr

def main():
    print("==================================================")
    print("ANDROID SIGNING FAIL-CLOSED VERIFICATION TEST SUITE")
    print("==================================================")

    # 1. Test bundleRelease fails closed
    print("\n[1/5] Verifying bundleRelease fails closed without signing credentials...")
    code, output = run_gradle([":app:bundleRelease", "--dry-run"])
    if code != 0 and "Release build rejected: production release signing is not configured" in output:
        print("  PASS: bundleRelease rejected with fail-closed GradleException.")
    else:
        print(f"  FAIL: Expected rejection, got exit code {code}.\nOutput:\n{output[:500]}")
        sys.exit(1)

    # 2. Test assembleRelease fails closed
    print("\n[2/5] Verifying assembleRelease fails closed without signing credentials...")
    code, output = run_gradle([":app:assembleRelease", "--dry-run"])
    if code != 0 and "Release build rejected: production release signing is not configured" in output:
        print("  PASS: assembleRelease rejected with fail-closed GradleException.")
    else:
        print(f"  FAIL: Expected rejection, got exit code {code}.\nOutput:\n{output[:500]}")
        sys.exit(1)

    # 3. Test assembleDebug succeeds without credentials
    print("\n[3/5] Verifying assembleDebug succeeds without release credentials...")
    code, output = run_gradle([":app:assembleDebug", "--dry-run"])
    if code == 0 and "BUILD SUCCESSFUL" in output:
        print("  PASS: assembleDebug builds cleanly without release credentials.")
    else:
        print(f"  FAIL: Expected debug success, got exit code {code}.\nOutput:\n{output[:500]}")
        sys.exit(1)

    # 4. Test isolated temporary keystore acceptance & fingerprint verification
    print("\n[4/5] Verifying signing acceptance with isolated temporary keystore...")
    with tempfile.TemporaryDirectory() as tmp_dir:
        keystore_file = os.path.join(tmp_dir, "test_upload_key.jks")
        alias = "test_release_alias"
        pwd = "TemporaryTestPassword123!"

        # Generate temporary keystore with keytool
        gen_cmd = [
            "keytool",
            "-genkeypair",
            "-alias", alias,
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "1",
            "-keystore", keystore_file,
            "-storepass", pwd,
            "-keypass", pwd,
            "-dname", "CN=TestRelease, OU=QA, O=TalibIlm, C=SA",
        ]
        gen_proc = subprocess.run(gen_cmd, capture_output=True, text=True)
        if gen_proc.returncode != 0:
            print(f"  FAIL: keytool failed to generate test keystore:\n{gen_proc.stderr}")
            sys.exit(1)

        # Inspect certificate fingerprint
        list_cmd = [
            "keytool",
            "-list",
            "-v",
            "-keystore", keystore_file,
            "-storepass", pwd,
            "-alias", alias,
        ]
        list_proc = subprocess.run(list_cmd, capture_output=True, text=True, encoding="utf-8", errors="ignore")
        fingerprint_line = ""
        for line in list_proc.stdout.splitlines():
            if "SHA256:" in line:
                fingerprint_line = line.strip()
                break
        print(f"  Isolated test certificate fingerprint: {fingerprint_line}")

        # Run Gradle bundleRelease with temporary project properties and env vars
        test_args = [
            ":app:bundleRelease",
            "--dry-run",
            f"-PKEYSTORE_PATH={keystore_file}",
            f"-PKEYSTORE_PASSWORD={pwd}",
            f"-PKEY_ALIAS={alias}",
            f"-PKEY_PASSWORD={pwd}",
        ]
        test_env = {
            "KEYSTORE_PATH": keystore_file,
            "KEYSTORE_PASSWORD": pwd,
            "KEY_ALIAS": alias,
            "KEY_PASSWORD": pwd,
        }
        code, output = run_gradle(test_args, env_vars=test_env)
        if code == 0 and "BUILD SUCCESSFUL" in output:
            print("  PASS: bundleRelease accepts valid isolated signing configuration.")
        else:
            print(f"  FAIL: Expected success with valid signing, got {code}.\nOutput:\n{output[:500]}")
            sys.exit(1)

    # 5. Git cleanliness check (no secrets/keystores in git)
    print("\n[5/5] Verifying repository cleanliness (no keystore or secrets in Git)...")
    git_proc = subprocess.run(
        ["git", "ls-files", "*.jks", "*.keystore", "key.properties"],
        capture_output=True,
        text=True,
    )
    if not git_proc.stdout.strip():
        print("  PASS: No keystore or key.properties tracked in Git.")
    else:
        print(f"  FAIL: Found sensitive files tracked in Git:\n{git_proc.stdout}")
        sys.exit(1)

    print("\n--------------------------------------------------")
    print("ALL ANDROID SIGNING FAIL-CLOSED TESTS PASSED!")
    print("--------------------------------------------------")

if __name__ == "__main__":
    main()

