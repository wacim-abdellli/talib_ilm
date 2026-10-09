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
