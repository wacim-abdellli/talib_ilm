import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/core/services/adhkar_reminder_service.dart';
import 'package:talib_ilm/core/services/notification_service.dart';
import 'package:talib_ilm/core/services/prayer_schedule_service.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class FakeNotificationService extends NotificationService {
  final List<Map<String, dynamic>> scheduledCalls = [];
  final List<int> cancelledIds = [];
  final List<Map<String, dynamic>> instantCalls = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
    bool isJumua = false,
  }) async {
    scheduledCalls.add({
      'type': 'prayer',
      'id': id,
      'prayerName': prayerName,
      'time': scheduledTime,
      'mode': mode,
    });
  }

  @override
  Future<void> schedulePrePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required int minutesBefore,
    bool isJumua = false,
  }) async {
    scheduledCalls.add({
      'type': 'pre_prayer',
      'id': id,
      'prayerName': prayerName,
      'time': scheduledTime,
      'minutesBefore': minutesBefore,
    });
  }

  @override
  Future<void> scheduleIqamaNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    bool isJumua = false,
  }) async {
    scheduledCalls.add({
      'type': 'iqama',
      'id': id,
      'prayerName': prayerName,
      'time': scheduledTime,
    });
  }

  @override
  Future<void> scheduleSurahAlKahfNotification({
    required int id,
    required DateTime scheduledTime,
  }) async {
    scheduledCalls.add({
      'type': 'surah_kahf',
      'id': id,
      'time': scheduledTime,
    });
  }

  @override
  Future<void> showInstantPrePrayerNotification({
    required int id,
    required String prayerName,
    required int minutesBefore,
    bool isJumua = false,
  }) async {
    instantCalls.add({
      'type': 'instant_pre_prayer',
      'id': id,
      'prayerName': prayerName,
      'minutesBefore': minutesBefore,
    });
  }

  @override
  Future<void> showInstantPrayerAlert({
    required int id,
    required String prayerName,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
  }) async {
    instantCalls.add({
      'type': 'instant_prayer',
      'id': id,
      'prayerName': prayerName,
      'mode': mode,
    });
  }

  @override
  Future<void> cancelPrayerNotificationsOnly({Set<int>? preserveIds}) async {
    for (var d = 0; d < 7; d++) {
      for (var i = 0; i <= 5; i++) {
        final adhanId = 1000 + (d * 100) + i;
        if (preserveIds == null || !preserveIds.contains(adhanId)) {
          cancelledIds.add(adhanId);
        }
        final preId = 2000 + (d * 100) + i;
        if (preserveIds == null || !preserveIds.contains(preId)) {
          cancelledIds.add(preId);
        }
        final iqamaId = 3000 + (d * 100) + i;
        if (preserveIds == null || !preserveIds.contains(iqamaId)) {
          cancelledIds.add(iqamaId);
        }
      }
      final kahfId = 4000 + (d * 100);
      if (preserveIds == null || !preserveIds.contains(kahfId)) {
        cancelledIds.add(kahfId);
      }
    }
  }

  @override
  Future<void> cancelActivePrayerAlertsOnly() async {
    for (int i = 700; i <= 710; i++) {
      cancelledIds.add(i);
    }
    for (int i = 750; i <= 760; i++) {
      cancelledIds.add(i);
    }
  }
}

class FakePrayerTimeService extends PrayerTimeService {
  final DateTime Function() _mockNow;
  FakePrayerTimeService(this._mockNow) : super(now: _mockNow);

