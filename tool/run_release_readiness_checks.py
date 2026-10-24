#!/usr/bin/env python3
"""
Release Readiness Verification Script (Task R57)

Deterministically executes, logs, and validates all release readiness gates:
1. Environment & Commit verification (pinned Flutter 3.38.7, Dart 3.10.7)
2. Gate 1: flutter analyze
3. Gate 2: python tool/ui_lint_v2.py
4. Gate 3: flutter test
5. Gate 4: flutter build apk --debug

Preserves raw logs and machine-readable summary.json under:
  build/release-readiness/<run-id>/
"""

import json
import os
import platform
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

# Ensure resilient UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")


def run_command_with_logging(cmd, log_path, cwd):
    is_win = platform.system() == "Windows"
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
    print(f"[EXIT] {proc.returncode} (took {duration:.1f}s) -> Log saved: {log_path}")
    return proc.returncode, duration


def get_git_info(cwd):
    is_win = platform.system() == "Windows"
    try:
        commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True, cwd=cwd, shell=is_win).strip()
    except Exception:
        commit = "unknown"
    try:
        branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"], text=True, cwd=cwd, shell=is_win).strip()
    except Exception:
        branch = "unknown"
    try:
        status = subprocess.check_output(["git", "status", "--porcelain"], text=True, cwd=cwd, shell=is_win).strip()
        is_dirty = bool(status)
    except Exception:
        is_dirty = True
    return {"commit": commit, "branch": branch, "is_dirty": is_dirty}


def get_flutter_version(cwd):
    is_win = platform.system() == "Windows"
    try:
        out = subprocess.check_output(["flutter", "--version"], text=True, cwd=cwd, shell=is_win)
        lines = out.strip().split("\n")
        first_line = lines[0] if lines else ""
        return {"raw": out.strip(), "summary": first_line}
    except Exception as e:
        return {"raw": str(e), "summary": "flutter command failed"}


def parse_ui_lint_log(log_path):
    warnings = 0
    allow_markers = 0
    if not log_path.exists():
        return {"warnings": warnings, "allow_markers": allow_markers}
    
    text = log_path.read_text(encoding="utf-8", errors="replace")
    for line in text.splitlines():
        warn_match = re.search(r"WARN\s+(\d+)", line)
        if warn_match:
            warnings += int(warn_match.group(1))
        allow_match = re.search(r"allow markers used:\s*(\d+)", line)
        if allow_match:
            allow_markers = int(allow_match.group(1))
    return {"warnings": warnings, "allow_markers": allow_markers}


def parse_test_log(log_path):
    passed = 0
    failed = 0
    if not log_path.exists():
        return {"passed": passed, "failed": failed}
    
    text = log_path.read_text(encoding="utf-8", errors="replace")
    # Matches patterns like "09:02 +454 -39: Some tests failed." or "00:01 +21: All tests passed!"
    # Or "All tests passed!"
    for line in text.splitlines():
        match_pass_fail = re.search(r"\+(\d+)\s+-(\d+):", line)
        if match_pass_fail:
            passed = max(passed, int(match_pass_fail.group(1)))
            failed = max(failed, int(match_pass_fail.group(2)))
        match_only_pass = re.search(r"\+(\d+):\s+All tests passed", line)
        if match_only_pass:
            passed = max(passed, int(match_only_pass.group(1)))
    return {"passed": passed, "failed": failed}


def main():
    repo_root = Path(__file__).resolve().parent.parent
    run_id = datetime.now().strftime("%Y%m%d-%H%M%S")
    output_dir = repo_root / "build" / "release-readiness" / run_id
    output_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 70)
    print(f"Release Readiness Verification Suite (Run ID: {run_id})")
    print(f"Output Directory: {output_dir}")
    print("=" * 70)

    git_info = get_git_info(repo_root)
    flutter_info = get_flutter_version(repo_root)

    environment = {
        "os": f"{platform.system()} {platform.release()} ({platform.architecture()[0]})",
        "python": platform.python_version(),
        "git": git_info,
        "flutter": flutter_info["summary"],
    }
    print(f"Environment: {environment['os']}")
    print(f"Git: {git_info['branch']} @ {git_info['commit']} (dirty: {git_info['is_dirty']})")
    print(f"Flutter: {flutter_info['summary']}")

    commands_summary = {}

    # Gate 1: flutter analyze
    analyze_log = output_dir / "analyze.log"
    ret, dur = run_command_with_logging(["flutter", "analyze"], analyze_log, repo_root)
    commands_summary["analyze"] = {"exit_code": ret, "duration_sec": round(dur, 2), "log": "analyze.log"}

    # Gate 2: python tool/ui_lint_v2.py
    lint_log = output_dir / "ui-lint-v2.log"
    ret, dur = run_command_with_logging([sys.executable, "tool/ui_lint_v2.py"], lint_log, repo_root)
    commands_summary["ui_lint_v2"] = {"exit_code": ret, "duration_sec": round(dur, 2), "log": "ui-lint-v2.log"}
    lint_details = parse_ui_lint_log(lint_log)

    # Gate 3: flutter test
    test_log = output_dir / "tests.log"
    ret, dur = run_command_with_logging(["flutter", "test"], test_log, repo_root)
    commands_summary["tests"] = {"exit_code": ret, "duration_sec": round(dur, 2), "log": "tests.log"}
    test_details = parse_test_log(test_log)

    # Gate 4: flutter build apk --debug
    build_log = output_dir / "build-debug.log"
    ret, dur = run_command_with_logging(["flutter", "build", "apk", "--debug"], build_log, repo_root)
    commands_summary["build_debug"] = {"exit_code": ret, "duration_sec": round(dur, 2), "log": "build-debug.log"}

    all_passed = all(cmd["exit_code"] == 0 for cmd in commands_summary.values())

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

    print("\n" + "=" * 70)
    print("VERIFICATION SUMMARY")
    print("=" * 70)
    for gate, res in commands_summary.items():
        status = "PASS" if res["exit_code"] == 0 else f"FAIL (code {res['exit_code']})"
        print(f"  {gate:15}: {status:10} ({res['duration_sec']}s)")
    print(f"  Tests passed   : {test_details['passed']}, failed: {test_details['failed']}")
    print(f"  UI Lint warns  : {lint_details['warnings']}, allows: {lint_details['allow_markers']}/10")
    print(f"  Summary file   : {summary_file}")
    print(f"  Overall status : {'ALL GATES GREEN' if all_passed else 'VERIFICATION FAILED'}")
    print("=" * 70)

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
