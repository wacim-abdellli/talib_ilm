import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/services/home_widget_service.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_home_screen_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testPrayerDay = PrayerTimesDay(
    city: 'الجزائر العاصمة',
    date: DateTime(2026, 10, 23),
    prayers: {
      AppStrings.prayerFajr: DateTime(2026, 10, 23, 5, 5),
      AppStrings.prayerDhuhr: DateTime(2026, 10, 23, 12, 3),
      AppStrings.prayerAsr: DateTime(2026, 10, 23, 15, 8),
      AppStrings.prayerMaghrib: DateTime(2026, 10, 23, 17, 33),
      AppStrings.prayerIsha: DateTime(2026, 10, 23, 18, 58),
    },
    nextPrayer: AppStrings.prayerMaghrib,
    nextPrayerTime: DateTime(2026, 10, 23, 17, 33),
  );

  group('HomeWidgetSnapshot invariants', () {
    test('savePrayerSnapshot writes all 10 keys and increments snapshot version atomically', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final eval = PrayerWidgetStateEvaluator.evaluate(
        now: DateTime(2026, 10, 23, 17, 0),
        all: testPrayerDay.prayers,
      );

      final vBefore = HomeWidgetSnapshot.snapshotVersion;
      await HomeWidgetSnapshot.savePrayerSnapshot(eval, preResolvedDark: true);
      final vAfter = HomeWidgetSnapshot.snapshotVersion;

      expect(vAfter, greaterThan(vBefore));
      expect(prefs.getInt('widget_snapshot_version'), vAfter);
      expect(prefs.getInt('next_prayer_epoch_ms'), eval.targetPrayerTime.millisecondsSinceEpoch);
      expect(prefs.getString('next_prayer_name'), eval.activePrayerName);
      expect(prefs.getString('prayer_display_title'), eval.displayTitle);
      expect(prefs.getInt('prayer_color_value'), isNotNull);
      expect(prefs.getInt('widget_text_color'), isNotNull);
      expect(prefs.getBool('widget_is_dark'), isTrue);
      expect(prefs.getString('prayer_widget_theme_mode'), 'dark');
      expect(prefs.getString('countdown_prefix'), 'بعد ');
      expect(prefs.getString('prayer_status_label'), eval.statusLabel);
      expect(prefs.getBool('is_prayer_active'), isFalse);
    });

    test('resolveWidgetIsDark respects explicit widget mode and app theme fallback', () async {
      SharedPreferences.setMockInitialValues({'prayer_widget_theme_mode': 'light'});
      expect(await HomeWidgetSnapshot.resolveWidgetIsDark(), isFalse);

      SharedPreferences.setMockInitialValues({'prayer_widget_theme_mode': 'dark'});
      expect(await HomeWidgetSnapshot.resolveWidgetIsDark(), isTrue);

      SharedPreferences.setMockInitialValues({'prayer_widget_theme_mode': 'auto', 'theme_mode': 'light'});
      expect(await HomeWidgetSnapshot.resolveWidgetIsDark(), isFalse);

      SharedPreferences.setMockInitialValues({'prayer_widget_theme_mode': 'auto', 'theme_mode': 'dark'});
      expect(await HomeWidgetSnapshot.resolveWidgetIsDark(), isTrue);
    });
  });

  group('HomeWidgetService concurrency and serialization', () {
    test('Concurrent updateAllWidgets calls are serialized without races', () async {
      SharedPreferences.setMockInitialValues({});
      HomeWidgetService.invalidateCache();

      // Launch multiple simultaneous calls
      final futures = [
        HomeWidgetService.updateAllWidgets(
          prayerDay: testPrayerDay,
          referenceTime: DateTime(2026, 10, 23, 17, 10),
        ),
        HomeWidgetService.updateAllWidgets(
          prayerDay: testPrayerDay,
          referenceTime: DateTime(2026, 10, 23, 17, 20),
        ),
        HomeWidgetService.updateAllWidgets(
          prayerDay: testPrayerDay,
          referenceTime: DateTime(2026, 10, 23, 17, 30),
        ),
      ];

      await Future.wait(futures);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('widget_snapshot_version'), isNotNull);
      // The latest call (17:30) evaluated Maghrib countdown correctly
      expect(prefs.getString('next_prayer_name'), AppStrings.prayerMaghrib);
    });

    test('Older operations yield when newer operation arrives during coalescing', () async {
      SharedPreferences.setMockInitialValues({});
      HomeWidgetService.invalidateCache();

      // Sequence calls rapidly
      unawaited(HomeWidgetService.updateAllWidgets(
        prayerDay: testPrayerDay,
        referenceTime: DateTime(2026, 10, 23, 12, 0),
      ));
      final finalCall = HomeWidgetService.updateAllWidgets(
        prayerDay: testPrayerDay,
        referenceTime: DateTime(2026, 10, 23, 17, 30),
      );

      await finalCall;

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('next_prayer_name'), AppStrings.prayerMaghrib);
    });
  });
}
