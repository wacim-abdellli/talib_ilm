# AGENTS.md — talib_ilm UI Overhaul Guidelines

**talib_ilm**: Islamic knowledge app (Arabic-only RTL, Light & Dark modes) transitioning from "consistent" to "excellent".

> **MANDATORY FIRST STEP**: Read `DESIGN_SYSTEM.md`, `ROUND2.md`, and `UI_PROGRESS.md` before doing any work. Execute ONE stage per session only, commit, report, and stop.

## Core Rules (13)
1. **Visual layer only** (unless explicitly lifted by R5/R6b). Never change models, services, routes, or Arabic strings.
2. **Forbidden outside `lib/app/theme/`**: `Color(...)`, `Colors.*` (except `transparent`), raw `TextStyle(`, `fontSize`/`fontFamily`, `Radius.circular`, `BorderRadius.circular`, numeric `EdgeInsets`, `Duration(...)`, `size:` in Icon, brightness/isDark branching, `BoxShadow`, bare `GestureDetector`, `.withOpacity`. Max 10 `// ui-lint: allow` repo-wide.
3. Propose tokens before use (name, value, contrast proof).
4. Contrast: text ≥ 4.5:1, UI/icons ≥ 3.0:1 via `tool/contrast.py`.
5. Min text 12sp; min tap target 48dp with ripple + Semantics/tooltip.
6. RTL-correct: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, mirror directional icons.
7. Must survive text scale 1.0, 1.5, 2.0 without overflow. No fixed heights on text containers.
8. Split files > 600 lines before restyling (separate commit).
9. Branch/tag discipline: `ui/r<n>-<name>`, tag `ui-r<n>-done` on stage completion. Never rewrite history.
10. Verify before reporting: analyze 0, ui_lint_v2 OK, tests pass, apk builds. Never claim unrun checks.
11. Max ~25 files changed per stage; stop and write `CONTINUE FROM R<n> step <k>` if exceeded.
12. Never run `git clean` or delete unlisted files.
13. Radical honesty: record any failures or skips under "Open issues" in `UI_PROGRESS.md`.

## Verification Commands
```bash
flutter analyze
python tool/ui_lint_v2.py
flutter test
flutter build apk --debug
```

## Report Format (≤ 8 lines per session)
`Stage · branch · commits · files changed · lint v2 before→after · analyze/tests/build results (what you actually ran) · what you looked at (goldens/screenshots) · open issues / owner actions`
