# Talib Ilm — Design System Brief (for your coding agent)

> Put this file in the repo as `DESIGN_SYSTEM.md`, delete `.agent/HOME_UI_DESIGN_PHILOSOPHY.md` and `.agent/TYPOGRAPHY.md` (they contradict the code), and add `tool/ui_lint.sh` + `tool/contrast.py`. The agent reads **only this file** for visual decisions.
> Based on the audit in `UI_UX_AUDIT_REPORT.md`. All colour pairs below were verified with `tool/contrast.py`.

## 0. Direction (the one decision that is yours)

**Recommended: "Calm Scholar"** — restrained, sacred, readable. It is what your own `.agent/HOME_UI_DESIGN_PHILOSOPHY.md` already asked for, and it fixes the contrast failures that the multi-colour "jewel" look causes.

- One brand colour (teal/emerald). Gold is a rare accent (progress milestones, bookmarks, the current prayer dot), not a theme.
- Surfaces are neutral slate. Colour comes from content (category tag, prayer dot), never from decorating every tile.
- No gradients on cards. No glow shadows. One soft shadow in light mode, none in dark (borders instead).
- Reading surfaces (Quran, Mutun, Adhkar) are the calmest screens in the app.

If you prefer the colourful "Celestial Oasis" look, keep the tokens in section 1 but allow per-feature accent *fills* only with the verified icon colours in the last table of section 1. Either way, **delete the other direction from the docs**.

## 1. Tokens (single source of truth: `lib/app/theme/`)

Replace `app_colors.dart`, `theme_colors.dart`, `app_ui.dart` with one `AppPalette extends ThemeExtension<AppPalette>` (implement `copyWith` and `lerp`), registered in both `ThemeData`s, plus a `context.palette` getter. Screens never use `isDark`, `Color(0x…)`, `Colors.white/black`, or `AppColors.*` directly. Delete every alias.

### Colour (light / dark) — all verified

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#F8FAFC` | `#0A0E13` | Scaffold |
| `surface` | `#FFFFFF` | `#12181F` | Cards, list rows |
| `surfaceRaised` | `#FFFFFF` | `#1A232C` | Sheets, dialogs, nav bar |
| `surfaceMuted` | `#F1F5F9` | `#0E1318` | Search field, recessed areas |
| `border` | `#E2E8F0` | `#22303C` | 1px card/input borders |
| `text` | `#0F172A` | `#F8FAFC` | Titles, body (18.5:1 in dark) |
| `textMuted` | `#475569` (7.6:1) | `#94A3B8` (6.96:1) | Secondary text |
| `textSubtle` | `#64748B` (4.55:1 on bg) | `#8A9BB0` (5.6:1 on raised) | Captions, timestamps. **Replaces `#94A3B8` light / `#64748B` dark, which fail.** |
| `primary` | `#0F766E` | `#10B981` | Buttons, active nav, links |
| `onPrimary` | `#FFFFFF` (5.47:1) | `#022C22` (5.97:1) | Text/icon on primary |
| `primarySoft` | `#CCFBF1` | `#064E3B` | Tonal buttons, selected chips. Text on it: light `#0F766E` (4.86:1); dark **`#34D399` (5.06:1)** — not `#10B981`, which is only 3.83:1 there |
| `gold` (text/icon) | `#B45309` (5.0:1) | `#FBBF24` (10.7:1) | Milestones, bookmarks |
| `goldFill` + `onGold` | `#F59E0B` + `#451A03` (6.97:1) | same | Gold chips/badges. **Never white on gold.** |
| `goldSoft` | `#FEF3C7` | `#451A03` | Gold tint backgrounds |
| `success / error` | `#047857` / `#B91C1C` | `#34D399` / `#F87171` | States. `#B91C1C` on `#FEE2E2` = 5.3:1 |
| `disabled` | text at 38% opacity — **never a separate light gray** (`#CBD5E1` is 1.48:1) |

Rule: any new colour pair must pass `python3 tool/contrast.py "<fg>" "<bg>"` (≥4.5 text, ≥3 icons).

**Category tags** (Aqidah / Quran / Hadith / Fiqh / Seerah / Language): define once in `AppPalette.category(Subject)` returning `{fg, bg}` (bg = 12% tint, fg darkened until ≥4.5:1 on that tint). Use ONLY for tag chips and a 4px side marker. Delete the three duplicate `_getCategoryColor` functions (`ilm_page`, `book_card`, plus the `AppColors.category*` copies). Use one mapping — the current code has Hadith/Fiqh swapped between files.

**Prayer colours** (`fajr…isha`): only for the 8px dot / ring on prayer tiles. Never as full backgrounds.

**Feature icon fills** (only if you keep the colourful direction): white icons pass 3:1 on `#0F766E` (5.47), `#B45309` (5.02), `#0369A1` (5.93), `#047857` (5.48), `#6D28D9` (7.10). They do **not** on today's `#F59E0B`, `#10B981`, `#0EA5E9`.

### Typography (Cairo for UI, one serif for sacred text)

Define 8 styles in `AppTextStyles`, wire them into `ThemeData.textTheme`, and use `Theme.of(context).textTheme.*` or `context.text.*`. **No `fontSize:`/`fontFamily:` in screens.**

