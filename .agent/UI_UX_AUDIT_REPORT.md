# Talib Ilm — UI/UX Audit Report

Repo: `wacim-abdellli/talib_ilm` · commit `5b7b1c1` ("Celestial Oasis luxury aesthetic & home screen overhaul")
Stack: Flutter (Dart 3.10), Arabic-only RTL, light + dark, ~27,300 lines of Dart.

**How this audit was done:** static analysis of the source. I read the whole theme layer, the app shell/navigation, the shared widgets, the Home hero card, the quick-action button, and the colour/typography code of the Home and Ilm screens, and I measured the entire codebase with scripted counts. I computed WCAG contrast ratios from the real hex values. **I did not run the app or see rendered screens**, so spacing/overflow problems below are inferred from code and must be confirmed on a device. Screens I only measured (not read line by line) are marked.

---

## 1. Verdict

Your instinct is right, but "bad colours / bad components" is a symptom. The root cause is that **the app has no single source of truth for its look**, so every screen re-decides colours, sizes and radii by hand. That is also exactly why your agent keeps changing things blindly: it is handed three contradictory design directions and a theme layer that screens ignore.

The good news: the foundation is not bad. The dark palette and the Material 3 surface ladder in `app_theme.dart` are well built, and you already have `AppColors / AppSpacing / AppRadius / AppTextStyles`. The work is **consolidation and enforcement**, not a from-scratch redesign.

---

## 2. Findings, ranked by impact

### F1 — Three conflicting design languages (CRITICAL — this is what misleads the agent)

| Source | What it says |
|---|---|
| `.agent/HOME_UI_DESIGN_PHILOSOPHY.md` | "Black first. Gold ≤5% of UI. **No per-feature colours. No gradients.** Icons neutral gray." |
| Latest commit / `AppColors` / `QuickActionButton` | "Celestial Oasis": per-feature jewel colours (gold/teal/emerald/azure), gradient medallions, glow shadows |
| `ilm_page.dart` | A third, older palette: warm beige light mode (`#F5F3F0`, `#FBFAF8`), muted teal `#5A8A8A`, gold `#D4A853`, and a neutral-gray dark mode (`#1F1F1F`) that matches nothing else |

`.agent/TYPOGRAPHY.md` also disagrees with the code (doc: heading1 = 24sp, bodySmall = 12sp, quran = 22sp; code: 32 / 13 / 24).
An agent reading these docs will "fix" the UI toward whichever it read last.

### F2 — Screens bypass the theme (CRITICAL)

Measured outside `lib/app/theme/` (the only place raw values should live):

| Violation | Count |
|---|---|
| Raw `Color(0x…)` literals | **88** (46 of them in `ilm_page.dart` alone) |
| Raw `fontSize: n` | **200** |
| Raw `fontFamily: 'Cairo'/'Amiri'` | **192** |
| Raw `BorderRadius.circular(n)` | **185** |
| `isDark ? … : …` ternaries | **162** |
| `Colors.white / Colors.black` | **167** |
| Text smaller than 12sp | **30** (the theme doc itself promises "no text smaller than 12sp") |

Resulting variety in the UI: **24 distinct font sizes**, **15 distinct corner radii**, **15 distinct icon sizes**. A design system has ~8, ~5 and ~4.

### F3 — Same category, different colours, in different places

`AppColors` defines `categoryFiqh = violet`, `categoryHadith = emerald`, `categoryAqidah = teal`, `categoryLanguage = azure`, `categorySeerah = terracotta`.
`ilm_page._getCategoryColor` defines **Hadith = violet, Fiqh = emerald** (swapped), Aqidah = cyan, Language = red, Seerah = pink.
`book_card.dart` has a third `_getCategoryColor` (not read in detail). A user sees the same subject in different colours on different screens.

### F4 — Contrast / accessibility failures (HIGH)

WCAG: text ≥ 4.5:1, icons/UI parts ≥ 3:1. Computed from your real values:

| Where | Pair | Ratio | Result |
|---|---|---|---|
| Light tertiary text (`textTertiary`) on white card | `#94A3B8` / `#FFFFFF` | **2.56** | Fail |
| Light disabled text | `#CBD5E1` / white | **1.48** | Fail |
| Primary button label, light mode | white / `#0D9488` | **3.74** | Fail (16sp is not "large text") |
| Gold as text/icon, light mode | `#F59E0B` / white | **2.15** | Fail |
| Quick-action medallion icon (Quran) | white / `#F59E0B` | **2.15** | Fail (3:1 needed) |
| Quick-action medallion icon (Adhkar / Qibla) | white / `#10B981`, `#0EA5E9` | **2.54 / 2.77** | Fail |
| Ilm gold accent | `#D4A853` / `#FBFAF8` | **2.11** | Fail |
| Dark tertiary on cards (hero card labels) | `#64748B` / `#12181F`, `#16202A` | **3.75 / 3.46** | Fail |
| Dark secondary text, dark primary button | `#94A3B8` / `#12181F`; `#022C22` / `#10B981` | **6.96 / 5.97** | Pass |

