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
import 'adhan_settings_service.dart';
import 'home_widget_snapshot.dart';
import 'prayer_time_service.dart';
import '../utils/async_lock.dart';

import 'home_widget_background_callback.dart';
export 'home_widget_background_callback.dart';
export 'home_widget_snapshot.dart';

/// HomeWidgetService - Manages synchronization, theme modes (Black/White/Auto),
/// and lag-free off-screen rendering of the Android Phone Launcher Home Screen AppWidget.
class HomeWidgetService {
  static const String androidWidgetName = 'PrayerWidgetProvider';
  static const String iOSWidgetName = 'TalibIlmWidgets';
  static const String widgetImageKey = 'prayer_widget_image';
  static const String themeModeKey = 'prayer_widget_theme_mode';

  /// Standard 4x1 Home Screen Android widget dimensions (Salaat First style)
  static const Size widgetLogicalSize = Size(380, 120);

  /// In-memory cache key to prevent redundant screenshot rasterizations within the same second and dimensions
  static String? _lastRenderKey;
  static String? _lastRibbonRenderKey;
  static String? _lastStandardRenderKey;
  static String? _lastLargeRenderKey;
  static String? _lastCompactRenderKey;
  static PrayerTimesDay? _cachedPrayerDay;

  /// Invalidates the render cache to force immediate redraw on resize or theme changes
  static void invalidateCache() {
    _lastRenderKey = null;
    _lastRibbonRenderKey = null;
    _lastStandardRenderKey = null;
    _lastLargeRenderKey = null;
    _lastCompactRenderKey = null;
    _cachedPrayerDay = null;
    HomeWidgetSnapshot.invalidateDailyCache();
  }

  static Future<PrayerTimesDay> _resolvePrayerDay(PrayerTimesDay? explicit) async {
    if (explicit != null) {
      _cachedPrayerDay = explicit;
      return explicit;
    }
    final now = DateTime.now();
    if (_cachedPrayerDay != null &&
        _cachedPrayerDay!.date.year == now.year &&
        _cachedPrayerDay!.date.month == now.month &&
        _cachedPrayerDay!.date.day == now.day) {
      return _cachedPrayerDay!;
    }
    final fetched = await PrayerTimeService().getPrayerTimesDay();
    _cachedPrayerDay = fetched;
    return fetched;
  }

