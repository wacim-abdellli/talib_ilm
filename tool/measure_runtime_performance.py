#!/usr/bin/env python3
"""
tool/measure_runtime_performance.py
Task R69 — Automated Runtime Performance, Startup, and Memory Profiler.

Executes reproducible benchmarks across all 7 operational journeys:
1. Cold & warm startup initialization sequence
2. Quran page retrieval & full-text search latency (604 pages, 6236 ayahs)
3. Offline Shamela syllabus catalog load & classical text parsing
4. Centralized audio focus switching & priority arbitration
5. Prayer calculation & Algerian wilayas timetable generation
6. Prolonged use memory footprint & storage retention bounds
7. Background-to-foreground lifecycle transition & state refresh

Collects environment metadata (OS, CPU, Flutter, Dart, build mode, device model).
Saves structured JSON baseline to docs/runtime_performance_baseline.json and prints summary.
"""

import argparse
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import time

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASELINE_JSON_PATH = os.path.join(REPO_ROOT, "docs", "runtime_performance_baseline.json")


def get_environment_metadata():
    """Gathers host environment and Flutter/Dart version metadata."""
    meta = {
        "os": platform.platform(),
        "processor": platform.processor(),
        "python_version": platform.python_version(),
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }

    flutter_bin = shutil.which("flutter") or "flutter"
    try:
        res = subprocess.run([flutter_bin, "--version"], capture_output=True, text=True, cwd=REPO_ROOT, check=False)
        first_line = res.stdout.strip().splitlines()[0] if res.stdout else "Flutter unknown"
        meta["flutter_version"] = first_line
    except Exception:
        meta["flutter_version"] = "Flutter 3.38.7 (pinned)"

    # Check for connected ADB devices
    adb_candidates = [
        "adb",
        os.path.expanduser(r"~\AppData\Local\Android\Sdk\platform-tools\adb.exe"),
    ]
    meta["attached_devices"] = []
    for adb in adb_candidates:
        try:
            res = subprocess.run([adb, "devices"], capture_output=True, text=True, check=False)
            lines = [l.strip() for l in res.stdout.splitlines() if l.strip() and not l.startswith("List of")]
            if lines:
                meta["attached_devices"] = lines
                meta["adb_binary"] = adb
                break
        except Exception:
            continue

    return meta


def run_flutter_benchmark():
    """Runs test/runtime_performance_benchmarks_test.dart and captures structured metrics."""
    flutter_bin = shutil.which("flutter") or "flutter"
    cmd = [flutter_bin, "test", "test/runtime_performance_benchmarks_test.dart"]
    res = subprocess.run(cmd, capture_output=True, text=True, cwd=REPO_ROOT, check=False)
    output = res.stdout + "\n" + res.stderr
    return res.returncode, output


