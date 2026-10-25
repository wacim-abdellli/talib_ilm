#!/usr/bin/env python3
"""
Release Readiness Verification Suite (Task R64)

Deterministic runner and verifier for release readiness gates:
1. Environment & Preflight:
   - Clean HEAD SHA, branch, and status verification.
   - Pinned Flutter (3.38.7), Dart (3.10.7), Java (17+), and Host OS version probing with timeout.
2. Gate 1: Static Analysis (flutter analyze)
3. Gate 2: UI Lint V2 (python tool/ui_lint_v2.py)
4. Gate 3: Automated Test Suite (flutter test) - strict final summary parsing.
5. Gate 4: Debug APK Compilation (flutter build apk --debug) with SHA-256 and size logging.
6. Gate 5: Test-Signed Release AAB Compilation (flutter build appbundle --release)
   and certificate verification (keytool -printcert -jarfile CN=TestUpload).

Outputs:
  build/release-readiness/<run_id>/
    - analyze.log
    - ui-lint-v2.log
    - tests.log
    - build-debug.log
    - build-release-bundle.log
    - verify-bundle-signer.log
    - summary.json
  build/release-readiness/latest/ (symlink/copy of latest run)
"""

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from datetime import datetime
from pathlib import Path

# Ensure resilient UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")


def is_windows():
    """
    Deterministic Windows platform detection without subprocess invocation.
    Uses sys.platform and os.name to prevent re-entrant subprocess calls when
    subprocess.run / Popen are patched during tests or timeout probing.
    """
    return sys.platform == "win32" or os.name == "nt"


def bytes_to_mb(b):
    """Decimal Megabytes (MB = 1,000,000 bytes)."""
    return round(b / 1_000_000, 2)


def bytes_to_mib(b):
    """Binary Mebibytes (MiB = 1,048,576 bytes)."""
    return round(b / (1024 * 1024), 2)


def compute_sha256(file_path):
    h = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def probe_git_info(cwd):
    is_win = is_windows()
    info = {
        "commit": "unknown",
        "branch": "unknown",
        "is_dirty": True,
        "dirty_files": [],
    }
    try:
        r = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
            cwd=cwd,
            shell=is_win,
            timeout=10,
        )
        if r.returncode == 0:
            info["commit"] = r.stdout.strip()
    except Exception as e:
        info["commit_error"] = str(e)

    try:
        r = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            cwd=cwd,
            shell=is_win,
            timeout=10,
        )
        if r.returncode == 0:
            info["branch"] = r.stdout.strip()
    except Exception as e:
        info["branch_error"] = str(e)

    try:
        r = subprocess.run(
            ["git", "status", "--porcelain"],
            capture_output=True,
            text=True,
            cwd=cwd,
            shell=is_win,
            timeout=15,
        )
        if r.returncode == 0:
            status_lines = [l for l in r.stdout.strip().splitlines() if l.strip()]
            info["is_dirty"] = len(status_lines) > 0
            info["dirty_files"] = status_lines
    except Exception as e:
        info["is_dirty"] = True
        info["status_error"] = str(e)

    return info


def probe_flutter_version(cwd, timeout_sec=30):
    env = os.environ.copy()
    env["CI"] = "true"
    env["FLUTTER_SUPPRESS_ANALYTICS"] = "true"

    cmd = ["flutter", "--version"]
    result = {
        "flutter_version": "unknown",
        "dart_version": "unknown",
        "channel": "unknown",
        "summary": "unknown",
        "raw": "",
        "timed_out": False,
        "exit_code": -1,
    }

    print(f"[PREFLIGHT] Probing Flutter & Dart version (timeout={timeout_sec}s)...")
    try:
        is_win = is_windows()
        proc = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            cwd=cwd,
            shell=is_win,
            stdin=subprocess.DEVNULL,
            env=env,
            timeout=timeout_sec,
        )
        result["raw"] = proc.stdout.strip()
        result["exit_code"] = proc.returncode

        # Extract Flutter version and channel
        fl_match = re.search(r"Flutter\s+([\d\.\-]+)\s+•\s+channel\s+([^\s•]+)", proc.stdout)
        if fl_match:
            result["flutter_version"] = fl_match.group(1)
            result["channel"] = fl_match.group(2)

        # Extract Dart version
        dart_match = re.search(r"Dart\s+([\d\.\-]+)", proc.stdout)
        if dart_match:
            result["dart_version"] = dart_match.group(1)

        first_line = proc.stdout.strip().splitlines()[0] if proc.stdout.strip() else ""
        result["summary"] = first_line
    except subprocess.TimeoutExpired:
        print(f"[ERROR] 'flutter --version' timed out after {timeout_sec}s!")
        result["timed_out"] = True
        result["summary"] = f"timed out after {timeout_sec}s"
    except Exception as e:
        print(f"[ERROR] Failed to execute 'flutter --version': {e}")
        result["summary"] = f"execution failed: {e}"

    return result