  /// Retrieves the user-selected widget theme mode (defaults to dark AMOLED card)
  static Future<WidgetThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(themeModeKey);
      if (modeStr == 'light') return WidgetThemeMode.light;
      if (modeStr == 'auto') return WidgetThemeMode.auto;
      return WidgetThemeMode.dark;
    } catch (_) {
      return WidgetThemeMode.dark;
    }
  }

  /// Updates the user's widget theme preference and triggers an instant widget redraw
  static Future<void> setThemeMode(WidgetThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(themeModeKey, mode.name);
      await HomeWidget.saveWidgetData<String>(themeModeKey, mode.name);
      invalidateCache();
      await updateAllWidgets(force: true);
    } catch (_) {}
  }

  static Future<ThemeData> _resolveAutoTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appTheme = prefs.getString('theme_mode');
      if (appTheme == 'light') return AppTheme.light();
      if (appTheme == 'dark') return AppTheme.dark();
    } catch (_) {}
    return AppTheme.resolveTheme(ThemeMode.system);
  }

  /// Registers background callback for interactive widget resizing
  static Future<void> initBackground() async {
    try {
      await HomeWidget.setAppGroupId('group.com.talibilm.app');
    } catch (_) {}
    try {
      await HomeWidget.registerInteractivityCallback(prayerWidgetBackgroundCallback);
    } catch (_) {}
  }

  /// Saves the target prayer epoch timestamp and properties for native widgets.
  static Future<void> _saveNextPrayerEpoch(
    EvaluatedPrayerWidgetState eval, {
    Map<String, DateTime>? allPrayers,
    bool? preResolvedDark,
  }) => HomeWidgetSnapshot.savePrayerSnapshot(
    eval,
    allPrayers: allPrayers,
    preResolvedDark: preResolvedDark,
  );

  /// Updates the Android Home Screen Widget by rendering the Flutter prayer card
  /// offscreen and notifying the native AppWidgetProvider.
  /// Throttled by minute, prayer phase, and dimensions; native Chronometer handles per-second live ticking.
  static Future<void> updatePrayerWidget({
    PrayerTimesDay? prayerDay,
    DateTime? referenceTime,
    bool force = false,
    EvaluatedPrayerWidgetState? preResolvedEval,
  }) async {
    try {
      final now = referenceTime ?? DateTime.now();
      final day = await _resolvePrayerDay(prayerDay);
      final iqamaOverrides = (await AdhanSettingsService().getSettings())
          .iqamaMinutesAfterAdhan;
      final mode = await getThemeMode();

      // Resolve theme according to user choice: Dark (AMOLED black), Light (crisp white), or Auto
      final themeData = switch (mode) {
        WidgetThemeMode.light => AppTheme.light(),
        WidgetThemeMode.dark => AppTheme.dark(),
        WidgetThemeMode.auto => await _resolveAutoTheme(),
      };

      // Dynamically adapt to user's launcher resize dimensions if available
      int targetW = 380;
      int targetH = 120;
      try {
        final rawW = await HomeWidget.getWidgetData<dynamic>('widget_width');
        final rawH = await HomeWidget.getWidgetData<dynamic>('widget_height');
        final savedW = rawW is int ? rawW : (rawW is num ? rawW.toInt() : int.tryParse(rawW?.toString() ?? ''));
        final savedH = rawH is int ? rawH : (rawH is num ? rawH.toInt() : int.tryParse(rawH?.toString() ?? ''));
        if (savedW != null && savedW >= 140) targetW = savedW.clamp(140, 480);
        if (savedH != null && savedH >= 70) targetH = savedH.clamp(70, 280);
      } catch (_) {}

      final all = day.prayers;
      final eval = preResolvedEval ?? PrayerWidgetStateEvaluator.evaluate(
        now: now,
        all: all,
        iqamaOverrides: iqamaOverrides,
      );
      if (preResolvedEval == null) {
        await _saveNextPrayerEpoch(eval, allPrayers: all);
      }

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey = '${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_${mode.name}_${targetW}x$targetH';
      if (!force && renderKey == _lastRenderKey) {
        return;
      }
      _lastRenderKey = renderKey;

      final resolvedSize = Size(targetW.toDouble(), targetH.toDouble());

      // Render the widget to PNG in application storage with optimal 1.5 pixel ratio (crisp, fast, safe for Android Binder)
      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: MediaQueryData(
            size: resolvedSize,
            devicePixelRatio: 1.5,
            textScaler: TextScaler.noScaling,
          ),
          child: Theme(
            data: themeData,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PrayerHomeScreenWidget(
                prayerDay: day,
                referenceTime: now,
                iqamaOverrides: iqamaOverrides,
                width: resolvedSize.width,
                height: resolvedSize.height,
              ),
            ),
          ),
        ),
        key: widgetImageKey,
        logicalSize: resolvedSize,
        pixelRatio: 1.5,
      );

      // Trigger the native Android AppWidget update
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable (e.g. unit tests)
    }
  }

  static String _formatHijri(DateTime date) {
    try {
      HijriCalendar.setLocal('ar');
      final h = HijriCalendar.fromDate(date);
      return '${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
    } catch (_) {
      return '';
    }
  }

  /// Updates the Ribbon (4x1, 360x80) Android Home Screen Widget.
  static Future<void> updateRibbon({
    PrayerTimesDay? prayerDay,
    DateTime? referenceTime,
    bool force = false,
    EvaluatedPrayerWidgetState? preResolvedEval,
    bool? preResolvedDark,
  }) async {
    try {
      final now = referenceTime ?? DateTime.now();
      final day = await _resolvePrayerDay(prayerDay);
      final all = day.prayers;
      final iqamaOverrides = (await AdhanSettingsService().getSettings())
          .iqamaMinutesAfterAdhan;
      final eval = preResolvedEval ?? PrayerWidgetStateEvaluator.evaluate(
        now: now,
        all: all,
        iqamaOverrides: iqamaOverrides,
      );
      final useDark = preResolvedDark ?? await _resolveWidgetIsDark();
      if (preResolvedEval == null) {
        await _saveNextPrayerEpoch(eval, allPrayers: all, preResolvedDark: useDark);
      }
      final hijri = _formatHijri(now);

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey = 'ribbon_${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_$useDark';
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
        iOSName: iOSWidgetName,
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  static Future<bool> _resolveWidgetIsDark() =>
      HomeWidgetSnapshot.resolveWidgetIsDark();

  /// Updates the Standard (4x2, 360x160) Android Home Screen Widget.
  static Future<void> updateStandard({
    PrayerTimesDay? prayerDay,
    DateTime? referenceTime,
    bool force = false,
    EvaluatedPrayerWidgetState? preResolvedEval,
    bool? preResolvedDark,
  }) async {
    try {
      final now = referenceTime ?? DateTime.now();
      final day = await _resolvePrayerDay(prayerDay);
      final all = day.prayers;
      final iqamaOverrides = (await AdhanSettingsService().getSettings())
          .iqamaMinutesAfterAdhan;
      final eval = preResolvedEval ?? PrayerWidgetStateEvaluator.evaluate(
        now: now,
        all: all,
        iqamaOverrides: iqamaOverrides,
      );
      final useDark = preResolvedDark ?? await _resolveWidgetIsDark();
      if (preResolvedEval == null) {
        await _saveNextPrayerEpoch(eval, allPrayers: all, preResolvedDark: useDark);
      }

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
              child: WidgetStandard(
                eval: eval,
                all: all,
                isDark: useDark,
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
        iOSName: iOSWidgetName,
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  /// Updates the Large (4x3, 360x240) Android Home Screen Widget.
  static Future<void> updateLarge({
    PrayerTimesDay? prayerDay,
    DateTime? referenceTime,
    bool force = false,
    EvaluatedPrayerWidgetState? preResolvedEval,
    bool? preResolvedDark,
  }) async {
    try {
      final now = referenceTime ?? DateTime.now();
      final day = await _resolvePrayerDay(prayerDay);
      final all = day.prayers;
      final iqamaOverrides = (await AdhanSettingsService().getSettings())
          .iqamaMinutesAfterAdhan;
      final eval = preResolvedEval ?? PrayerWidgetStateEvaluator.evaluate(
        now: now,
        all: all,
        iqamaOverrides: iqamaOverrides,
      );
      final useDark = preResolvedDark ?? await _resolveWidgetIsDark();
      if (preResolvedEval == null) {
        await _saveNextPrayerEpoch(eval, allPrayers: all, preResolvedDark: useDark);
      }
      final hijri = _formatHijri(now);
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
        iOSName: iOSWidgetName,
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  /// Updates the Compact (2x2, 160x160) Android Home Screen Widget.
  static Future<void> updateCompact({
    PrayerTimesDay? prayerDay,
    DateTime? referenceTime,
    bool force = false,
    EvaluatedPrayerWidgetState? preResolvedEval,
    bool? preResolvedDark,
  }) async {
    try {
      final now = referenceTime ?? DateTime.now();
      final day = await _resolvePrayerDay(prayerDay);
      final all = day.prayers;
      final iqamaOverrides = (await AdhanSettingsService().getSettings())
          .iqamaMinutesAfterAdhan;
      final eval = preResolvedEval ?? PrayerWidgetStateEvaluator.evaluate(
        now: now,
        all: all,
        iqamaOverrides: iqamaOverrides,
      );
      final useDark = preResolvedDark ?? await _resolveWidgetIsDark();
      if (preResolvedEval == null) {
        await _saveNextPrayerEpoch(eval, allPrayers: all, preResolvedDark: useDark);
      }

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
              child: WidgetCompact(
                eval: eval,
                isDark: useDark,
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
        iOSName: iOSWidgetName,
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

  static final AsyncLock _updateLock = AsyncLock();
  static int _latestOperation = 0;
  static int get snapshotVersion => HomeWidgetSnapshot.snapshotVersion;

  /// Updates all Android widgets simultaneously with serialization and coalescing.
  static Future<void> updateAllWidgets({
    PrayerTimesDay? prayerDay,
    DateTime? referenceTime,
    bool force = false,
  }) async {
    final op = ++_latestOperation;
    return _updateLock.synchronized(() async {
      if (op < _latestOperation && !force) return;
      try {
        final now = referenceTime ?? DateTime.now();
        final day = await _resolvePrayerDay(prayerDay);
        final iqamaOverrides = (await AdhanSettingsService().getSettings())
            .iqamaMinutesAfterAdhan;
        final eval = PrayerWidgetStateEvaluator.evaluate(
          now: now,
          all: day.prayers,
          iqamaOverrides: iqamaOverrides,
        );
        final useDark = await _resolveWidgetIsDark();
        if (op < _latestOperation && !force) return;

        await _saveNextPrayerEpoch(eval, allPrayers: day.prayers, preResolvedDark: useDark);
        if (op < _latestOperation && !force) return;

        await Future.wait([
          updateRibbon(
            prayerDay: day,
            referenceTime: now,
            force: force,
            preResolvedEval: eval,
            preResolvedDark: useDark,
          ),
          updateCompact(
            prayerDay: day,
            referenceTime: now,
            force: force,
            preResolvedEval: eval,
            preResolvedDark: useDark,
          ),
          updateLarge(
            prayerDay: day,
            referenceTime: now,
            force: force,
            preResolvedEval: eval,
            preResolvedDark: useDark,
          ),
          updateStandard(
            prayerDay: day,
            referenceTime: now,
            force: force,
            preResolvedEval: eval,
            preResolvedDark: useDark,
          ),
          updatePrayerWidget(
            prayerDay: day,
            referenceTime: now,
            force: force,
            preResolvedEval: eval,
          ),
        ]);
      } catch (_) {
        // Graceful fallback when platform channels are unavailable
      }
    });
  }
}
