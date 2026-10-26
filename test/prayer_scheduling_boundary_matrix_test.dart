import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/core/services/notification_service.dart';
import 'package:talib_ilm/core/services/prayer_schedule_service.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class MockableNotificationService extends NotificationService {
  final List<Map<String, dynamic>> scheduledCalls = [];
  bool simulateFailure = false;
  bool simulateAdhkarFailure = false;
  bool exactAlarmsAllowed = true;
  int adhkarScheduleCalls = 0;
  ScheduleOutcomeStatus failureType = ScheduleOutcomeStatus.failed;

  @override
  Future<void> init() async {}

  @override
  Future<void> cancelPrayerNotificationsOnly({Set<int>? preserveIds}) async {}

  @override
  Future<bool> arePermissionsGranted() async => true;

  @override
  Future<bool?> canScheduleExactNotifications() async => exactAlarmsAllowed;

  @override
  Future<bool> tryCancelNotification(int id) async => true;

  @override
  Future<ScheduleOutcome> scheduleDailyAdhkarNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    adhkarScheduleCalls++;
    if (simulateAdhkarFailure) {
      return ScheduleOutcome(
        status: ScheduleOutcomeStatus.failed,
        errorMessage: 'Simulated Adhkar failure for id $id',
        notificationId: id,
      );
    }
    return ScheduleOutcome(
      status: ScheduleOutcomeStatus.exact,
      notificationId: id,
    );
  }

  @override
  Future<ScheduleOutcome> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
    bool isJumua = false,
  }) async {
    if (simulateFailure) {
      return ScheduleOutcome(
        status: failureType,
        errorMessage: 'Simulated failure for id $id',
        notificationId: id,
      );
    }
    scheduledCalls.add({
      'type': 'prayer',
      'id': id,
      'prayerName': prayerName,
      'time': scheduledTime,
      'mode': mode,
    });
    return ScheduleOutcome(
      status: ScheduleOutcomeStatus.exact,
      notificationId: id,
    );
  }

  @override
  Future<ScheduleOutcome> schedulePrePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required int minutesBefore,
    bool isJumua = false,
  }) async {
    if (simulateFailure) {
      return ScheduleOutcome(
        status: failureType,
        errorMessage: 'Simulated pre-prayer failure for id $id',
        notificationId: id,
      );
    }
    scheduledCalls.add({
      'type': 'pre_prayer',
      'id': id,
      'prayerName': prayerName,
      'time': scheduledTime,
    });
    return ScheduleOutcome(
      status: ScheduleOutcomeStatus.exact,
      notificationId: id,
    );
  }

  @override
  Future<ScheduleOutcome> scheduleIqamaNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    bool isJumua = false,
  }) async {
    if (simulateFailure) {
      return ScheduleOutcome(
        status: failureType,
        errorMessage: 'Simulated iqama failure for id $id',
        notificationId: id,
      );
    }
    scheduledCalls.add({
      'type': 'iqama',
      'id': id,
      'prayerName': prayerName,
      'time': scheduledTime,
    });
    return ScheduleOutcome(
      status: ScheduleOutcomeStatus.exact,
      notificationId: id,
    );
  }

  @override
  Future<ScheduleOutcome> scheduleSurahAlKahfNotification({
    required int id,
    required DateTime scheduledTime,
  }) async {
    if (simulateFailure) {
      return ScheduleOutcome(
        status: failureType,
        errorMessage: 'Simulated kahf failure for id $id',
        notificationId: id,
      );
    }
    scheduledCalls.add({'type': 'surah_kahf', 'id': id, 'time': scheduledTime});
    return ScheduleOutcome(
      status: ScheduleOutcomeStatus.exact,
      notificationId: id,
    );
  }
}

class ControllablePrayerTimeService extends PrayerTimeService {
  final DateTime Function() _mockNow;
  int fajrOffsetMinutes = 0;
  String currentCity = 'الجزائر العاصمة';

  ControllablePrayerTimeService(this._mockNow) : super(now: _mockNow);

