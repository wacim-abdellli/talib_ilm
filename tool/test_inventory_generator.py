#!/usr/bin/env python3
"""
test_inventory_generator.py — Regression tests for tool/generate_code_and_asset_inventory.py

Verifies that the code and asset inventory generator runs reliably,
correctly parses tracked files, detects oversized files, finds all allow markers,
and emits the comprehensive markdown inventory report.
"""

import unittest
import tempfile
import sys
from pathlib import Path

# Add tool directory to import path
TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))

import generate_code_and_asset_inventory as gen


class TestInventoryGenerator(unittest.TestCase):
    def setUp(self):
        self.repo_root = gen.get_repo_root()

    def test_repo_root_exists(self):
        self.assertTrue(self.repo_root.exists())
        self.assertTrue((self.repo_root / "pubspec.yaml").is_file())

    def test_get_git_tracked_files(self):
        files = gen.get_git_tracked_files(self.repo_root)
        self.assertGreater(len(files), 1000)
        self.assertIn("pubspec.yaml", files)
        self.assertIn("lib/main.dart", files)
        self.assertIn("packages/qcf_quran_plus/pubspec.yaml", files)

    def test_count_file_lines(self):
        with tempfile.NamedTemporaryFile("w", delete=False, encoding="utf-8") as tf:
            tf.write("line 1\nline 2\nline 3\n")
            temp_path = Path(tf.name)
        try:
            self.assertEqual(gen.count_file_lines(temp_path), 3)
        finally:
            temp_path.unlink()

    def test_collect_inventory_counts(self):
        files = gen.get_git_tracked_files(self.repo_root)
        inv = gen.collect_inventory(self.repo_root, files)

        # Check first-party Dart files
        fp_dart = inv["categories"]["first_party_dart"]
        self.assertGreater(len(fp_dart), 300)

        # Check vendored Dart files
        v_dart = inv["categories"]["vendored_dart"]
        self.assertGreater(len(v_dart), 20)

        # Check test Dart files
        t_dart = inv["categories"]["test_dart"]
        self.assertGreater(len(t_dart), 80)

        # Check allow markers: exactly 8 (within cap 10)
        self.assertEqual(len(inv["allow_markers"]), 8)
        self.assertLessEqual(len(inv["allow_markers"]), 10)
        marker_paths = [m["path"] for m in inv["allow_markers"]]
        self.assertIn("lib/core/services/prayer_notification_scheduler.dart", marker_paths)
        self.assertIn("lib/features/radio/data/services/quran_radio_service.dart", marker_paths)

        # Check oversized files
        oversized = inv["oversized_files"]
        oversized_paths = [o["path"] for o in oversized]
        # In first-party code, only static catalogs exceed 600 lines
        self.assertIn("lib/app/theme/app_palette.dart", oversized_paths)
        self.assertIn("lib/features/ilm/data/catalogs/mutun_lessons_catalog.dart", oversized_paths)
        self.assertIn("lib/core/constants/verified_cities.dart", oversized_paths)
        self.assertIn("lib/features/ilm/data/catalogs/mutun_audio_catalog.dart", oversized_paths)

        # Verify zero first-party behavior files > 600 lines
        fp_oversized_behavior = [
            o for o in oversized
            if o["scope"] == "First-party app code" and o["type"] == "Behavior"
        ]
        self.assertEqual(len(fp_oversized_behavior), 0)

    def test_markdown_report_generation(self):
        files = gen.get_git_tracked_files(self.repo_root)
        inv = gen.collect_inventory(self.repo_root, files)
        with tempfile.NamedTemporaryFile("w", delete=False, encoding="utf-8") as tf:
            out_path = Path(tf.name)
        try:
            gen.generate_markdown_report(inv, out_path)
            content = out_path.read_text(encoding="utf-8")
            self.assertIn("# Whole-Repository Code & Asset Inventory Report", content)
            self.assertIn("First-party Dart Code", content)
            self.assertIn("qcf_quran_plus", content)
            self.assertIn("Allow Markers Audit", content)
            self.assertIn("KFC 604 Page Fonts", content)
            self.assertIn("network_security_config.xml", content)
        finally:
            out_path.unlink()


if __name__ == "__main__":
    unittest.main()
