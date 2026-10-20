import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/theme/app_theme.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import 'prayer_time_service.dart';
import 'theme_service.dart';

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
      await HomeWidgetService.updatePrayerWidget();
    }
  }
}

/// HomeWidgetService - Manages synchronization and off-screen rendering
/// of the Android Phone Launcher Home Screen AppWidget.
class HomeWidgetService {
  static const String androidWidgetName = 'PrayerWidgetProvider';
  static const String widgetImageKey = 'prayer_widget_image';

  /// Standard 4x2 Home Screen Android widget dimensions
  static const Size widgetLogicalSize = Size(380, 145);

  /// Registers background callback for interactive widget resizing
  static Future<void> initBackground() async {
    try {
      await HomeWidget.registerInteractivityCallback(prayerWidgetBackgroundCallback);
    } catch (_) {}
  }

  /// Updates the Android Home Screen Widget by rendering the Flutter prayer card
  /// offscreen and notifying the native AppWidgetProvider.
  static Future<void> updatePrayerWidget({
    PrayerTimesDay? prayerDay,
    DateTime? referenceTime,
  }) async {
    try {
      final now = referenceTime ?? DateTime.now();
      final day = prayerDay ?? await PrayerTimeService().getPrayerTimesDay();

      // Resolve theme mode cleanly via AppTheme token provider
      final themeService = ThemeService();
      await themeService.loadTheme();
      final themeData = AppTheme.resolveTheme(themeService.themeMode);

      // Dynamically adapt to user's launcher resize dimensions if available
      int targetW = 380;
      int targetH = 145;
      try {
        final rawW = await HomeWidget.getWidgetData<dynamic>('widget_width');
        final rawH = await HomeWidget.getWidgetData<dynamic>('widget_height');
        final savedW = rawW is int ? rawW : (rawW is num ? rawW.toInt() : int.tryParse(rawW?.toString() ?? ''));
        final savedH = rawH is int ? rawH : (rawH is num ? rawH.toInt() : int.tryParse(rawH?.toString() ?? ''));
        if (savedW != null && savedW >= 130) targetW = savedW.clamp(130, 650);
        if (savedH != null && savedH >= 65) targetH = savedH.clamp(65, 550);
      } catch (_) {}

      final resolvedSize = Size(targetW.toDouble(), targetH.toDouble());

      // Render the widget to PNG in application storage with crisp pixel ratio
      await HomeWidget.renderFlutterWidget(
        MediaQuery(
          data: MediaQueryData(
            size: resolvedSize,
            devicePixelRatio: 3.0,
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
        pixelRatio: 3.0,
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
