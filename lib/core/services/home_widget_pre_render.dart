import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/constants/app_strings.dart';
import '../../app/theme/app_theme.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import '../../features/prayer/presentation/widgets/widget_large.dart';
import '../../features/prayer/presentation/widgets/widget_ribbon.dart';
import 'adhan_settings_service.dart';

/// Pre-renders daily prayer state variations for native Android widgets to enable
/// lag-free AlarmManager exact scheduled switches without background Flutter engines.
class HomeWidgetPreRender {
  const HomeWidgetPreRender._();

  static String? _lastDailyRibbonRenderKey;
  static String? _lastDailyLargeRenderKey;

  /// Invalidates cached daily pre-rendered prayer state snapshots.
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
    double? width,
    double? height,
  }) async {
    final effectiveW = width ?? kRibbonW;
    final effectiveH = height ?? kRibbonH;
    final dailyKey =
        '${day.city}_${day.date.year}-${day.date.month}-${day.date.day}_${useDark}_${effectiveW.toInt()}x${effectiveH.toInt()}';
    if (!force && dailyKey == _lastDailyRibbonRenderKey) return;
    _lastDailyRibbonRenderKey = dailyKey;

    final resolvedSize = Size(effectiveW, effectiveH);
    final all = day.prayers;
    final iqamaOverrides =
        (await AdhanSettingsService().getSettings()).iqamaMinutesAfterAdhan;

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
        iqamaOverrides: iqamaOverrides,
      );

      try {
        await HomeWidget.renderFlutterWidget(
          MediaQuery(
            data: MediaQueryData(
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
                  width: effectiveW,
                  height: effectiveH,
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
    double? width,
    double? height,
  }) async {
    final effectiveW = width ?? kLargeW;
    final effectiveH = height ?? kLargeH;
    final dailyKey =
        '${day.city}_${day.date.year}-${day.date.month}-${day.date.day}_${useDark}_${effectiveW.toInt()}x${effectiveH.toInt()}';
    if (!force && dailyKey == _lastDailyLargeRenderKey) return;
    _lastDailyLargeRenderKey = dailyKey;

    final resolvedSize = Size(effectiveW, effectiveH);
    final all = day.prayers;
    final iqamaOverrides =
        (await AdhanSettingsService().getSettings()).iqamaMinutesAfterAdhan;

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
        iqamaOverrides: iqamaOverrides,
      );

      try {
        await HomeWidget.renderFlutterWidget(
          MediaQuery(
            data: MediaQueryData(
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
                  width: effectiveW,
                  height: effectiveH,
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
