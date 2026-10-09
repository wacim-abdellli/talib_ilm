#!/usr/bin/env bash
# UI consistency guard for talib_ilm. Run from the repo root:  bash tool/ui_lint.sh
# Counts design-system violations in screens/widgets (lib/app/theme is the ONLY place raw values may live).
# Exit code 1 if any budget is exceeded, so the agent can't "finish" while violations grow.
set -u
cd "$(dirname "$0")/.." 2>/dev/null || true
SRC=lib
EXCL='lib/app/theme'
fail=0

count() { # $1=label $2=regex $3=budget
  local n
  n=$(grep -rEn --include=*.dart "$2" $SRC | grep -v "^$EXCL" | wc -l)
  printf "%-46s %5d   (budget %s)\n" "$1" "$n" "$3"
  if [ "$n" -gt "$3" ]; then fail=1; fi
}

echo "=== UI lint (outside lib/app/theme) ==="
count "Raw Color(0x...) literals"                 'Color\(0x[0-9A-Fa-f]{8}\)'                 ${B_COLOR:-0}
count "Raw fontSize: <n>"                         'fontSize: *[0-9]'                          ${B_FONT:-0}
count "Raw fontFamily: '...'"                     "fontFamily: *'"                            ${B_FAMILY:-0}
count "Raw BorderRadius.circular(<n>)"            'BorderRadius\.circular\([0-9]'             ${B_RADIUS:-0}
count "Raw EdgeInsets with numbers"               'EdgeInsets\.(all|symmetric|only|fromLTRB)\([^)]*[0-9]' ${B_INSETS:-0}
count "Text smaller than 12"                      'fontSize: *(9|10|11)(\.[0-9]+)?[,)]'       0
count "Colors.white/black used as text/bg"        'Colors\.(white|black)\b'                   ${B_WB:-0}
count "isDark ? ... : ... (use theme tokens)"     'isDark *\?'                                ${B_ISDARK:-0}
count "Hardcoded magic bottom spacer (height: 100)" 'SizedBox\(height: *(80|90|100|110|120)\)'  0
echo
if [ $fail -ne 0 ]; then echo "FAIL: budgets exceeded. Fix by using tokens, not by raising budgets."; exit 1; fi
echo "OK"