  @override
  Future<PrayerTimesDay> getPrayerTimesDay({DateTime? date}) async {
    final d = date ?? _mockNow();
    final prayers = <String, DateTime>{
      AppStrings.prayerFajr: DateTime(d.year, d.month, d.day, 5, 10),
      'الشروق': DateTime(d.year, d.month, d.day, 6, 35),
      AppStrings.prayerDhuhr: DateTime(d.year, d.month, d.day, 12, 15),
      AppStrings.prayerAsr: DateTime(d.year, d.month, d.day, 15, 30),
      AppStrings.prayerMaghrib: DateTime(d.year, d.month, d.day, 18, 0),
      AppStrings.prayerIsha: DateTime(d.year, d.month, d.day, 19, 20),
    };
    return PrayerTimesDay(
      city: 'الجزائر العاصمة',
      date: d,
      prayers: prayers,
      nextPrayer: AppStrings.prayerFajr,
      nextPrayerTime: prayers[AppStrings.prayerFajr],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  group('7-Day Rolling Prayer Schedule & 15-Minute Advance Reminder Tests', () {
    late FakeNotificationService fakeNotif;
    late FakePrayerTimeService fakePrayerTimes;
    late PrayerScheduleService scheduleService;
    // Set fixed reference time to 04:00 AM so all prayers of today and upcoming days are in future
    final fixedTime = DateTime(2026, 10, 19, 4, 0);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeNotif = FakeNotificationService();
      fakePrayerTimes = FakePrayerTimeService(() => fixedTime);
      scheduleService = PrayerScheduleService(
        notificationService: fakeNotif,
        prayerTimeService: fakePrayerTimes,
        now: () => fixedTime,
      );
    });

    test('Schedules a full 7-day rolling window (days 0..6)', () async {
      await scheduleService.refreshSchedulesIfNeeded(force: true);

      // Verify that all 7 days have scheduled adhans and pre-prayer notifications
      final adhanCalls =
          fakeNotif.scheduledCalls.where((c) => c['type'] == 'prayer').toList();
      final prePrayerCalls = fakeNotif.scheduledCalls
          .where((c) => c['type'] == 'pre_prayer')
          .toList();

      // 5 prayers per day (excluding sunrise) * 7 days = 35 adhan notifications
      expect(adhanCalls.length, equals(35));
      // 5 pre-prayer 15-min notifications per day * 7 days = 35 pre-prayer notifications
      expect(prePrayerCalls.length, equals(35));
    });

    test('All 15-minute advance reminders are scheduled exactly 15 minutes before prayer time', () async {
      await scheduleService.refreshSchedulesIfNeeded(force: true);

      final prePrayerCalls = fakeNotif.scheduledCalls
          .where((c) => c['type'] == 'pre_prayer')
          .toList();
      final adhanCalls =
          fakeNotif.scheduledCalls.where((c) => c['type'] == 'prayer').toList();

      expect(prePrayerCalls.isNotEmpty, isTrue);

      for (final pre in prePrayerCalls) {
        expect(pre['minutesBefore'], equals(15));
        final preId = pre['id'] as int;
        // Corresponding adhan has id = preId - 1000
        final matchingAdhan = adhanCalls.firstWhere(
          (a) => (a['id'] as int) == (preId - 1000),
        );
        final preTime = pre['time'] as DateTime;
        final adhanTime = matchingAdhan['time'] as DateTime;
        expect(adhanTime.difference(preTime).inMinutes, equals(15));
      }
    });

    test('Strict collision-free ID partitioning across all 7 days', () async {
      await scheduleService.refreshSchedulesIfNeeded(force: true);

      final allIds = fakeNotif.scheduledCalls.map((c) => c['id'] as int).toList();
      final uniqueIds = allIds.toSet();

      // No duplicates amongst all scheduled calls
      expect(allIds.length, equals(uniqueIds.length));

      // Assert ranges:
      // Adhans: 1000..1699
      for (final id in fakeNotif.scheduledCalls
          .where((c) => c['type'] == 'prayer')
          .map((c) => c['id'] as int)) {
        expect(id >= 1000 && id < 1700, isTrue);
      }

      // Pre-prayers: 2000..2699
      for (final id in fakeNotif.scheduledCalls
          .where((c) => c['type'] == 'pre_prayer')
          .map((c) => c['id'] as int)) {
        expect(id >= 2000 && id < 2700, isTrue);
      }

      // Iqama: 3000..3699
      for (final id in fakeNotif.scheduledCalls
          .where((c) => c['type'] == 'iqama')
          .map((c) => c['id'] as int)) {
        expect(id >= 3000 && id < 3700, isTrue);
      }

      // Adhkar IDs (301, 302, 303) are never used by prayer schedule
      expect(uniqueIds.contains(AdhkarReminderService.idMorning), isFalse);
      expect(uniqueIds.contains(AdhkarReminderService.idEvening), isFalse);
      expect(uniqueIds.contains(AdhkarReminderService.idSleep), isFalse);

      // Instant alert IDs (700..710 and 750..760) are never used for scheduled alarms
      for (int i = 700; i <= 760; i++) {
        expect(uniqueIds.contains(i), isFalse);
      }
    });

    test('Preserves actively sounding prayer when refreshing schedule', () async {
      // Create a scenario where Dhuhr is currently active (diff is 30 seconds ago)
      final dhuhrTime = DateTime(2026, 10, 19, 12, 15);
      final activeNow = dhuhrTime.add(const Duration(seconds: 30));
      final dynamicPrayerTimes = FakePrayerTimeService(() => activeNow);
      final dynamicScheduleService = PrayerScheduleService(
        notificationService: fakeNotif,
        prayerTimeService: dynamicPrayerTimes,
        now: () => activeNow,
      );

      final day = await dynamicPrayerTimes.getPrayerTimesDay(date: activeNow);
      await dynamicScheduleService.refreshSchedulesIfNeeded(day: day, force: true);

      // The active prayer is Dhuhr (index 2: Fajr=0, Sunrise skipped, Dhuhr=2)
      // Notification ID 1002 must NOT be in cancelledIds
      expect(fakeNotif.cancelledIds.contains(1002), isFalse);
      expect(fakeNotif.cancelledIds.contains(702), isFalse);
    });

    test('cancelActivePrayerAlertsOnly does not cancel scheduled future alarms', () async {
      await fakeNotif.cancelActivePrayerAlertsOnly();

      // Only cancels 700..710 and 750..760
      for (final id in fakeNotif.cancelledIds) {
        expect((id >= 700 && id <= 710) || (id >= 750 && id <= 760), isTrue);
      }
      // Zero 7-day scheduled alarms cancelled
      expect(fakeNotif.cancelledIds.any((id) => id >= 1000 && id < 5000), isFalse);
    });
  });

  group('Daily Adhkar Notifications Verification', () {
    test('Adhkar reminders use isolated IDs 301, 302, 303 with default morning/evening/sleep times', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeNotif = FakeNotificationService();
      final adhkarService = AdhkarReminderService(notificationService: fakeNotif);

      final settings = await adhkarService.getSettings();
      expect(settings.morningHour, equals(6));
      expect(settings.morningMinute, equals(30));
      expect(settings.eveningHour, equals(17));
      expect(settings.sleepHour, equals(22));

      expect(AdhkarReminderService.idMorning, equals(301));
      expect(AdhkarReminderService.idEvening, equals(302));
      expect(AdhkarReminderService.idSleep, equals(303));
    });
  });
}
