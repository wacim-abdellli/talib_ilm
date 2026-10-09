# MASTER DESIGN SYSTEM — talib_ilm UI/UX overhaul

## A. WHY THE UI IS BAD (so you fix the cause, not the symptoms)

The app has no single source of truth. Screens bypass the theme. Measured OUTSIDE `lib/app/theme/`:

- 88 raw `Color(0x…)` (46 in `ilm_page.dart`) · 200 raw `fontSize` · 192 raw `fontFamily` · 185 raw `BorderRadius.circular(n)` · 162 `isDark ? :` ternaries · 167 `Colors.white/black` · 30 texts smaller than 12sp · 4 magic `SizedBox(height: 100)` spacers.
- 24 distinct font sizes, 15 radii, 15 icon sizes.
- `ilm_page.dart` has its own private palette (beige `#F5F3F0`, teal `#5A8A8A`, gold `#D4A853`, gray dark `#1F1F1F`); category colours are defined 3 times and Hadith/Fiqh are swapped between files.
- Contrast failures: light tertiary text 2.56:1, white on light primary `#0D9488` 3.74:1, white icons on gold/emerald/azure circles 2.15–2.77:1, dark hero labels 3.46:1.
- 8 of 10 animation-duration tokens are all 180ms; `tapTargetMin = 32` is unused; `AppUi` only re-exports `AppSpacing`/`AppRadius`; `app_colors.dart` has ~114 literals full of aliases.
- No shared Button/Card/Tag/SectionHeader/ListTile: 35 raw `IconButton`s, hand-built tappable `Container`s (14 `GestureDetector` without ripple), 71 hand-written `BoxShadow`s.
- Floating bottom nav (`lib/shared/navigation/app_shell.dart`): hard-coded colours, fixed 68px height with 10–11sp labels, all 5 tabs kept built in a `Stack`+`AnimatedOpacity`.
- Giant files: `ilm_page` 1813 lines, `home_page` 1211, `book_view_page` 1137, `tasbeeh_istighfar_page` 1011, `adhkar_page` 908, `prayer_page` 884.
- Junk in repo root: `git.exe` (13MB), `analysis*.txt`, `build_log.txt`, `cleanup_script.py`.

## B. DESIGN DIRECTION: "Calm Scholar"

Restrained, sacred, readable. One brand colour (teal/emerald). Gold is a RARE accent (milestones, bookmarks, current-prayer dot), never a theme. Surfaces are neutral slate. Colour comes from content (category tag, prayer dot), not from decorating every tile. No gradients on cards, no glow shadows. Light mode: one soft shadow. Dark mode: no shadow, borders instead. Reading surfaces (Quran, Mutun, Adhkar) are the calmest screens.

## C. STRICT RULES (never break; they apply to every phase)

1. **Visual layer only.** Do not change behaviour, data, services, models, navigation logic, routes, or Arabic strings. Leave every string exactly as it is.
2. **Outside `lib/app/theme/` it is FORBIDDEN to write:** `Color(0x…)`, `Colors.white`, `Colors.black` (except `Colors.transparent`), `fontSize:`, `fontFamily:`, `BorderRadius.circular(<number>)`, `EdgeInsets…(<number>)`, `isDark ?`/`brightness ==` ternaries, `BoxShadow(` hand-written, `Duration(milliseconds:` literals, icon `size: <number>`. Use tokens and shared components only.
3. **No new values.** If a design needs a colour/size that is not a token below, STOP and propose the token (name, value, contrast proof) before using it.
4. **Contrast is law.** Text ≥ 4.5:1, icons/UI boundaries ≥ 3:1, verified with `tool/contrast.py` (create it, section I). Never white text/icon on gold. Never use a disabled-looking separate light gray; disabled = 38% opacity.
5. **Minimum text size 12sp.** Nothing below, anywhere, including nav labels and badges.
6. **Minimum tap target 48×48dp** for every tappable, with ripple/pressed feedback (`InkWell`/`InkResponse`/`AppButton`, never a bare `GestureDetector`) and a `Semantics` label or `tooltip`.
7. **RTL-correct.** New/edited code uses `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`; directional icons (chevrons, arrows) must mirror correctly.
8. **Text scaling must not break layout.** Test at 1.0 and 1.5. Fixed `height:` on anything containing text is forbidden; use `minHeight`/`ConstrainedBox`, ellipsis, or wrapping.
9. **One style per concept.** Do not create variants. Reuse the shared component; extend it only if the spec below lacks a needed option.
10. **Split before you restyle.** Any file > 600 lines: first extract widgets into separate files in a commit with NO visual change, then restyle in a second commit.
11. **Small, reversible commits**, one per phase/screen, message `ui(<scope>): <what>`. Never mix refactor and restyle. Never delete a feature or screen.
12. **Verify every step:** `flutter analyze` clean, `bash tool/ui_lint.sh` numbers going down (never up), goldens reviewed (section H). If `flutter` is unavailable, say so and continue with static checks only; do not claim visual verification you didn't do.
13. **Be frugal.** Read only the files in the current scope. Do not re-read files you just edited. Do not paste big diffs in your reports.
14. **Do not touch** `pubspec.yaml` dependencies, `android/ ios/ web/ windows/ linux/ macos/`, or Quran/PDF rendering internals (`quran_library`, Syncfusion viewer behaviour). You may only restyle their surrounding chrome.

