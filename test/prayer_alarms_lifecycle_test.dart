import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/services/foreground_prayer_service.dart';
import 'package:talib_ilm/core/services/home_widget_snapshot.dart';
import 'package:talib_ilm/core/services/notification_service.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_widget_state_evaluator.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrayerTimeService.clearCache();
    ForegroundPrayerService().resetForTesting();
  });

  group('R92 / Area E: Timezone & DST Resilience', () {
    test('findLocationByOffset resolves accurate IANA locations for prayer regions', () {
      // Algeria / Tunisia (+60 min)
      final algeriaLoc = NotificationService.findLocationByOffset(60);
      expect(algeriaLoc, isNotNull);
      expect(algeriaLoc!.name, equals('Africa/Algiers'));

      // Egypt (+120 min)
      final cairoLoc = NotificationService.findLocationByOffset(120);
      expect(cairoLoc, isNotNull);
      expect(cairoLoc!.name, equals('Africa/Cairo'));

      // Saudi Arabia / Makkah / Kuwait / Qatar (+180 min)
      final riyadhLoc = NotificationService.findLocationByOffset(180);
      expect(riyadhLoc, isNotNull);
      expect(riyadhLoc!.name, equals('Asia/Riyadh'));

      // UAE / Dubai (+240 min)
      final dubaiLoc = NotificationService.findLocationByOffset(240);
      expect(dubaiLoc, isNotNull);
      expect(dubaiLoc!.name, equals('Asia/Dubai'));

      // UTC (0 min)
      final utcLoc = NotificationService.findLocationByOffset(0);
      expect(utcLoc, isNotNull);
      expect(utcLoc!.name, equals('UTC'));
    });

    test('PrayerTimeService rolls over to tomorrow Fajr using civil date arithmetic', () async {
      // Simulate 23:59 PM (after Isha has passed)
      final lateNight = DateTime(2026, 10, 25, 23, 59);
      final service = PrayerTimeService(now: () => lateNight);

      final day = await service.getPrayerTimesDay();
      expect(day.nextPrayer, equals(AppStrings.prayerFajr));
      expect(day.nextPrayerTime, isNotNull);
      expect(day.nextPrayerTime!.isAfter(lateNight), isTrue);
      expect(day.nextPrayerTime!.day, equals(26));
      expect(day.nextPrayerTime!.month, equals(10));
    });

    test('HomeWidgetSnapshot computes tomorrow Fajr epoch using civil date rollover', () async {
      final now = DateTime(2026, 10, 25, 12, 0);
      final allPrayers = {
        AppStrings.prayerFajr: DateTime(2026, 10, 25, 5, 15),
        AppStrings.prayerDhuhr: DateTime(2026, 10, 25, 12, 30),
        AppStrings.prayerAsr: DateTime(2026, 10, 25, 15, 45),
        AppStrings.prayerMaghrib: DateTime(2026, 10, 25, 18, 10),
        AppStrings.prayerIsha: DateTime(2026, 10, 25, 19, 30),
      };

      final eval = PrayerWidgetStateEvaluator.evaluate(now: now, all: allPrayers);
      await HomeWidgetSnapshot.savePrayerSnapshot(eval, allPrayers: allPrayers);

      final prefs = await SharedPreferences.getInstance();
      final tomorrowFajrMs = prefs.getInt('prayer_tomorrow_fajr_epoch_ms');
      expect(tomorrowFajrMs, isNotNull);

      final tomorrowFajr = DateTime.fromMillisecondsSinceEpoch(tomorrowFajrMs!);
      expect(tomorrowFajr.year, equals(2026));
      expect(tomorrowFajr.month, equals(10));
      expect(tomorrowFajr.day, equals(26));
      expect(tomorrowFajr.hour, equals(5));
      expect(tomorrowFajr.minute, equals(15));
    });
  });

  group('R92 / Area E: ForegroundPrayerService Lifecycle & State Bounding', () {
    test('resetForTesting clears alerts and polling state', () {
      final service = ForegroundPrayerService();
      expect(service.isPolling, isFalse);
      expect(service.activeAlert.value, isNull);
      expect(service.alertedKeysForTesting, isEmpty);
    });

    test('alerted keys are capped and older entries are trimmed', () async {
      final prefs = await SharedPreferences.getInstance();
      // Pre-seed 55 old alerted keys
      final seededKeys = List.generate(55, (i) => '2026-10-25_key_$i');
      await prefs.setStringList('adhan_alerted_keys', seededKeys);

      final service = ForegroundPrayerService();
      await service.init();
      expect(service.alertedKeysForTesting.length, equals(55));

      // Running check trims keys exceeding 50 entries
      await service.checkForTesting();

      expect(service.alertedKeysForTesting.length, lessThanOrEqualTo(50));
    });
  });
}
