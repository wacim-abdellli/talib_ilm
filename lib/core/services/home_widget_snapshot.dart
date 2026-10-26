import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_theme.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';

/// Supported visual themes for the Android Home Screen AppWidget.
enum WidgetThemeMode {
  dark,
  light,
  auto,
}

/// Manages native Android widget preference serialization, snapshot versioning,
/// and theme resolution to guarantee data coherence across all widget providers.
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot._();

  static const String themeModeKey = 'prayer_widget_theme_mode';
  static int _snapshotVersion = 0;
  static int get snapshotVersion => _snapshotVersion;

  /// Resolves whether the widget should render in dark mode.
  static Future<bool> resolveWidgetIsDark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(themeModeKey);
      if (modeStr == 'light') return false;
      if (modeStr == 'dark') return true;

      final appTheme = prefs.getString('theme_mode');
      if (appTheme == 'light') return false;
      if (appTheme == 'dark') return true;
      if (appTheme == 'system') {
        return AppTheme.isSystemDark();
      }
    } catch (_) {}
    return true;
  }

  /// Saves the target prayer epoch timestamp and all visual attributes for the
  /// native Android Chronometer and providers. Writes an atomic snapshot version
  /// to eliminate mixed/stale preference reads across widget updates.
  static Future<void> savePrayerSnapshot(
    EvaluatedPrayerWidgetState eval, {
    Map<String, DateTime>? allPrayers,
    bool? preResolvedDark,
  }) async {
    try {
      final int epochMs;
      final String countdownPrefix;
      switch (eval.phase) {
        case PrayerWidgetPhase.beforeAdhan:
        case PrayerWidgetPhase.postSalah:
          epochMs = eval.targetPrayerTime.millisecondsSinceEpoch;
          countdownPrefix = 'بعد ';
          break;
        case PrayerWidgetPhase.betweenAdhanAndIqama:
          final iqamaMinutes = PrayerWidgetStateEvaluator.getIqamaMinutes(
            eval.activePrayerName,
          );
          final iqamaTime = eval.targetPrayerTime.add(Duration(minutes: iqamaMinutes));
          epochMs = iqamaTime.millisecondsSinceEpoch;
          countdownPrefix = 'الإقامة بعد ';
          break;
        case PrayerWidgetPhase.atAdhan:
        case PrayerWidgetPhase.inSalah:
          epochMs = 0; // Chronometer hidden during active adhan or congregational prayer
          countdownPrefix = '';
          break;
      }

      final isPrayerActive = eval.phase == PrayerWidgetPhase.atAdhan ||
          eval.phase == PrayerWidgetPhase.inSalah;

      final useDark = preResolvedDark ?? await resolveWidgetIsDark();
      final palette = useDark ? AppPalette.dark : AppPalette.light;
      final prayerColor = palette.prayer(eval.activePrayerName);
      final prayerColorInt = prayerColor.toARGB32();
      final textColorInt = palette.text.toARGB32();
      final version = ++_snapshotVersion;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('next_prayer_epoch_ms', epochMs);
      await prefs.setString('next_prayer_name', eval.activePrayerName);
      await prefs.setString('prayer_display_title', eval.displayTitle);
      await prefs.setInt('prayer_color_value', prayerColorInt);
      await prefs.setInt('widget_text_color', textColorInt);
      await prefs.setBool('widget_is_dark', useDark);
      await prefs.setString('prayer_widget_theme_mode', useDark ? 'dark' : 'light');
      await prefs.setString('countdown_prefix', countdownPrefix);
      await prefs.setString('prayer_status_label', eval.statusLabel);
      await prefs.setBool('is_prayer_active', isPrayerActive);
      await prefs.setInt('widget_snapshot_version', version);
      await prefs.remove('widget_ribbon_width');
      await prefs.remove('widget_ribbon_height');
      await prefs.remove('widget_large_width');
      await prefs.remove('widget_large_height');

      try {
        await HomeWidget.saveWidgetData<int>('next_prayer_epoch_ms', epochMs);
        await HomeWidget.saveWidgetData<String>('next_prayer_name', eval.activePrayerName);
        await HomeWidget.saveWidgetData<String>('prayer_display_title', eval.displayTitle);
        await HomeWidget.saveWidgetData<int>('prayer_color_value', prayerColorInt);
        await HomeWidget.saveWidgetData<int>('widget_text_color', textColorInt);
        await HomeWidget.saveWidgetData<bool>('widget_is_dark', useDark);
        await HomeWidget.saveWidgetData<String>('prayer_widget_theme_mode', useDark ? 'dark' : 'light');
        await HomeWidget.saveWidgetData<String>('countdown_prefix', countdownPrefix);
        await HomeWidget.saveWidgetData<String>('prayer_status_label', eval.statusLabel);
        await HomeWidget.saveWidgetData<bool>('is_prayer_active', isPrayerActive);
        await HomeWidget.saveWidgetData<int>('widget_snapshot_version', version);
      } catch (_) {}

      // Persist full 24-hour prayer schedule for autonomous native Android widget evaluation
      if (allPrayers != null && allPrayers.isNotEmpty) {
        final fajrTime = allPrayers[AppStrings.prayerFajr];
        final dhuhrTime = allPrayers[AppStrings.prayerDhuhr];
        final asrTime = allPrayers[AppStrings.prayerAsr];
        final maghribTime = allPrayers[AppStrings.prayerMaghrib];
        final ishaTime = allPrayers[AppStrings.prayerIsha];
        final tomorrowFajrTime = fajrTime != null
            ? DateTime(fajrTime.year, fajrTime.month, fajrTime.day + 1, fajrTime.hour, fajrTime.minute, fajrTime.second)
            : null;

        final refTime = dhuhrTime ?? DateTime.now();
        final isFriday = refTime.weekday == DateTime.friday;

        final iqamaFajr = PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerFajr);
        final iqamaDhuhr = PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerDhuhr, isJumua: isFriday);
        final iqamaAsr = PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerAsr);
        final iqamaMaghrib = PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerMaghrib);
        final iqamaIsha = PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerIsha);

        final fajrColor = palette.prayer(AppStrings.prayerFajr).toARGB32();
        final dhuhrColor = (isFriday ? palette.success : palette.prayer(AppStrings.prayerDhuhr)).toARGB32();
        final asrColor = palette.prayer(AppStrings.prayerAsr).toARGB32();
        final maghribColor = palette.prayer(AppStrings.prayerMaghrib).toARGB32();
        final ishaColor = palette.prayer(AppStrings.prayerIsha).toARGB32();

        if (fajrTime != null) await prefs.setInt('prayer_fajr_epoch_ms', fajrTime.millisecondsSinceEpoch);
        if (dhuhrTime != null) await prefs.setInt('prayer_dhuhr_epoch_ms', dhuhrTime.millisecondsSinceEpoch);
        if (asrTime != null) await prefs.setInt('prayer_asr_epoch_ms', asrTime.millisecondsSinceEpoch);
        if (maghribTime != null) await prefs.setInt('prayer_maghrib_epoch_ms', maghribTime.millisecondsSinceEpoch);
        if (ishaTime != null) await prefs.setInt('prayer_isha_epoch_ms', ishaTime.millisecondsSinceEpoch);
        if (tomorrowFajrTime != null) await prefs.setInt('prayer_tomorrow_fajr_epoch_ms', tomorrowFajrTime.millisecondsSinceEpoch);
        await prefs.setBool('is_friday', isFriday);
        await prefs.setInt('iqama_fajr_min', iqamaFajr);
        await prefs.setInt('iqama_dhuhr_min', iqamaDhuhr);
        await prefs.setInt('iqama_asr_min', iqamaAsr);
        await prefs.setInt('iqama_maghrib_min', iqamaMaghrib);
        await prefs.setInt('iqama_isha_min', iqamaIsha);

        await prefs.setInt('prayer_color_fajr', fajrColor);
        await prefs.setInt('prayer_color_dhuhr', dhuhrColor);
        await prefs.setInt('prayer_color_asr', asrColor);
        await prefs.setInt('prayer_color_maghrib', maghribColor);
        await prefs.setInt('prayer_color_isha', ishaColor);

        try {
          if (fajrTime != null) await HomeWidget.saveWidgetData<int>('prayer_fajr_epoch_ms', fajrTime.millisecondsSinceEpoch);
          if (dhuhrTime != null) await HomeWidget.saveWidgetData<int>('prayer_dhuhr_epoch_ms', dhuhrTime.millisecondsSinceEpoch);
          if (asrTime != null) await HomeWidget.saveWidgetData<int>('prayer_asr_epoch_ms', asrTime.millisecondsSinceEpoch);
          if (maghribTime != null) await HomeWidget.saveWidgetData<int>('prayer_maghrib_epoch_ms', maghribTime.millisecondsSinceEpoch);
          if (ishaTime != null) await HomeWidget.saveWidgetData<int>('prayer_isha_epoch_ms', ishaTime.millisecondsSinceEpoch);
          if (tomorrowFajrTime != null) await HomeWidget.saveWidgetData<int>('prayer_tomorrow_fajr_epoch_ms', tomorrowFajrTime.millisecondsSinceEpoch);
          await HomeWidget.saveWidgetData<bool>('is_friday', isFriday);
          await HomeWidget.saveWidgetData<int>('iqama_fajr_min', iqamaFajr);
          await HomeWidget.saveWidgetData<int>('iqama_dhuhr_min', iqamaDhuhr);
          await HomeWidget.saveWidgetData<int>('iqama_asr_min', iqamaAsr);
          await HomeWidget.saveWidgetData<int>('iqama_maghrib_min', iqamaMaghrib);
          await HomeWidget.saveWidgetData<int>('iqama_isha_min', iqamaIsha);

          await HomeWidget.saveWidgetData<int>('prayer_color_fajr', fajrColor);
          await HomeWidget.saveWidgetData<int>('prayer_color_dhuhr', dhuhrColor);
          await HomeWidget.saveWidgetData<int>('prayer_color_asr', asrColor);
          await HomeWidget.saveWidgetData<int>('prayer_color_maghrib', maghribColor);
          await HomeWidget.saveWidgetData<int>('prayer_color_isha', ishaColor);
        } catch (_) {}
      }
    } catch (_) {}
  }
}
