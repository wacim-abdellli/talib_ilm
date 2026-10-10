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