| Style | Size / weight / line-height | Use |
|---|---|---|
| `display` | 28 / 700 / 1.4 | Hero numbers, countdown |
| `title` | 20 / 700 / 1.5 | Screen/section titles |
| `titleSmall` | 17 / 700 / 1.5 | Card titles |
| `body` | 15 / 400 / 1.7 | Body (Cairo reads small; 15 not 14) |
| `bodySmall` | 13 / 400 / 1.6 | Secondary |
| `label` | 13 / 600 / 1.3 | Buttons, chips, nav labels |
| `caption` | **12 (floor)** / 500 / 1.4 | Timestamps. **Nothing below 12.** |
| `sacred` (+ `sacredLarge`) | 22–26 / 400 / 2.0 | Quran, Hadith, Dhikr in ONE serif face |

Fonts: keep Cairo + Amiri; remove **Vazirmatn** (0 uses). Check whether `quran_library` needs ScheherazadeNew before removing it. Drop the "legacy" label.
Cap total text scale: in `app.dart` use `TextScaler.linear((system * sizeScale).clamp(0.9, 1.5))`, and make fixed-height widgets (nav bar, hero card, medallions) grow with `minHeight` + `FittedBox`/ellipsis, not fixed `height`.

### Spacing / radius / icon / motion (use these names only)

| Group | Values |
|---|---|
| `AppSpace` | `xs 4 · sm 8 · md 12 · lg 16 · xl 20 (screen side padding) · xxl 24 · xxxl 32` |
| `AppRadius` | `sm 8 (tags, small chips) · md 12 (buttons, inputs, snackbars) · lg 16 (cards) · xl 24 (sheets, hero, nav) · pill 999` |
| `AppIcon` | `sm 16 · md 20 · lg 24 · xl 28` (+ `hero 40`) |
| `AppMotion` | `fast 120ms · base 200ms · slow 320ms`, curves `easeOutCubic` / `easeInCubic` |
| `AppSize` | `tap 48 (min hit area, everywhere) · buttonH 48 · inputH 52 · navH 64 + bottom inset` |
| Bottom clearance | one constant `AppSize.navClearance(context)` = nav height + margin + bottom inset. Replaces every `SizedBox(height: 100)`. |

Delete: `AppUi` entirely (it only re-exports), the 8 duplicate 180 ms duration tokens, `tapTargetMin = 32`, `gapSMPlus`/`XXSPlus`-style half-steps.

## 2. Component spec (build these once in `lib/shared/widgets/`, then replace usages)

| Component | Spec |
|---|---|
| `AppButton` (primary / tonal / outline / text; sm/md) | Height 48 (sm 40 with 48 hit area), radius `md`, label `label` 16/600 style, primary = `primary` bg + `onPrimary`; tonal = `primarySoft`; outline = 1px `border`. Pressed: scale 0.98 + overlay (via `InkWell`, never bare `GestureDetector`). Disabled: 38% opacity. Loading: spinner replaces label, width stays. Haptic `lightImpact` on primary only. |
| `AppIconButton` | 24 icon inside 48×48 hit area, tooltip required (accessibility). |
| `AppCard` | `surface`, 1px `border`, radius `lg`, padding 16. Light: one shadow `0 2 8 @4%`. Dark: **no shadow**. Tappable variant uses `InkWell` + `AppMotion.fast` press scale. Replaces `PressableCard` (remove the `#E5DED0` fallback). |
| `AppTag` / chip | Height 28 visual (48 hit if tappable), radius `sm`, `caption` text, category `{fg,bg}`. |
| `IconBadge` | 44×44, radius `md`, `primarySoft` bg + `primary` icon 22. One style for all feature tiles — replaces the 50px gradient glow medallions. |
| `SectionHeader` | `titleSmall` + optional trailing text button ("عرض الكل"), 24 top / 12 bottom spacing. |
| `AppListTile` | Min height 56, leading `IconBadge`, title `body`/600, subtitle `bodySmall` `textMuted`, trailing chevron mirrored for RTL, divider = `border` inset. Used by More, Settings, Favorites, Library. |
| `AppProgress` | Height 6, radius 3, track `border`, fill `primary`; gold only at 100%. |
| `AppSheet` | `surfaceRaised`, top radius `xl`, handle 36×4 `border`, max height 72%. |
| `AppSnackbar` | floating, radius `md`, `surfaceRaised`, margin 16 above nav (use `navClearance`). |
| `AppEmptyState` | 64 icon in a 96 `primarySoft` circle, `titleSmall`, `bodySmall`, optional `AppButton`. |
| `AppSkeleton` | shimmer using `surfaceMuted`→`border` (add to palette; stop using `AppColors.shimmer*`). |
| Bottom nav (`NavBar`) | Height 64 + inset, `surfaceRaised`, 1px `border`, radius `xl`. Items: 24 icon, label **12** `label`, active = `primarySoft` pill 56×32 behind the icon + `primary`; inactive = `textSubtle`. Min item hit area 48 high. Colours from palette only. |
| App bar | Transparent over `bg`, title `title`, back arrow `text` colour (not primary), 1px bottom border only when scrolled. |
| Inputs | Height 52, radius `md`, `surfaceMuted` fill, 1px `border`, focus 2px `primary`, error `error`. |

