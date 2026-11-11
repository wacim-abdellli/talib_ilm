import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import 'adhan_settings_service.dart';
import 'home_widget_snapshot.dart';
import 'prayer_time_service.dart';
import '../utils/async_lock.dart';

import 'home_widget_android_renderer.dart';
export 'home_widget_android_renderer.dart';
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
  static bool _appGroupReady = false;

  /// Standard 4x1 Home Screen Android widget dimensions (Salaat First style)
  static const Size widgetLogicalSize = Size(380, 120);

  /// In-memory cache key to prevent redundant screenshot rasterizations within the same second and dimensions
  static String? _lastRenderKey;
  static PrayerTimesDay? _cachedPrayerDay;

  /// Invalidates the render cache to force immediate redraw on resize or theme changes
  static void invalidateCache() {
    _lastRenderKey = null;
    _cachedPrayerDay = null;
    HomeWidgetAndroidRenderer.invalidateCache();
    HomeWidgetSnapshot.invalidateDailyCache();
  }

  static Future<PrayerTimesDay> _resolvePrayerDay(
    PrayerTimesDay? explicit,
  ) async {
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

  /// Retrieves the user-selected widget theme mode (defaults to automatic system matching)
  static Future<WidgetThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(themeModeKey);
      if (modeStr == 'light') return WidgetThemeMode.light;
      if (modeStr == 'dark') return WidgetThemeMode.dark;
      return WidgetThemeMode.auto;
    } catch (_) {
      return WidgetThemeMode.auto;
    }
  }

  /// Updates the user's widget theme preference and triggers an instant widget redraw
  static Future<bool> setThemeMode(WidgetThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(themeModeKey, mode.name);
      await prefs.setBool('widget_theme_user_selected', true);
      if (Platform.isIOS && !_appGroupReady) await initBackground();
      await HomeWidgetSnapshot.writeWidgetValue<String>(
        themeModeKey,
        mode.name,
      );
      await HomeWidgetSnapshot.writeWidgetValue<bool>(
        'widget_theme_user_selected',
        true,
      );
      invalidateCache();
      await updateAllWidgets(force: true);
      return true;
    } catch (error) {
      invalidateCache();
      debugPrint('Home widget theme sync warning: $error');
      return true;
    }
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
      final configured = await HomeWidget.setAppGroupId(
        HomeWidgetSnapshot.appGroupId,
      );
      _appGroupReady = !Platform.isIOS || configured == true;
      if (Platform.isIOS) {
        _appGroupReady = await HomeWidgetSnapshot.verifyAppGroup();
      }
    } catch (error) {
      _appGroupReady = false;
      debugPrint('iOS widget App Group setup notice: $error');
    }
    try {
      await HomeWidget.registerInteractivityCallback(
        prayerWidgetBackgroundCallback,
      );
    } catch (_) {}
  }

  /// Saves the target prayer epoch timestamp and properties for native widgets.
  static Future<void> _saveNextPrayerEpoch(
    EvaluatedPrayerWidgetState eval, {
    Map<String, DateTime>? allPrayers,
    bool? preResolvedDark,
    String? cityName,
  }) async {
    if (Platform.isIOS && !_appGroupReady) await initBackground();
    await HomeWidgetSnapshot.savePrayerSnapshot(
      eval,
      allPrayers: allPrayers,
      preResolvedDark: preResolvedDark,
      cityName: cityName,
    );
    if (Platform.isIOS) {
      try {
        await HomeWidget.updateWidget(
          name: iOSWidgetName,
          iOSName: iOSWidgetName,
        );
      } catch (error) {
        debugPrint('iOS widget reload notification notice: $error');
      }
    }
  }

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
      final iqamaOverrides =
          (await AdhanSettingsService().getSettings()).iqamaMinutesAfterAdhan;
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
        final savedW = rawW is int
            ? rawW
            : (rawW is num
                  ? rawW.toInt()
                  : int.tryParse(rawW?.toString() ?? ''));
        final savedH = rawH is int
            ? rawH
            : (rawH is num
                  ? rawH.toInt()
                  : int.tryParse(rawH?.toString() ?? ''));
        if (savedW != null && savedW >= 140) targetW = savedW.clamp(140, 480);
        if (savedH != null && savedH >= 70) targetH = savedH.clamp(70, 280);
      } catch (_) {}

      final all = day.prayers;
      final eval =
          preResolvedEval ??
          PrayerWidgetStateEvaluator.evaluate(
            now: now,
            all: all,
            iqamaOverrides: iqamaOverrides,
          );
      if (preResolvedEval == null) {
        await _saveNextPrayerEpoch(eval, allPrayers: all, cityName: day.city);
      }

      final timeKey = '${now.hour}:${now.minute}';
      final renderKey =
          '${day.city}_${timeKey}_${eval.activePrayerName}_${eval.phase}_${mode.name}_${targetW}x$targetH';
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

  static Future<bool> _resolveWidgetIsDark() =>
      HomeWidgetSnapshot.resolveWidgetIsDark();

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
      final iqamaOverrides =
          (await AdhanSettingsService().getSettings()).iqamaMinutesAfterAdhan;
      final eval =
          preResolvedEval ??
          PrayerWidgetStateEvaluator.evaluate(
            now: now,
            all: all,
            iqamaOverrides: iqamaOverrides,
          );
      final useDark = preResolvedDark ?? await _resolveWidgetIsDark();
      if (preResolvedEval == null) {
        await _saveNextPrayerEpoch(
          eval,
          allPrayers: all,
          preResolvedDark: useDark,
          cityName: day.city,
        );
      }
      await HomeWidgetAndroidRenderer.updateRibbon(
        day: day,
        now: now,
        eval: eval,
        useDark: useDark,
        force: force,
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable
    }
  }

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
      final iqamaOverrides =
          (await AdhanSettingsService().getSettings()).iqamaMinutesAfterAdhan;
      final eval =
          preResolvedEval ??
          PrayerWidgetStateEvaluator.evaluate(
            now: now,
            all: all,
            iqamaOverrides: iqamaOverrides,
          );
      final useDark = preResolvedDark ?? await _resolveWidgetIsDark();
      if (preResolvedEval == null) {
        await _saveNextPrayerEpoch(
          eval,
          allPrayers: all,
          preResolvedDark: useDark,
          cityName: day.city,
        );
      }
      await HomeWidgetAndroidRenderer.updateStandard(
        day: day,
        now: now,
        eval: eval,
        useDark: useDark,
        force: force,
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
      final iqamaOverrides =
          (await AdhanSettingsService().getSettings()).iqamaMinutesAfterAdhan;
      final eval =
          preResolvedEval ??
          PrayerWidgetStateEvaluator.evaluate(
            now: now,
            all: all,
            iqamaOverrides: iqamaOverrides,
          );
      final useDark = preResolvedDark ?? await _resolveWidgetIsDark();
      if (preResolvedEval == null) {
        await _saveNextPrayerEpoch(
          eval,
          allPrayers: all,
          preResolvedDark: useDark,
          cityName: day.city,
        );
      }
      await HomeWidgetAndroidRenderer.updateLarge(
        day: day,
        now: now,
        eval: eval,
        useDark: useDark,
        force: force,
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
      final iqamaOverrides =
          (await AdhanSettingsService().getSettings()).iqamaMinutesAfterAdhan;
      final eval =
          preResolvedEval ??
          PrayerWidgetStateEvaluator.evaluate(
            now: now,
            all: all,
            iqamaOverrides: iqamaOverrides,
          );
      final useDark = preResolvedDark ?? await _resolveWidgetIsDark();
      if (preResolvedEval == null) {
        await _saveNextPrayerEpoch(
          eval,
          allPrayers: all,
          preResolvedDark: useDark,
          cityName: day.city,
        );
      }
      await HomeWidgetAndroidRenderer.updateCompact(
        day: day,
        now: now,
        eval: eval,
        useDark: useDark,
        force: force,
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
      if (op < _latestOperation) return;
      try {
        final now = referenceTime ?? DateTime.now();
        final day = await _resolvePrayerDay(prayerDay);
        final iqamaOverrides =
            (await AdhanSettingsService().getSettings()).iqamaMinutesAfterAdhan;
        final eval = PrayerWidgetStateEvaluator.evaluate(
          now: now,
          all: day.prayers,
          iqamaOverrides: iqamaOverrides,
        );
        final useDark = await _resolveWidgetIsDark();
        if (op < _latestOperation) return;

        await _saveNextPrayerEpoch(
          eval,
          allPrayers: day.prayers,
          preResolvedDark: useDark,
          cityName: day.city,
        );
        if (op < _latestOperation) return;

        await updateRibbon(
          prayerDay: day,
          referenceTime: now,
          force: force,
          preResolvedEval: eval,
          preResolvedDark: useDark,
        );
        await updateStandard(
          prayerDay: day,
          referenceTime: now,
          force: force,
          preResolvedEval: eval,
          preResolvedDark: useDark,
        );
        await updateLarge(
          prayerDay: day,
          referenceTime: now,
          force: force,
          preResolvedEval: eval,
          preResolvedDark: useDark,
        );
        await updateCompact(
          prayerDay: day,
          referenceTime: now,
          force: force,
          preResolvedEval: eval,
          preResolvedDark: useDark,
        );
        await updatePrayerWidget(
          prayerDay: day,
          referenceTime: now,
          force: force,
          preResolvedEval: eval,
        );
      } catch (error) {
        // Keep the current widget contents when an update cannot be completed.
        HomeWidgetSnapshot.lastSyncError ??= error.toString();
        debugPrint('Prayer widget update failed: $error');
      }
    });
  }
}