def parse_benchmark_output(output):
    """Parses BENCHMARK_* logs from the test output."""
    results = {}

    # BENCHMARK_STARTUP: min=585us, mean=1294us, p95=1054us, max=18108us
    m = re.search(r"BENCHMARK_STARTUP:\s*min=(\d+)us,\s*mean=(\d+)us,\s*p95=(\d+)us,\s*max=(\d+)us", output)
    if m:
        results["startup"] = {
            "min_us": int(m.group(1)),
            "mean_us": int(m.group(2)),
            "p95_us": int(m.group(3)),
            "max_us": int(m.group(4)),
            "mean_ms": round(int(m.group(2)) / 1000.0, 3),
        }

    # BENCHMARK_QURAN_PAGES: 604 pages total=4ms, avg=7us/page
    m = re.search(r"BENCHMARK_QURAN_PAGES:\s*604 pages total=(\d+)ms,\s*avg=(\d+)us/page", output)
    if m:
        results["quran_pages"] = {
            "total_604_pages_ms": int(m.group(1)),
            "avg_page_retrieval_us": int(m.group(2)),
        }

    # BENCHMARK_QURAN_SEARCH: {"الله":97,"الرحمن":54,...}
    m = re.search(r"BENCHMARK_QURAN_SEARCH:\s*(\{.*\})", output)
    if m:
        try:
            results["quran_search"] = json.loads(m.group(1))
        except json.JSONDecodeError:
            pass

    # BENCHMARK_MUTUN_CATALOG: loaded usul thalatha with 7 sections in 1354us
    m = re.search(r"BENCHMARK_MUTUN_CATALOG:\s*loaded usul thalatha with (\d+) sections in (\d+)us", output)
    if m:
        results["mutun_catalog_sections"] = int(m.group(1))
        results["mutun_catalog_load_us"] = int(m.group(2))

    # BENCHMARK_MUTUN_TEXT_PARSE: avg=14us over 100 runs
    m = re.search(r"BENCHMARK_MUTUN_TEXT_PARSE:\s*avg=(\d+)us over (\d+) runs", output)
    if m:
        results["mutun_text_parse_avg_us"] = int(m.group(1))
        results["mutun_text_parse_runs"] = int(m.group(2))

    # BENCHMARK_AUDIO_SWITCH: total=2574us, avg=12us/switch across 200 switches
    m = re.search(r"BENCHMARK_AUDIO_SWITCH:\s*total=(\d+)us,\s*avg=(\d+)us/switch across (\d+) switches", output)
    if m:
        results["audio_switch"] = {
            "total_us": int(m.group(1)),
            "avg_us": int(m.group(2)),
            "switches": int(m.group(3)),
        }

    # BENCHMARK_PRAYER_WILAYAS: computed 15 wilayas in 16ms, avg=1073us/city
    m = re.search(r"BENCHMARK_PRAYER_WILAYAS:\s*computed (\d+) wilayas in (\d+)ms,\s*avg=(\d+)us/city", output)
    if m:
        results["prayer_wilayas"] = {
            "wilayas_computed": int(m.group(1)),
            "total_ms": int(m.group(2)),
            "avg_city_us": int(m.group(3)),
        }

    # BENCHMARK_PROLONGED_MEMORY: initial=334.6MB, after=336.0MB, delta=1.39MB, time=52ms for 150 sessions
    m = re.search(
        r"BENCHMARK_PROLONGED_MEMORY:\s*initial=([\d\.]+)MB,\s*after=([\d\.]+)MB,\s*delta=([\d\.]+)MB,\s*time=(\d+)ms for (\d+) sessions",
        output,
    )
    if m:
        results["memory"] = {
            "initial_rss_mb": float(m.group(1)),
            "after_rss_mb": float(m.group(2)),
            "delta_rss_mb": float(m.group(3)),
            "elapsed_ms": int(m.group(4)),
            "sessions_count": int(m.group(5)),
        }

    # BENCHMARK_RESUME_REFRESH: resume and re-evaluation completed in 597us
    m = re.search(r"BENCHMARK_RESUME_REFRESH:\s*resume and re-evaluation completed in (\d+)us", output)
    if m:
        results["resume_refresh_us"] = int(m.group(1))

    return results


def main():
    parser = argparse.ArgumentParser(description="Measure runtime performance and memory baselines")
    parser.add_argument("--save-baseline", action="store_true", default=True, help="Save baseline JSON")
    args = parser.parse_args()

    print("=== talib_ilm Runtime Performance & Memory Profiler ===")
    meta = get_environment_metadata()
    print(f"Host OS: {meta.get('os')}")
    print(f"Flutter: {meta.get('flutter_version')}")
    attached = meta.get("attached_devices")
    if attached:
        print(f"Attached ADB devices: {', '.join(attached)}")
    else:
        print("Attached ADB devices: None detected (running on host engine harness)")

    print("\nRunning automated benchmark test suite...")
    code, output = run_flutter_benchmark()
    if code != 0:
        print(f"ERROR: Benchmark test suite failed (exit code {code}):\n{output}")
        sys.exit(1)

    metrics = parse_benchmark_output(output)
    report = {
        "metadata": meta,
        "metrics": metrics,
    }

    if args.save_baseline:
        with open(BASELINE_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        print(f"\nSaved structured baseline to {os.path.relpath(BASELINE_JSON_PATH, REPO_ROOT)}")

    print("\n=== Measured Baseline Performance Metrics ===")
    startup = metrics.get("startup", {})
    print(f"1. Startup Initialization: mean {startup.get('mean_ms')} ms (p95: {startup.get('p95_us')} us)")
    quran_p = metrics.get("quran_pages", {})
    print(f"2. Quran 604 Pages Indexing: {quran_p.get('total_604_pages_ms')} ms total ({quran_p.get('avg_page_retrieval_us')} us/page)")
    qs = metrics.get("quran_search", {})
    print(f"   Quran Search Latency: {json.dumps(qs, ensure_ascii=False)}")
    print(f"3. Mutun Catalog & Parse: load {metrics.get('mutun_catalog_load_us')} us, parse {metrics.get('mutun_text_parse_avg_us')} us")
    audio = metrics.get("audio_switch", {})
    print(f"4. Audio Focus Arbitration: {audio.get('avg_us')} us/switch across {audio.get('switches')} switches")
    prayer = metrics.get("prayer_wilayas", {})
    print(f"5. Prayer Calculation: {prayer.get('total_ms')} ms across {prayer.get('wilayas_computed')} wilayas ({prayer.get('avg_city_us')} us/city)")
    mem = metrics.get("memory", {})
    print(f"6. Prolonged Memory Footprint: delta {mem.get('delta_rss_mb')} MB over {mem.get('sessions_count')} sessions in {mem.get('elapsed_ms')} ms")
    print(f"7. Resume & State Re-evaluation: {metrics.get('resume_refresh_us')} us")


if __name__ == "__main__":
    main()
