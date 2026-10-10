# ROUND 2 — talib_ilm: from "consistent" to "excellent"

> HOW TO USE (for the owner, not the agent)
> 1. FIRST session: paste everything from "BEGIN PROMPT" to the end. Stage R0 will save it as `ROUND2.md` and `AGENTS.md` in the repo.
> 2. EVERY later session (one stage per session, always a fresh session) paste only this:
>    `Read AGENTS.md, DESIGN_SYSTEM.md, ROUND2.md and UI_PROGRESS.md. Execute stage R<n> only. Stop after committing and reporting.`
> 3. Put the logo pack files in `assets/branding/` before stage R2 (from talib_ilm_logo_obsidian_gold_pack.zip).
> 4. Also copy `tool/ui_lint_v2.py` (given with this file) into the repo's `tool/` folder before R0.

---

# BEGIN PROMPT

You are a senior Flutter engineer continuing the UI/UX overhaul of **talib_ilm** (Arabic-only RTL, light + dark). Round 1 is reported complete in `UI_PROGRESS.md` (tokens, components, nav, all screens, 34 goldens, lint v1 = 0). Round 2 makes it excellent, in stages. **Do not trust Round 1's self-report: verify it (stage R0).** Do ONE stage per session, then stop.

## 0. Ground truth about the project (verified by the owner's auditor)

- On GitHub (`origin/master` at `7ec40d2`) NONE of Round 1's code was present: no `app_palette.dart`, no `nav_bar.dart`, no `test/golden/`, no `UI_PROGRESS.md`; `git.exe` was still there. So Round 1 may exist only on the owner's machine = **unbacked-up work**. Backing it up is the first thing you do.
- The five `assets/fonts/Cairo-*.ttf` files on origin were NOT fonts (they were saved GitHub HTML pages, ~297KB each). If still true locally, the main UI font has never loaded.
- Lint v1 (`tool/ui_lint.sh`) misses many violation kinds. The authority from now on is **`tool/ui_lint_v2.py`** (it also checks `Color.fromARGB`, `Colors.<any>`, `Radius.circular`, raw `TextStyle(`, `Duration` literals, icon `size:`, `brightness` branching, `IconButton` without `tooltip`, leftover `@Deprecated` shims, RTL left/right). On the pre-overhaul code v2 reported, e.g., 392 fontSize/fontFamily, 243 raw TextStyle, 115 icon sizes, 77 Duration literals, 19 IconButtons without tooltip.
- Rounds' goldens test isolated widgets in a test harness. They do NOT prove the real screens look right on a real phone.

## 1. Rules (these supersede Round 1's section C; unchanged rules still apply)

