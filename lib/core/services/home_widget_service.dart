import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/theme/app_theme.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import 'prayer_time_service.dart';

/// HomeWidgetService - Manages synchronization and off-screen rendering
/// of the Android Phone Launcher Home Screen AppWidget.
class HomeWidgetService {
  static const String androidWidgetName = 'PrayerWidgetProvider';
  static const String widgetImageKey = 'prayer_widget_image';

  /// Updates the Android Home Screen Widget by rendering the Flutter prayer card
  /// offscreen and notifying the native AppWidgetProvider.
  static Future<void> updatePrayerWidget({
    PrayerTimesDay? prayerDay,
    DateTime? referenceTime,
  }) async {
    try {
      final now = referenceTime ?? DateTime.now();
      final day = prayerDay ?? await PrayerTimeService().getPrayerTimesDay();

      // Render the widget matching Pic 2 to PNG in application storage
      await HomeWidget.renderFlutterWidget(
        Theme(
          data: AppTheme.light(),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PrayerHomeScreenWidget(
              prayerDay: day,
              referenceTime: now,
            ),
          ),
        ),
        key: widgetImageKey,
        logicalSize: const Size(360, 195),
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