## D. TOKENS (the single source of truth: `lib/app/theme/`)

Replace `app_colors.dart`, `theme_colors.dart` and `app_ui.dart` with ONE `AppPalette extends ThemeExtension<AppPalette>` (implement `copyWith` + `lerp`; `static const light` / `static const dark`), register it in BOTH `ThemeData`s in `app_theme.dart`, and expose `context.palette`. Also expose `context.text` (the 8 text styles via `Theme.of(context).textTheme`). Delete every alias. Keep temporary `@Deprecated` shims for the old names (pointing to new values) ONLY until all screens are migrated; delete them in Phase 6.

### D1. Colour — all pairs verified

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#F8FAFC` | `#0A0E13` | Scaffold |
| `surface` | `#FFFFFF` | `#12181F` | Cards, list rows |
| `surfaceRaised` | `#FFFFFF` | `#1A232C` | Sheets, dialogs, nav bar |
| `surfaceMuted` | `#F1F5F9` | `#0E1318` | Search field, recessed areas, skeleton base |
| `border` | `#E2E8F0` | `#22303C` | 1px borders, dividers, progress track |
| `text` | `#0F172A` | `#F8FAFC` | Titles, body |
| `textMuted` | `#475569` | `#94A3B8` | Secondary text |
| `textSubtle` | `#64748B` | `#8A9BB0` | Captions, timestamps (4.55:1 on bg light / 5.6:1 on raised dark) |
| `primary` | `#0F766E` | `#10B981` | Buttons, active nav, links |
| `onPrimary` | `#FFFFFF` (5.47) | `#022C22` (5.97) | On primary |
| `primarySoft` | `#CCFBF1` | `#064E3B` | Tonal buttons, selected chips |
| `onPrimarySoft` | `#0F766E` (4.86) | `#34D399` (5.06) | Text/icon on primarySoft (NOT `#10B981` in dark: 3.83) |
| `gold` (text/icon) | `#B45309` (5.0) | `#FBBF24` (10.7) | Milestones, bookmarks |
| `goldFill` / `onGold` | `#F59E0B` / `#451A03` (6.97) | same | Gold badges |
| `goldSoft` | `#FEF3C7` | `#451A03` | Gold tint background |
| `success` | `#047857` | `#34D399` | |
| `error` | `#B91C1C` | `#F87171` | `#B91C1C` on `#FEE2E2` = 5.3 |
| `errorSoft` | `#FEE2E2` | `#3B1414` | |
| `shadow` | `0 2 8 @4% black` | none | Light mode only, one shadow token |

Also define in `AppPalette`:
- `category(Subject)` → `{fg, bg}` for Aqidah/Quran/Hadith/Fiqh/Seerah/Language/Other: bg = 12% tint of a hue, fg = darkened/lightened until ≥ 4.5:1 on that tint (prove with `contrast.py`). Used ONLY for tag chips and a 4px side marker. **One mapping for the whole app**: delete the three duplicate `_getCategoryColor` implementations (`ilm_page.dart`, `book_card.dart`, and the `AppColors.category*` copies).
- `prayer(PrayerName)` → colour for the 8px dot/ring only (Fajr indigo, Sunrise amber, Dhuhr sky, Asr orange, Maghrib rose, Isha violet; reuse current hues, verify ≥ 3:1 on `surface`).

