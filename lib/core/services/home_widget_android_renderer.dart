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

  /// Resolves the actual launcher widget dimensions dynamically reported by Android.
  static Future<Size> resolveDimensions({
    required String prefix,
    required double fallbackW,
    required double fallbackH,
    required double minW,
    required double maxW,
    required double minH,
    required double maxH,
  }) async {
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
        final clampedW = w.toDouble().clamp(minW, maxW);
        final clampedH = h.toDouble().clamp(minH, maxH);
        return Size(clampedW, clampedH);
      }
    } catch (_) {}
    return Size(fallbackW, fallbackH);
  }

  /// Updates the Ribbon (4x1) Android Home Screen Widget dynamically.
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

      final resolvedSize = await resolveDimensions(
        prefix: 'ribbon',
        fallbackW: kRibbonW,
        fallbackH: kRibbonH,
        minW: 200.0,
        maxW: 600.0,
        minH: 50.0,
        maxH: 250.0,
      );

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'ribbon_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_${useDark}_${resolvedSize.width.toInt()}x${resolvedSize.height.toInt()}';
      if (!force && renderKey == _lastRibbonRenderKey) {
        return;
      }
      _lastRibbonRenderKey = renderKey;

      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: MediaQueryData(
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
                width: resolvedSize.width,
                height: resolvedSize.height,
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
        width: resolvedSize.width,
        height: resolvedSize.height,
      );

      await HomeWidget.updateWidget(
        name: 'RibbonWidgetProvider',
        androidName: 'RibbonWidgetProvider',
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  /// Updates the Standard (4x2) Android Home Screen Widget dynamically.
  static Future<void> updateStandard({
    required PrayerTimesDay day,
    required DateTime now,
    required EvaluatedPrayerWidgetState eval,
    required bool useDark,
    bool force = false,
  }) async {
    try {
      final all = day.prayers;

      final resolvedSize = await resolveDimensions(
        prefix: 'standard',
        fallbackW: kStandardW,
        fallbackH: kStandardH,
        minW: 200.0,
        maxW: 600.0,
        minH: 80.0,
        maxH: 350.0,
      );

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'standard_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_${useDark}_${resolvedSize.width.toInt()}x${resolvedSize.height.toInt()}';
      if (!force && renderKey == _lastStandardRenderKey) {
        return;
      }
      _lastStandardRenderKey = renderKey;

      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: MediaQueryData(
            size: resolvedSize,
            devicePixelRatio: 2.0,
            textScaler: TextScaler.noScaling,
          ),
          child: Theme(
            data: useDark == true ? AppTheme.dark() : AppTheme.light(),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: WidgetStandard(
                eval: eval,
                all: all,
                isDark: useDark,
                width: resolvedSize.width,
                height: resolvedSize.height,
              ),
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

  /// Updates the Large (4x3/4x2/4x1) Android Home Screen Widget dynamically.
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

      final resolvedSize = await resolveDimensions(
        prefix: 'large',
        fallbackW: kLargeW,
        fallbackH: kLargeH,
        minW: 200.0,
        maxW: 600.0,
        minH: 60.0,
        maxH: 300.0,
      );

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'large_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_${useDark}_${resolvedSize.width.toInt()}x${resolvedSize.height.toInt()}';
      if (!force && renderKey == _lastLargeRenderKey) {
        return;
      }
      _lastLargeRenderKey = renderKey;

      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: MediaQueryData(
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
                width: resolvedSize.width,
                height: resolvedSize.height,
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
        width: resolvedSize.width,
        height: resolvedSize.height,
      );

      await HomeWidget.updateWidget(
        name: 'LargeWidgetProvider',
        androidName: 'LargeWidgetProvider',
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  /// Updates the Compact (2x2) Android Home Screen Widget dynamically.
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
        fallbackW: kCompactW,
        fallbackH: kCompactH,
        minW: 100.0,
        maxW: 300.0,
        minH: 100.0,
        maxH: 300.0,
      );

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          'compact_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_${useDark}_${resolvedSize.width.toInt()}x${resolvedSize.height.toInt()}';
      if (!force && renderKey == _lastCompactRenderKey) {
        return;
      }
      _lastCompactRenderKey = renderKey;

      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: MediaQueryData(
            size: resolvedSize,
            devicePixelRatio: 2.5,
            textScaler: TextScaler.noScaling,
          ),
          child: Theme(
            data: useDark == true ? AppTheme.dark() : AppTheme.light(),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: WidgetCompact(
                eval: eval,
                isDark: useDark,
                width: resolvedSize.width,
                height: resolvedSize.height,
              ),
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
