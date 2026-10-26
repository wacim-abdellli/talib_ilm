import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_theme.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import '../../features/prayer/presentation/widgets/widget_large.dart';
import '../../features/prayer/presentation/widgets/widget_ribbon.dart';

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

  static String? _lastDailyRibbonRenderKey;
  static String? _lastDailyLargeRenderKey;

  /// Invalidates cached daily pre-rendered prayer state snapshots
  static void invalidateDailyCache() {
    _lastDailyRibbonRenderKey = null;
    _lastDailyLargeRenderKey = null;
  }

  /// Pre-renders the 5 prayer lifecycle states (Fajr, Dhuhr, Asr, Maghrib, Isha)
  /// into distinct on-disk images for the Ribbon (4x1) widget. This allows native
  /// Android AlarmManager exact wakeups to switch the active prayer pill instantly
  /// without requiring a background Flutter engine or user app launch.
  static Future<void> preRenderDailyRibbonSnapshots({
    required PrayerTimesDay day,
    required bool useDark,
    required String hijriDate,
    bool force = false,
  }) async {
    final dailyKey =
        '${day.city}_${day.date.year}-${day.date.month}-${day.date.day}_$useDark';
    if (!force && dailyKey == _lastDailyRibbonRenderKey) return;
    _lastDailyRibbonRenderKey = dailyKey;

    const resolvedSize = Size(kRibbonW, kRibbonH);
    final all = day.prayers;

    const slugs = {
      AppStrings.prayerFajr: 'fajr',
      AppStrings.prayerDhuhr: 'dhuhr',
      AppStrings.prayerAsr: 'asr',
      AppStrings.prayerMaghrib: 'maghrib',
      AppStrings.prayerIsha: 'isha',
    };

    for (final entry in slugs.entries) {
      final pName = entry.key;
      final slug = entry.value;
      final pTime = all[pName];
      if (pTime == null) continue;

      final pEval = PrayerWidgetStateEvaluator.evaluate(
        now: pTime.add(const Duration(minutes: 2)),
        all: all,
      );

      try {
        await HomeWidget.renderFlutterWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: resolvedSize,
              devicePixelRatio: 2.5,
              textScaler: TextScaler.noScaling,
            ),
            child: Theme(
              data: useDark ? AppTheme.dark() : AppTheme.light(),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: WidgetRibbon(
                  eval: pEval,
                  all: all,
                  hijriDate: hijriDate,
                  isDark: useDark,
                  forNativeWidget: true,
                ),
              ),
            ),
          ),
          key: 'prayer_ribbon_widget_$slug',
          logicalSize: resolvedSize,
          pixelRatio: 2.5,
        );
      } catch (_) {}
    }
  }

  /// Pre-renders the 5 prayer lifecycle states for the Large (4x3/4x2) widget.
  static Future<void> preRenderDailyLargeSnapshots({
    required PrayerTimesDay day,
    required bool useDark,
    required String hijriDate,
    bool force = false,
  }) async {
    final dailyKey =
        '${day.city}_${day.date.year}-${day.date.month}-${day.date.day}_$useDark';
    if (!force && dailyKey == _lastDailyLargeRenderKey) return;
    _lastDailyLargeRenderKey = dailyKey;

    const resolvedSize = Size(kLargeW, kLargeH);
    final all = day.prayers;

    const slugs = {
      AppStrings.prayerFajr: 'fajr',
      AppStrings.prayerDhuhr: 'dhuhr',
      AppStrings.prayerAsr: 'asr',
      AppStrings.prayerMaghrib: 'maghrib',
      AppStrings.prayerIsha: 'isha',
    };

    for (final entry in slugs.entries) {
      final pName = entry.key;
      final slug = entry.value;
      final pTime = all[pName];
      if (pTime == null) continue;

      final pEval = PrayerWidgetStateEvaluator.evaluate(
        now: pTime.add(const Duration(minutes: 2)),
        all: all,
      );

      try {
        await HomeWidget.renderFlutterWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: resolvedSize,
              devicePixelRatio: 2.0,
              textScaler: TextScaler.noScaling,
            ),
            child: Theme(
              data: useDark ? AppTheme.dark() : AppTheme.light(),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: WidgetLarge(
                  eval: pEval,
                  all: all,
                  hijriDate: hijriDate,
                  cityName: day.city,
                  isDark: useDark,
                  forNativeWidget: true,
                ),
              ),
            ),
          ),
          key: 'prayer_large_widget_$slug',
          logicalSize: resolvedSize,
          pixelRatio: 2.0,
        );
      } catch (_) {}
    }
  }
}