### D2. Typography (8 styles; Cairo for UI, ONE serif for sacred text)

| Style | Size / weight / line-height | Use |
|---|---|---|
| `display` | 28 / 700 / 1.4 | Hero numbers, countdown |
| `title` | 20 / 700 / 1.5 | Screen & section titles |
| `titleSmall` | 17 / 700 / 1.5 | Card titles |
| `body` | 15 / 400 / 1.7 | Body |
| `bodySmall` | 13 / 400 / 1.6 | Secondary |
| `label` | 13 / 600 / 1.3 | Buttons, chips, nav labels |
| `caption` | 12 / 500 / 1.4 | Smallest allowed |
| `sacred` / `sacredLarge` | 22 / 26, 400, line-height 2.0 | Quran, Hadith, Dhikr — Amiri |

Remove Vazirmatn from `pubspec.yaml` fonts (0 uses). Keep ScheherazadeNew only if `quran_library` or Quran code uses it (grep first). Remove the "legacy" label on Amiri. Colours of text styles come from the palette, not hard-coded.

In `lib/app/app.dart` the text scaler currently multiplies the system scale by up to 1.2 with no cap. Change to `TextScaler.linear((systemScale * sizeScale).clamp(0.9, 1.5))`.

### D3. Spacing / radius / icon / motion / size

| Group | Values |
|---|---|
| `AppSpace` | `xs 4 · sm 8 · md 12 · lg 16 · xl 20 (screen side padding) · xxl 24 · xxxl 32` |
| `AppRadius` | `sm 8 · md 12 (buttons, inputs, snackbars) · lg 16 (cards) · xl 24 (sheets, hero, nav) · pill 999` |
| `AppIcon` | `sm 16 · md 20 · lg 24 · xl 28 · hero 40` |
| `AppMotion` | `fast 120ms · base 200ms · slow 320ms`; curves `easeOutCubic` (in) / `easeInCubic` (out) |
| `AppSize` | `tap 48 · buttonH 48 · inputH 52 · navH 64` and `navClearance(context)` = navH + nav bottom margin + bottom safe-area inset |

Delete: `AppUi`, the 8 duplicate 180ms durations, `tapTargetMin = 32`, all half-step spacings (`gapSMPlus`, `gapXXSPlus`…). Replace every `SizedBox(height: 100)`-style bottom spacer with `AppSize.navClearance(context)`.

## E. SHARED COMPONENTS (build once in `lib/shared/widgets/`, then replace usages)

| Component | Spec |
|---|---|
| `AppButton` (primary / tonal / outline / text; `sm`/`md`) | Height 48 (sm 40 visual with 48 hit area), radius `md`, text `label`@16/600. primary = `primary` bg + `onPrimary`; tonal = `primarySoft` + `onPrimarySoft`; outline = 1px `border` + `text`. Pressed: scale 0.98 + ink overlay. Disabled: 38% opacity. Loading: spinner replaces label, width unchanged. Haptic `lightImpact` on primary only. |
| `AppIconButton` | 24 icon in 48×48 hit area, `tooltip` REQUIRED. |
| `AppCard` | `surface`, 1px `border`, radius `lg`, padding 16. Light: palette shadow. Dark: none. Tappable variant = `InkWell` + press scale 0.98 (`AppMotion.fast`). Replaces `PressableCard` (remove its `#E5DED0` fallback border and `primaryDark` shadow). |
| `AppTag` | Height 28, radius `sm`, `caption`, category `{fg,bg}`; if tappable, 48 hit area. |
| `IconBadge` | 44×44, radius `md`, `primarySoft` bg, `onPrimarySoft` icon at `AppIcon.md` (20). One style for ALL feature tiles; replaces the 50px gradient/glow medallions in `QuickActionButton` and the Home bento. |
| `SectionHeader` | `titleSmall` + optional trailing text button ("عرض الكل"), 24 top / 12 bottom. |
| `AppListTile` | Min height 56, leading `IconBadge`, title `body`/600, subtitle `bodySmall` `textMuted`, trailing chevron mirrored for RTL, divider `border` inset. Used by More, Drawer, Favorites, Library, Settings sheets. |
| `AppProgress` | Height 6, radius 3, track `border`, fill `primary`; fill `gold` only at 100%. |
| `AppSheet` | `surfaceRaised`, top radius `xl`, handle 36×4 in `border`, max height 72%. |
| `AppSnackbar` | Floating, radius `md`, `surfaceRaised`, `text`, bottom margin from `navClearance`. |
| `AppEmptyState` | 96px `primarySoft` circle with an `AppIcon.hero` (40) icon, `titleSmall`, `bodySmall`, optional `AppButton`. Rewrite `app_states.dart` (it hard-codes 80px icons / 20 / 15sp). |
| `AppSkeleton` | Shimmer between `surfaceMuted` and `border`. |
| `NavBar` | Height `navH`(64)+inset, `surfaceRaised`, 1px `border`, radius `xl`, 16 side margin. Item: 24 icon, label **12sp** `label`, ≥48 hit area. Active = `primarySoft` pill 56×32 behind icon + `onPrimarySoft`/`primary` colour; inactive = `textSubtle`. Haptic light. All colours from palette (remove `#10171F`, `#22303C`, `#94A3B8`, `#64748B`). |
| App bar (`PrimaryAppBar`) | Background `bg`, title `titleSmall`, back arrow `text` colour (not primary), 1px bottom `border`. Keep the RTL arrow logic. |
| Inputs / search | Height 52, radius `md`, `surfaceMuted` fill, 1px `border`, focus 2px `primary`, error `error`. Put in `ThemeData.inputDecorationTheme`. |

