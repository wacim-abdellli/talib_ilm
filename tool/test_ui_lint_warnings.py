#!/usr/bin/env python3
"""
Unit and regression tests for Task R68:
Validates that UI lint debt reduction targets are strictly maintained:
- Zero FAIL rules repository-wide
- Zero RTL directional layout warnings (Alignment.*Left|Right, EdgeInsets.only(left/right))
- Zero numeric SizedBox dimensions (SizedBox(width/height: <n>))
- Allow markers stay strictly at or below cap (cap 10)
"""

import os
import re
import subprocess
import sys
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI_LINT_V2_SCRIPT = os.path.join(REPO_ROOT, "tool", "ui_lint_v2.py")


class TestUiLintDebtReduction(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        result = subprocess.run(
            [sys.executable, UI_LINT_V2_SCRIPT, "--root", REPO_ROOT],
            capture_output=True,
            text=True,
            cwd=REPO_ROOT,
        )
        cls.stdout = result.stdout
        cls.stderr = result.stderr
        cls.exit_code = result.returncode

    def test_lint_executes_successfully(self):
        """ui_lint_v2.py should exit with code 0 indicating no FAIL-level violations."""
        self.assertEqual(
            self.exit_code,
            0,
            f"ui_lint_v2.py failed with exit code {self.exit_code}:\n{self.stderr}\n{self.stdout}",
        )

    def test_zero_fail_rules(self):
        """Verify that zero FAIL rules are triggered across the codebase."""
        fail_matches = re.findall(r"FAIL\s+\d+\s+.*", self.stdout)
        self.assertEqual(
            fail_matches,
            [],
            f"Unexpected FAIL violations found:\n" + "\n".join(fail_matches),
        )

    def test_zero_rtl_directional_warnings(self):
        """Task R68: Verify that RTL directional warnings are 0."""
        rtl_warning = re.search(
            r"WARN\s+(\d+)\s+RTL: EdgeInsets\.only\(left/right\)",
            self.stdout,
        )
        self.assertIsNone(
            rtl_warning,
            f"RTL directional warnings must be 0, found: {rtl_warning.group(0) if rtl_warning else None}",
        )

    def test_zero_numeric_sized_box_warnings(self):
        """Task R68: Verify that SizedBox(width/height: <n>) warnings are 0."""
        sized_box_warning = re.search(
            r"WARN\s+(\d+)\s+SizedBox\(width/height: <n>\)",
            self.stdout,
        )
        self.assertIsNone(
            sized_box_warning,
            f"Numeric SizedBox warnings must be 0, found: {sized_box_warning.group(0) if sized_box_warning else None}",
        )

    def test_allow_markers_within_cap(self):
        """Verify that allow markers do not exceed the cap of 10."""
        match = re.search(r"info\s+allow markers used:\s*(\d+)\s*\(cap\s*(\d+)\)", self.stdout)
        self.assertIsNotNone(match, "Allow markers line not found in lint output")
        used = int(match.group(1))
        cap = int(match.group(2))
        self.assertLessEqual(used, cap, f"Allow markers ({used}) exceeded cap ({cap})")
        self.assertLessEqual(used, 6, f"Allow markers ({used}) must not increase beyond current 6")


if __name__ == "__main__":
    unittest.main()
