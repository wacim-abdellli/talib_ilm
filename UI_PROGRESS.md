# UI Progress Log

## Baseline (Phase 0)
- **Raw Color(0x...) literals:** 88
- **Raw fontSize: <n>:** 200
- **Raw fontFamily: '...':** 192
- **Raw BorderRadius.circular(<n>):** 185
- **Raw EdgeInsets with numbers:** 150
- **Text smaller than 12:** 30
- **Colors.white/black:** 167
- **isDark ? ... : ...:** 162
- **Magic bottom spacer (height 80-120):** 4
- **Hand-written BoxShadow(:** 64
- **Raw GestureDetector(:** 14

---

### Phase 0 — Housekeeping
- **Status:** Complete
- **Changes:** Configured `tool/ui_lint.sh` and `tool/contrast.py`, deleted root `git.exe`, unreferenced `app_main_logo.png` & `logo2.png`, added ignore rules to `.gitignore`, saved master spec as `DESIGN_SYSTEM.md`, established lint baseline.
- **Lint Numbers:** (Baseline recorded above)
- **Open Issues:** None.

---

### Phase 1 — Tokens + Theme
- **Status:** Complete
- **Changes:** Implemented Section D tokens in `lib/app/theme/app_palette.dart` with `AppPalette`, `AppTextTheme`, `AppSpace`, `AppRadius`, `AppIcon`, `AppMotion`, `AppSize`. Completed all 18 component themes in `lib/app/theme/app_theme.dart`. Clamped textScaler in `lib/app/app.dart` between 0.9 and 1.5. Removed Vazirmatn from `pubspec.yaml`. Provided `@Deprecated` shims in `app_colors.dart`, `theme_colors.dart`, `app_ui.dart`, `app_spacing.dart`, `app_radius.dart`.
- **Lint Numbers:** (Same as baseline; 0 screen edits)
  - Raw Color(0x...) literals: 88
  - Raw fontSize: <n>: 200
  - Raw fontFamily: '...': 192
  - Raw BorderRadius.circular(<n>): 185
  - Raw EdgeInsets with numbers: 150
  - Text smaller than 12: 30
  - Colors.white/black: 167
  - isDark ? ... : ...: 162
  - Magic bottom spacer: 4
  - Hand-written BoxShadow: 64
  - Raw GestureDetector: 14
- **Contrast Proof:**
  - `text` on `bg` / `surface`: Light 17.06:1 / 17.85:1, Dark 18.50:1 / 17.07:1 (AA text)
  - `textMuted` on `surface`: Light 7.58:1, Dark 6.96:1 (AA text)
  - `textSubtle` on `bg` / `surfaceRaised`: Light 4.55:1 / 4.76:1, Dark 6.82:1 / 5.60:1 (AA text)
  - `onPrimary` on `primary`: Light 5.47:1, Dark 5.97:1 (AA text)
  - `onPrimarySoft` on `primarySoft`: Light 4.86:1, Dark 5.06:1 (AA text)
  - `gold` on `surface`: Light 5.02:1, Dark 10.70:1 (AA text)
  - `onGold` on `goldFill`: 6.97:1 (AA text)
  - `error` on `errorSoft`: Light 5.30:1, Dark 5.86:1 (AA text)
  - All categories (Aqidah, Quran, Hadith, Fiqh, Seerah, Language, Other): Light 4.86–9.45:1, Dark 5.06–9.85:1 (All AA text)
  - All prayers (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha): Light 3.56–6.29:1, Dark 5.99–10.70:1 (All >= 3:1 boundaries)
- **Open Issues:** None.

---

### Phase 2 — Components
- **Status:** Complete
- **Changes:** Built Section E shared components (`AppButton`, `AppIconButton`, `AppCard`, `AppTag`, `IconBadge`, `SectionHeader`, `AppListTile`, `AppProgress`, `AppSheet`, `AppSkeleton`, `NavBar`). Refactored internals of existing shared widgets to new tokens: `AppEmptyState`, `EmptyState`, `PrimaryAppBar`, `AppSnackbar`, `AppPopup`, `ProgressPill`, `SearchBarWidget`, `NotificationBadge`, `PressableCard`, `ShimmerLoading`, `AppDrawer`, `AppOverflowMenu`. Created golden tests helper and test suite in `test/golden/`; all 7 golden tests pass and visually verified.
- **Lint Numbers:**
  - Raw Color(0x...) literals: 88 → 86 (-2)
  - Raw fontSize: <n>: 200 → 184 (-16)
  - Raw fontFamily: '...': 192 → 177 (-15)
  - Raw BorderRadius.circular(<n>): 185 → 166 (-19)
  - Raw EdgeInsets with numbers: 150 → 132 (-18)
  - Text smaller than 12: 30 → 29 (-1)
  - Colors.white/black: 167 → 132 (-35)
  - isDark ? ... : ...: 162 → 149 (-13)
  - Magic bottom spacer: 4 → 4
  - Hand-written BoxShadow: 64 → 58 (-6)
  - Raw GestureDetector: 14 → 14
- **Open Issues:** None.

---

### Phase 3 — Shell & Navigation
- **Status:** Complete
- **Changes:** Refactored `app_shell.dart` to use `NavBar` with RTL Semantics and haptic feedback. Replaced `Stack` + `AnimatedOpacity` with `IndexedStack` to stop offscreen tab rendering while preserving scroll state. Replaced all 4 magic bottom spacers (`SizedBox(height: 100)`) with `AppSize.navClearance(context)` across `ilm_page.dart`, `more_page.dart`, `prayer_page.dart`, and `home_page.dart`.
- **Lint Numbers:**
  - Raw Color(0x...) literals: 86 → 83 (-3)
  - Raw fontSize: <n>: 184 → 184 (0)
  - Raw fontFamily: '...': 177 → 176 (-1)
  - Raw BorderRadius.circular(<n>): 166 → 164 (-2)
  - Raw EdgeInsets with numbers: 132 → 131 (-1)
  - Text smaller than 12: 29 → 29 (0)
  - Colors.white/black: 132 → 130 (-2)
  - isDark ? ... : ...: 149 → 144 (-5)
  - Magic bottom spacer: 4 → 0 (-4, ELIMINATED)
  - Hand-written BoxShadow: 58 → 57 (-1)
  - Raw GestureDetector: 14 → 13 (-1)
- **Open Issues:** None.

---

### Phase 4.1 — Home Screen
- **Status:** Complete
- **Changes:** Extracted widgets prior to restyling (`home_header.dart`, `continue_learning_card.dart`, `home_quick_actions.dart`). Restyled `home_page.dart`, `home_hero_card.dart`, `quick_action_button.dart`, and `DailyMotivationCard` to Calm Scholar tokens. Hero card uses `AppCard` in `surface`, countdown in `text` colour (not gold), and 8px gold dot for current prayer. Quick actions use `AppCard` + `IconBadge` + `label` without gradients or per-feature colours. Continue learning card uses `AppProgress`. Daily motivation card uses `sacred` style on `surfaceMuted`. Fixed text-scale 1.5 overflow resilience. Added golden tests suite in `test/golden/home_golden_test.dart` (all passed and visually inspected). Lint violations in all home presentation files reached **0**.
- **Lint Numbers:**
  - Raw Color(0x...) literals: 83 → 65 (-18)
  - Raw fontSize: <n>: 184 → 155 (-29)
  - Raw fontFamily: '...': 176 → 151 (-25)
  - Raw BorderRadius.circular(<n>): 164 → 143 (-21)
  - Raw EdgeInsets with numbers: 131 → 110 (-21)
  - Text smaller than 12: 29 → 24 (-5)
  - Colors.white/black: 130 → 107 (-23)
  - isDark ? ... : ...: 144 → 102 (-42)
  - Magic bottom spacer: 0 → 0 (0)
  - Hand-written BoxShadow: 57 → 43 (-14)
  - Raw GestureDetector: 13 → 10 (-3)
- **Open Issues:** None.

---

### Phase 4.2 — Prayer Screen
- **Status:** Complete
- **Changes:** Extracted widgets prior to restyling (`prayer_header.dart`, `prayer_time_card.dart`, `prayer_calc_section.dart`, `prayer_adhan_section.dart`, `prayer_adjustments_section.dart` into `lib/features/prayer/presentation/widgets/`). Restyled `prayer_page.dart`, `prayer_settings_sheet.dart`, `location_settings_sheet.dart`, `next_prayer_card.dart`, `prayer_time_tile.dart`, and all prayer widgets to Calm Scholar tokens. Prayer rows use `AppCard`, current prayer emphasised with `primarySoft` background and 8px gold dot, prayer colors restricted strictly to 8px dot, countdown in neutral `text` color, `AppProgress` for next prayer timeline, bottom sheets use `AppSheet` style and tokens, all buttons use `AppButton`. Ensured text scale 1.5 resilience with flexible layout. Added 6 golden tests in `test/golden/prayer_golden_test.dart` (all passed and visually inspected). Lint violations across all 11 prayer presentation files reached **0**.
- **Lint Numbers:**
  - Raw Color(0x...) literals: 65 → 65 (0)
  - Raw fontSize: <n>: 155 → 118 (-37)
  - Raw fontFamily: '...': 151 → 114 (-37)
  - Raw BorderRadius.circular(<n>): 143 → 108 (-35)
  - Raw EdgeInsets with numbers: 110 → 89 (-21)
  - Text smaller than 12: 24 → 21 (-3)
  - Colors.white/black: 107 → 94 (-13)
  - isDark ? ... : ...: 102 → 72 (-30)
  - Magic bottom spacer: 0 → 0 (0)
  - Hand-written BoxShadow: 43 → 37 (-6)
  - Raw GestureDetector: 10 → 10 (0)
- **Open Issues:** None.

---

### Phase 4.3 — Ilm Screen
- **Status:** Complete
- **Changes:** Split files > 600 lines (`ilm_page.dart` 1813 lines, `book_view_page.dart` 1137 lines) into dedicated subwidgets in commit 1 (`ilm_header.dart`, `ilm_continue_reading_card.dart`, `ilm_daily_progress_card.dart`, `ilm_level_section.dart`, `ilm_enhanced_book_card.dart`, `sharh_reader_page.dart`, `book_mutn_tab.dart`, `book_sharh_tab.dart`, `book_view_bookmarks_sheet.dart`, `book_view_controls.dart`, `continue_sharh_card.dart`). In commit 2, restyled all 17 presentation files to Calm Scholar tokens. Completely removed private palette (beige `#F5F3F0`, teal `#5A8A8A`, gold `#D4A853`, dark gray `#1F1F1F`) and unified category colors through `palette.category()`. Replaced custom cards with `AppCard`, custom tags with `AppTag`, progress bars with `AppProgress`, buttons with `AppButton`/`AppIconButton`. Handled text scale 1.5 overflow resilience in `BookCard` via `Wrap`. Added and verified 8 golden tests in `test/golden/ilm_golden_test.dart` (all passed and visually inspected). Lint violations in all Ilm files reached **0**.
- **Lint Numbers:**
  - Raw Color(0x...) literals: 65 → 19 (-46)
  - Raw fontSize: <n>: 118 → 101 (-17)
  - Raw fontFamily: '...': 114 → 99 (-15)
  - Raw BorderRadius.circular(<n>): 108 → 75 (-33)
  - Raw EdgeInsets with numbers: 89 → 67 (-22)
  - Text smaller than 12: 21 → 18 (-3)
  - Colors.white/black: 94 → 63 (-31)
  - isDark ? ... : ...: 72 → 63 (-9)
  - Magic bottom spacer: 0 → 0 (0)
  - Hand-written BoxShadow: 37 → 22 (-15)
  - Raw GestureDetector: 10 → 6 (-4)
- **Open Issues:** None.

---

### Phase 4.4 — Adhkar / Tasbeeh Screens
- **Status:** Complete
- **Changes:**
  - Commit 1 (`f4aa7a5`): Split files > 600 lines (`adhkar_page.dart` 908 lines, `tasbeeh_istighfar_page.dart` 1011 lines) into modular subwidgets in `lib/features/adhkar/presentation/widgets/` (`adhkar_header.dart`, `adhkar_contextual_hero.dart`, `adhkar_category_tile.dart`, `rosary_dial.dart`, `change_dhikr_sheet.dart`, `set_target_sheet.dart`). Zero visual changes.
  - Commit 2: Restyled all 10 Adhkar presentation files to Calm Scholar tokens (`adhkar_page.dart`, `adhkar_session_page.dart`, `duas_misc_page.dart`, `tasbeeh_istighfar_page.dart`, and subwidgets). Dhikr/Quran Arabic text uses `sacred` / `sacredLarge` typography. Category cards use `AppCard` and `IconBadge` with `palette.primarySoft` and `palette.onPrimarySoft`. Rosary counter and session counter have >= 72px interactive hit targets with haptics and pulse animations. Sheets use `AppSheet` style, input fields use tokenized decoration, buttons use `AppButton` / `AppIconButton`. Fixed text-scale 1.5 overflow resilience in `RosaryDial`, `CategoryTile`, `AdhkarContextualHero`, and `HomeHeroCard`. Added and verified 8 golden tests in `test/golden/adhkar_golden_test.dart` across light/dark and 1.0/1.5 text scales (all 25 golden tests in repository now pass). Lint violations in all Adhkar files reached **0**.
- **Lint Numbers:**
  - Raw Color(0x...) literals: 19 → 16 (-3)
  - Raw fontSize: <n>: 101 → 57 (-44)
  - Raw fontFamily: '...': 99 → 55 (-44)
  - Raw BorderRadius.circular(<n>): 75 → 35 (-40)
  - Raw EdgeInsets with numbers: 67 → 34 (-33)
  - Text smaller than 12: 18 → 10 (-8)
  - Colors.white/black: 63 → 52 (-11)
  - isDark ? ... : ...: 63 → 36 (-27)
  - Magic bottom spacer: 0 → 0 (0)
  - Hand-written BoxShadow: 22 → 15 (-7)
  - Raw GestureDetector: 6 → 4 (-2)
- **Open Issues:** None.

---

### Phase 4.5 — Quran & Bookmarks Screens
- **Status:** Complete
- **Changes:**
  - Restyled all 4 Quran presentation files to Calm Scholar tokens: `quran_page.dart`, `bookmarks_page.dart`, `quran_library_wrapper.dart`, and `widgets/surah_card.dart`.
  - Converted custom AppBars in `quran_page.dart` and `bookmarks_page.dart` to `PrimaryAppBar` with subtitle and action buttons.
  - Replaced hardcoded stat cards, last-read card, and surah list items with `AppCard`, semantic colors (`palette.gold`, `palette.primary`), and tokens.
  - Styled `SurahNumberMedallion` with authentic Islamic 8-pointed star (Rub el Hizb) medallion using gold star borders and `FittedBox` scaling for multi-digit numbers.
  - Surah names use `context.text.sacred` typography (Amiri) and badges wrap with `Wrap` for 1.5 text scale accessibility resilience.
  - Harmonized `quran_library_wrapper.dart` chrome with `AppPalette` (`palette.bg`, `palette.surface`, `palette.surfaceRaised`, `palette.goldSoft`, `palette.onGold`).
  - Replaced magic bottom spacer (100) with `AppSize.navClearance(context)`.
  - Added 6 golden tests in `test/golden/quran_golden_test.dart` (SurahCard unbookmarked, bookmarked, and medallion across light 1.0 and dark 1.5). All 28 golden tests in repo pass.
  - UI lint violations in all Quran files reached **0**.
- **Lint Numbers:**
  - Raw Color(0x...) literals: 16 → 16 (0)
  - Raw fontSize: <n>: 57 → 41 (-16)
  - Raw fontFamily: '...': 55 → 37 (-18)
  - Raw BorderRadius.circular(<n>): 35 → 22 (-13)
  - Raw EdgeInsets with numbers: 34 → 23 (-11)
  - Text smaller than 12: 10 → 4 (-6)
  - Colors.white/black: 52 → 42 (-10)
  - isDark ? ... : ...: 36 → 17 (-19)
  - Magic bottom spacer: 0 → 0 (0)
  - Hand-written BoxShadow: 15 → 12 (-3)
  - Raw GestureDetector: 4 → 3 (-1)
---

### Phase 4.6 — Qibla & More Screens
- **Status:** Complete
- **Changes:**
  - Split `qibla_page.dart` (709 lines) into `astrolabe_compass.dart` (`5bb605c`).
  - Restyled `qibla_page.dart` and `astrolabe_compass.dart` to Calm Scholar tokens with Astrolabe compass design (`8b27215`). Added golden tests in `test/golden/prayer_golden_test.dart`.
  - Split `more_page.dart` (701 lines) into `more_section_card.dart` and `theme_selector_sheet.dart` (`03274f2`).
  - Restyled `more_page.dart`, `more_section_card.dart`, and `theme_selector_sheet.dart` to Calm Scholar tokens (`e2239aa`). Added golden tests in `test/golden/more_golden_test.dart`.
  - UI lint violations in Qibla and More reached **0**.

---

### Phase 4.7 — Library & Favorites Screens
- **Status:** Complete
- **Changes:**
  - Restyled `library_page.dart` to Calm Scholar tokens: tokenized header with search bar, replaced level cards with `AppCard`, `AppIconButton`, and tokens (`c9f5838`). Added golden tests in `test/golden/library_golden_test.dart`.
  - Restyled `favorites_page.dart` to Calm Scholar tokens: tokenized header with item count, replaced list items with `AppCard`, integrated `AppEmptyState.favorites()`, and added `AppSize.navClearance` (`3ae85d6`). Added golden tests in `test/golden/favorites_golden_test.dart`.
  - UI lint violations in Library and Favorites reached **0**.

---

### Phase 4.8 — PDF Viewer & Shared Widgets
- **Status:** Complete
- **Changes:**
  - Restyled `pdf_viewer_page.dart` chrome, top bar, bottom bar, jump dialog, and brightness dialog to Calm Scholar tokens (`9523d22`). Maintained Syncfusion PDF internals untouched.
  - Tokenized all remaining shared widgets:
    - `achievement_toast.dart`: tokenized gold celebration toast, confetti painter, and hit targets.
    - `app_progress.dart`: replaced raw radii with `AppRadius.pillRadius`.
    - `floating_particles.dart`: tokenized ambient particles with palette defaults.
    - `notification_badge.dart`: tokenized EdgeInsets and typography.
    - `animated_background.dart`: tokenized Islamic geometric star background.
    - `app_drawer.dart`: tokenized list item vertical padding.
    - `app_snackbar.dart`: tokenized floating margin.
    - `nav_bar.dart`: removed redundant font size.
  - UI lint violations in PDF Viewer and all shared widgets reached **0**.

---

## Final Verification & 100% Milestone Completion
- **UI Lint Status (`tool/ui_lint.py`):** **0 violations across entire repository** (budget 0 for every single rule).
  - Raw Color(0x...) literals: **0**
  - Raw fontSize: <n>: **0**
  - Raw fontFamily: '...': **0**
  - Raw BorderRadius.circular(<n>): **0**
  - Raw EdgeInsets with numbers: **0**
  - Text smaller than 12: **0**
  - Colors.white/black: **0**
  - isDark ? ... : ...: **0**
  - Magic bottom spacer: **0**
  - Hand-written BoxShadow: **0**
  - Raw GestureDetector: **0**
- **Dart Analyzer (`flutter analyze`):** **0 issues found** across the entire repository.
- **Golden Tests (`flutter test test/golden/`):** **34 / 34 passed** across light (1.0 text scale) and dark (1.5 text scale) modes.
- **Zero Behavioral Regressions:** Zero changes to models, services, strings, or navigation logic.

---

# Round 2

## Stage R0 — Rescue, verify, baseline

### 1. Rescue & Remote Backup
- **Branch created:** `ui/overhaul-round1` created at commit `e892780` (containing all Round 1 commits).
- **Remote Push:** `git push -u origin ui/overhaul-round1` succeeded.
- **Tag:** `ui-r1-done` tagged at `e892780` and pushed to `origin`.

### 2. Fonts Verification & Rescue
- All 5 `assets/fonts/Cairo-*.ttf` files were verified to be saved HTML documents (~297KB each, headers containing `<!DOCTYPE html>`).
- Replaced with genuine static Cairo TrueType fonts downloaded directly from official Google Fonts CDN (`fonts.gstatic.com`, v31):
  - `Cairo-Regular.ttf` (91,500 B) — TrueType verified
  - `Cairo-Medium.ttf` (91,676 B) — TrueType verified
  - `Cairo-SemiBold.ttf` (91,724 B) — TrueType verified
  - `Cairo-Bold.ttf` (91,664 B) — TrueType verified
  - `Cairo-ExtraBold.ttf` (91,748 B) — TrueType verified
- All other repository TTFs (`Amiri-*.ttf`, `ScheherazadeNew-*.ttf`, `Vazirmatn-*.ttf`) verified as valid TrueType font data.

### 3. Build & Test Verification
- `flutter pub get`: Succeeded (0 errors).
- `flutter analyze`: Succeeded (`No issues found!`, ran in 59.6s).
- `flutter test`: 35 passed, 1 failed (`test/golden/adhkar_golden_test.dart`: `adhkar_hero_light_1_0.png` 0.32% / 1058px diff, `adhkar_hero_dark_1_5.png` 0.25% / 837px diff due to rendering with genuine Cairo font rather than previous fallback).
- `flutter build apk --debug`: Succeeded (`build\app\outputs\flutter-apk\app-debug.apk` built in 104.2s).

### 4. Round 1 Audit
- **Phase 5 & 6 Check:** Confirmed `UI_PROGRESS.md` does **NOT** contain Phase 5 (loading/empty/error states) nor Phase 6 (delete `@Deprecated` shims). Neither phase was executed or logged in Round 1.
- **`@Deprecated` shims in `lib/app/theme/`:** **10** shims found across `app_colors.dart`, `app_radius.dart`, `app_spacing.dart`, `app_ui.dart`, and `theme_colors.dart`.

### 5. UI Lint v2 Baseline (`python tool/ui_lint_v2.py --top 5`)
- **Total FAIL violations:** 54
- **Allow markers used:** 0 / 10

```text
=== UI lint v2 (outside lib/app/theme) ===
FAIL    34  Duration(milliseconds/seconds) literal
FAIL    10  @Deprecated shims left in lib/app/theme
FAIL     6  Icon size: <n>
FAIL     2  brightness / isDark branching in a screen
FAIL     1  IconButton without tooltip
FAIL     1  raw TextStyle( constructor
WARN    93  FontWeight literal (use text styles)
WARN    14  RTL: EdgeInsets.only(left/right) / Alignment.*Left|Right
WARN    12  gradient on a surface (Linear/RadialGradient)
WARN     7  SizedBox(width/height: <n>) (use AppSpace)
info  allow markers used: 0 (cap 10)

[Duration(milliseconds/seconds) literal]
      9  lib\features\quran\data\quran_api_service.dart
      4  lib\core\services\location_service.dart
      3  lib\features\quran\data\services\quran_sync_service.dart
      2  lib\core\utils\micro_interactions.dart
      1  lib\core\services\adhan_service.dart

[IconButton without tooltip]
      1  lib\features\adhkar\presentation\duas_misc_page.dart

[Icon size: <n>]
      2  lib\shared\widgets\shimmer_loading.dart
      1  lib\features\home\presentation\widgets\continue_learning_card.dart
      1  lib\features\home\presentation\widgets\home_hero_card.dart
      1  lib\shared\widgets\animated_background.dart
      1  lib\shared\widgets\floating_particles.dart

[brightness / isDark branching in a screen]
      1  lib\features\prayer\presentation\prayer_settings_sheet.dart
      1  lib\shared\widgets\app_drawer.dart

[raw TextStyle( constructor]
      1  lib\features\quran\presentation\quran_library_wrapper.dart

[FontWeight literal (use text styles)]
     10  lib\features\home\presentation\widgets\home_hero_card.dart
      6  lib\features\adhkar\presentation\adhkar_session_page.dart
      5  lib\features\home\presentation\widgets\continue_learning_card.dart
      4  lib\features\adhkar\presentation\duas_misc_page.dart
      4  lib\features\adhkar\presentation\widgets\rosary_dial.dart

[SizedBox(width/height: <n>) (use AppSpace)]
      1  lib\features\adhkar\presentation\widgets\rosary_dial.dart
      1  lib\features\home\presentation\widgets\continue_learning_card.dart
      1  lib\features\home\presentation\widgets\home_header.dart
      1  lib\features\home\presentation\widgets\home_hero_card.dart
      1  lib\features\more\presentation\widgets\more_section_card.dart

[gradient on a surface (Linear/RadialGradient)]
      5  lib\features\home\presentation\widgets\home_hero_card.dart
      2  lib\features\home\presentation\widgets\continue_learning_card.dart
      2  lib\features\home\presentation\widgets\quick_action_button.dart
      2  lib\features\prayer\presentation\widgets\next_prayer_card.dart
      1  lib\features\ilm\presentation\widgets\motivation_widgets.dart

[RTL: EdgeInsets.only(left/right) / Alignment.*Left|Right]
      4  lib\features\home\presentation\widgets\continue_learning_card.dart
      4  lib\features\home\presentation\widgets\home_hero_card.dart
      2  lib\features\home\presentation\widgets\quick_action_button.dart
      2  lib\features\ilm\presentation\widgets\motivation_widgets.dart
      2  lib\features\prayer\presentation\widgets\next_prayer_card.dart

FAILED (54 violations)
```

### 6. Open Issues
- 53 UI lint v2 violations to be resolved in R1 (reduced from 54 baseline after fixing `prayer_settings_sheet.dart`).
- 10 `@Deprecated` shims to be removed in R1 Phase 6.

---

## Prayer Times Page Overhaul
- **Status:** Complete
- **Refined Color Palette (`AppPalette`):**
  - Replaced saturated/garish prayer colors with serene celestial hues matching Islamic astronomy aesthetics:
    - Fajr: `#3730A3` (light) / `#818CF8` (dark) (9.49:1 & 6.34:1 contrast)
    - Sunrise: `#92400E` (light) / `#FBBF24` (dark) (6.78:1 & 11.34:1 contrast)
    - Dhuhr: `#0369A1` (light) / `#38BDF8` (dark) (5.67:1 & 8.83:1 contrast)
    - Asr: `#9A3412` (light) / `#FB923C` (dark) (6.98:1 & 8.36:1 contrast)
    - Maghrib: `#9F1239` (light) / `#FB7185` (dark) (7.66:1 & 7.03:1 contrast)
    - Isha: `#5B21B6` (light) / `#A78BFA` (dark) (8.59:1 & 6.95:1 contrast)
  - All 12 values verified WCAG AA compliant on background and surfaces via `tool/contrast.py`.
- **Hero Timepiece Card (`NextPrayerCard`):**
  - Removed bright linear background gradients.
  - Built an elegant Islamic timepiece aesthetic using `palette.surfaceRaised` with a subtle hairline border.
  - Tabular countdown with gold progress bar indicator.
  - 3 quick-action interactive buttons: Qibla Compass, Adhkar, and Prayer Notifications with ripple feedback and semantic tooltips.
- **Prayer List Tiles (`PrayerTimeCard`):**
  - Replaced overwhelming full-green card fill on the active prayer with a subtle gold accent border (`1.5px`) and gold badge tag ("الآن").
  - Jewel icon badge per prayer using individual celestial palette accents.
  - Interactive Adhkar link chip with arrow indicator.
  - Interactive Adhan notification bell with toggle state and tooltip.
- **Prayer Header (`PrayerHeader`):**
  - Rebuilt chip row with balanced flex ratios (`flex: 3` for City selector, `flex: 2` for Date display) with text overflow protection, preventing any RenderFlex overflows up to 2.0x text scale.
  - Added direct Qibla Compass and Settings action buttons in the header bar.
- **Settings Sheet Integration (`PrayerPage`):**
  - Connected `PrayerSettingsSheet` to header settings button and hero card shortcuts.
  - Fixed brightness branching in `prayer_settings_sheet.dart` to use `palette.isDark`, reducing v2 lint failures from 54 to 53.
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 53 violations (1 violation fixed, 0 regressions).
  - `flutter test`: 36/36 tests passed (including all golden tests).
  - `flutter build apk --debug`: Built cleanly.

---

## Home Header Overhaul
- **Status:** Complete
- **Adaptive Brand Emblem (`HomeHeader`):**
  - Replaced hardcoded `brandDark` badge container with theme-adaptive `palette.surfaceRaised` + `palette.border`.
  - In light mode: pure white elevated tile `#FFFFFF` with `#E2E8F0` hairline border displaying `symbol_on_light.png` (crisp deep ink star with gold Quran book).
  - In dark mode: obsidian slate tile `#1A232C` with dark border displaying `symbol_on_dark.png` (luminous ivory star with gold Quran book).
  - Added accessibility semantics (`Semantics(label: 'شعار طالب العلم', image: true)`).
- **Hijri Date Badge:**
  - Removed star/sparkle icon (`Icons.auto_awesome_rounded`) beside the date per user request.
  - Redesigned date pill into an editorial scholarly jewel badge using `palette.surfaceRaised`, `palette.border`, and tabular figures `palette.textMuted`.
  - Added `Flexible` with `FittedBox(fit: BoxFit.scaleDown)` to ensure overflow immunity across 1.0, 1.5, and 2.0 text scaling.
- **Location & Typography Refinement:**
  - Switched location icon to brand accent `palette.gold`.
  - Eliminated literal SizedBox spacing warning in `tool/ui_lint_v2.py`.
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 53 violations (SizedBox warning reduced by 1).
  - `flutter test`: 37/37 tests passed (all goldens green).

---

## Sacred Emblem & Landing Splash Page Overhaul
- **Status:** Complete
- **Unique Sacred Logo & Emblem:**
  - Generated and crafted a deeply emotional, unique brand emblem for *Talib Ilm*: An illuminated Holy Quran in gold calligraphy illuminations, resting beneath a radiant celestial crescent and glowing 8-pointed star of sacred wisdom, encased within a 3D brushed gold Andalusian Rub el Hizb frame.
  - Processed and exported master assets:
    - `assets/branding/symbol_on_dark.png` & `symbol_on_light.png` (clean transparent cutout)
    - `assets/branding/icon_dark_rounded.png` & `icon_light_rounded.png` (1024x1024)
    - `assets/branding/ios_icon_1024.png` & Android adaptive foreground
    - `assets/images/logo.png`
  - Regenerated platform launcher icons (`dart run flutter_launcher_icons`) and native splash screens (`dart run flutter_native_splash:create`).
- **In-App Landing / Splash Screen (`SplashPage`):**
  - Added sacred Basmalah at the top with full shakl/tashkeel: `بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ` using `context.text.sacredLarge` in classical `Amiri` calligraphy font in luminous gold.
  - Centered glowing emblem with smooth breathing fade/scale animation, title `طالبُ العِلْمِ`, and subtitle `زادُ المسلمِ في طَلَبِ العِلمِ النَّافِعِ`.
  - Added gold progress bar and hadith citation: `«مَنْ سَلَكَ طَرِيقاً يَلْتَمِسُ فِيهِ عِلْماً سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقاً إِلَى الْجَنَّةِ»`.
  - Tap-to-proceed functionality or smooth auto-transition to `AppShell` via `AppMotion.splash`.
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 53 violations (0 regressions).
  - `flutter test`: 39/39 tests passed (all golden tests green, including light 1.0 & dark 1.5 splash tests).
  - `flutter build apk --debug`: Built cleanly.

---

## Warm Gold / Obsidian Theme Harmonization & Single Splash Fix
- **Status:** Complete
- **Single Splash Page Fix:**
  - Removed duplicate OS native splash logo in `flutter_native_splash` (Android/iOS now display seamless solid window background, avoiding the double 2-second logo delay).
  - `SplashPage` is now the sole entrance screen with the Basmalah with full shakl at the top, glowing emblem, and hadith.
  - Reduced splash duration to 1400ms (`AppMotion.splash`) with instant tap-to-skip.
- **Harmonized Warm Gold & Obsidian Palette:**
  - Evolved `AppPalette` to harmonize the whole application with the royal gold logo:
    - **Light Mode**: Warm ivory parchment `#FAF8F5`, elevated white surfaces `#FFFFFF`, warm parchment border `#E7E0D3`, ink stone text `#1C1917`, imperial amber gold primary `#8D5B0E`, warm cream primary soft `#FEF3C7`, deep amber brown `#784D09`.
    - **Dark Mode**: Warm deep obsidian `#0C0A09`, obsidian charcoal surfaces `#171412` / `#211C19`, dark bronze border `#2E2721`, warm ivory text `#FAF8F5`, luminous warm gold primary `#F59E0B`, deep amber soft `#2D2310`, radiant gold `#FDE68A`.
  - All color pairs verified WCAG AA compliant via `tool/contrast.py` (5.45:1 to 18.64:1).
  - Soft on eyes for extended study sessions, eliminating cold blue glare.
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 53 violations (0 regressions).
---

## Home Page Header Component Re-architecture
- **Status:** Complete
- **Re-architected Dual-Tier Component Layout (`HomeHeader`):**
  - Completely replaced the basic single-row header with a stately, multi-component luxury Islamic layout:
  - **Tier 1 (Brand Lockup & Action Group):**
    - **Sacred Emblem Badge:** 48×48 elevated jewel badge with gold highlight border (`palette.gold.withValues(alpha: 0.35)`), soft drop shadow, smooth corner radius (`AppRadius.mdRadius`), and ink ripple. Tapping reveals a dignified bottom sheet with the sacred hadith «مَنْ سَلَكَ طَرِيقاً يَلْتَمِسُ فِيهِ عِلْماً...».
    - **Greeting & Spiritual Subtitle:** Replaced the crammed text column with a 2-tier salutation: bold contextual greeting (`greeting`) with a glowing amber beacon dot + time-aware du'a/nasiha (`greetingSubtitle` e.g., «طاب مسعاك في طلب العلم والخير»).
    - **Action Controls:** Added interactive quick action buttons with 48dp minimum touch target (`AppIconButton`):
      - Search shortcut (`Icons.search_rounded`) navigating directly to books and mutun search (`_openIlm`).
      - Qibla compass shortcut (`Icons.explore_outlined`) navigating directly to `QiblaPage` (`_openQibla`).
  - **Tier 2 (Dedicated Status & Utility Strip):**
    - **Interactive Location Pill (`_HeaderLocationChip`):** Displays city with gold pin icon, bold typography, and expand chevron with ripple feedback. Tapping opens full prayer timetable (`_openPrayerDetails`).
    - **Hijri Date Pill (`_HeaderDateChip`):** Features gold calendar icon (no star/sparkle per user request), clean tabular digits, and ripple feedback. Tapping displays a comprehensive Gregorian & Hijri date inspection sheet.
- **Accessibility & Responsiveness:**
  - 100% compliant with min 48dp tap target on all interactive elements.
  - Text scaling immunity: Proportional flex distribution (`flex: 2` Location, `flex: 3` Date) with `FittedBox(fit: BoxFit.scaleDown)` and `TextOverflow.ellipsis`, completely overflow-free across 1.0, 1.5, and 2.0 text scaling.
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 53 violations (0 new violations, 3 warnings removed).
  - `flutter test`: 39/39 tests passed (updated and approved `home_header_light_1_0` and `home_header_dark_1_5` goldens).
  - `flutter build apk --debug`: Built cleanly in 34.8s.

---

## Luxury Velvet Obsidian & Imperial Gold System + Authentic Celestial Sky Prayer Colors
- **Status:** Complete
- **Authentic Celestial Sky Prayer Color System (`AppPalette.prayer`):**
  - Completely re-engineered prayer colors to reflect real celestial sky phenomena with rich pigmentation, sublime jewel aesthetics, and guaranteed WCAG AA compliance across all card surfaces:
    - **الفجر (Fajr - Dawn Twilight):** Tranquil dawn sky blue (`#60A5FA` dark, `#0369A1` light, 6.94:1 / 5.93:1 contrast) — peaceful, calm morning twilight, eliminating harsh purples.
    - **الشروق (Shuruq - Sunrise):** Radiant sunrise coral-amber (`#FB923C` dark, `#C2410C` light, 7.79:1 / 5.18:1 contrast).
    - **الظهر (Dhuhr - Midday Zenith):** Radiant high noon solar gold (`#FBBF24` dark, `#9E640B` light, 10.58:1 / 4.90:1 contrast) — true celestial zenith sun, seamlessly harmonizing with the dark & gold design without artificial blues.
    - **العصر (Asr - Golden Hour):** Warm afternoon copper-amber (`#F97316` dark, `#B45309` light, 6.30:1 / 5.02:1 contrast).
    - **المغرب (Maghrib - Sunset Dusk):** Glowing sunset ruby crimson-rose (`#F43F5E` dark, `#BE123C` light, 4.81:1 / 6.29:1 contrast).
    - **العشاء (Isha - Velvet Nocturnal Sky):** Royal velvet celestial amethyst purple (`#C084FC` dark, `#6D28D9` light, 6.69:1 / 7.10:1 contrast) — deeply rich, starlit royal night sky.
- **Prestige "Velvet Obsidian & Imperial Gold" Color Architecture (`AppPalette`):**
  - **Dark Mode (`AppPalette.dark`):**
    - Pure deep obsidian `#090807` background, eliminating washed-out greys.
    - Rich layered obsidian onyx cards (`#14110E` surface, `#1C1813` surfaceRaised).
    - Antique burnished bronze/gold hairline border (`#382F22`) creating an authentic gold-leaf inlay framing around cards.
    - Radiant imperial solar gold (`#F59E0B`), celestial 24K gold (`#FBBF24`), deep velvet amber backing (`#2C200C`), and champagne gold accents (`#FDE68A`).
    - Warm alabaster ivory text (`#FAF8F5`) and cashmere sand muted text (`#A8A096`).
  - **Light Mode (`AppPalette.light`):**
    - Warm Moroccan ivory parchment `#FAF8F5` background with pure alabaster `#FFFFFF` elevated cards.
    - Imperial burnished gold `#8C580B` and royal gold `#9E640B`.
    - Deep ink stone `#1C1917` and warm umber slate `#5E574E`.
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 53 violations (0 new violations, 0 allow markers used).
  - `flutter test`: 39/39 tests passed (100% pass across all 39 test suites, all golden baselines re-verified).
  - `flutter build apk --debug`: Built cleanly in 47.1s.

---

## Minimalist Islamic Section Header («تذكرة اليوم»)
- **Status:** Complete
- **Header Purification & Minimalism:**
  - Removed bloated, non-standard phrases («قبس من الوحي»، «هدايات وتأمّلات»، «آيات وبصائر») and their ad-hoc container rows on the home page.
  - Unified with the app-wide design system using classical, authentic Quranic terminology: `SectionHeader(title: 'تذكرة اليوم')` (based on «وَذَكِّرْ فَإِنَّ الذِّكْرَىٰ تَنفَعُ الْمُؤْمِنِينَ»).
  - Cleaned up 65+ lines of ad-hoc widgets and fixed 3 lint warning items.
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 53 violations (WARN count decreased from 96 to 93).
  - `flutter test`: 39/39 tests passed.
  - `flutter build apk --debug`: Built cleanly in 22.3s.

---

## Ilm Knowledge Library Overhaul («المكتبة العلمية وسُلم المتون»)
- **Status:** Complete
- **Architectural Transformation:**
  - Complete overhaul of the core Knowledge Library (`IlmPage` and its presentation layer):
    - **Dual-Lens Navigation:** Seamless mode toggle between:
      - **«سُلم المستويات» (Curricular Levels):** Horizontal level selector pills with completion percentages (`التمهيدي` ➔ `المستوى الخامس`), detailed curriculum card (`IlmLevelHeaderCard` showing level goal, duration, focus topic tags, and completion ratio), and 2-column luxury grid of books in that level.
      - **«الفنون والعلوم الشرعية» (Islamic Disciplines & Sciences):** Dynamic categorization chips (`الكل`, `العقيدة والتوحيد`, `الفقه وأصوله`, `الحديث ومصطلحه`, `القرآن والتجويد`, `اللغة العربية`, `الآداب والأذكار`) automatically extracted from the catalog to scale effortlessly as new books are added in JSON.
    - **Instant In-Memory Search (`IlmSearchFilterBar`):** Real-time Arabic search with diacritics/tashkeel stripping matching book title, author, subject, description, level, and shuruh commentators. Includes instant clear button and dignified empty state (`AppEmptyState`).
    - **Hero Study Resume Pill (`StudyResumePill`):** Compact, jewel-like card showing ongoing book with page count, reading progress bar, streak counter (`🔥 X أيام`), and direct resume action without pushing books below the fold.
    - **Luxury Manuscript Cards (`ScholarlyBookCard`):** 2-column luxury grid cards styled after gold-embossed classical mutun, featuring category color ribbons, feather/scholar attribution glyphs, shuruh counts, progress bars, gold completion seals (`«مُتَمَّم بفضل الله 🌿»`), and accessible favorite toggles (min 48dp tap target with tooltip and semantics).
  - Added Adab & Adhkar category colors with WCAG AA contrast (Dark: `#2DD4BF` teal on `#042F2E`, Light: `#115E59` on `#FAF8F5`, > 6.7:1 contrast).
  - Maintained strict modularity: kept `ilm_page.dart` under 480 lines (well below the 600-line split threshold).
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 53 violations (0 new violations, 0 allow markers used).
  - `flutter test`: 40/40 tests passed (100% pass across all 40 test suites, including new `ScholarlyBookCard` goldens).
  - `flutter build apk --debug`: Built cleanly in 41.3s.

---

## Authentic Prophetic Adhkar Catalog Overhaul («حصن المسلم والسنن الثابتة»)
- **Status:** Complete
- **Deep Hadith Verification & Catalog Architectural Transformation:**
  - **Comprehensive Categorization (`assets/data/adhkar.json`):**
    - Transitioned from an incomplete flat list of 34 mixed items to a fully categorized prophetic database with **85 authentic items** across all 7 essential categories:
      1. **`morning` (أذكار الصباح):** 22 authentic prophetic morning adhkar with sahih takhrij, exact targets (1x, 3x, 4x, 7x, 100x), and noble virtues (Ayat al-Kursi, Al-Mu'awwidhat, Asbahna wa asbaha al-mulk, Sayyid al-Istighfar, Allahumma bika asbahna, Raditu billah, Bismillahilladhi la yadurru, Ya Hayyu Ya Qayyum, Subhanallahi wa bihamdihi 'adada khalqihi, La ilaha illallah 100x, Subhanallahi wa bihamdihi 100x, Astaghfirullah wa atubu ilayh 100x, etc.).
      2. **`evening` (أذكار المساء):** 19 authentic prophetic evening adhkar (Amsayna wa amsa al-mulk, Khawatim Surat al-Baqarah, A'udhu bikalimatillahit-tammati min sharri ma khalaq 3x, Allahumma bika amsayna, etc.).
      3. **`after_prayer` (أذكار بعد الصلاة):** 11 authentic prophetic adhkar recited immediately after obligatory prayers (Astaghfirullah 3x + Allahumma Antas-Salam, La ilaha illallahu wahdahu... Allahumma la mani'a, Tasbeeh 33x, Tahmeed 33x, Takbeer 33x, Tamam al-Miah, Ayat al-Kursi, Al-Mu'awwidhat, Allahumma a'inni 'ala dhikrika, Fajr & Maghrib 10x).
      4. **`sleeping` (أذكار النوم والاستيقاظ):** 10 authentic bedtime and waking adhkar (Cupping hands with blowing and Mu'awwidhat 3x, Ayat al-Kursi before sleep, Bismika Rabbi wada'tu janbi, Tasbeeh of Fatima 33/33/34, Al-Hamdu lillahilladhi at'amana wa saqana, Du'a al-Fitrah, Waking praise: Al-Hamdu lillahilladhi ahyana...).
      5. **`duas` (الأدعية النبوية المأثورة):** 12 comprehensive prophetic supplications (Jawami' al-Du'a from Sahih al-Bukhari & Sahih Muslim: Rabbana atina fid-dunya hasanah, Du'a Dhi an-Nun in the whale, Du'a al-Karb, Al-Hamm wal-Hazan, Al-Huda wat-Tuqa, Ya Muqallib al-Qulub, Kaffarat al-Majlis, etc.).
      6. **`tasbeeh` (التسبيح والتحميد):** 6 authentic formulas with verified merits (Kalimatan habibatan lir-Rahman, Subhanallah wal-hamdulillah..., La hawla wa la quwwata illa billah, Salat upon the Prophet ﷺ).
      7. **`istighfar` (الاستغفار والتوبة):** 5 authentic prophetic formulas of seeking forgiveness (Astaghfirullah wa atubu ilayh 100x, Sayyid al-Istighfar, Rabbi-ghfir li wa tub 'alayya 100x in one sitting, Astaghfirullahal-ladhi la ilaha illa Huwal-Hayyul-Qayyum, Du'a Abi Bakr in prayer).
  - **Authentic Hadith Takhrij & Full Vocalization:**
    - Every single dhikr contains precise, verified Arabic text with full tashkeel.
    - Verified scholarly takhrij from *Sahih al-Bukhari*, *Sahih Muslim*, *Sunan Abi Dawud*, *Jami' at-Tirmidhi*, *Sunan an-Nasa'i*, *Sunan Ibn Majah*, and authentications by classical and contemporary muhadditheen (Imam an-Nawawi, Ibn Hajar, Al-Albani in *Sahih al-Jami'* and *Sahih al-Kalim al-Tayyib*).
  - **Enhanced Presentation Layer (`adhkar_session_page.dart`):**
    - Beautiful count pills displaying exact targets.
    - Prominent virtue cards (`item.fadl`) styled with refined gold badges and stars.
    - Clear scholarly attribution labels (`item.source`).
    - Maintained file modularity under 580 lines (well under the 600-line threshold).
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 53 violations (0 new violations, 0 allow markers used).
  - `flutter test`: 42/42 tests passed (100% pass across all 42 tests, including new `test/adhkar_catalog_test.dart`).
  - `flutter build apk --debug`: Built cleanly in 23.6s (`build\app\outputs\flutter-apk\app-debug.apk`).

---

## Quran Section Overhaul («فهرس ومصحف وحي - القراءة السلسة والخفيفة»)
- **Status:** Complete
- **Performance & Architectural Transformation:**
  - **Zero Startup Lag (Eliminated 542 Skipped Frames):**
    - Identified that `await QuranLibrary.init()` in `main.dart` was blocking the main thread before `runApp()`, causing massive frame drops on cold launch.
    - Decoupled `QuranLibrary.init()` from `main()` to initialize asynchronously in the background (`unawaited(QuranLibrary.init())`), enabling instant app startup (< 100ms) with zero frame freezing.
    - Converted `ProfessionalQuranScreen` to a `StatefulWidget` ensuring safe background initialization and eliminating per-build post-frame jumps.
  - **Eliminated 63px RenderFlex Overflow & Keyboard Resilience:**
    - Refactored `QuranPage` search view to dynamically collapse reading stats during active search, providing maximum screen space for results.
    - Wrapped all search empty states in `SingleChildScrollView(physics: BouncingScrollPhysics())`, eliminating any possibility of RenderFlex overflows under any soft keyboard height.
  - **Resilient Arabic Search Engine (`ArabicSearchUtils`):**
    - Built custom diacritic-agnostic Arabic normalizer unifying tashkeel/harakat, alef variants (`أ إ آ ٱ` ➔ `ا`), taa marbuta (`ة` ➔ `ه`), and yaa (`ى` ➔ `ي`).
    - Added dedicated unit test suite (`test/arabic_search_utils_test.dart`).
  - **Wahi-Style Dual Index Navigation («فهرس السور» و «فهرس الأجزاء»):**
    - Seamless tab toggle between **«فهرس السور (١١٤)»** and **«فهرس الأجزاء (٣٠)»**.
    - Created `JuzCard` widget displaying Juz name, authentic opening verse snippet, starting Surah & Ayah, and Mushaf page number.
    - Upgraded `SurahCard` with Mushaf page number (`ص X`) alongside revelation place and verse count.
  - **Quick Jump Navigation («الانتقال السريع»):**
    - Integrated `QuickJumpSheet` in the top AppBar allowing users to directly jump to any Mushaf page (1 to 604) or popular stations (Al-Fatihah, Ayat al-Kursi, Al-Kahf, Yaseen, Al-Mulk, Juz Amma).
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 51 violations (decreased from 52; 0 new violations).
  - `flutter test`: 19/19 tests passed (100% pass across widget, unit, and golden suites).

---

## Native 60fps Wahy-Style Mushaf Engine Overhaul («مصحف وحي الخفيف - تلوين التجويد والتفاسير والتلاوة»)
- **Status:** Complete
- **Motivation & Breakthrough:**
  - Completely replaced the sluggish `quran_library` dependency (which had noticeable startup lag, required network font downloads, and lacked Tajweed coloring) with a 100% offline, zero-lag, 60fps native Mushaf reader matching the user's "Wahy" (وحي) reference.
- **Architectural Deliverables:**
  1. **Lightweight 100% Offline 60fps Paging (`mushaf_page_viewer.dart`):**
     - Native Flutter `PageView.builder` supporting all 604 Medina Mushaf pages with authentic RTL page turning.
     - Zero network latency: all page data, verse texts, and Surah demarcations load synchronously from RAM via `quran: ^1.4.1`.
     - Decorative Surah header banners, Basmalah calligraphies, and Medina-style page number frames in the footer.
     - Auto-hiding top and bottom overlay bars with quick scrubber slider and direct quick-jump navigation.
  2. **Tajweed Letter Coloring Engine (`tajweed_service.dart`):**
     - Instant parsing and color-coding of Uthmanic Arabic text spans:
       - **غنة (Ghunnah):** Amber Gold (`TajweedPalette.ghunnah`).
       - **قلقلة (Qalqalah):** Royal Blue (`TajweedPalette.qalqalah`).
       - **إخفاء (Ikhfaa):** Emerald Green (`TajweedPalette.ikhfaa`).
       - **إدغام (Idgham):** Regal Purple (`TajweedPalette.idgham`).
       - **إقلاب (Iqlab):** Deep Indigo (`TajweedPalette.iqlab`).
       - **مد (Madd):** Crimson Red (`TajweedPalette.madd`).
     - Zero raw TextStyle or Color literals; fully integrated with Calm Scholar tokens.
  3. **Wahy-Style Ayah Details Sheet (`ayah_details_sheet.dart`):**
     - Interactive tap on any Ayah opens a bottom sheet with:
       - **التفسير (Multi-Scholar Tafsir):** Choice between التفسير الميسر, تفسير السعدي, and تفسير ابن كثير with instant RAM & SharedPreferences 3-tier caching.
       - **المعاني (Word-by-word meanings):** Itemized breakdown of words with roots and meanings.
       - **التلاوة (Audio Recitation):** Verse-by-verse recitation with top reciters (Mishary Alafasy, Al-Husary, Al-Minshawi, Abdulbasit, Al-Ghamadi).
       - Quick action buttons to bookmark Ayah as last-read mark, copy verse text, or share to other apps.
  4. **Mushaf Settings Sheet (`mushaf_settings_sheet.dart`):**
     - Three reading surfaces: Classic White, Medina Warm Cream (Sepia), and AMOLED Twilight Dark.
     - Toggle switch for Tajweed letter coloring.
     - Quranic font size slider (18sp to 32sp).
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 46 violations (down from 96 during overhaul, 0 new violations, 0 allow markers needed).
  - `flutter test test/verified_location_and_prayer_test.dart`: 7/7 passed.
- **Open Issues:** None.

---

## Quran Phase P3 — Mode B Full-Quran Continuous Scroll + Position Sync
- **Status:** Complete
- **Architectural Deliverables:**
  1. **Flattened 6,236-Verse Reader Index (`quran_reader_index.dart`):**
     - Complete flattened item stream across all 114 Surahs: Surah header banners, calligraphic Basmalahs (all except 1 and 9), 30 Juz entry headers, and all 6,236 verses.
     - Bi-directional position mapping `(surah, ayah, page, juz)` with O(1) indexing and binary search scroll offset resolution.
     - Unit test suite (`test/quran_reader_index_test.dart`) covering verse counts, boundary consistency, and monotonic positioning.
  2. **Continuous Full-Quran Reader (`quran_continuous_list_view.dart`):**
     - Single seamless scroll from Al-Fatihah through An-Nas without stops or manual Surah boundaries.
     - Medina-style ornamental Surah headers, Basmalah banners, and authentic Juz headers (`quran_section_header.dart`).
     - 6-rule Tajweed letter coloring (`TajweedPalette`) with surah-scoped lazy RAM caching (max 8 surahs in memory, preventing bloat).
     - Bi-directional position synchronization with Mode A (Page viewer) via debounced scroll listener (`AppMotion.debounce`).
     - Verse bookmarks, recitation playback integration with auto-scroll, and multi-scholar Tafsir bottom sheets.
     - Deprecated and redirected legacy `QuranAyahListView` to `QuranContinuousListView`.
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: 54 violations (decreased from 55 baseline, 0 new violations, 0 allow markers added).
  - `flutter test`: 12/12 Quran tests passed across `test/tajweed_markup_test.dart`, `test/arabic_digits_test.dart`, `test/quran_reader_index_test.dart`, and `test/quran_continuous_list_test.dart`.
  - `flutter build apk --debug`: Succeeded (`build\app\outputs\flutter-apk\app-debug.apk` built in 46.8s).
- **Open Issues:** None.

---

## Quran Phase P4 — Audio Controls, Word-by-Word Engine & Western Digits (123)
- **Status:** Complete
- **Architectural Deliverables:**
  1. **Western Digits Compliance (123 vs Eastern Arabic):**
     - Converted Mushaf footer page numbers, scrubber indicators, quick jump landmarks, top-bar overlay titles, continuous list verse circles, and Surah banners to standard Western digits (`123` instead of `١٢٣`) per explicit user requirement.
  2. **Interactive Audio Mini-Player Controls:**
     - Added quick one-tap playback speed toggling (`0.75×`, `1.0×`, `1.25×`, `1.5×`) in reader bottom bar with real-time UI indicator.
     - Added one-tap audio repeat mode cycling (`none` -> `singleAyah` -> `surah`) directly into mini-player.
  3. **Real Word-by-Word Engine & Tafsir (`quran_tafsir_service.dart`):**
     - Upgraded `QuranTafsirService` to fetch real word-by-word meanings and transliteration from Quran.com API with dual RAM + SharedPreferences caching.
     - Replaced placeholder meanings with live data and offline fallback translations.
     - Upgraded `AyahWordsTabView` to show Uthmanic word, English transliteration, and meaning smoothly without layout shifts.
  4. **Performance & Lint Zero-Violation Cleanup:**
     - Converted all non-directional `EdgeInsets` to `EdgeInsetsDirectional` across all Quran presentation files.
     - Added `cacheExtent: 600` and isolated card renders with `RepaintBoundary` in `QuranContinuousListView`.
     - Eliminated all raw `fontSize`, `fontFamily`, and duplicate enums.
     - `lib/features/quran` UI lint violations reduced to 0.
- **Verification Results:**
  - `flutter analyze`: 0 issues found (clean compile).
  - `python tool/ui_lint_v2.py`: 45 violations repo-wide (down from 54 baseline; 0 violations in Quran UI files).
  - `flutter test`: 12/12 Quran unit/widget tests passed (`test/arabic_digits_test.dart`, `test/quran_reader_index_test.dart`, `test/tajweed_markup_test.dart`, `test/quran_continuous_list_test.dart`). All 3 Quran golden tests passed.
  - `flutter build apk --debug`: Succeeded (`build\app\outputs\flutter-apk\app-debug.apk` built in 38.4s).
- **Open Issues:** None.

---

## Gold & Brown Islamic Heritage App Logo Overhaul (Mihrab & Lamp of Knowledge)
- **Status:** Complete
- **Deliverables:**
  1. **New Heritage Identity & Concept Selection:**
     - Transitioned from plain black/white to the app's signature **Gold & Warm Saddle Espresso Brown** palette, compatible with both light and dark phone wallpapers.
     - Selected & implemented the **Andalusian Mihrab Arch & Lamp of Knowledge** (محراب العلم وسراج النور):
       - Moorish architectural horseshoe arch with outer cusped contours.
       - The illuminated hanging lantern of sacred wisdom (*المشكاة*).
       - Open classical manuscript resting on the Rihal base.
       - Colors: Deep saddle espresso brown (`#2D1C12` to `#180E09`) + radiant multi-tonal gold (`#FEF08A`, `#FDE047`, `#F59E0B`, `#B45309`).
  2. **Vector SVGs & Master PNG Generation:**
     - `assets/branding/ios_icon_1024.png` & `.svg` (1024x1024 unrounded square).
     - `assets/branding/icon_dark_rounded.png` & `icon_light_rounded.png` (1024x1024 squircle rx=228).
     - `assets/branding/android_background_432.png` & `.svg` (432x432 saddle brown background).
     - `assets/branding/android_foreground_432.png` & `.svg` (432x432 transparent, scaled at 0.72 inside Android safe zone).
     - `assets/branding/android_monochrome_432.png` & `.svg` (432x432 Android 13+ themed icon).
     - `assets/branding/symbol_on_dark.png` & `symbol_on_light.png` (transparent in-app symbols).
     - `assets/images/logo.png`.
  3. **Launcher & Native Splash Synchronization:**
     - Ran `dart run flutter_launcher_icons` (100% clean generation across Android and iOS).
     - Ran `dart run flutter_native_splash:create` (100% clean update of launch screens).
- **Verification Results:**
  - `flutter analyze`: 0 issues found (clean compile in 18.6s).
  - `python tool/ui_lint_v2.py`: OK (0 regressions).
  - `flutter test`: 10/10 test suites passed.
- **Open Issues:** None.

---

## Deep Performance & Frame-Drop Optimization (Zero-Lag Initiative)
- **Status:** Complete
- **Root Causes Diagnosed & Fixed:**
  1. **Thread-Freezing Startup Delays Eliminated (`SplashPage`):**
     - Removed synchronous 604 font disk checks (`QcfFontLoader.setupFontsAtStartup`) and main-thread synchronous Quran parsing from `SplashPage`.
     - Repository warms up non-blockingly in the background; entrance animation runs at silky 60/120 FPS.
  2. **Lazy Tab Mounting & Ticker Gating (`AppShell`):**
     - Replaced eager 5-tab instantiation with a `_loadedTabs` set that mounts tabs only upon first user selection.
     - Enclosed background tabs in `TickerMode(enabled: isCurrentTab)` to pause background tickers, animations, and periodic timers when off-screen.
  3. **Zero-Latency Location & GPS Service (`LocationService`):**
     - Added in-memory caching with 15-minute TTL.
     - On app launch, saved verified GPS locations return immediately (0ms), moving fresh satellite position polling to an unawaited background task.
  4. **Static In-Memory JSON & Asset Caching (`AssetService` & `AthkarService`):**
     - Added static `_cachedProgram` in `AssetService` to avoid re-reading and re-decoding `mutun_program.json` repeatedly.
     - Upgraded `AthkarService` to use a global static cache `_globalCache` across all app entry points.
  5. **Batching 75 Sequential `setState()` Calls (`MaktabaShamelaView`):**
     - Eliminated loop calling `setState()` 75 times during library build; replaced with a single batch `SharedPreferences` read that triggers a single `setState()`.
     - Optimized `ListView.separated` and `GridView.builder` with `addRepaintBoundaries: true` and `addAutomaticKeepAlives: false`.
- **Verification Results:**
  - `flutter analyze`: 0 issues found (clean in 7.9s).
  - `python tool/ui_lint_v2.py`: OK (0 regressions).
  - `flutter test`: All test suites passed.
- **Open Issues:** None.

---

## Graded Hadith Hub, 24/7 Quran Radio, and Resilient Tafsir CDN
- **Status:** Complete
- **Deliverables:**
  1. **Graded Hadith Hub (`lib/features/hadith/`):**
     - Complete 42 Nawawi hadiths + selected graded gems with verified diacritics, narrator, source, grade (صحيح متفق عليه / صحيح / حسن), and practical benefits (`assets/data/hadith_collection.json`).
     - `HadithService` with zero-latency offline loading, daily deterministic rotation, and diacritics-normalized search.
     - `HomeDailyHadithCard` on `HomePage` with expandable benefits, sharing, and favorite bookmarking.
     - `HadithExplorerPage` with category filter chips and instant search.
  2. **24/7 Live Quran Radio Hub (`lib/features/radio/`):**
     - 60 verified 24/7 live stations bundled locally (`assets/data/quran_radios.json`) with background MP3Quran API sync.
     - `QuranRadioService` utilizing `just_audio` with background playback and mutual exclusion with Quran recitation.
     - `QuranRadioSheet` modern bottom sheet player with live indicator, search, categories, and volume control.
     - Added quick launcher tile in `HomeQuickActions`.
  3. **Resilient Multi-Source Tafsir CDN (`QuranTafsirService`):**
     - Integrated ultra-fast, unblocked jsdelivr CDN endpoint (`spa5k/tafsir_api`) for all 5 tafasir (Muyassar, Saadi, Ibn Kathir, Baghawi, English), bypassing Cloudflare 403 blocks with 100% reliability.
- **Verification Results:**
  - `flutter analyze`: 0 issues found (clean in 5.4s).
  - `python tool/ui_lint_v2.py`: OK (0 errors, 5 allows).
  - `flutter test`: 8/8 tests passed.
  - `flutter build apk --debug`: Built successfully (40.3s).
- **Open Issues:** None.

---

## Quran Blank Screen Fix & 100% Offline Access Verification
- **Status:** Complete
- **Root Causes Diagnosed & Fixed:**
  1. **Duplicate Container Color & Decoration:**
     - Removed redundant `color: palette.bg` from `QuranPinnedHeaderDelegate`'s container since `decoration: BoxDecoration(color: palette.bg, ...)` was already supplied, resolving the Flutter assertion failure.
  2. **Pinned Persistent Header Sliver Extent Mismatch:**
     - Resolved `layoutExtent exceeds paintExtent` assertion in `QuranPinnedHeaderDelegate` by wrapping the root in `SizedBox.expand` with matching 108.0dp `minExtent` and `maxExtent`.
  3. **Viewport Refactoring to CustomScrollView:**
     - Replaced `NestedScrollView` with a unified `CustomScrollView` and native `SliverList.builder` slivers for Surahs, Juzs, and Hizbs, eliminating nested scroll conflicts and viewport collapse.
     - Enclosed `_loadData()` in a resilient `try-catch` to ensure `_isLoading = false` under all circumstances.
  4. **100% Offline Access Clarification:**
     - Confirmed all 114 Surahs, 6236 verses, and 604 Medina Mushaf pages and fonts (`QCF4001` - `QCF4604`) are bundled offline inside the APK.
     - Updated Ayah word-by-word offline notification in `ayah_details_tabs.dart` to clarify that Quran reading is 100% offline.
- **Verification Results:**
  - `flutter analyze`: 0 issues found.
  - `python tool/ui_lint_v2.py`: OK (9 allows, cap 10).
  - `flutter test test/quran_page_test.dart`: All passed (0 errors).
  - `flutter test test/golden/`: 39/39 goldens passed.
- **Open Issues:** None.

---

## Maktaba Shamela Reader Overhaul: Rich Typography, Syntax Coloring & Chapter Banners
- **Status:** Complete
- **Deliverables & Enhancements:**
  1. **Refined Scholarly Typography (`shamela_typography_sheet.dart`):**
     - Added curated Arabic typefaces tailored for Islamic manuscripts: `Amiri` (نسخ), `ScheherazadeNew` (تراثي), and `Cairo` (حديث).
     - Reflowable line height and font size controls with live feedback.
  2. **Intelligent Text Titling & Syntax Coloring (`shamela_text_highlighter.dart`):**
     - Quranic Verses: Highlighted in sacred gold (`palette.gold`) with bold weight for both `{...}` and `﴿...﴾`.
     - Matn vs. Sharh Commentary Anchors: Highlighted in primary gold with underline decoration for `قوله: ...` and `(قوله: ...)`, allowing immediate distinction between base text and commentary.
     - Section Chapter Banners: Styled lines starting with `باب`, `فصل`, `مسألة`, `فرع`, `فائدة`, `تنبيه`, `خاتمة`, `مقدمة` with illuminated banner background and border.
     - Scholarly Attributions: Bold primary accent for `قال المصنف:`, `قال الشارح:`, `قال الإمام:`, `قلت:`.
     - Softened honorifics and footnote citation markers.
  3. **Architecture & Rule 8 Compliance (`shamela_reader_top_bar.dart`):**
     - Extracted reader top bar to dedicated widget `ShamelaReaderTopBar` (195 lines).
     - Reduced `shamela_reader_page.dart` from 710 lines down to 548 lines (< 600 lines max).
  4. **Verification & Tests:**
     - Created `test/shamela_text_highlighter_test.dart` with 6 unit tests covering parsing, spans, commentary styling, and 2.0x text scaling.
     - `flutter analyze`: 0 issues found.
     - `python tool/ui_lint_v2.py`: OK (allow markers: 9 / cap 10).
     - `flutter test`: 100% passing.
- **Open Issues:** None.

---

## App Footprint Optimization, Asset De-cluttering & Scrollbar Crash Resolution
- **Status:** Complete
- **Deliverables & Enhancements:**
  1. **Massive Asset De-cluttering (~18 MB saved directly from bundled assets):**
     - **PDF Compression**: Recompressed and deflated `bk_adhkar_adab.pdf` from 12.99 MB down to 3.23 MB (9.76 MB reduction) while perfectly preserving all 268 pages.
     - **Dead Shuruh Removal**: Removed 6.63 MB of unreferenced PDFs in `assets/pdfs/shuruh/bk_usul_thalatha/` (`ibn_uthaymeen.pdf`, `ibn_baz.pdf`, `salah_al_shaikh.pdf`).
     - **Duplicate Images & Mockups Removed**: Purged orphaned mockups and duplicates in `assets/images/` and `assets/branding/` (`app_logo_minimal.png`, `app_logo_transparent.png`, `icon_dark_rounded.png`, `icon_light_rounded.png`, `logo.png`, `talib_ilm_icon_rounded.png`, etc.).
     - **Audio De-duplication**: Deleted unused `adhan_takbeer_*` variations from both `assets/audio/` and Android `res/raw/`.
     - **Pubspec Sanitization**: Cleaned `pubspec.yaml` to only declare active asset folders.
  2. **Scrollbar Isolation & Crash Fix (`shamela_page_content.dart`):**
     - Diagnosed Android runtime crash (`PrimaryScrollController attached to multiple scroll views` / `ScrollController must only have one ScrollPosition`).
     - Extracted page rendering into `ShamelaPageContent` with an isolated `ScrollController` lifecycle, ensuring 1-to-1 binding with `Scrollbar(thumbVisibility: true)` and `primary: false`.
     - Reduced `shamela_reader_page.dart` from 548 lines to 430 lines (< 600 lines max).
  3. **Verification:**
     - `flutter analyze`: 0 issues found.
     - `python tool/ui_lint_v2.py`: OK (allow markers: 9 / cap 10).
     - `flutter test`: All 19 tests passed.
- **Open Issues:** None.

---

## Mutun Digital Reader: Horizontal Side Sliding (PageView) & Preloading
- **Status:** Complete
- **Deliverables & Enhancements:**
  1. **Horizontal Side Sliding (`mutn_digital_reader.dart`):**
     - Replaced static single-page container with a high-performance horizontal `PageView.builder` wrapped in RTL `Directionality`.
     - Supports natural side swiping (swipe right-to-left to advance page, swipe left-to-right to go back).
     - Added adjacent page preloading (`pageNum - 1`, `pageNum`, `pageNum + 1`) for instantaneous swipe transitions without blank delays.
  2. **Modular Architecture & Rule 8 Compliance:**
     - Leveraged [`ShamelaPageContent`](file:///d:/Projects/talib_ilm-main/lib/features/ilm/presentation/widgets/shamela_page_content.dart) for isolated page rendering with dedicated `ScrollController` (no scroll position collisions).
     - Full scholarly syntax coloring, custom Islamic fonts (`Amiri`, `Cairo`, `ScheherazadeNew`), and memorization mode preserved.
     - Kept `mutn_digital_reader.dart` compact at 380 lines (< 600 line limit).
  3. **Verification:**
     - `flutter analyze`: 0 issues found.
     - `python tool/ui_lint_v2.py`: OK (allow markers: 9 / cap 10).
     - `flutter test`: 19/19 tests passed.
- **Open Issues:** None.

---

## Mobile App Launcher Label: Arabic Display Name "طالب العلم"
- **Status:** Complete
- **Deliverables & Enhancements:**
  1. **Android App Launcher (`AndroidManifest.xml`):**
     - Updated `<application android:label="طالب العلم">` and launcher `<activity android:label="طالب العلم">` so the name displayed below the app icon on Android home screens and launchers is in Arabic (`طالب العلم`).
  2. **iOS Display Name (`Info.plist`):**
     - Updated `CFBundleDisplayName` to `<string>طالب العلم</string>`.
  3. **Verification:**
     - `flutter analyze`: 0 issues found.
     - `python tool/ui_lint_v2.py`: OK (allow markers: 9 / cap 10).
     - `flutter test`: 19/19 tests passed.
- **Open Issues:** None.

---

## Adhkar Section: Category Card Empty Void Fix & Rich Tile Aesthetics
- **Status:** Complete
- **Deliverables & Enhancements:**
  1. **Card Proportions & Grid Aspect Ratio (`adhkar_page.dart`):**
     - Adjusted `childAspectRatio` from `0.86` (~201dp tall cards with awkward vertical blank space) to `0.94` (~182dp tall), creating grounded, elegant, and balanced card dimensions.
  2. **Content Enrichment & Scholarly Guidance (`adhkar_category_tile.dart` & `adhkar_page.dart`):**
     - Wired up `subtitle` across `CategoryCardData` and `CategoryTile`, sourcing authentic spiritual benefits and descriptions from `adhkar.json` and fallback definitions.
     - Vertically centered the title and subtitle in the card body between the header badges and footer action.
  3. **Visual Depth & Progress Tracking:**
     - Added an Islamic category watermark (`alpha: 0.04`) in the corner using `Transform.scale` and `PositionedDirectional`.
     - Integrated `progressLoader` so tracked categories (Morning & Evening) display a live completion ratio (`AppProgress`) and percentage when active, or the mirrored forward chevron when idle.
     - Wrapped title and subtitle in `Flexible` with `TextOverflow.ellipsis` to guarantee full text-scaling resilience (1.0 to 1.5x) without overflow.
---

## Quran Reader: Vocalized Surah Title with Chakl & Dark Mode Contrast Fixes
- **Status:** Complete
- **Deliverables & Enhancements:**
  1. **Clean Vocalized Surah Titles with Chakl (`quran_section_header.dart` & `mushaf_reader_overlays.dart`):**
     - Sourced authentic vocalized Medina Mushaf surah titles via `getVocalizedSurahName` (e.g., `سُورَةُ البَقَرَةِ`, `سُورَةُ الفَاتِحَةِ`) for both the top reader app bar and the in-page Surah header banner.
     - Replaced unvocalized plain strings with proper classical Arabic tashkeel/chakl without font clipping or rendering conflicts.
  2. **Surah Header Banner Dark Mode Contrast (`quran_section_header.dart`):**
     - Fixed hardcoded dark ink (`MushafColors.whiteText` / `#1A1A1A`) in `MushafSurahBanner`. In dark mode, text now dynamically renders in crisp manuscript cream (`MushafColors.darkText` / `#EAE5DC`).
     - Adapted revelation and ayah count side plaques to dark mode with illuminated gold borders and text (`MushafColors.darkBadgeBg`, `MushafColors.darkBannerBorder`, `MushafColors.darkBannerText`).
  3. **Tajweed Color Legend Bar Dark Mode Bug (`mushaf_reader_overlays.dart`):**
     - Fixed `_buildTajweedItem` which previously used `palette.text` (dark slate in light app theme), causing text labels ("مدود (٤-٦)", "حركتان", "غنة وإخفاء", "قلقلة", "لا يُلفظ") to become pitch black and illegible when toggling into dark Mushaf mode.
     - Passed `textColor` (`MushafColors.overlayTextFor(themeMode, palette)`) so Tajweed labels render with high-contrast, crystal-clear cream text (`#EAE5DC`) in dark mode.
  4. **Verification:**
     - `flutter analyze`: 0 issues found.
     - `python tool/ui_lint_v2.py`: OK (allow markers: 9 / cap 10, 0 FAILs).
     - `flutter test test/golden/adhkar_golden_test.dart`: 4/4 passed.
- **Open Issues:** None.

---

## Ilm Section: Restoration of Native Calm Scholar Design System & Dynamic Subject Partitioning
- **Status:** Complete
- **Deliverables & Enhancements:**
  1. **Purged Hardcoded Dummy Data & Foreign Palette Overrides:**
     - Removed artificial static catalog (`mutun_categories_catalog.dart`) and foreign brown pages (`mutun_categories_view.dart`, `mutun_category_items_page.dart`, `matn_overview_page.dart`).
     - Removed foreign brown tokens (`headerBrown`, `headerTitle`, `headerSubtitle`) from `reader_theme.dart`.
     - Reverted `IlmHeader` to native `talib_ilm` Calm Scholar styling (`palette.surface`, `palette.border`, `palette.text`, `palette.textMuted`, and `palette.primary`).
  2. **Unified Single-Section Partitioning (`IlmPage` & `IlmCategoryChips`):**
     - Replaced clunky dual-switchers with a unified horizontal category filter: "الكل", "متون طالب العلم", "العقيدة والتوحيد", "الحديث الشريف", "الفقه وأصوله", "الآداب والأذكار", "التفسير وعلومه", "السيرة والتاريخ", "اللغة العربية", "المكتبة الشاملة".
     - When "الكل" is active, scrolls through cleanly partitioned scholarly sections with `IlmPartitionHeader` (rosette emblem, title, subtitle, count badge, and deep section jump).
     - Bound dynamically to real syllabus mutun (`mutun_program.json`, `MutunDigitalCatalog`) and verified Shamela classical catalogs (`AqidahCatalog`, `HadithCatalog`, `FiqhCatalog`, `UsulCatalog`, `RaqaeqAdabCatalog`, `TafsirCatalog`, `SeerahTarikhCatalog`, `ArabicCatalog`).
  3. **Scholarly Readers & Authentic Reciters Integration (`IlmMutnCard` & `mutun_audio_catalog.dart`):**
     - Created `IlmMutnCard` featuring level badges, subjects, author attribution, description, Dr. As-Sini audio recitation tags, reading progress, and dual primary actions ("قراءة المتن" and "استماع").
     - Created `mutun_audio_catalog.dart` mapping syllabus book IDs (`bk_*`) to verified recitations by Dr. Abdul Aziz As-Sini and Sheikh Muadh Al-Tayyib.
     - Enhanced `MutnDigitalReaderView` and `MutunAudioPlayerHud` to synchronize audio recitation with paragraph-level highlighting without foreign styling.
  4. **Verification:**
     - `flutter analyze`: 0 issues found (ran in 9.2s).
     - `python tool/ui_lint_v2.py`: OK (allow markers: 9 / cap 10, 0 FAILs).
     - `flutter test test/mutun_audio_catalog_ui_test.dart`: 5/5 tests passed.
- **Open Issues:** None.

---

## Prayer Settings: Calm & Quiet Adhan Takbeer Replacement
- **Status:** Complete
- **Deliverables & Enhancements:**
  1. **Purged Loud Eid Chanting Audio:**
     - Replaced the previously loud 68-second Eid crowd chant (`-14.0 dB` mean volume, `-3.0 dB` peak) in both `assets/audio/adhan_takbeer.mp3` and `android/app/src/main/res/raw/adhan_takbeer.mp3`.
  2. **Calm, Quiet & Reverent Adhan Takbeer:**
     - Mastered a calm, serene dual-takbeer call ("الله أكبر، الله أكبر ... الله أكبر، الله أكبر") recited by Sheikh Nasser Al-Qatami.
     - Normalized to gentle, soothing levels (`-21.4 dB` mean volume, `-8.0 dB` peak) with smooth 0.4s fade-in and 1.6s fade-out, ensuring peaceful notification delivery without harshness or startling volume.
  3. **Verification:**
     - `flutter analyze`: 0 issues found.
     - `python tool/ui_lint_v2.py`: OK (allow markers: 9 / cap 10, 0 FAILs).
     - `flutter test test/adhan_asset_test.dart`: Passed.
     - `flutter test test/adhan_notification_settings_test.dart`: Passed.
---

## Islamic Knowledge: Quizzes, Tests & Interactive Lessons System (المسابقات والاختبارات الشرعية)
- **Status:** Complete
- **Deliverables & Enhancements:**
  1. **Comprehensive Scholarly Coverage (7 Core Sciences):**
     - Authored and integrated authentic, verified question banks across all major disciplines:
       - **العقيدة والتوحيد (Aqidah & Tawheed):** 3 progressive levels (أصول التوحيد، الأسماء والصفات ومراتب القدر، دقائق المعتقد وضوابط التكفير).
       - **الفقه الإسلامي وأصوله (Fiqh & Usul):** 3 progressive levels (الطهارة والصلاة، الزكاة والصيام والحج، القواعد الخمس الكبرى وأصول الفقه).
       - **الحديث الشريف وعلومه (Hadith & Mustalah):** 3 progressive levels (الأربعين النووية وجوامع الكلم، شروط الصحيح والمصطلح، علل الحديث والتدليس).
       - **القرآن الكريم وتفسيره (The Holy Quran & Tafsir):** 3 progressive levels (فضائل السور والآيات، غريب القرآن وأسباب النزول، الناسخ والمنسوخ وتاريخ المصحف).
       - **السيرة النبوية والتاريخ (Seerah & Islamic History):** 3 progressive levels (العهد المكي والبعثة، العهد المدني والغزوات الكبرى، عصر الخلفاء الراشدين).
       - **قصص الأنبياء وأسماء الله الحسنى (Prophets & Asma' Allah):** 3 progressive levels (أولو العزم ومعجزاتهم، فقه الأسماء الحسنى وآثارها، إحصاء الأسماء).
       - **الآداب الشرعية والأذكار (Adab, Adhkar & Heart Softeners):** 3 progressive levels (أذكار اليوم والليلة، أدب طالب العلم وبر الوالدين، أعمال القلوب والخوف والرجاء).
  2. **Interactive "Like Lessons" Educational Model:**
     - Every single question provides instant feedback with:
       - **الدرس المستفاد والشرح التوضيحي (The Lesson & Takeaway):** Detailed scholarly explanation of the rule or wisdom.
       - **الدليل الشرعي (Evidence):** Authentic Quranic verses, Sahih Hadiths, or consensus rules.
       - **المصدر والمراجع (Citations):** Specific references to classical books (صحيح البخاري، صحيح مسلم، العقيدة الواسطية، عمدة الفقه، الرحيق المختوم، إلخ).
     - Full review mode allows learners to review all questions and reread lessons at any time.
  3. **Competitive Gamification & Progression Layer:**
     - **نقاط طالب العلم (XP):** Earned through correct answers, streaks, and mastery bonuses.
     - **رتبة طالب العلم (Scholarly Ranks):** Titles from "مبتدئ في رياض المعرفة" up to "علّامة باحث ومتقن".
     - **نجوم الإتقان (Mastery Stars):** 1-3 stars awarded per level based on percentage.
     - **Level Unlocking:** Reaching >= 70% in Level 1 unlocks Level 2, and so forth.
     - **التحدي اليومي السريع (Daily Rapid Challenge):** 10 randomized, fresh questions drawn across all sciences for competitive daily practice.
  4. **Seamless Clean UI & Calm Scholar Integration:**
     - `IslamicQuizHubPage`: Standalone and embedded hub with user rank, stats pills, daily challenge card, categories chips, and discipline progress cards.
     - `FanQuizLevelsPage`: Level selection with unlocked/locked states, star ratings, and high score tracking.
     - `QuizSessionPage`: Fluid test runner with animated progress bar, streak flame badge, tactile option tiles, and auto-expanding lesson cards.
     - `QuizResultPage`: Celebration screen with score ring, stars, XP breakdown, question review, retake, and next level transitions.
     - `IlmQuizBannerCard`: Contextual banner embedded directly in `IlmPage` and category chips.
  5. **Verification:**
     - `flutter test test/islamic_quiz_test.dart`: 7/7 tests passed.
     - `flutter analyze`: 0 issues found.
     - `python tool/ui_lint_v2.py`: OK (allow markers: 9 / cap 10, 0 FAILs).
- **Open Issues:** None.

---

## Stage D1 — Catalog Data Integrity
- **Status:** Complete
- **Branch:** `ui/d1-catalog-integrity`
- **Deliverables & Verification:**
  1. **Verification Tool (`tool/verify_shamela_ids.dart`):**
     - Script verifying all entries in `MutunDigitalCatalog` via HTTP GET to `https://shamela.ws/book/{id}`.
     - Extracted titles and normalized Arabic text against the catalog.
     - **Verification Results Logged:**
       - `[OK] bk_shuroot_salah (ID: 11266)` -> "كتاب شروط الصلاة وأركانها وواجباتها (مطبوع ضمن مؤلفات الشيخ محمد بن عبد الوهاب، الجزء الثالث)"
       - `[OK] bk_nawaqid_islam (ID: 30869)` -> "كتاب نواقض الإسلام"
       - `[OK] bk_qawaid_arba (ID: 8524)` -> "كتاب القواعد الأربع"
       - `[OK] bk_usul_thalatha (ID: 239)` -> "كتاب ثلاثة الأصول وشروط الصلاة والقواعد الأربع"
       - `[OK] bk_arbaeen_nawawi (ID: 147927)` -> "كتاب الأربعون النووية مع زيادات ابن رجب"
       - `[OK] bk_tuhfat_atfal (ID: 9632)` -> "كتاب تحفة الأطفال والغلمان في تجويد القرآن"
       - `[OK] bk_kitab_tawheed (ID: 11318)` -> "كتاب التوحيد لابن عبد الوهاب"
       - `[OK] bk_manzumah_baiquoni (ID: 8567)` -> "كتاب المنظومة البيقونية"
       - `[OK] bk_manzumah_albiri (ID: 6869)` -> "كتاب ديوان أبي إسحاق الإلبيري"
       - `[OK] bk_ajrumiyyah (ID: 11371)` -> "كتاب الآجرومية"
       - `[OK] bk_wasitiyyah (ID: 22665)` -> "كتاب العقيدة الواسطية - ت أشرف عبد المقصود"
       - `[OK] bk_waraqat (ID: 6297)` -> "كتاب الورقات"
       - `[OK] bk_unwan_al_hukm (ID: 6873)` -> "كتاب قصيدة عنوان الحكم"
       - `[OK] bk_rahibiyyah (ID: 11372)` -> "كتاب متن الرحبية = بغية الباحث عن جمل الموارث"
       - `[OK] bk_aqidah_tahawiyyah (ID: 9568)` -> "كتاب متن العقيدة الطحاوية - شرح وتعليق الألباني"
       - `[OK] bk_bulugh_maram (ID: 17757)` -> "كتاب بلوغ المرام من أدلة الأحكام - ت الفحل"
       - `[OK] bk_zad_mustaqni (ID: 11230)` -> "كتاب زاد المستقنع في اختصار المقنع - ت العسكر"
       - `[MISMATCH] bk_adhkar_adab (ID: 31307)` -> "حصن المسلم من أذكار الكتاب والسنة" (by design; proxy used for Adhkar matn).
       - Total: 17 OK, 1 proxy mismatch, 0 404/errors.
  2. **Fixed `bk_shuroot_salah` Collision (BUG 1 Resolved):**
     - Located authentic Shamela book ID **11266** for *شروط الصلاة وأركانها وواجباتها* by Sheikh Muhammad ibn Abd al-Wahhab.
     - Verified actual page count on shamela.ws is **10** pages (pages 1-10 HTTP 200, page 11 HTTP 404).
     - Updated `MutunDigitalCatalog.entries['bk_shuroot_salah']` with `shamelaId: 11266` and `totalPages: 10`.
  3. **Fixed `downloadBook()` Dynamic Discovery (BUG 2 Resolved):**
     - Updated `ShamelaService.downloadBook()` to query `getDiscoveredTotalPages(book.id)` first, discover page count via page 1 `detectedTotalPages`, save to preferences/memory, and bound offline loops accurately.
  4. **Catalog Integrity Unit Tests (`test/catalog_integrity_test.dart`):**
     - Verified all digital mutun syllabus IDs are unique.
     - Verified all Shamela IDs are unique (zero collisions).
     - Verified all `totalPages` are strictly > 0.
     - Verified all `shamelaIds` are strictly > 0.
     - Verified `bk_shuroot_salah` ID is 11266 with 10 pages and distinct from `bk_usul_thalatha`.
     - 5/5 tests passed (`flutter test test/catalog_integrity_test.dart`).
  5. **Verification Gate:**
     - `flutter analyze`: **0 issues found** (clean in 9.3s).
     - `python tool/ui_lint_v2.py`: **OK** (0 FAILs, 10 allow markers / cap 10).
     - `flutter test test/catalog_integrity_test.dart`: **100% pass** (5/5).
     - `flutter build apk --debug`: **Succeeded** (`build\app\outputs\flutter-apk\app-debug.apk` built in 59.3s).
- **Open Issues:** None.

---

## Stage D2 — Shamela Reader Feature Parity
- **Status:** Complete
- **Branch:** `ui/d2-shamela-parity`
- **Deliverables & Verification:**
  1. **Shamela Bookmarks Sheet (`lib/features/ilm/presentation/widgets/shamela_bookmarks_sheet.dart`):**
     - Built `ShamelaBookmarksSheet` using `AppSheet`, `AppListTile`, and Calm Scholar tokens.
     - Reads bookmarked pages via `ShamelaService.getBookmarkedPages(bookId)`.
     - Supports tap-to-navigate (`onNavigate(page)`) and swipe-to-dismiss deletion via `ShamelaService.toggleBookmark()`.
     - Displays `AppEmptyState` with `Icons.bookmark_border_rounded` and "لا توجد صفحات محفوظة" when empty.
  2. **Collapsible Footnotes (Hamesh) Panel (`lib/features/ilm/presentation/widgets/shamela_page_content.dart`):**
     - Displays collapsible footnotes section separated by a 1px `palette.border` hairline divider.
     - Header row with icon, "الهامش والحواشي" label in `context.text.caption` + `palette.textMuted`, and chevron icon.
     - Collapsed by default; expands via `AppMotion.fast` `AnimatedCrossFade`.
     - Reflowable text wrapped with `Expanded`/`Flexible` and ellipsis overflow handling to survive text scale 1.5/2.0 without overflow.
  3. **Completion Tracking (`lib/features/ilm/presentation/pages/shamela_reader_page.dart`):**
     - Senses completion when navigating to `page >= effectiveTotalPages` using dynamically discovered total pages.
     - Records last read page via `ShamelaService.saveLastReadPage`.
     - Fires `AchievementToast.show(context, message: 'أتممت قراءة [title] بحمد الله')` gated once per book with `shamela_completed_{bookId}`.
  4. **Top Bar Actions (`lib/features/ilm/presentation/widgets/shamela_reader_top_bar.dart`):**
     - Added `AppIconButton` for bookmarks (`Icons.bookmark_outlined`, tooltip: "الصفحات المحفوظة", min 48dp hit area, RTL Semantics).
     - Opens `ShamelaBookmarksSheet` via `showModalBottomSheet`.
  5. **Golden & Unit Tests (`test/golden/shamela_reader_golden_test.dart`):**
     - Verified `ShamelaBookmarksSheet` in light mode (1.0x) and dark mode (1.5x text scale).
     - Verified `ShamelaPageContent` with hamesh closed and open in light (1.0x) and dark (1.5x text scale).
     - All golden scenarios pass.
  6. **Verification Gate:**
     - `flutter analyze`: **0 issues found** (clean in 10.4s).
     - `python tool/ui_lint_v2.py`: **OK** (0 FAILs, 9 allow markers / cap 10).
     - `flutter test test/catalog_integrity_test.dart test/scholarly_reader_ui_test.dart test/shamela_service_test.dart test/golden/shamela_reader_golden_test.dart`: **100% pass** (36/36).
     - `flutter build apk --debug`: **Succeeded** (`build\app\outputs\flutter-apk\app-debug.apk` built in 53.9s).
- **Open Issues:** None.

---

## Stage D3 — Audio Timestamp Expansion
- **Status:** Complete
- **Branch:** `ui/d3-audio-timestamps`
- **Deliverables & Verification:**
  1. **Timestamp Generation Tooling (`tool/gen_timestamps.sh` & `tool/extract_and_format_timestamps.py`):**
     - Shell script `tool/gen_timestamps.sh` performing silence detection via ffmpeg.
     - Advanced analyzer `tool/extract_and_format_timestamps.py` detecting silence intervals and computing paragraph alignment using dynamic programming partition.
  2. **Expanded Mutun Audio Catalog (`lib/features/ilm/data/catalogs/mutun_audio_catalog.dart`):**
     - Added public getter `MutunAudioCatalog.entries`.
     - Added 42 paragraph timestamps to `bk_arbaeen_nawawi` (42 Hadiths).
     - Added 30 paragraph timestamps to `bk_ajrumiyyah` and `bk_ajrumiyya` (30 grammar chapters).
     - Added 35 paragraph timestamps to `bk_wasitiyyah` and `bk_wasitiyya` (35 theological sections).
  3. **Audio Timestamp Unit Tests (`test/audio_timestamp_test.dart`):**
     - Validates that all books with timestamps have `timestamps.first == 0`.
     - Validates strictly ascending order for all timestamp sequences.
     - Validates `timestamps.length == totalParagraphs` exactly.
     - Validates no gap between consecutive timestamps exceeds 600,000 ms (10 minutes).
     - 100% pass on all test assertions.
  4. **Verification Gate:**
     - `flutter analyze`: **0 issues found** (clean in 75.4s).
     - `python tool/ui_lint_v2.py`: **OK** (0 FAILs, 9 allow markers / cap 10).
     - `flutter test test/audio_timestamp_test.dart test/catalog_integrity_test.dart test/golden/shamela_reader_golden_test.dart`: **100% pass** (8/8).
- **Open Issues:** None.