Also complete `ThemeData` for both modes: `elevatedButtonTheme`, `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `iconButtonTheme`, `chipTheme`, `cardTheme`, `dialogTheme` (radius 20), `bottomSheetTheme`, `snackBarTheme`, `dividerTheme`, `listTileTheme`, `progressIndicatorTheme`, `switchTheme`, `appBarTheme`, `inputDecorationTheme`, `tooltipTheme`, `scrollbarTheme`, `pageTransitionsTheme`; so even un-migrated widgets look right.

## F. PHASES — execute IN ORDER, one at a time

After EACH phase: run `flutter analyze` + `bash tool/ui_lint.sh`, commit, append a 3–5 line entry to `UI_PROGRESS.md` (phase, what changed, lint numbers, open issues), then continue to the next phase. **If your context is getting long or you are unsure, STOP after committing and write "CONTINUE FROM PHASE X" in `UI_PROGRESS.md`; on resume, read `UI_PROGRESS.md` first and do not redo finished phases.**

- Phase 0 — Housekeeping
- Phase 1 — Tokens + theme
- Phase 2 — Components
- Phase 3 — Shell & navigation
- Phase 4 — Screens (Home, Prayer, Ilm, Adhkar, Quran, More/Drawer, Qibla, PDF/video, etc.)
- Phase 5 — States
- Phase 6 — Lock

## G. DEFINITION OF DONE

- `bash tool/ui_lint.sh` prints `OK` (all counts 0 outside `lib/app/theme/`).
- `flutter analyze` has no new warnings.
- Every colour pair used passes `tool/contrast.py`.
- No text < 12sp, no tappable < 48dp, no fixed-height text container.
- Light/dark goldens at text scale 1.0 and 1.5, RTL, show no overflow or clipping.
- One category mapping, one primary button style, one card style, one tag style, one list tile.
- `UI_PROGRESS.md` shows each phase complete with its lint numbers.

## H. HOW TO SEE YOUR OWN WORK (do not work blind)

1. Create `test/golden/` with a helper that pumps a widget inside `MaterialApp(theme: AppTheme.light(), darkTheme: AppTheme.dark(), locale: Locale('ar'))` wrapped in `Directionality(rtl)`, with the app's real `ThemeData`, at a phone size (390×844) and text scale 1.0 and 1.5, in light and dark. Use `matchesGoldenFile`.
2. Generate with `flutter test --update-goldens test/golden`, then open the PNGs and look at them (read the image files) before reporting done. Look specifically for: overflow stripes, clipped text, unreadable contrast, misaligned RTL, touch targets that look < 48.
3. For screens, use `SharedPreferences.setMockInitialValues({})` and fake data. If a screen cannot be pumped without heavy plugin mocking (geolocator, just_audio, webview, Syncfusion), golden-test the shared components and the extracted sub-widgets of that screen instead and say so in `UI_PROGRESS.md`.
4. If `flutter` is not installed in your environment, skip goldens, and rely on lint + analyze + contrast only. Never claim visual verification you did not do.