All of these have a verified fix in the brief (e.g. light primary `#0F766E` = 5.47:1; light gold text `#B45309` = 5.02:1; dark tertiary `#8A9BB0` = 6.29:1).

### F5 — The token layer itself is bloated and partly fake (HIGH)

- `app_colors.dart`: **114 colour literals** with many aliases of the same value (`primaryDark`… `jewelIlmDark`, `islamicGreen*` vs `jewelAdhkar` vs `success`, `blueGray50–900` "compat aliases", `gold = accentGold = accent`).
- `AppUi` re-exports `AppSpacing`/`AppRadius` one constant at a time (~100 lines of pure duplication), so the same value has 2–3 names.
- **8 of the 10 animation-duration tokens are all 180 ms** (`animShort, animMedium, animNormal, animSlow, animSlowest, animProgress, animPulse, animScroll`). There is no motion hierarchy; the names lie.
- `tapTargetMin = 32` — below the 44–48dp minimum — and it is **never used**.
- `AppSpacing.paddingMD = 20`, `gapLG = 20`, `gapXL = gapBetweenSections = 24`: names don't describe a scale.
- `ThemeColors` mixes `ColorScheme` lookups with raw `AppColors` and `isDark` ternaries, so some "theme-aware" colours are not actually driven by the theme.
- `AppColors` is used in 281 places and `context.xColor` in many more: two competing access styles.

### F6 — No real component library (HIGH)

There is no shared Button, Card, Chip/Tag, SectionHeader, IconBadge or ListTile. Evidence: 35 raw `IconButton`s, 5 `ElevatedButton`, 5 `FilledButton`, 4 `TextButton`, 1 `OutlinedButton`, and many hand-built tappable `Container`s (14 `GestureDetector` vs 23 `InkWell`, so some taps have no ripple/feedback; 71 hand-written `BoxShadow`s). `PressableCard` falls back to a hard-coded beige border `#E5DED0` and an `primaryDark` shadow — leftovers of an older palette that look wrong against the current slate/teal one. `AppEmptyState` hard-codes 80px icons and 20/15sp text.

### F7 — Navigation shell (MEDIUM–HIGH)

`app_shell.dart` (the floating bottom bar seen on every screen):
- Hard-coded colours (`#10171F`, `#22303C`, `#94A3B8`, `#64748B`) instead of theme tokens.
- Fixed 68px height with **10sp / 11sp labels**, under a text-scaler that is *also* multiplied by up to 1.2× on top of the user's own accessibility setting, with no upper cap (`app.dart`). Fixed-height parts are where clipping appears first.
- Each screen clears the floating bar with a hand-tuned `SizedBox(height: 100)` (4 places) instead of one shared constant derived from the bar's real height + safe-area inset. Likely tight on gesture-nav phones — **verify on device**.
- All five tabs stay mounted in a `Stack` with `AnimatedOpacity`, so hidden tabs stay built and can keep their timers/animations running (battery/perf cost; check with the profiler).
- Works well: haptics, active pill indicator, RTL back-arrow handling in `PrimaryAppBar`.

### F8 — Typography (MEDIUM)

- Doc and code disagree (F1). Cairo is hard-coded 192× instead of coming from the theme.
- Fonts: Cairo (UI) · Amiri (16 uses, labelled "legacy") · ScheherazadeNew (2 uses) · **Vazirmatn (0 uses — bundled but dead)**. Pick one content face and delete the rest (check `quran_library` first before removing Scheherazade).
- Sizes jump 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 19 → 20 → 21 → 22 … — too fine-grained to read as a hierarchy.

### F9 — Giant files make "blind" edits inevitable (MEDIUM, and this is your token cost)

`ilm_page.dart` 1,813 lines · `home_page.dart` 1,211 · `book_view_page.dart` 1,137 · `tasbeeh_istighfar_page.dart` 1,011 · `adhkar_page.dart` 908 · `prayer_page.dart` 884. Only 6–7 private `_build` methods in a 1,800-line file means huge widgets. The agent must read thousands of lines to change one button — that is why it costs tokens and changes things blindly.

### F10 — Repo hygiene that wastes agent tokens (LOW effort / HIGH payoff)

