#!/usr/bin/env python3
"""UI lint v2 for talib_ilm: catches what ui_lint v1 missed (Color.fromARGB, Radius.circular, Colors.red,
raw TextStyle(, Duration literals, icon size, RTL left/right, IconButton without tooltip, leftover @Deprecated shims).

Usage (repo root):   python3 tool/ui_lint_v2.py            -> exit 1 on any FAIL rule
                     python3 tool/ui_lint_v2.py --strict   -> WARN rules also fail
                     python3 tool/ui_lint_v2.py --top 8    -> show worst files per rule
Allowed escape hatch: a line containing `// ui-lint: allow <reason>` is skipped, but the TOTAL number of
allow markers is capped (--max-allow, default 10) so the hatch cannot be used to cheat.
Raw values are legal ONLY inside lib/app/theme/ .
"""
import argparse, os, re, sys
from collections import Counter

ap = argparse.ArgumentParser()
ap.add_argument("--root", default=".")
ap.add_argument("--strict", action="store_true")
ap.add_argument("--top", type=int, default=0)
ap.add_argument("--max-allow", type=int, default=10)
a = ap.parse_args()

LIB = os.path.join(a.root, "lib")
THEME = os.path.normpath(os.path.join(LIB, "app", "theme"))
ALLOW = re.compile(r"//\s*ui-lint:\s*allow\b")

# (level, label, regex)  -- single-line rules
RULES = [
    ("FAIL", "Color(0x..) / Color.fromARGB / fromRGBO",   re.compile(r"\bColor\(\s*0x|Color\.from(ARGB|RGBO)\(")),
    ("FAIL", "Colors.<anything> except transparent",       re.compile(r"\bColors\.(?!transparent\b)\w+")),
    ("FAIL", "Radius.circular(<n>) (covers BorderRadius.only/all)", re.compile(r"Radius\.circular\(\s*[0-9]")),
    ("FAIL", "BorderRadius.circular(<n>)",                 re.compile(r"BorderRadius\.circular\(\s*[0-9]")),
    ("FAIL", "raw TextStyle( constructor",                 re.compile(r"\bTextStyle\(")),
    ("FAIL", "fontSize / fontFamily literal",              re.compile(r"\b(fontSize|fontFamily)\s*:\s*['\"0-9]")),
    ("FAIL", "EdgeInsets with numbers",                    re.compile(r"EdgeInsets(Directional)?\.(all|symmetric|only|fromLTRB|fromSTEB)\([^)]*[0-9]")),
    ("FAIL", "Duration(milliseconds/seconds) literal",     re.compile(r"\bDuration\(\s*(milliseconds|seconds|microseconds)")),
    ("FAIL", "Icon size: <n>",                             re.compile(r"\bsize\s*:\s*[0-9]")),
    ("FAIL", "brightness / isDark branching in a screen",  re.compile(r"Brightness\.(dark|light)|\.brightness\b|platformBrightness|\bisDark\s*\?")),
    ("FAIL", "hand-written BoxShadow(",                    re.compile(r"\bBoxShadow\(")),
    ("FAIL", "bare GestureDetector( (use InkWell/AppButton)", re.compile(r"\bGestureDetector\(")),
    ("FAIL", "deprecated .withOpacity(",                   re.compile(r"\.withOpacity\(")),
    ("WARN", "SizedBox(width/height: <n>) (use AppSpace)", re.compile(r"SizedBox\([^)]*(width|height)\s*:\s*[0-9]")),
    ("WARN", "RTL: EdgeInsets.only(left/right) / Alignment.*Left|Right", re.compile(r"EdgeInsets\.only\([^)]*\b(left|right)\s*:|Alignment\.(center|top|bottom)(Left|Right)\b")),
    ("WARN", "RTL: Positioned(left/right) (use PositionedDirectional)", re.compile(r"\bPositioned\([^)]*\b(left|right)\s*:")),
    ("WARN", "gradient on a surface (Linear/RadialGradient)", re.compile(r"\b(Linear|Radial|Sweep)Gradient\(")),
    ("WARN", "FontWeight literal (use text styles)",       re.compile(r"\bFontWeight\.w[0-9]")),
]

fails, warns = Counter(), Counter()
per_file = {}          # label -> Counter(file)
allow_total = 0
shims = 0
icon_no_tooltip = Counter()

def bump(level, label, path):
    (fails if level == "FAIL" else warns)[label] += 1
    per_file.setdefault(label, Counter())[os.path.relpath(path, a.root)] += 1

for dp, dn, fn in os.walk(LIB):
    for f in fn:
        if not f.endswith(".dart") or f.endswith((".g.dart", ".freezed.dart")):
            continue
        path = os.path.join(dp, f)
        in_theme = os.path.normpath(dp).startswith(THEME)
        try:
            lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
        except OSError:
            continue
        if in_theme:
            shims += sum(1 for l in lines if "@Deprecated" in l)
            continue
        for i, line in enumerate(lines):
            s = line.strip()
            if s.startswith("//") and not ALLOW.search(s):
                continue
            if ALLOW.search(line):
                allow_total += 1
                continue
            for level, label, rx in RULES:
                if rx.search(line):
                    bump(level, label, path)
            # IconButton / IconButton.* without tooltip within the next 14 lines
            if re.search(r"\bIconButton(\.\w+)?\(", line):
                block = "\n".join(lines[i:i + 14])
                if "tooltip:" not in block and "AppIconButton" not in line:
                    bump("FAIL", "IconButton without tooltip", path)

if shims:
    fails["@Deprecated shims left in lib/app/theme"] = shims
if allow_total > a.max_allow:
    fails[f"ui-lint allow markers ({allow_total} > {a.max_allow})"] = allow_total

print("=== UI lint v2 (outside lib/app/theme) ===")
for label, n in sorted(fails.items(), key=lambda x: -x[1]):
    print(f"FAIL {n:5d}  {label}")
for label, n in sorted(warns.items(), key=lambda x: -x[1]):
    print(f"WARN {n:5d}  {label}")
print(f"info  allow markers used: {allow_total} (cap {a.max_allow})")
if a.top:
    for label in list(fails) + list(warns):
        if label in per_file:
            print(f"\n[{label}]")
            for p, n in per_file[label].most_common(a.top):
                print(f"   {n:4d}  {p}")
bad = sum(fails.values()) + (sum(warns.values()) if a.strict else 0)
print("\nOK" if bad == 0 else f"\nFAILED ({bad} violations)")
sys.exit(1 if bad else 0)
