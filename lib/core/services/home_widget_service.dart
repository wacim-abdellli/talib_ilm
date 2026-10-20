import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import 'prayer_time_service.dart';

/// Supported visual themes for the Android Home Screen AppWidget.
enum WidgetThemeMode {
  dark,
  light,
  auto,
}

/// Top-level background callback invoked when the Android widget is resized or interacted with.
@pragma('vm:entry-point')
Future<void> prayerWidgetBackgroundCallback(Uri? uri) async {
  if (uri?.host == 'resize') {
    final wStr = uri?.queryParameters['minWidth'];
    final hStr = uri?.queryParameters['minHeight'];
    final w = int.tryParse(wStr ?? '');
    final h = int.tryParse(hStr ?? '');
    if (w != null && h != null) {
      await HomeWidget.saveWidgetData<int>('widget_width', w);
      await HomeWidget.saveWidgetData<int>('widget_height', h);
      await HomeWidgetService.updatePrayerWidget(force: true);
    }
  }
}

/// HomeWidgetService - Manages synchronization, theme modes (Black/White/Auto),
/// and lag-free off-screen rendering of the Android Phone Launcher Home Screen AppWidget.
class HomeWidgetService {
  static const String androidWidgetName = 'PrayerWidgetProvider';
  static const String widgetImageKey = 'prayer_widget_image';
  static const String themeModeKey = 'prayer_widget_theme_mode';

  /// Standard 4x1 Home Screen Android widget dimensions (Salaat First style)
  static const Size widgetLogicalSize = Size(380, 95);

  /// In-memory cache key to prevent redundant screenshot rasterizations within the same minute
  static String? _lastRenderKey;

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
      _lastRenderKey = null; // Invalidate cache to force immediate redraw
      await updatePrayerWidget(force: true);
    } catch (_) {}
  }

  /// Registers background callback for interactive widget resizing
  static Future<void> initBackground() async {
    try {
      await HomeWidget.registerInteractivityCallback(prayerWidgetBackgroundCallback);
    } catch (_) {}
  }

  /// Updates the Android Home Screen Widget by rendering the Flutter prayer card
  /// offscreen and notifying the native AppWidgetProvider.
  /// Throttled by minute and prayer phase to guarantee zero phone lag.
  static Future<void> updatePrayerWidget({
    PrayerTimesDay? prayerDay,
    DateTime? referenceTime,
    bool force = false,
  }) async {
    try {
      final now = referenceTime ?? DateTime.now();
      final day = prayerDay ?? await PrayerTimeService().getPrayerTimesDay();
      final mode = await getThemeMode();

      // Resolve theme according to user choice: Dark (AMOLED black), Light (crisp white), or Auto
      final themeData = switch (mode) {
        WidgetThemeMode.light => AppTheme.light(),
        WidgetThemeMode.dark => AppTheme.dark(),
        WidgetThemeMode.auto => AppTheme.resolveTheme(ThemeMode.system),
      };

      // Throttling key: Prevents redundant heavy screenshot rasterization within the exact same minute
      final all = day.prayers;
      final eval = PrayerWidgetStateEvaluator.evaluate(now: now, all: all);
      final renderKey = '${day.city}_${now.hour}:${now.minute}_${eval.activePrayerName}_${eval.phase}_${mode.name}';
      if (!force && renderKey == _lastRenderKey) {
        return;
      }
      _lastRenderKey = renderKey;

      // Dynamically adapt to user's launcher resize dimensions if available
      int targetW = 380;
      int targetH = 95;
      try {
        final rawW = await HomeWidget.getWidgetData<dynamic>('widget_width');
        final rawH = await HomeWidget.getWidgetData<dynamic>('widget_height');
        final savedW = rawW is int ? rawW : (rawW is num ? rawW.toInt() : int.tryParse(rawW?.toString() ?? ''));
        final savedH = rawH is int ? rawH : (rawH is num ? rawH.toInt() : int.tryParse(rawH?.toString() ?? ''));
        if (savedW != null && savedW >= 160) targetW = savedW.clamp(160, 650);
        if (savedH != null && savedH >= 60) targetH = savedH.clamp(60, 450);
      } catch (_) {}

      final resolvedSize = Size(targetW.toDouble(), targetH.toDouble());

      // Render the widget to PNG in application storage with crisp 2.0 pixel ratio (fast, sharp, zero lag)
      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: MediaQueryData(
            size: resolvedSize,
            devicePixelRatio: 2.0,
            textScaler: TextScaler.noScaling,
          ),
          child: Theme(
            data: themeData,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PrayerHomeScreenWidget(
                prayerDay: day,
                referenceTime: now,
                width: resolvedSize.width,
                height: resolvedSize.height,
              ),
            ),
          ),
        ),
        key: widgetImageKey,
        logicalSize: resolvedSize,
        pixelRatio: 2.0,
      );

      // Trigger the native Android AppWidget update
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
    } catch (_) {
      // Graceful fallback when platform channels are unavailable (e.g. unit tests)
    }
  }
}