Committed to the repo root: `git.exe` (13 MB), `analysis.txt`, `analysis_output.txt`, `analysis_output_2.txt`, `analysis_output_3.txt`, `build_log.txt`, `cleanup_script.py`. Tests: one 9-line file. `assets/images/` has `app_main_logo.png` and `logo2.png` that are neither declared in `pubspec.yaml` nor referenced.

---

## 3. Screen-by-screen notes

| Screen | Evidence | Main problems |
|---|---|---|
| **Home** (`home_page.dart`, hero card, quick actions) *read* | 8 raw colours, 12sp/11sp labels, hero card 10 raw colours, 9/10/11sp text | Per-feature jewel colours with white icons fail contrast; hero card dark labels fail contrast; hand-hardcoded `isDark` colours (`#0D141C`, `#1A242F`, `#CBD5E1`…); gradients/glows contradict the written philosophy |
| **Ilm** (`ilm_page.dart`) *read (colour code)* | 46 raw colours, 1,813 lines | Own palette (beige/`#5A8A8A`/`#D4A853`), gray `#1F1F1F` dark mode, swapped category colours, 2.1:1 gold |
| **Prayer** *measured* | `prayer_page` 884 lines, settings sheet 796, `prayer_time_tile` uses `AppColors` prayer colours (good) | Large sheets/pages; sub-12sp text in 2 places |
| **Qibla** *measured* | 7 raw colours, 3 sub-12sp texts | Off-system colours |
| **Adhkar / Tasbeeh** *measured* | 4 sub-12sp texts in `adhkar_page`, 3 in session page; 1,011-line tasbeeh page | Counter/tap targets should be the largest, simplest elements — verify on device |
| **Quran** *measured* | 4 sub-12sp texts in `quran_page`, 1 in `surah_card` | Reading surface needs its own spec (see brief) |
| **More / Drawer** *measured* | `more_page` 701 lines, spacer 100 | Magic spacer; no shared list-tile |
| **PDF viewer** *measured* | 5 raw colours | Off-system chrome |

Not reviewed in depth: `book_view_page`, `lessons_list_page`, Quran library wrapper, favorites, library page.

---

## 4. Skills and tools — what actually exists (searched)

No skill will "fix the UI" by itself; a skill only gives the agent better rules. What I found and verified:

| Tool | What it gives you | Fit |
|---|---|---|
| **Official Flutter/Dart plugin** (`claude plugin install dart-flutter@dart-flutter`, docs.flutter.dev/ai/agent-skills) | Skills for responsive layout, fixing overflow/unbounded-constraint errors, widget previews, widget tests, architecture, localization; plus an `a11y` accessibility audit agent | **Best fit.** Covers layout bugs and accessibility. Note: it has **no theming/visual-design skill**. |
| **UI UX Pro Max** (github.com/nextlevelbuilder/ui-ux-pro-max-skill) | 192 colour palettes, 74 font pairings, 119 UX guidelines, 79 styles, **Flutter is one of its 22 supported stacks**. Install: `/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill` then `/plugin install ui-ux-pro-max@ui-ux-pro-max-skill`, or `npx ui-ux-pro-max-cli init --ai claude`. Needs Python 3. | Good for **design decisions** (palette/type pairing), not for enforcing consistency. Flutter flag syntax (`--stack flutter`) is my inference, not documented. Not Arabic-specific. |
| **Material 3 skill** (hamen/material-3-skill) | M3 tokens, components, theming, accessibility, and an "MD3 compliance audit" mode scoring 10 categories. Install: `npx claudepluginhub hamen/material-3-skill --plugin material-3`. | Flutter is secondary (Compose is primary). Useful as an auditor for `ThemeData`/`ColorScheme`. |

My recommendation: install the **official Flutter plugin** (layout + a11y), optionally **UI UX Pro Max** for the palette/type pass, and — most important — give the agent the **brief and lint script** in this package. Those are what stop the blind changes.

---

## 5. What to do, in order (details in `AGENT_DESIGN_BRIEF.md`)

1. **Housekeeping (30 min):** delete junk files, replace the three contradictory docs with one `DESIGN_SYSTEM.md`.
2. **One decision from you:** pick the direction (the brief recommends the restrained one your own `.agent` doc describes).
3. **Tokens:** collapse to one `AppPalette` theme extension (light/dark), 8 text styles, 5 radii, 7 spacings, 4 icon sizes, 3 durations.
4. **Components:** AppButton, AppCard, AppTag, SectionHeader, IconBadge, AppListTile, AppSheet, NavBar.
5. **Shell/nav fix**, then screens in traffic order: Home → Prayer → Ilm → Adhkar → Quran → More → Qibla.
6. **Guardrails:** `tool/ui_lint.sh` budgets that only go down, plus golden screenshots (light/dark × text scale) so the agent can *see* its changes instead of guessing.
