#!/usr/bin/env python3
"""WCAG contrast checker. Usage:  python3 tool/contrast.py "#FFFFFF" "#0F766E" ["#FFFFFF" "#B45309" ...]
Pass pairs as foreground background. Needs >= 4.5 for text, >= 3.0 for icons / UI boundaries."""
import sys


def _lum(h):
    h = h.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def ratio(a, b):
    la, lb = _lum(a), _lum(b)
    if la < lb:
        la, lb = lb, la
    return (la + 0.05) / (lb + 0.05)


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) < 2 or len(args) % 2:
        sys.exit(__doc__)
    bad = False
    for fg, bg in zip(args[::2], args[1::2]):
        r = ratio(fg, bg)
        verdict = "AA text" if r >= 4.5 else ("icons only (>=3)" if r >= 3 else "FAIL")
        bad |= r < 3
        print(f"{r:5.2f}:1  {fg} on {bg}  -> {verdict}")
    sys.exit(1 if bad else 0)
