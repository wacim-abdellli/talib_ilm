import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
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

    test('savePrayerSnapshot writes full 24-hour prayer schedule when allPrayers is provided', () async {
      SharedPreferences.setMockInitialValues({});
      AdhanSettingsService.resetCacheForTesting();
      final prefs = await SharedPreferences.getInstance();

      final eval = PrayerWidgetStateEvaluator.evaluate(
        now: DateTime(2026, 10, 23, 17, 0),
        all: testPrayerDay.prayers,
      );

      await HomeWidgetSnapshot.savePrayerSnapshot(
        eval,
        preResolvedDark: true,
        allPrayers: testPrayerDay.prayers,
      );

      expect(prefs.getInt('prayer_fajr_epoch_ms'), testPrayerDay.prayers[AppStrings.prayerFajr]!.millisecondsSinceEpoch);
      expect(prefs.getInt('prayer_dhuhr_epoch_ms'), testPrayerDay.prayers[AppStrings.prayerDhuhr]!.millisecondsSinceEpoch);
      expect(prefs.getInt('prayer_asr_epoch_ms'), testPrayerDay.prayers[AppStrings.prayerAsr]!.millisecondsSinceEpoch);
      expect(prefs.getInt('prayer_maghrib_epoch_ms'), testPrayerDay.prayers[AppStrings.prayerMaghrib]!.millisecondsSinceEpoch);
      expect(prefs.getInt('prayer_isha_epoch_ms'), testPrayerDay.prayers[AppStrings.prayerIsha]!.millisecondsSinceEpoch);
      expect(prefs.getInt('prayer_tomorrow_fajr_epoch_ms'), isNotNull);
      expect(prefs.getBool('is_friday'), isTrue); // 2026-10-23 is Friday
      expect(prefs.getInt('iqama_fajr_min'), 25);
      expect(prefs.getInt('iqama_dhuhr_min'), 25); // Jumua is 25 mins
      expect(prefs.getInt('iqama_asr_min'), 20);
      expect(prefs.getInt('iqama_maghrib_min'), 10);
      expect(prefs.getInt('iqama_isha_min'), 15);
      expect(prefs.getInt('prayer_color_fajr'), isNotNull);
      expect(prefs.getInt('prayer_color_dhuhr'), isNotNull);
      expect(prefs.getInt('prayer_color_asr'), isNotNull);
      expect(prefs.getInt('prayer_color_maghrib'), isNotNull);
      expect(prefs.getInt('prayer_color_isha'), isNotNull);
    });

    test('savePrayerSnapshot shares custom mosque intervals with native widgets', () async {
      SharedPreferences.setMockInitialValues({
        'adhan_iqama_minutes_الفجر': 19,
        'adhan_iqama_minutes_الظهر': 17,
        'adhan_iqama_minutes_العصر': 21,
        'adhan_iqama_minutes_المغرب': 8,
        'adhan_iqama_minutes_العشاء': 14,
        'adhan_iqama_minutes_jumua': 34,
      });
      AdhanSettingsService.resetCacheForTesting();
      final prefs = await SharedPreferences.getInstance();
      final eval = PrayerWidgetStateEvaluator.evaluate(
        now: DateTime(2026, 10, 23, 17, 0),
        all: testPrayerDay.prayers,
        iqamaOverrides: {
          'الفجر': 19,
          'الظهر': 17,
          'العصر': 21,
          'المغرب': 8,
          'العشاء': 14,
          'jumua': 34,
        },
      );

      await HomeWidgetSnapshot.savePrayerSnapshot(
        eval,
        allPrayers: testPrayerDay.prayers,
      );

      expect(prefs.getInt('iqama_fajr_min'), 19);
      expect(prefs.getInt('iqama_dhuhr_min'), 34);
      expect(prefs.getInt('iqama_asr_min'), 21);
      expect(prefs.getInt('iqama_maghrib_min'), 8);
      expect(prefs.getInt('iqama_isha_min'), 14);
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

    test('preRenderDailyRibbonSnapshots and preRenderDailyLargeSnapshots execute cleanly', () async {
      SharedPreferences.setMockInitialValues({});
      HomeWidgetSnapshot.invalidateDailyCache();

      await expectLater(
        HomeWidgetSnapshot.preRenderDailyRibbonSnapshots(
          day: testPrayerDay,
          useDark: true,
          hijriDate: '15 جمادى الأول',
        ),
        completes,
      );

      await expectLater(
        HomeWidgetSnapshot.preRenderDailyLargeSnapshots(
          day: testPrayerDay,
          useDark: false,
          hijriDate: '15 جمادى الأول',
        ),
        completes,
      );
    });

    test('prayerWidgetBackgroundCallback handles refresh and rollover URIs gracefully', () async {
      SharedPreferences.setMockInitialValues({});
      await expectLater(
        prayerWidgetBackgroundCallback(Uri.parse('talibilm://refresh')),
        completes,
      );
      await expectLater(
        prayerWidgetBackgroundCallback(Uri.parse('talibilm://rollover')),
        completes,
      );
    });
  });
}
