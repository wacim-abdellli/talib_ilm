import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import '../../features/prayer/presentation/widgets/widget_large.dart';
import '../../features/prayer/presentation/widgets/widget_ribbon.dart';
import '../../features/prayer/presentation/widgets/widget_standard.dart';
import 'home_widget_snapshot.dart';

/// Android widget dimension resolution and native `AppWidgetProvider` notifications.
///
/// Android widgets (`RibbonWidgetProvider` 4x1 Medium and `LargeWidgetProvider`
/// 4x2 Max/Large) render 100% natively via `RemoteViews` XML layouts and
/// `WidgetChronometerHelper.kt`, eliminating offscreen bitmap scaling and
/// aspect-ratio distortion across all launcher grid sizes.
class HomeWidgetAndroidRenderer {
  const HomeWidgetAndroidRenderer._();

  static String? _lastRibbonRenderKey;
  static String? _lastStandardRenderKey;
  static String? _lastLargeRenderKey;
  static String? _lastCompactRenderKey;

  static void invalidateCache() {
    _lastRibbonRenderKey = null;
    _lastStandardRenderKey = null;
    _lastLargeRenderKey = null;
    _lastCompactRenderKey = null;
  }

  static String formatHijri(DateTime date) {
    try {
      HijriCalendar.setLocal('ar');
      final h = HijriCalendar.fromDate(date);
      return '${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
    } catch (_) {
      return '';
    }
  }

  static Future<ThemeData> resolveAutoTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appTheme = prefs.getString('theme_mode');
      if (appTheme == 'light') return AppTheme.light();
      if (appTheme == 'dark') return AppTheme.dark();
    } catch (_) {}
    return AppTheme.resolveTheme(ThemeMode.system);
  }

  /// Resolves the actual launcher widget dimensions dynamically reported by Android,
  /// enforcing Medium (280dp) as the minimum width.
  static Future<Size> resolveDimensions({
    required String prefix,
    required double fallbackW,
    required double fallbackH,
    required double minW,
    required double maxW,
    required double minH,
    required double maxH,
  }) async {
    final effectiveMinW = minW < 280.0 ? 280.0 : minW;
    try {
      int? w;
      int? h;
      try {
        w = await HomeWidget.getWidgetData<int>('${prefix}_widget_width');
        h = await HomeWidget.getWidgetData<int>('${prefix}_widget_height');
      } catch (_) {}

      if (w == null || h == null) {
        final prefs = await SharedPreferences.getInstance();
        w ??= prefs.getInt('${prefix}_widget_width') ??
            prefs.getInt('widget_${prefix}_width') ??
            prefs.getInt('widget_width');
        h ??= prefs.getInt('${prefix}_widget_height') ??
            prefs.getInt('widget_${prefix}_height') ??
            prefs.getInt('widget_height');
      }

      if (w != null && h != null && w > 0 && h > 0) {
        final clampedW = w.toDouble().clamp(effectiveMinW, maxW);
        final clampedH = h.toDouble().clamp(minH, maxH);
        return Size(clampedW, clampedH);
      }
    } catch (_) {}
    return Size(fallbackW.clamp(effectiveMinW, maxW), fallbackH);
  }

  /// Updates the Medium Ribbon (4x1 / 5x1) Android Home Screen Widget.
  static Future<void> updateRibbon({
    required PrayerTimesDay day,
    required DateTime now,
    required EvaluatedPrayerWidgetState eval,
    required bool useDark,
    bool force = false,
  }) async {
    try {
      final hijri = formatHijri(now);

      final resolvedSize = await resolveDimensions(
        prefix: 'ribbon',
        fallbackW: kRibbonW,
        fallbackH: kRibbonH,
        minW: 280.0,
        maxW: 600.0,
        minH: 80.0,
        maxH: 250.0,
      );

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'ribbon_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_${useDark}_${resolvedSize.width.toInt()}x${resolvedSize.height.toInt()}';
      if (!force && renderKey == _lastRibbonRenderKey) {
        return;
      }
      _lastRibbonRenderKey = renderKey;

      await HomeWidgetSnapshot.preRenderDailyRibbonSnapshots(
        day: day,
        useDark: useDark,
        hijriDate: hijri,
        force: force,
        width: resolvedSize.width,
        height: resolvedSize.height,
      );

      await HomeWidget.updateWidget(
        name: 'RibbonWidgetProvider',
        androidName: 'RibbonWidgetProvider',
        qualifiedAndroidName: 'com.talibilm.app.RibbonWidgetProvider',
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  /// Updates the Standard (4x2) Android Home Screen Widget.
  static Future<void> updateStandard({
    required PrayerTimesDay day,
    required DateTime now,
    required EvaluatedPrayerWidgetState eval,
    required bool useDark,
    bool force = false,
  }) async {
    try {
      final resolvedSize = await resolveDimensions(
        prefix: 'standard',
        fallbackW: kStandardW,
        fallbackH: kStandardH,
        minW: 280.0,
        maxW: 600.0,
        minH: 135.0,
        maxH: 350.0,
      );

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'standard_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_${useDark}_${resolvedSize.width.toInt()}x${resolvedSize.height.toInt()}';
      if (!force && renderKey == _lastStandardRenderKey) {
        return;
      }
      _lastStandardRenderKey = renderKey;

      await HomeWidget.updateWidget(
        name: 'StandardWidgetProvider',
        androidName: 'StandardWidgetProvider',
        qualifiedAndroidName: 'com.talibilm.app.StandardWidgetProvider',
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  /// Updates the Max/Large (4x2 / 5x2) Android Home Screen Widget.
  static Future<void> updateLarge({
    required PrayerTimesDay day,
    required DateTime now,
    required EvaluatedPrayerWidgetState eval,
    required bool useDark,
    bool force = false,
  }) async {
    try {
      final hijri = formatHijri(now);

      final resolvedSize = await resolveDimensions(
        prefix: 'large',
        fallbackW: kLargeW,
        fallbackH: kLargeH,
        minW: 280.0,
        maxW: 600.0,
        minH: 135.0,
        maxH: 350.0,
      );

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'large_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_${useDark}_${resolvedSize.width.toInt()}x${resolvedSize.height.toInt()}';
      if (!force && renderKey == _lastLargeRenderKey) {
        return;
      }
      _lastLargeRenderKey = renderKey;

      await HomeWidgetSnapshot.preRenderDailyLargeSnapshots(
        day: day,
        useDark: useDark,
        hijriDate: hijri,
        force: force,
        width: resolvedSize.width,
        height: resolvedSize.height,
      );

      await HomeWidget.updateWidget(
        name: 'LargeWidgetProvider',
        androidName: 'LargeWidgetProvider',
        qualifiedAndroidName: 'com.talibilm.app.LargeWidgetProvider',
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  /// Retained for legacy call sites; redirects to Medium minimum dimensions.
  static Future<void> updateCompact({
    required PrayerTimesDay day,
    required DateTime now,
    required EvaluatedPrayerWidgetState eval,
    required bool useDark,
    bool force = false,
  }) async {
    try {
      final resolvedSize = await resolveDimensions(
        prefix: 'compact',
        fallbackW: kRibbonW,
        fallbackH: kRibbonH,
        minW: 280.0,
        maxW: 600.0,
        minH: 80.0,
        maxH: 250.0,
      );

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'compact_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_${useDark}_${resolvedSize.width.toInt()}x${resolvedSize.height.toInt()}';
      if (!force && renderKey == _lastCompactRenderKey) {
        return;
      }
      _lastCompactRenderKey = renderKey;
    } catch (_) {}
  }
}
