#!/usr/bin/env python3
"""
Unit and regression tests for tool/measure_runtime_performance.py (Task R69).
Validates metadata extraction, benchmark log parsing, metric computation, and baseline persistence.
"""

import json
import os
import sys
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO_ROOT, "tool"))
import measure_runtime_performance as mrp


SAMPLE_BENCHMARK_OUTPUT = """
00:00 +0: Task R69 — Runtime Performance & Memory Benchmarks Benchmark 1: Core Startup Initialization Sequence
BENCHMARK_STARTUP: min=500us, mean=1200us, p95=1100us, max=15000us
00:00 +1: Task R69 — Runtime Performance & Memory Benchmarks Benchmark 2: Quran Page Retrieval & Search Latency
BENCHMARK_QURAN_PAGES: 604 pages total=3ms, avg=5us/page
BENCHMARK_QURAN_SEARCH: {"الله":80,"الرحمن":50,"الصلاة":20,"الجنة":25,"الصبر":30}
00:00 +2: Task R69 — Runtime Performance & Memory Benchmarks Benchmark 3: Offline Shamela Syllabus & Text Processing
BENCHMARK_MUTUN_CATALOG: loaded usul thalatha with 7 sections in 1200us
BENCHMARK_MUTUN_TEXT_PARSE: avg=15us over 100 runs
00:00 +3: Task R69 — Runtime Performance & Memory Benchmarks Benchmark 4: Centralized Audio Coordinator Switching Latency
BENCHMARK_AUDIO_SWITCH: total=2400us, avg=12us/switch across 200 switches
00:00 +4: Task R69 — Runtime Performance & Memory Benchmarks Benchmark 5: Prayer Calculation & Algerian Wilayas Timetable Generation
BENCHMARK_PRAYER_WILAYAS: computed 15 wilayas in 14ms, avg=950us/city
00:00 +5: Task R69 — Runtime Performance & Memory Benchmarks Benchmark 6: Prolonged Use Memory Footprint & Storage Retention Bounds
BENCHMARK_PROLONGED_MEMORY: initial=330.0MB, after=331.5MB, delta=1.50MB, time=45ms for 150 sessions
00:00 +6: Task R69 — Runtime Performance & Memory Benchmarks Benchmark 7: Background to Foreground Transition & State Refresh
BENCHMARK_RESUME_REFRESH: resume and re-evaluation completed in 650us
00:00 +7: All tests passed!
"""


class TestPerformanceRunner(unittest.TestCase):
    def test_get_environment_metadata(self):
        meta = mrp.get_environment_metadata()
        self.assertIn("os", meta)
        self.assertIn("processor", meta)
        self.assertIn("python_version", meta)
        self.assertIn("timestamp", meta)
        self.assertIn("flutter_version", meta)
        self.assertIsInstance(meta["attached_devices"], list)

    def test_parse_benchmark_output(self):
        metrics = mrp.parse_benchmark_output(SAMPLE_BENCHMARK_OUTPUT)

        self.assertIn("startup", metrics)
        self.assertEqual(metrics["startup"]["min_us"], 500)
        self.assertEqual(metrics["startup"]["mean_us"], 1200)
        self.assertEqual(metrics["startup"]["p95_us"], 1100)
        self.assertEqual(metrics["startup"]["mean_ms"], 1.2)

        self.assertIn("quran_pages", metrics)
        self.assertEqual(metrics["quran_pages"]["total_604_pages_ms"], 3)
        self.assertEqual(metrics["quran_pages"]["avg_page_retrieval_us"], 5)

        self.assertIn("quran_search", metrics)
        self.assertEqual(metrics["quran_search"]["الله"], 80)
        self.assertEqual(metrics["quran_search"]["الرحمن"], 50)

        self.assertIn("mutun_catalog_sections", metrics)
        self.assertEqual(metrics["mutun_catalog_sections"], 7)
        self.assertEqual(metrics["mutun_catalog_load_us"], 1200)
        self.assertEqual(metrics["mutun_text_parse_avg_us"], 15)

        self.assertIn("audio_switch", metrics)
        self.assertEqual(metrics["audio_switch"]["avg_us"], 12)
        self.assertEqual(metrics["audio_switch"]["switches"], 200)

        self.assertIn("prayer_wilayas", metrics)
        self.assertEqual(metrics["prayer_wilayas"]["wilayas_computed"], 15)
        self.assertEqual(metrics["prayer_wilayas"]["avg_city_us"], 950)

        self.assertIn("memory", metrics)
        self.assertEqual(metrics["memory"]["initial_rss_mb"], 330.0)
        self.assertEqual(metrics["memory"]["after_rss_mb"], 331.5)
        self.assertEqual(metrics["memory"]["delta_rss_mb"], 1.50)
        self.assertEqual(metrics["memory"]["sessions_count"], 150)

        self.assertIn("resume_refresh_us", metrics)
        self.assertEqual(metrics["resume_refresh_us"], 650)

    def test_baseline_json_exists_and_valid(self):
        self.assertTrue(os.path.exists(mrp.BASELINE_JSON_PATH))
        with open(mrp.BASELINE_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        self.assertIn("metadata", data)
        self.assertIn("metrics", data)
        self.assertIn("startup", data["metrics"])
        self.assertIn("quran_pages", data["metrics"])
        self.assertIn("quran_search", data["metrics"])
        self.assertIn("audio_switch", data["metrics"])
        self.assertIn("prayer_wilayas", data["metrics"])
        self.assertIn("memory", data["metrics"])


if __name__ == "__main__":
    unittest.main()