  @override
  Future<PrayerTimesDay> getPrayerTimesDay({
    DateTime? date,
    bool forceRefresh = false,
  }) async {
    final d = date ?? _mockNow();
    final prayers = <String, DateTime>{
      AppStrings.prayerFajr: DateTime(
        d.year,
        d.month,
        d.day,
        5,
        10 + fajrOffsetMinutes,
      ),
      'الشروق': DateTime(d.year, d.month, d.day, 6, 40),
      AppStrings.prayerDhuhr: DateTime(d.year, d.month, d.day, 12, 45),
      AppStrings.prayerAsr: DateTime(d.year, d.month, d.day, 15, 55),
      AppStrings.prayerMaghrib: DateTime(d.year, d.month, d.day, 18, 30),
      AppStrings.prayerIsha: DateTime(d.year, d.month, d.day, 19, 50),
    };
    return PrayerTimesDay(
      city: currentCity,
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

  group('T05 — Prayer Calculation & Scheduling Boundary Matrix (C11, C12)', () {
    late DateTime fixedNow;
    late MockableNotificationService notificationService;
    late ControllablePrayerTimeService prayerTimeService;
    late AdhanSettingsService adhanSettingsService;
    late PrayerScheduleService scheduleService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PrayerScheduleService.resetSharedStateForTesting();
      fixedNow = DateTime(2026, 10, 23, 4, 0); // Friday 04:00 AM before Fajr
      notificationService = MockableNotificationService();
      prayerTimeService = ControllablePrayerTimeService(() => fixedNow);
      adhanSettingsService = AdhanSettingsService();
      scheduleService = PrayerScheduleService(
        notificationService: notificationService,
        prayerTimeService: prayerTimeService,
        adhanSettingsService: adhanSettingsService,
        now: () => fixedNow,
      );
    });

    test(
      'C11: Failed schedule returns typed failure and DOES NOT persist success fingerprint, enabling retry',
      () async {
        final prefs = await SharedPreferences.getInstance();
        notificationService.simulateFailure = true;

        final result = await scheduleService.refreshSchedulesIfNeeded(
          force: true,
        );

        // Batch result correctly captures failures
        expect(result.isSuccess, isFalse);
        expect(result.failed, greaterThan(0));
        expect(result.errors, isNotEmpty);

        // Success fingerprint is NOT stored!
        expect(prefs.getString('prayer_schedule_fingerprint'), isNull);
        expect(prefs.getInt('prayer_schedule_timestamp'), isNull);

        // Now simulate recovery: failure resolves and retry runs without early-return
        notificationService.simulateFailure = false;
        final retryResult = await scheduleService.refreshSchedulesIfNeeded(
          force: false,
        );

        expect(retryResult.isSuccess, isTrue);
        expect(retryResult.exactScheduled, greaterThan(0));
        expect(prefs.getString('prayer_schedule_fingerprint'), isNotNull);
        expect(prefs.getInt('prayer_schedule_timestamp'), isNotNull);
      },
    );

    test(
      'Adhkar failures retry independently without rebuilding a healthy prayer schedule',
      () async {
        final prefs = await SharedPreferences.getInstance();
        notificationService.simulateAdhkarFailure = true;

        final first = await scheduleService.refreshSchedulesIfNeeded(
          force: true,
        );
        expect(first.isSuccess, isFalse);
        expect(first.failed, equals(3));
        expect(prefs.getString('prayer_schedule_fingerprint'), isNotNull);
        expect(prefs.getString('adhkar_schedule_fingerprint'), isNull);
        final prayerCallCount = notificationService.scheduledCalls.length;
        final prayerTimestamp = prefs.getInt('prayer_schedule_timestamp');

        notificationService.simulateAdhkarFailure = false;
        final retry = await scheduleService.refreshSchedulesIfNeeded();

        expect(retry.isSuccess, isTrue);
        expect(retry.totalAttempted, equals(3));
        expect(retry.exactScheduled, equals(3));
        expect(notificationService.adhkarScheduleCalls, equals(6));
        expect(notificationService.scheduledCalls.length, prayerCallCount);
        expect(prefs.getInt('prayer_schedule_timestamp'), prayerTimestamp);
        expect(prefs.getString('adhkar_schedule_fingerprint'), isNotNull);
      },
    );

    test(
      'granting exact-alarm permission invalidates the schedule fingerprint immediately',
      () async {
        final prefs = await SharedPreferences.getInstance();
        notificationService.exactAlarmsAllowed = false;

        await scheduleService.refreshSchedulesIfNeeded(force: true);
        final fingerprintWithoutExactAccess = prefs.getString(
          'prayer_schedule_fingerprint',
        );
        final scheduledBeforeGrant = notificationService.scheduledCalls.length;

        notificationService.exactAlarmsAllowed = true;
        final afterGrant = await scheduleService.refreshSchedulesIfNeeded();

        expect(afterGrant.totalAttempted, greaterThan(0));
        expect(
          prefs.getString('prayer_schedule_fingerprint'),
          isNot(equals(fingerprintWithoutExactAccess)),
        );
        expect(
          notificationService.scheduledCalls.length,
          greaterThan(scheduledBeforeGrant),
        );
      },
    );

    test(
      'C12: Fingerprint invalidates on calculation method, madhab, or minute adjustments even with same city',
      () async {
        final prefs = await SharedPreferences.getInstance();

        // Initial schedule
        final firstResult = await scheduleService.refreshSchedulesIfNeeded();
        expect(firstResult.isSuccess, isTrue);
        final initialFingerprint = prefs.getString(
          'prayer_schedule_fingerprint',
        );
        expect(initialFingerprint, isNotNull);

        // Immediate subsequent call with unchanged settings returns early (0 attempted)
        final earlyResult = await scheduleService.refreshSchedulesIfNeeded();
        expect(earlyResult.totalAttempted, equals(0));

        // Change minute adjustment for Fajr (+2 minutes)
        final currentSettings = await adhanSettingsService.getSettings();
        await adhanSettingsService.saveSettings(
          currentSettings.copyWith(adjustments: {AppStrings.prayerFajr: 2}),
        );

        // Schedule service must detect fingerprint invalidation and reschedule
        final adjustmentResult = await scheduleService
            .refreshSchedulesIfNeeded();
        expect(adjustmentResult.totalAttempted, greaterThan(0));
        expect(adjustmentResult.isSuccess, isTrue);
        expect(
          prefs.getString('prayer_schedule_fingerprint'),
          isNot(equals(initialFingerprint)),
        );

        // Change calculation method
        final afterAdjFingerprint = prefs.getString(
          'prayer_schedule_fingerprint',
        );
        final currentSettings2 = await adhanSettingsService.getSettings();
        await adhanSettingsService.saveSettings(
          currentSettings2.copyWith(calculationMethod: 'umm_al_qura'),
        );

        final methodResult = await scheduleService.refreshSchedulesIfNeeded();
        expect(methodResult.totalAttempted, greaterThan(0));
        expect(
          prefs.getString('prayer_schedule_fingerprint'),
          isNot(equals(afterAdjFingerprint)),
        );
      },
    );

    test(
      'C12: Fingerprint invalidates when coordinates change prayer times in the same city',
      () async {
        final prefs = await SharedPreferences.getInstance();

        await scheduleService.refreshSchedulesIfNeeded();
        final firstFingerprint = prefs.getString('prayer_schedule_fingerprint');

        // Same city name, but prayer times shifted by 3 minutes (simulating moving across coordinates)
        prayerTimeService.fajrOffsetMinutes = 3;

        final shiftedResult = await scheduleService.refreshSchedulesIfNeeded();
        expect(shiftedResult.totalAttempted, greaterThan(0));
        expect(
          prefs.getString('prayer_schedule_fingerprint'),
          isNot(equals(firstFingerprint)),
        );
      },
    );

    test(
      'C12: Civil calendar date arithmetic correctly handles multi-day schedule across month and daylight changes',
      () async {
        // Start on October 30 (month boundary + DST season)
        fixedNow = DateTime(2026, 10, 30, 8, 0);

        final result = await scheduleService.refreshSchedulesIfNeeded(
          force: true,
        );
        expect(result.isSuccess, isTrue);

        // Ensure notifications span across 7 days properly without calendar day collapse
        final prayerDates = notificationService.scheduledCalls
            .where((call) => call['type'] == 'prayer')
            .map((call) => (call['time'] as DateTime).day)
            .toSet();

        // 7 distinct calendar days must be represented
        expect(prayerDates.length, equals(7));
      },
    );

    test(
      'Concurrent refreshSchedulesIfNeeded calls serialize safely through AsyncLock without clashing',
      () async {
        final futures = List.generate(
          5,
          (_) => scheduleService.refreshSchedulesIfNeeded(force: true),
        );

        final results = await Future.wait(futures);
        for (final r in results) {
          expect(r.failed, equals(0));
        }
      },
    );
  });
}