def probe_java_version(timeout_sec=15):
    result = {
        "version": "unknown",
        "summary": "unknown",
        "raw": "",
        "exit_code": -1,
    }
    print(f"[PREFLIGHT] Probing Java version (timeout={timeout_sec}s)...")
    try:
        is_win = is_windows()
        proc = subprocess.run(
            ["java", "-version"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            shell=is_win,
            stdin=subprocess.DEVNULL,
            timeout=timeout_sec,
        )
        result["raw"] = proc.stdout.strip()
        result["exit_code"] = proc.returncode
        first_line = proc.stdout.strip().splitlines()[0] if proc.stdout.strip() else ""
        result["summary"] = first_line
        v_match = re.search(r'version\s+"([^"]+)"', proc.stdout)
        if v_match:
            result["version"] = v_match.group(1)
    except subprocess.TimeoutExpired:
        print(f"[ERROR] 'java -version' timed out after {timeout_sec}s!")
        result["summary"] = f"timed out after {timeout_sec}s"
    except Exception as e:
        result["summary"] = f"execution failed: {e}"

    return result


def probe_os_version():
    return {
        "system": platform.system(),
        "release": platform.release(),
        "version": platform.version(),
        "machine": platform.machine(),
        "architecture": platform.architecture()[0],
        "summary": f"{platform.system()} {platform.release()} ({platform.architecture()[0]})",
    }


def parse_ui_lint_log(log_path_or_content):
    warnings = 0
    allow_markers = 0
    if isinstance(log_path_or_content, Path):
        if not log_path_or_content.exists():
            return {"warnings": warnings, "allow_markers": allow_markers}
        text = log_path_or_content.read_text(encoding="utf-8", errors="replace")
    elif isinstance(log_path_or_content, str):
        text = log_path_or_content
    else:
        text = str(log_path_or_content)

    for line in text.splitlines():
        warn_match = re.search(r"WARN\s+(\d+)", line)
        if warn_match:
            warnings += int(warn_match.group(1))
        allow_match = re.search(r"allow markers used:\s*(\d+)", line)
        if allow_match:
            allow_markers = int(allow_match.group(1))
    return {"warnings": warnings, "allow_markers": allow_markers}


def parse_test_log(log_input, exit_code=0):
    """
    Parses test counts strictly from the FINAL actual test summary line.
    Never infers pass from intermediate '+N' progress lines.
    Asserts exit_code == 0 and failed == 0.
    """
    if isinstance(log_input, Path):
        if not log_input.exists():
            return {
                "passed": 0,
                "failed": 0,
                "skipped": 0,
                "total": 0,
                "summary_found": False,
                "is_success": False,
                "error": "Log file does not exist",
            }
        text = log_input.read_text(encoding="utf-8", errors="replace")
    elif isinstance(log_input, str):
        text = log_input
    else:
        text = str(log_input)

    # Strip ANSI escape sequences
    text_clean = re.sub(r"\x1b\[[0-9;]*[a-zA-Z]", "", text)

    # Replace carriage returns and split into non-empty lines
    lines = [line.strip() for line in text_clean.replace("\r", "\n").split("\n")]
    lines = [l for l in lines if l]

    if not lines:
        return {
            "passed": 0,
            "failed": 0,
            "skipped": 0,
            "total": 0,
            "summary_found": False,
            "is_success": False,
            "error": "Empty test log",
        }

    # Strict final summary regexes:
    # Pass: 02:46 +548: All tests passed! or +548: All tests passed! or +540 ~2: All tests passed!
    pass_pattern = re.compile(r"^(?:\d+:\d+\s+)?\+(\d+)(?:\s+~(\d+))?:\s+All tests passed!\s*$")
    # Fail: 03:12 +540 -8: Some tests failed. or +540 ~2 -8: Some tests failed.
    fail_pattern = re.compile(r"^(?:\d+:\d+\s+)?\+(\d+)(?:\s+~(\d+))?\s+-(\d+):\s+Some tests failed\.\s*$")

    summary_found = False
    passed = 0
    failed = 0
    skipped = 0

    # Search from the end of the log upwards
    for line in reversed(lines):
        m_pass = pass_pattern.match(line)
        if m_pass:
            summary_found = True
            passed = int(m_pass.group(1))
            skipped = int(m_pass.group(2)) if m_pass.group(2) else 0
            failed = 0
            break

        m_fail = fail_pattern.match(line)
        if m_fail:
            summary_found = True
            passed = int(m_fail.group(1))
            skipped = int(m_fail.group(2)) if m_fail.group(2) else 0
            failed = int(m_fail.group(3))
            break

    total = passed + failed + skipped
    is_success = False
    error = None

    if not summary_found:
        is_success = False
        error = "No final test summary found (interrupted, empty, or compilation failure)"
        if exit_code != 0:
            error += f" [exit code {exit_code}]"
    elif exit_code != 0:
        is_success = False
        error = f"Process exited with non-zero exit code {exit_code}"
    elif failed > 0:
        is_success = False
        error = f"{failed} test(s) failed"
    elif passed == 0:
        is_success = False
        error = "Zero tests passed"
    else:
        is_success = True

    return {
        "passed": passed,
        "failed": failed,
        "skipped": skipped,
        "total": total,
        "summary_found": summary_found,
        "is_success": is_success,
        "error": error,
    }


def run_command_with_logging(cmd, log_path, cwd, env=None, expected_artifact=None):
    is_win = is_windows()
    cmd_display = " ".join(cmd) if isinstance(cmd, list) else cmd
    print(f"\n[RUN] {cmd_display}")
    start_time = time.time()

    cmd_exec = subprocess.list2cmdline(cmd) if is_win and isinstance(cmd, list) else cmd
    shell_val = is_win or isinstance(cmd, str)

    with open(log_path, "w", encoding="utf-8") as log_file:
        proc = subprocess.Popen(
            cmd_exec,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            cwd=cwd,
            shell=shell_val,
            env=env,
        )
        for line in proc.stdout:
            try:
                sys.stdout.write(line)
                sys.stdout.flush()
            except Exception:
                pass
            log_file.write(line)
            log_file.flush()
        proc.wait()

    duration = time.time() - start_time
    print(f"[EXIT] {proc.returncode} (took {duration:.1f}s) -> Log saved: {log_path.name}")

    artifact_info = None
    if expected_artifact:
        art_path = Path(expected_artifact)
        if not art_path.is_absolute():
            art_path = cwd / art_path
        if art_path.exists():
            mtime = art_path.stat().st_mtime
            # Verify artifact was created or modified during this run
            if mtime >= start_time - 5.0:
                size_bytes = art_path.stat().st_size
                sha256 = compute_sha256(art_path)
                artifact_info = {
                    "path": str(art_path.relative_to(cwd) if art_path.is_relative_to(cwd) else art_path),
                    "size_bytes": size_bytes,
                    "size_mb": bytes_to_mb(size_bytes),
                    "size_mib": bytes_to_mib(size_bytes),
                    "sha256": sha256,
                    "fresh": True,
                }
                print(f"[ARTIFACT] {artifact_info['path']} ({artifact_info['size_mb']} MB / {artifact_info['size_mib']} MiB)")
                print(f"[SHA-256]  {sha256}")
            else:
                artifact_info = {
                    "path": str(art_path),
                    "fresh": False,
                    "error": f"Stale artifact detected (mtime {mtime} < start {start_time})",
                }
                print(f"[WARN] Stale artifact detected: {art_path}")
        else:
            artifact_info = {
                "path": str(art_path),
                "fresh": False,
                "error": "Expected artifact was not produced by command",
            }
            print(f"[WARN] Expected artifact was not found: {art_path}")

    return {
        "exit_code": proc.returncode,
        "duration_sec": round(duration, 2),
        "log": log_path.name,
        "artifact": artifact_info,
    }


def build_and_verify_release_bundle(repo_root, output_dir):
    print("\n" + "=" * 70)
    print("GATE 5: Test-Signed Release AAB Compilation & Certificate Verification")
    print("=" * 70)

    # 1. Setup isolated temporary signing directory
    temp_dir = tempfile.mkdtemp(prefix="talib_ilm_readiness_bundle_")
    try:
        empty_props = os.path.join(temp_dir, "empty.properties")
        with open(empty_props, "w", encoding="utf-8") as f:
            f.write("# Isolated empty properties for release readiness check\n")

        keystore_path = os.path.join(temp_dir, f"test-upload-{uuid.uuid4().hex[:8]}.jks")
        dname = "CN=TestUpload, OU=ReleaseReadiness, O=TalibIlm, C=DZ"

        # 2. Generate temporary keystore
        keytool_cmd = [
            "keytool", "-genkeypair",
            "-alias", "testupload",
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "1",
            "-keystore", f'"{keystore_path}"',
            "-storepass", "testpass123",
            "-keypass", "testpass123",
            "-dname", f'"{dname}"',
        ]
        is_win = is_windows()
        res_kt = subprocess.run(
            " ".join(keytool_cmd) if is_win else keytool_cmd,
            shell=is_win,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            cwd=temp_dir,
        )
        if res_kt.returncode != 0 or not os.path.exists(keystore_path):
            return {
                "exit_code": 1,
                "duration_sec": 0,
                "passed": False,
                "error": f"Failed to generate test keystore:\n{res_kt.stdout}",
            }

        # 3. Build release AAB using isolated environment
        env = os.environ.copy()
        env["KEY_PROPERTIES_PATH"] = empty_props
        env["KEYSTORE_PATH"] = keystore_path
        env["KEYSTORE_PASSWORD"] = "testpass123"
        env["KEY_ALIAS"] = "testupload"
        env["KEY_PASSWORD"] = "testpass123"
        env["CI"] = "true"

        bundle_log = output_dir / "build-release-bundle.log"
        expected_aab = repo_root / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"

        bundle_res = run_command_with_logging(
            ["flutter", "build", "appbundle", "--release"],
            bundle_log,
            repo_root,
            env=env,
            expected_artifact=expected_aab,
        )

        if bundle_res["exit_code"] != 0:
            return {
                "exit_code": bundle_res["exit_code"],
                "duration_sec": bundle_res["duration_sec"],
                "log": "build-release-bundle.log",
                "passed": False,
                "error": "Release AAB compilation failed",
                "artifact": bundle_res.get("artifact"),
            }

        # 4. Verify certificate on the AAB using keytool
        signer_log = output_dir / "verify-bundle-signer.log"
        signer_cmd = ["keytool", "-printcert", "-jarfile", str(expected_aab)]
        signer_res = run_command_with_logging(
            signer_cmd,
            signer_log,
            repo_root,
        )

        signer_stdout = signer_log.read_text(encoding="utf-8", errors="replace")
        has_test_signer = "CN=TestUpload" in signer_stdout
        has_debug_signer = "CN=Android Debug" in signer_stdout

        signer_verified = (signer_res["exit_code"] == 0) and has_test_signer and not has_debug_signer

        signer_info = {
            "verified": signer_verified,
            "has_test_signer": has_test_signer,
            "has_debug_signer": has_debug_signer,
            "exit_code": signer_res["exit_code"],
            "log": "verify-bundle-signer.log",
        }

        if not signer_verified:
            err = "AAB certificate verification failed (missing CN=TestUpload or contains CN=Android Debug)"
            print(f"[FAIL] {err}")
            return {
                "exit_code": 1,
                "duration_sec": round(bundle_res["duration_sec"] + signer_res["duration_sec"], 2),
                "log": "build-release-bundle.log",
                "passed": False,
                "error": err,
                "artifact": bundle_res.get("artifact"),
                "signer": signer_info,
            }

        print("[PASS] Release AAB compiled and verified with CN=TestUpload.")
        return {
            "exit_code": 0,
            "duration_sec": round(bundle_res["duration_sec"] + signer_res["duration_sec"], 2),
            "log": "build-release-bundle.log",
            "passed": True,
            "artifact": bundle_res.get("artifact"),
            "signer": signer_info,
        }
    finally:
        # Safely clean up only inside temp_dir
        if os.path.exists(temp_dir):
            try:
                shutil.rmtree(temp_dir, ignore_errors=True)
            except Exception:
                pass


def main():
    parser = argparse.ArgumentParser(description="Run release readiness verification suite (Task R64).")
    parser.add_argument("--require-clean", action="store_true", help="Fail immediately if working directory is dirty.")
    parser.add_argument("--skip-bundle", action="store_true", help="Skip Gate 5 (release AAB compilation and signer check).")
    parser.add_argument("--only-bundle", action="store_true", help="Run only Gate 5 (release AAB compilation and signer check).")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    run_id = datetime.now().strftime("%Y%m%d-%H%M%S")
    output_dir = repo_root / "build" / "release-readiness" / run_id
    output_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 70)
    print(f"Release Readiness Verification Suite (Run ID: {run_id})")
    print(f"Output Directory: {output_dir}")
    print("=" * 70)

    # 1. Probe environment
    git_info = probe_git_info(repo_root)
    flutter_info = probe_flutter_version(repo_root)
    java_info = probe_java_version()
    os_info = probe_os_version()

    environment = {
        "os": os_info,
        "python": platform.python_version(),
        "git": git_info,
        "flutter": flutter_info,
        "java": java_info,
    }

    print(f"Host OS:  {os_info['summary']}")
    print(f"Git:      {git_info['branch']} @ {git_info['commit']} (dirty: {git_info['is_dirty']})")
    print(f"Flutter:  {flutter_info['flutter_version']} (channel {flutter_info['channel']})")
    print(f"Dart:     {flutter_info['dart_version']}")
    print(f"Java:     {java_info['version']}")

    # Check clean git status requirement
    if git_info["is_dirty"]:
        print("\n[WARNING] Git working directory is DIRTY:")
        for line in git_info["dirty_files"][:10]:
            print(f"  {line}")
        if len(git_info["dirty_files"]) > 10:
            print(f"  ... and {len(git_info['dirty_files']) - 10} more files")
        if args.require_clean:
            print("\n[FATAL] --require-clean was specified and working tree is dirty. Aborting.")
            return 1
    else:
        print("[CHECK] Git working directory is strictly CLEAN.")

    # Check Flutter startup failure
    if flutter_info.get("timed_out") or flutter_info.get("exit_code") != 0:
        print("\n[FATAL] Flutter preflight check failed or timed out. Refusing to run gates.")
        summary = {
            "run_id": run_id,
            "timestamp": datetime.now().isoformat(),
            "environment": environment,
            "all_passed": False,
            "error": "Flutter preflight probe failed",
            "gates": {},
        }
        with open(output_dir / "summary.json", "w", encoding="utf-8") as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)
        return 1

    commands_summary = {}
    lint_details = {}
    test_details = {}

    if not args.only_bundle:
        # Gate 1: flutter analyze
        print("\n" + "=" * 70)
        print("GATE 1: flutter analyze")
        print("=" * 70)
        analyze_log = output_dir / "analyze.log"
        res_analyze = run_command_with_logging(["flutter", "analyze"], analyze_log, repo_root)
        commands_summary["analyze"] = {
            "command": "flutter analyze",
            "exit_code": res_analyze["exit_code"],
            "duration_sec": res_analyze["duration_sec"],
            "log": "analyze.log",
            "passed": res_analyze["exit_code"] == 0,
        }

        # Gate 2: python tool/ui_lint_v2.py
        print("\n" + "=" * 70)
        print("GATE 2: python tool/ui_lint_v2.py")
        print("=" * 70)
        lint_log = output_dir / "ui-lint-v2.log"
        res_lint = run_command_with_logging([sys.executable, "tool/ui_lint_v2.py"], lint_log, repo_root)
        lint_details = parse_ui_lint_log(lint_log)
        lint_passed = (res_lint["exit_code"] == 0) and (lint_details["allow_markers"] <= 10)
        commands_summary["ui_lint_v2"] = {
            "command": "python tool/ui_lint_v2.py",
            "exit_code": res_lint["exit_code"],
            "duration_sec": res_lint["duration_sec"],
            "log": "ui-lint-v2.log",
            "passed": lint_passed,
            "warnings": lint_details["warnings"],
            "allow_markers": lint_details["allow_markers"],
        }

        # Gate 3: flutter test
        print("\n" + "=" * 70)
        print("GATE 3: flutter test")
        print("=" * 70)
        test_log = output_dir / "tests.log"
        res_tests = run_command_with_logging(["flutter", "test"], test_log, repo_root)
        test_details = parse_test_log(test_log, exit_code=res_tests["exit_code"])
        commands_summary["tests"] = {
            "command": "flutter test",
            "exit_code": res_tests["exit_code"],
            "duration_sec": res_tests["duration_sec"],
            "log": "tests.log",
            "passed": test_details["is_success"],
            "test_counts": test_details,
        }

        # Gate 4: flutter build apk --debug
        print("\n" + "=" * 70)
        print("GATE 4: flutter build apk --debug")
        print("=" * 70)
        build_log = output_dir / "build-debug.log"
        expected_debug_apk = repo_root / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk"
        res_build = run_command_with_logging(
            ["flutter", "build", "apk", "--debug"],
            build_log,
            repo_root,
            expected_artifact=expected_debug_apk,
        )
        debug_passed = (res_build["exit_code"] == 0) and bool(res_build.get("artifact", {}).get("fresh"))
        commands_summary["build_debug_apk"] = {
            "command": "flutter build apk --debug",
            "exit_code": res_build["exit_code"],
            "duration_sec": res_build["duration_sec"],
            "log": "build-debug.log",
            "passed": debug_passed,
            "artifact": res_build.get("artifact"),
        }

    # Gate 5: Test-Signed Release AAB Verification
    if not args.skip_bundle:
        res_bundle = build_and_verify_release_bundle(repo_root, output_dir)
        commands_summary["release_bundle_verification"] = {
            "command": "flutter build appbundle --release && keytool -printcert -jarfile",
            "exit_code": res_bundle["exit_code"],
            "duration_sec": res_bundle["duration_sec"],
            "log": res_bundle.get("log", "build-release-bundle.log"),
            "passed": res_bundle.get("passed", False),
            "artifact": res_bundle.get("artifact"),
            "signer": res_bundle.get("signer"),
            "error": res_bundle.get("error"),
        }

    all_passed = all(g.get("passed", False) for g in commands_summary.values())

    summary = {
        "run_id": run_id,
        "timestamp": datetime.now().isoformat(),
        "environment": environment,
        "all_passed": all_passed,
        "gates": commands_summary,
        "lint_details": lint_details,
        "test_details": test_details,
    }

    summary_file = output_dir / "summary.json"
    with open(summary_file, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)

    # Mirror to build/release-readiness/latest/
    latest_dir = repo_root / "build" / "release-readiness" / "latest"
    try:
        if latest_dir.exists():
            shutil.rmtree(latest_dir, ignore_errors=True)
        shutil.copytree(output_dir, latest_dir)
    except Exception as e:
        print(f"[WARN] Failed to mirror report to latest directory: {e}")

    print("\n" + "=" * 70)
    print("VERIFICATION SUMMARY")
    print("=" * 70)
    print(f"Run ID:        {run_id}")
    print(f"Commit:        {git_info['commit']} (dirty: {git_info['is_dirty']})")
    print(f"Environment:   {os_info['summary']} | Flutter {flutter_info['flutter_version']} | Dart {flutter_info['dart_version']} | Java {java_info['version']}")
    print("-" * 70)
    for gate_name, res in commands_summary.items():
        status = "PASS" if res.get("passed") else f"FAIL (exit {res.get('exit_code')})"
        dur = f"{res.get('duration_sec', 0):.1f}s"
        print(f"  {gate_name:28}: {status:12} ({dur})")
        if "artifact" in res and res["artifact"] and res["artifact"].get("sha256"):
            art = res["artifact"]
            print(f"    Artifact: {art.get('path')} ({art.get('size_mb')} MB / {art.get('size_mib')} MiB)")
            print(f"    SHA-256:  {art.get('sha256')}")

    if test_details.get("summary_found"):
        print(f"\n  Tests Passed : {test_details.get('passed')}, Failed: {test_details.get('failed')}, Skipped: {test_details.get('skipped')}")
    if lint_details:
        print(f"  UI Lint Warns: {lint_details.get('warnings')}, Allow Markers: {lint_details.get('allow_markers')}/10")
    print(f"  Summary JSON : {summary_file}")
    print(f"  OVERALL RESULT: {'ALL GATES GREEN (RELEASE READINESS CONFIRMED)' if all_passed else 'VERIFICATION FAILED'}")
    print("=" * 70)

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
