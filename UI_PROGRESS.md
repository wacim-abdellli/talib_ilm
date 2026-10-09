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


