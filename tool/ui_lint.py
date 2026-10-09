#!/usr/bin/env python3
import os
import re
import sys

# UI consistency guard matching tool/ui_lint.sh
root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src_dir = os.path.join(root_dir, 'lib')
excl_prefix = os.path.normpath(os.path.join(src_dir, 'app', 'theme'))

dart_files = []
for dirpath, _, filenames in os.walk(src_dir):
    for f in filenames:
        if f.endswith('.dart'):
            full_path = os.path.normpath(os.path.join(dirpath, f))
            if not full_path.startswith(excl_prefix):
                dart_files.append(full_path)

rules = [
    ("Raw Color(0x...) literals", re.compile(r'Color\(0x[0-9A-Fa-f]{8}\)'), int(os.environ.get('B_COLOR', 0))),
    ("Raw fontSize: <n>", re.compile(r'fontSize: *[0-9]'), int(os.environ.get('B_FONT', 0))),
    ("Raw fontFamily: '...'", re.compile(r"fontFamily: *'"), int(os.environ.get('B_FAMILY', 0))),
    ("Raw BorderRadius.circular(<n>)", re.compile(r'BorderRadius\.circular\([0-9]'), int(os.environ.get('B_RADIUS', 0))),
    ("Raw EdgeInsets with numbers", re.compile(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\([^)]*[0-9]'), int(os.environ.get('B_INSETS', 0))),
    ("Text smaller than 12", re.compile(r'fontSize: *(9|10|11)(\.[0-9]+)?[,)]'), 0),
    ("Colors.white/black", re.compile(r'Colors\.(white|black)\b'), int(os.environ.get('B_WB', 0))),
    ("isDark ? ... : ...", re.compile(r'isDark *\?'), int(os.environ.get('B_ISDARK', 0))),
    ("Magic bottom spacer (height 80-120)", re.compile(r'SizedBox\(height: *(80|90|100|110|120)\)'), 0),
    ("Hand-written BoxShadow(", re.compile(r'BoxShadow\('), int(os.environ.get('B_SHADOW', 0))),
    ("Raw GestureDetector( (use InkWell/AppButton)", re.compile(r'GestureDetector\('), int(os.environ.get('B_GESTURE', 0))),
]

# Can optionally filter by file or folder
args = sys.argv[1:]
by_file = "--files" in args
if by_file:
    args.remove("--files")

target_filter = os.path.normpath(args[0]) if len(args) > 0 else None
if target_filter:
    dart_files = [f for f in dart_files if target_filter in f]

file_lines = {}
for path in dart_files:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            file_lines[path] = f.readlines()
    except Exception as e:
        print(f"Error reading {path}: {e}")

if by_file:
    print(f"=== UI lint violations by file (filtered: {target_filter or 'all'}) ===")
    file_counts = {}
    for path, lines in file_lines.items():
        rel = os.path.relpath(path, root_dir)
        total_for_file = 0
        details = []
        for label, pattern, _ in rules:
            c = sum(1 for line in lines if pattern.search(line))
            if c > 0:
                total_for_file += c
                details.append(f"{label}: {c}")
        if total_for_file > 0:
            file_counts[rel] = (total_for_file, details)
    
    for rel, (cnt, details) in sorted(file_counts.items(), key=lambda x: x[1][0], reverse=True):
        print(f"{rel:<55} {cnt:>4}  ({', '.join(details)})")
    sys.exit(0)

print("=== UI lint (outside lib/app/theme) ===")
fail = False
for label, pattern, budget in rules:
    count = 0
    for path, lines in file_lines.items():
        for line in lines:
            if pattern.search(line):
                count += 1
    print(f"{label:<46} {count:>5}   (budget {budget})")
    if count > budget:
        fail = True

print()
if fail:
    print("FAIL: budgets exceeded. Fix with tokens; never raise a budget.")
    sys.exit(1)
else:
    print("OK")