1. **Visual layer only**, EXCEPT where a stage below explicitly lifts it (R5, R6b) and only for what that stage lists. Never change data models, service logic, routes, or any Arabic string.
2. Outside `lib/app/theme/` forbidden: `Color(0x…)`, `Color.fromARGB/RGBO`, any `Colors.*` except `transparent`, `TextStyle(` constructors, `fontSize/fontFamily`, `Radius.circular(<n>)`, `BorderRadius.circular(<n>)`, `EdgeInsets…(<n>)`, `Duration(…)` literals, `Icon(size: <n>)`, `brightness`/`isDark` branching, `BoxShadow(`, bare `GestureDetector(`, `.withOpacity(`. Painters (CustomPainter) may use `// ui-lint: allow <reason>`; **max 10 allow markers in the whole repo.**
3. No new values: propose a token first (name, value, contrast proof).
4. Contrast: text ≥ 4.5, icons/UI boundaries ≥ 3.0, proven with `tool/contrast.py`.
5. Min text 12sp. Min tap target 48dp with ripple + Semantics/tooltip.
6. RTL-correct: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`; mirror directional icons.
7. Must survive text scale 1.0, 1.5 and 2.0 without overflow. No fixed `height` on text containers.
8. Split files > 600 lines in a separate no-visual-change commit before restyling.
9. **Branch + tag discipline:** one branch per stage `ui/r<n>-<name>`; one commit per logical step; after the stage passes, tag `ui-r<n>-done`. Never force-push. Never rewrite history.
10. Verify before reporting: `flutter analyze` = 0 issues, `python3 tool/ui_lint_v2.py` = OK, `flutter test` all green, `flutter build apk --debug` succeeds. If a command cannot run in your environment, SAY SO plainly; never claim a check you did not run.
11. Be frugal: read only files in the stage's scope; no big diffs in reports; no refactors outside scope; **max ~25 files changed per stage** — if more are needed, stop and write `CONTINUE FROM R<n> step <k>` in `UI_PROGRESS.md`.
12. Never run `git clean`, `rm -rf` outside build folders, or delete anything the stage did not list.
13. Honesty: if a step fails or is skipped, record it under "Open issues" in `UI_PROGRESS.md`. A truthful "not done" beats a false "done".

## 2. Stages

### R0 — Rescue, verify, baseline (do this first; no design work)
1. `git status`, `git branch -a`, `git log --oneline -20`. Commit any uncommitted work on the current branch. Create branch `ui/overhaul-round1` from it and `git push -u origin ui/overhaul-round1`. If the push fails (auth/network), STOP and print the exact error and the exact command the owner must run. Tag `ui-r1-done`.
2. Save this whole prompt as `ROUND2.md`. Create `AGENTS.md` (≤60 lines) containing: the project one-liner, "read DESIGN_SYSTEM.md + ROUND2.md + UI_PROGRESS.md first", the 13 rules above in condensed form, the verification commands, and the report format. (This file is how future sessions obey the rules without being re-pasted.)
3. **Fonts:** `file assets/fonts/*.ttf`. Every file must say `TrueType Font data`. If any Cairo file says `HTML document`, the fonts are broken: try to fetch real static Cairo TTFs (Regular, Medium, SemiBold, Bold, ExtraBold) from the official Google Fonts repository; if the network blocks it, STOP and ask the owner to drop the 5 files into `assets/fonts/` (tell them to download from fonts.google.com/specimen/Cairo → static). Do not continue with fake fonts.
4. Prove the app builds: `flutter pub get && flutter analyze && flutter test && flutter build apk --debug`. Record results.
5. Round 1 audit — record in `UI_PROGRESS.md`: (a) does `UI_PROGRESS.md` contain Phase 5 (loading/empty/error states) and Phase 6 (delete `@Deprecated` shims)? They were NOT logged; (b) count `@Deprecated` in `lib/app/theme/`; (c) run `python3 tool/ui_lint_v2.py --top 5` and save the full output as the **R0 baseline**.
6. Acceptance: branch pushed (or owner told exactly how), fonts valid, build result recorded, v2 baseline recorded, AGENTS.md written. No other change.

### R1 — Make "0" real (clear the v2 lint)
Goal: `python3 tool/ui_lint_v2.py` prints `OK`, including **0 shims**.
- Work file by file in order of the v2 `--top` list. Same token/component rules as Round 1. Replace `TextStyle(` with `context.text.*.copyWith(...)` only for colour/weight changes the palette allows; add missing text styles to the theme rather than inline.
- Add tooltips/Semantics to every flagged `IconButton`; replace remaining `GestureDetector` with `InkWell`/`AppButton`; replace `.withOpacity` with palette tokens or `withValues(alpha:)` only inside the theme.
- Phase 5 (states): every list/async screen has loading (`AppSkeleton`), empty (`AppEmptyState`), error (message + retry `AppButton`) — verify each screen and fix gaps.
- Phase 6: delete all `@Deprecated` shims and now-unused tokens/files; fix the fallout.
- Acceptance: v2 = OK, analyze 0, tests green, APK builds, goldens re-approved and LOOKED AT (read the PNGs).

### R2 — Rebrand to "Obsidian & Gold" (the payoff of a token system: change values, not screens)
The new logo is a solid ivory 8-point star with a gold open book on obsidian black. The app must match. Brand rule: **gold is the single brand colour; it may cover at most ~10% of any screen** (buttons, active-nav pill, progress fill, bookmark/star accents, icon badges). Text is ivory/ink, never gold paragraphs; no gold cards or gold backgrounds.
1. Change ONLY values in `lib/app/theme/` (names unchanged). All pairs below were verified; do not alter them without re-running `tool/contrast.py`:

| Token | Light | Dark |
|---|---|---|
| `bg` | `#F7F4EE` | `#0A0A0C` |
| `surface` | `#FFFFFF` | `#131316` |
| `surfaceRaised` | `#FFFFFF` | `#1C1C21` |
| `surfaceMuted` | `#EFEBE3` | `#0F0F12` |
| `border` | `#E4DED2` | `#2B2B32` |
| `text` | `#14130F` (18.6:1) | `#F4EFE6` (16.2:1) |
| `textMuted` | `#57534A` (7.7) | `#A9A59C` (7.6) |
| `textSubtle` | `#6B665B` (5.2 on bg) | `#8C887F` (4.8 on raised) |
| `primary` / `onPrimary` | `#14130F` / `#F4EFE6` (16.2) | `#E3B341` / `#0A0A0C` (10.2) |
| `primarySoft` / `onPrimarySoft` | `#F1E6C8` / `#5E410A` (7.6) | `#2B2210` / `#F0C85F` (9.8) |
| `gold` (text/icon/progress fill) | `#8A6210` (5.5 on white, 4.6 on muted) | `#E3B341` (9.5) |
| `goldFill` / `onGold` | `#E3B341` / `#14130F` (9.6) | `#E3B341` / `#0A0A0C` |
| `goldSoft` | `#F1E6C8` | `#2B2210` |
| `success` | `#047857` (5.5) | `#34D399` (9.7) |
| `error` / `errorSoft` | `#B91C1C` / `#FDE8E8` (5.5) | `#F87171` / `#3A1A1A` |

   Known trap: light-mode progress fill must be `gold` `#8A6210`, NOT `#B8841F` (2.47:1 on its track = fail).
2. Re-derive `category()` and `prayer()` colours so they sit calmly next to gold (slightly desaturated hues; keep them distinguishable; fg ≥ 4.5 on its 12% tint, prayer dots ≥ 3:1 on `surface`). Paste the contrast proof into `UI_PROGRESS.md`.
3. Add `logoSymbol` (asset path) to `AppPalette` so screens never branch on brightness: dark → `assets/branding/symbol_on_dark.png`, light → `assets/branding/symbol_on_light.png`. Create `AppLogo` widget (symbol, sizes 24/32/64; semantics label "طالب العلم"). Use it in the Home header and a lockup (`lockup_on_dark/light.png`, chosen the same way) on the More → About area.
4. Owner has placed the logo pack in `assets/branding/`. If missing, STOP and tell the owner. Declare `assets/branding/` in `pubspec.yaml`. **Exception to the "don't touch pubspec" rule for this stage only:** add dev_dependencies `flutter_launcher_icons` and `flutter_native_splash`; configure launcher icons from `assets/branding/README_LOGO.md` (iOS icon, Android adaptive fg/bg/monochrome); native splash = background `#0A0A0C` (dark) / `#F7F4EE` (light) with `symbol_on_dark.png` / `symbol_on_light.png`. Run both generators. Do not edit native folders by hand.
5. First launch default theme = dark (brand is dark); the user's saved choice still wins.
6. Gold-budget audit: open the Home, Prayer, Ilm, Adhkar screens in goldens; if gold covers more than ~10% or appears as large fills, reduce it and say what you changed.
- Acceptance: lint v2 OK; contrast proofs logged; goldens regenerated (light/dark × 1.0/1.5) and LOOKED AT; app icon + splash generated; no teal/emerald anywhere (`grep -ri "0f766e\|10b981\|064e3b\|0d9488" lib` returns nothing outside comments).

### R3 — Real-screen verification (stop trusting isolated goldens)
- If an emulator/device is available: run the app and capture full-screen screenshots (`flutter screenshot` or an `integration_test` with screenshots) for: Home, Prayer, Ilm, a Book view, Adhkar list + a session, Tasbeeh, Quran list, More, Qibla, Favorites, Library — in light + dark, at font scale 1.0, 1.5, **2.0** (Android: Settings → Display → Font size), on a small phone (360×640) and a large one (412×915). LOOK at every screenshot.
- If no device is available: write `QA_CHECKLIST.md` for the owner: the screens above × modes × scales with "what to look for" (clipped text, overlap with the floating nav bar, gold overuse, unreadable gray, RTL arrows, tap targets, keyboard covering inputs, status/navigation bar colours), and stop. Do not pretend.
- Fix every defect found (stay in scope). Log each defect + fix in `UI_PROGRESS.md`.
- Acceptance: a table of screens × states with ✅/❌ and the commit that fixed each ❌.

### R4 — Component gallery + motion polish
1. **Debug-only gallery screen** (`lib/dev/component_gallery.dart`, reachable only when `kDebugMode`, e.g. long-press the About version text): shows every shared component in all states (default/pressed/disabled/loading/error), all 8 text styles, the full palette swatches with their contrast ratios printed, spacing/radius scale. Add golden tests for it (light/dark). This becomes the single place to review the design system.
2. **Motion** (all durations/curves from `AppMotion`; none > 320ms; respect `MediaQuery.disableAnimations` → fall back to instant):
   - Page transitions: one shared route (fade-through or shared-axis) for all pushes; no custom per-screen routes.
   - Press feedback on every tappable (scale 0.98 + ink).
   - Progress/ring fills animate once on first show, not continuously.
   - Tasbeeh counter: tap → light haptic + 1-step scale pulse + number tick animation; milestone (33/99/100) → medium haptic + brief gold ring (no confetti loops).
   - Book cover → book page uses `Hero`.
   - Remove or gate any decorative infinite animation (`animated_background`, `floating_particles`): off by default, no continuous tickers behind content.
- Acceptance: gallery exists + goldens; no animation controller left running on hidden tabs (verify with `TickerMode` on `IndexedStack` children).

### R5 — Reading experience (rule 1 lifted ONLY for a persisted `ReaderPrefs`)
The app's core is reading. Improve the reading surfaces for Adhkar sessions, Mutun/Sharh/book reader, and Hadith cards. **Do NOT touch `quran_library` or the Syncfusion PDF internals.** For Quran only restyle chrome around it.
- One new service `ReaderPrefs` (SharedPreferences): `fontStep` (5 steps mapping to sacred sizes 20/22/26/30/34), `lineHeight` (3 steps), `readingTheme` (follow app / ivory-paper / true-black). Provide a single `ReaderSettingsSheet` (uses `AppSheet`) opened from a "Aa" `AppIconButton` in reader app bars.
- Focus mode: single tap on the reading area hides/shows app bar and bottom controls (animated, `AppMotion.base`); keep screen awake while reading (`wakelock_plus` already in pubspec).
- Typography check for `sacred`: line-height ≥ 2.0, no text clipped by diacritics at max step, verse/hadith separators use `border` hairlines, chapter headings `title` in `text` colour (gold only for the small star ornament).
- Resume: reuse existing last-position services; show a subtle "continue" chip, no new data model.
- Acceptance: goldens for the sheet and the reader at each fontStep (light/dark/ivory/true-black); no overflow at font scale 2.0; no change to Quran/PDF internals.

### R6 — Home as a daily dashboard, then onboarding
**R6a (visual only): Home hierarchy.** At most 4 modules above the fold in this order: (1) next-prayer hero, (2) continue where you left off, (3) today's progress (existing progress services), (4) quick actions. Daily hadith/motivation below. Remove anything redundant. One primary action per screen.
**R6b (rule 1 lifted for these only): first-run.** (i) Onboarding: max 3 pages, skippable, shown once (one SharedPreferences flag), Arabic copy supplied by the owner or kept to short neutral text you clearly list for owner approval; (ii) pre-permission explainer sheets before the OS dialogs for notifications and location, with a "not now" path that still lets the app work and a clear empty state when location is denied.
- Acceptance: R6a goldens; R6b flow works with permissions granted, denied, and "not now"; list every new string for owner review in `UI_PROGRESS.md`.

### R7 — Accessibility + responsive
- Use the official Flutter skills if installed (`flutter-build-responsive-layout`, `flutter-fix-layout-issues`, and the `a11y` agent) — otherwise do it by hand.
- Semantics: logical reading order for RTL, `MergeSemantics` on cards, labels for icons, `selected`/`button`/`header` roles, announce counter changes in Tasbeeh, no information by colour alone (prayer state also has an icon/label).
- Accessibility sweep at text scale 2.0 and with "reduce motion".
- Responsive: content max width `AppSize.maxContent` (520) centred on wide screens; tablets/landscape/foldables (≥ 840dp) switch the bottom `NavBar` to a navigation rail; no screen assumes portrait.
- Acceptance: goldens at 360×640, 412×915, 800×1280, landscape; no overflow; Semantics tree dump reviewed for Home and Tasbeeh.

### R8 — Performance
Measure before changing anything (use `flutter run --profile` + DevTools if a device exists; otherwise static review and say so).
- Continuous work: find every `AnimationController`, `Timer.periodic`, `Ticker`, particle/background painter; ensure none runs while hidden/off-screen; wrap heavy painters in `RepaintBoundary`.
- Lists: `ListView.builder`/slivers for long lists; `const` constructors; no `setState` at page root for small changes; image `cacheWidth/cacheHeight`.
- Size: remove unused fonts/weights and unused assets (verify with grep first).
- Startup: nothing blocking before the first frame except theme load.
- Acceptance: a short before/after note with what was measured or, if no device, an honest "static review only" with the fixes made.

### R9 — Ship + lock
- `.github/workflows/ci.yml`: on push/PR run `flutter pub get`, `flutter analyze`, `flutter test`, `python3 tool/ui_lint_v2.py`, `bash tool/ui_lint.sh`, `flutter build apk --debug`.
- Make `tool/ui_lint.sh` call v2 so there is one command.
- Final `DESIGN_SYSTEM.md` (Obsidian & Gold tokens, components, rules) and `AGENTS.md` updated.
- Store assets: app name, version bump + `CHANGELOG.md`; 4–6 marketing screenshots generated from goldens (light/dark) in `store/screenshots/`.
- Remove dead code/assets found by the lint/grep.
- Acceptance: CI green on the branch; open a PR `ui/overhaul-round1 → master` with a description listing stages, lint numbers before/after, and open issues. **Do not merge it.**

### RX — Cold review (run ONLY in a separate fresh session when R9 is done)
You are a hostile reviewer. You did not write this code. Assume the author's report is wrong.
Run `flutter analyze`, `flutter test`, `python3 tool/ui_lint_v2.py --strict --top 10`, `bash tool/ui_lint.sh`, `flutter build apk --debug`. Open every golden PNG. Grep for: `0f766e|10b981|0d9488` (old teal), `Colors\.`, `TextStyle\(`, `@Deprecated`, `allow` markers. Check text scale 2.0 and RTL on the 6 busiest screens. Report: the 10 worst remaining visual/UX defects with file + line, any claim in `UI_PROGRESS.md` you could not reproduce, and a PASS/FAIL per stage. Change nothing.

## 3. Report format (every session, ≤ 8 lines)
`Stage · branch · commits · files changed · lint v2 before→after · analyze/tests/build results (what you actually ran) · what you looked at (goldens/screenshots) · open issues / owner actions`.