## 3. Phases (one phase per agent session; each ends with the acceptance checks)

**P0 — Housekeeping (low risk).** Delete `git.exe`, `analysis*.txt`, `build_log.txt`, `cleanup_script.py`; add to `.gitignore`. Remove undeclared logos (or declare them). Replace the two contradictory `.agent` docs with this file. *Accept:* `flutter analyze` clean, repo root tidy.

**P1 — Tokens.** Implement `AppPalette`, `AppTextStyles` (8), `AppSpace/Radius/Icon/Motion/Size`; update `app_theme.dart` (light + dark) to read from them; keep temporary `@Deprecated` shims for old names so the app still compiles. *Accept:* `flutter analyze`; `bash tool/ui_lint.sh` runs; app looks the same except fixed contrast.

**P2 — Components.** Build section 2 components with a preview/golden test each (light/dark). *Accept:* components render at text scale 1.0 and 1.5 without overflow.

**P3 — Shell & navigation.** `NavBar` from palette, `navClearance`, keep tabs alive with `IndexedStack`/`Offstage` (so hidden tabs stop animating; keep scroll state), cap text scale. *Accept:* no `SizedBox(height: 100)` left.

**P4 — Screens, in traffic order** (split any file >600 lines into widgets first, *then* restyle — no mixed commits): Home → Prayer (+ settings sheet) → Ilm (biggest win: removes its private palette) → Adhkar/Tasbeeh → Quran + bookmarks → More/Drawer → Qibla → PDF viewer → Favorites/Library. For each screen: replace raw values with tokens/components, fix sub-12sp text, ensure every tappable is ≥48 with ripple and a Semantics label. *Accept per screen:* the screen's lint violations = 0, goldens updated and reviewed.

**P5 — Lock it.** Set the lint budgets in `tool/ui_lint.sh` to 0 (or CI-fail on increase). Delete deprecated shims.

### Current lint baseline (outside `lib/app/theme`)
`Color(0x…)` 88 · `fontSize` 200 · `fontFamily` 192 · `BorderRadius.circular(n)` 185 · `isDark ?` 162 · `Colors.white/black` 167 · text <12sp 30 · magic spacers 4. Goal: 0 across the board; ratchet the budgets down after each phase (`B_COLOR=40 bash tool/ui_lint.sh`, etc.).

## 4. How to stop the agent working blind (this is where your tokens go)

1. **Let it see.** Add golden tests per screen: light/dark × RTL × `textScaleFactor 1.0 & 1.5`, with fake data. The agent regenerates PNGs (`flutter test --update-goldens`) and **opens the images** to check its own work. One run replaces ten guess-and-check rounds. (This repo currently has a single 9-line test.)
2. **Small context.** Never ask it to "improve the UI". Ask for one phase / one screen. Tell it to read this file + that screen only.
3. **Mechanical checks first.** `bash tool/ui_lint.sh`, `python3 tool/contrast.py`, `flutter analyze` before it reports done.
4. **No new values.** If a design needs a value that is not a token, it must propose the token first.

## 5. Master prompt (paste to the agent)

```
You are restyling the Flutter app "talib_ilm". Read DESIGN_SYSTEM.md fully; it is the only authority on visual decisions. Ignore any older design docs.

Task: execute PHASE <N> only (and for P4: SCREEN <name> only).

Hard rules:
- No raw Color(0x…), Colors.white/black, fontSize, fontFamily, BorderRadius.circular(n), EdgeInsets with magic numbers, or isDark ternaries outside lib/app/theme. Use context.palette, text styles, AppSpace/AppRadius/AppIcon/AppMotion and the shared components.
- Never use a colour pair that fails tool/contrast.py (4.5 text, 3.0 icons). Never white text on gold.
- Minimum text 12sp. Minimum tap target 48dp with ripple feedback and a Semantics label/tooltip.
- Do not change behaviour, data, navigation or strings. Visual layer only.
- If a file is over 600 lines, first split it into widgets in a separate step, then restyle.
- Do not add new colours/sizes. If something is missing, stop and propose a token.

Before finishing: run `flutter analyze`, `bash tool/ui_lint.sh`, update and LOOK AT the golden images for light/dark at text scale 1.0 and 1.5, and report remaining violations for this scope. Output a 5-line summary, not a recap of every edit.
```

## 6. Skills to install for the agent (optional, verified to exist)

```
# Official Flutter + Dart skills (layout bugs, overflow fixes, widget previews, tests, a11y audit agent)
claude plugin install dart-flutter@dart-flutter

# Palette / font pairing / UX guidelines (Flutter is one of its supported stacks; needs Python 3)
/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
/plugin install ui-ux-pro-max@ui-ux-pro-max-skill

# Material 3 auditor (Flutter is secondary support)
npx claudepluginhub hamen/material-3-skill --plugin material-3
```

These help the agent *judge* design; the brief, tokens and lint script are what make it *consistent*.
