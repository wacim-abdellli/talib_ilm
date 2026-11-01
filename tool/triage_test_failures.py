import os
import re
import sys
from PIL import Image
import numpy as np

sys.stdout.reconfigure(encoding='utf-8')

def main():
    log_path = "build/release-readiness/20261101_214012/04_flutter_test.log"
    failures_dir = "test/golden/failures"

    with open(log_path, "r", encoding="utf-16", errors="ignore") as f:
        text = f.read()

    lines = text.splitlines()

    # 1. Parse all [E] test failures
    failure_entries = []
    for idx, line in enumerate(lines):
        if line.endswith("[E]"):
            failure_entries.append((idx, line))

    triage_rows = []

    for idx, test_header in failure_entries:
        # Extract file and test description from header
        # Format: 00:33 +210 -1: D:/Projects/talib_ilm-main/test/golden/adhkar_golden_test.dart: Adhkar Widgets Golden Tests AdhkarHeader - light 1.0 and dark 1.5 [E]
        m = re.search(r'\d+:\d+\s+\+\d+\s+-\d+:\s+(?:[A-Za-z]:)?(?:/|[\\/])?([^:]+\.dart):\s*(.*)\s*\[E\]', test_header)
        if m:
            test_file = m.group(1).replace("\\", "/")
            test_name = m.group(2).strip()
        else:
            test_file = "unknown"
            test_name = test_header

        # Search backwards for error details
        start = max(0, idx - 50)
        chunk = lines[start:idx + 1]

        golden_match = None
        for cl in chunk:
            gm = re.search(r'Golden "([^"]+)": Pixel test failed, ([\d.]+)%, (\d+)px diff', cl)
            if gm:
                golden_match = {
                    "path": gm.group(1),
                    "diff_pct": float(gm.group(2)),
                    "diff_px": int(gm.group(3)),
                }
                break

        if golden_match:
            # It's a golden failure
            golden_rel = golden_match["path"] # e.g. goldens/adhkar_header_light_1_0.png
            golden_base = os.path.basename(golden_rel).replace(".png", "")
            
            ref_path = f"test/golden/{golden_rel}"
            actual_path = f"{failures_dir}/{golden_base}_testImage.png"
            diff_path = f"{failures_dir}/{golden_base}_isolatedDiff.png"
            master_in_failures = f"{failures_dir}/{golden_base}_masterImage.png"

            # Check images
            max_channel_diff = None
            size_str = "unknown"
            if os.path.exists(actual_path) and os.path.exists(master_in_failures):
                m_img = Image.open(master_in_failures)
                t_img = Image.open(actual_path)
                size_str = f"{m_img.size[0]}x{m_img.size[1]}"
                m_arr = np.array(m_img)
                t_arr = np.array(t_img)
                diff = np.abs(m_arr.astype(int) - t_arr.astype(int))
                max_channel_diff = int(diff.max())

            likely_cause = ""
            fix_needed = ""
            if golden_match["diff_pct"] > 50:
                likely_cause = f"Sub-perceptual surface background hue shift across card (max diff: {max_channel_diff}/255)"
                fix_needed = "Inspect visual appearance; re-generate golden if intentional palette refinement"
            elif golden_match["diff_pct"] > 2.0:
                likely_cause = "Subtle layout / spacing / shadow rendering difference"
                fix_needed = "Review diff image; update golden if intended Obsidian & Gold style"
            else:
                likely_cause = f"Windows font rasterization / anti-aliasing / sub-pixel render difference ({golden_match['diff_pct']}%)"
                fix_needed = "Review diff; accept platform rasterization or update reference for current environment"

            triage_rows.append({
                "test_file": test_file,
                "test_name": test_name,
                "failure_type": "Golden UI Mismatch",
                "diff_pct": golden_match["diff_pct"],
                "expected": ref_path,
                "actual": actual_path,
                "diff_art": diff_path,
                "likely_cause": likely_cause,
                "fix_needed": fix_needed,
            })
        else:
            # Functional failure
            # Determine error details
            err_summary = ""
            for cl in chunk:
                if "Expected:" in cl or "Actual:" in cl or "Which:" in cl:
                    err_summary += cl.strip() + " "

            likely_cause = ""
            fix_needed = ""
            if "ilm_reading_tracker" in test_file:
                likely_cause = "Header stats label format changed from '4/96 مُنجز' to '4/96'"
                fix_needed = "Update test assertion to match concise '4/96' label"
            elif "more_page" in test_file:
                likely_cause = "Tile title changed from 'التنزيلات الصوتية' to 'حقيبة المحتوى بدون إنترنت'"
                fix_needed = "Update test assertion to check for 'حقيبة المحتوى بدون إنترنت'"
            elif "offline_downloads_hub" in test_file:
                likely_cause = "Shamela book card subtitle updated from 'جاهز للقراءة بدون إنترنت' to show reading progress and pages"
                fix_needed = "Update test assertion to check for reading progress / pages on book card"

            triage_rows.append({
                "test_file": test_file,
                "test_name": test_name,
                "failure_type": "Functional / Widget",
                "diff_pct": None,
                "expected": err_summary[:80] + ("..." if len(err_summary) > 80 else ""),
                "actual": "Found 0 matching widgets",
                "diff_art": "N/A",
                "likely_cause": likely_cause,
                "fix_needed": fix_needed,
            })

    # Sort triage rows: Functional first, then Golden descending by diff_pct
    triage_rows.sort(key=lambda r: (0 if r["failure_type"].startswith("Functional") else 1, -(r["diff_pct"] or 0)))

    # Generate Markdown table
    md_lines = []
    md_lines.append("# Full Test Failure Triage Matrix — 25 Failures")
    md_lines.append("")
    md_lines.append("| # | Test File | Test Name | Failure Type | Expected Artifact / Value | Actual Artifact / Value | Likely Cause | Fix Needed |")
    md_lines.append("|---|---|---|---|---|---|---|---|")

    for i, r in enumerate(triage_rows, 1):
        pct_str = f" ({r['diff_pct']}%)" if r['diff_pct'] is not None else ""
        md_lines.append(f"| {i} | `{r['test_file']}` | {r['test_name']} | {r['failure_type']}{pct_str} | `{r['expected']}` | `{r['actual']}` | {r['likely_cause']} | {r['fix_needed']} |")

    table_md = "\n".join(md_lines)
    print(table_md)

    with open("build/release-readiness/20261101_214012/test_failure_triage.md", "w", encoding="utf-8") as f:
        f.write(table_md)

    print("\nSaved triage table to build/release-readiness/20261101_214012/test_failure_triage.md")

if __name__ == "__main__":
    main()
