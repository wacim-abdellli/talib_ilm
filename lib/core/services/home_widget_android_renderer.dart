import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import '../../features/prayer/presentation/widgets/widget_compact.dart';
import '../../features/prayer/presentation/widgets/widget_large.dart';
import '../../features/prayer/presentation/widgets/widget_ribbon.dart';
import '../../features/prayer/presentation/widgets/widget_standard.dart';
import 'home_widget_snapshot.dart';

/// Offscreen Android widget bitmap rendering and provider notifications.
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

  /// Updates the Ribbon (4x1, 360x80) Android Home Screen Widget.
  static Future<void> updateRibbon({
    required PrayerTimesDay day,
    required DateTime now,
    required EvaluatedPrayerWidgetState eval,
    required bool useDark,
    bool force = false,
  }) async {
    try {
      final all = day.prayers;
      final hijri = formatHijri(now);

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'ribbon_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_$useDark';
      if (!force && renderKey == _lastRibbonRenderKey) {
        return;
      }
      _lastRibbonRenderKey = renderKey;

      const resolvedSize = Size(kRibbonW, kRibbonH);

      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: resolvedSize,
            devicePixelRatio: 2.5,
            textScaler: TextScaler.noScaling,
          ),
          child: Theme(
            data: useDark == true ? AppTheme.dark() : AppTheme.light(),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: WidgetRibbon(
                eval: eval,
                all: all,
                hijriDate: hijri,
                isDark: useDark,
                forNativeWidget: true,
              ),
            ),
          ),
        ),
        key: 'prayer_ribbon_widget',
        logicalSize: resolvedSize,
        pixelRatio: 2.5,
      );

      await HomeWidgetSnapshot.preRenderDailyRibbonSnapshots(
        day: day,
        useDark: useDark,
        hijriDate: hijri,
        force: force,
      );

      await HomeWidget.updateWidget(
        name: 'RibbonWidgetProvider',
        androidName: 'RibbonWidgetProvider',
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  /// Updates the Standard (4x2, 360x160) Android Home Screen Widget.
  static Future<void> updateStandard({
    required PrayerTimesDay day,
    required DateTime now,
    required EvaluatedPrayerWidgetState eval,
    required bool useDark,
    bool force = false,
  }) async {
    try {
      final all = day.prayers;

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'standard_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_$useDark';
      if (!force && renderKey == _lastStandardRenderKey) {
        return;
      }
      _lastStandardRenderKey = renderKey;

      const resolvedSize = Size(kStandardW, kStandardH);

      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: resolvedSize,
            devicePixelRatio: 2.0,
            textScaler: TextScaler.noScaling,
          ),
          child: Theme(
            data: useDark == true ? AppTheme.dark() : AppTheme.light(),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: WidgetStandard(eval: eval, all: all, isDark: useDark),
            ),
          ),
        ),
        key: 'prayer_standard_widget',
        logicalSize: resolvedSize,
        pixelRatio: 2.0,
      );

      await HomeWidget.updateWidget(
        name: 'StandardWidgetProvider',
        androidName: 'StandardWidgetProvider',
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  /// Updates the Large (4x3, 360x240) Android Home Screen Widget.
  static Future<void> updateLarge({
    required PrayerTimesDay day,
    required DateTime now,
    required EvaluatedPrayerWidgetState eval,
    required bool useDark,
    bool force = false,
  }) async {
    try {
      final all = day.prayers;
      final hijri = formatHijri(now);
      final city = day.city.isNotEmpty ? day.city : 'طالب العلم';

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'large_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_$useDark';
      if (!force && renderKey == _lastLargeRenderKey) {
        return;
      }
      _lastLargeRenderKey = renderKey;

      const resolvedSize = Size(kLargeW, kLargeH);

      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: resolvedSize,
            devicePixelRatio: 2.0,
            textScaler: TextScaler.noScaling,
          ),
          child: Theme(
            data: useDark == true ? AppTheme.dark() : AppTheme.light(),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: WidgetLarge(
                eval: eval,
                all: all,
                hijriDate: hijri,
                cityName: city,
                isDark: useDark,
                forNativeWidget: true,
              ),
            ),
          ),
        ),
        key: 'prayer_large_widget',
        logicalSize: resolvedSize,
        pixelRatio: 2.0,
      );

      await HomeWidgetSnapshot.preRenderDailyLargeSnapshots(
        day: day,
        useDark: useDark,
        hijriDate: hijri,
        force: force,
      );

      await HomeWidget.updateWidget(
        name: 'LargeWidgetProvider',
        androidName: 'LargeWidgetProvider',
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  /// Updates the Compact (2x2, 160x160) Android Home Screen Widget.
  static Future<void> updateCompact({
    required PrayerTimesDay day,
    required DateTime now,
    required EvaluatedPrayerWidgetState eval,
    required bool useDark,
    bool force = false,
  }) async {
    try {
      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'compact_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_$useDark';
      if (!force && renderKey == _lastCompactRenderKey) {
        return;
      }
      _lastCompactRenderKey = renderKey;

      const resolvedSize = Size(kCompactW, kCompactH);

      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: resolvedSize,
            devicePixelRatio: 2.5,
            textScaler: TextScaler.noScaling,
          ),
          child: Theme(
            data: useDark == true ? AppTheme.dark() : AppTheme.light(),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: WidgetCompact(eval: eval, isDark: useDark),
            ),
          ),
        ),
        key: 'prayer_compact_widget',
        logicalSize: resolvedSize,
        pixelRatio: 2.5,
      );

      await HomeWidget.updateWidget(
        name: 'CompactWidgetProvider',
        androidName: 'CompactWidgetProvider',
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }
}
