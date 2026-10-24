import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/core/services/notification_service.dart';
import 'package:talib_ilm/core/services/prayer_schedule_service.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class RecordingNotificationService extends NotificationService {
  final List<String> eventLog = [];
  final List<int> scheduledPrayerIds = [];
  int cancelCount = 0;
  bool simulateFailure = false;
  ScheduleOutcomeStatus failureType = ScheduleOutcomeStatus.failed;

  @override
  Future<void> init() async {}

  @override
  Future<void> cancelPrayerNotificationsOnly({Set<int>? preserveIds}) async {
    cancelCount++;
    eventLog.add('cancel_start');
    await Future.delayed(const Duration(milliseconds: 20));
    eventLog.add('cancel_end');
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
        errorMessage: 'Simulated failure for $id',
        notificationId: id,
      );
    }
    scheduledPrayerIds.add(id);
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
    return ScheduleOutcome(
      status: ScheduleOutcomeStatus.exact,
      notificationId: id,
    );
  }
}

class TestPrayerTimeService extends PrayerTimeService {
  final DateTime Function() _mockNow;
  String currentCity = 'الجزائر العاصمة';

  TestPrayerTimeService(this._mockNow) : super(now: _mockNow);

  @override
  Future<PrayerTimesDay> getPrayerTimesDay({
    DateTime? date,
    bool forceRefresh = false,
  }) async {
    final d = date ?? _mockNow();
    final prayers = <String, DateTime>{
      AppStrings.prayerFajr: DateTime(d.year, d.month, d.day, 5, 15),
      'الشروق': DateTime(d.year, d.month, d.day, 6, 45),
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

  group('Finding C30: Prayer Scheduling Multi-Instance Serialization', () {
    late DateTime fixedNow;
    late RecordingNotificationService notificationService;
    late TestPrayerTimeService prayerTimeService;
    late AdhanSettingsService adhanSettingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fixedNow = DateTime(2026, 10, 24, 8, 0);
      notificationService = RecordingNotificationService();
      prayerTimeService = TestPrayerTimeService(() => fixedNow);
      adhanSettingsService = AdhanSettingsService();
      PrayerScheduleService.resetSharedStateForTesting();
    });

    test(
      'two distinct service instances refresh concurrently: serialized via shared lock so second sees up-to-date cache',
      () async {
        final instance1 = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );
        final instance2 = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );

        final results = await Future.wait([
          instance1.refreshSchedulesIfNeeded(force: false),
          instance2.refreshSchedulesIfNeeded(force: false),
        ]);

        // Exactly one instance runs the full 7-day schedule; the other sees fresh cache and returns 0 attempted
        final attemptedCounts = results.map((r) => r.totalAttempted).toList();
        expect(attemptedCounts.where((c) => c > 0).length, equals(1));
        expect(attemptedCounts.where((c) => c == 0).length, equals(1));

        // Cancellation should NOT interleave or duplicate
        expect(notificationService.cancelCount, equals(1));
      },
    );

    test(
      'forced refresh overlapping normal refresh on distinct instances executes safely',
      () async {
        final instance1 = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );
        final instance2 = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );

        final results = await Future.wait([
          instance1.refreshSchedulesIfNeeded(force: false),
          instance2.refreshSchedulesIfNeeded(force: true),
        ]);

        // Both complete without failure
        expect(results[0].failed, equals(0));
        expect(results[1].failed, equals(0));
        expect(results[1].totalAttempted, greaterThan(0));
      },
    );

    test(
      'settings change while a refresh is pending is picked up by subsequent instance',
      () async {
        final instance1 = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );
        final instance2 = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );

        // First run initial schedule
        await instance1.refreshSchedulesIfNeeded(force: false);
        final prefs = await SharedPreferences.getInstance();
        final initialFingerprint = prefs.getString('prayer_schedule_fingerprint');

        // Now modify settings in SharedPreferences
        final currentSettings = await adhanSettingsService.getSettings();
        await adhanSettingsService.saveSettings(
          currentSettings.copyWith(
            calculationMethod: 'umm_al_qura',
          ),
        );

        // Second instance refresh should detect settings change and update fingerprint
        final result2 = await instance2.refreshSchedulesIfNeeded(force: false);
        expect(result2.totalAttempted, greaterThan(0));

        final updatedFingerprint = prefs.getString('prayer_schedule_fingerprint');
        expect(updatedFingerprint, isNot(equals(initialFingerprint)));
      },
    );

    test(
      'mid-batch failure in instance1 does NOT store fingerprint, allowing instance2 to retry and succeed',
      () async {
        notificationService.simulateFailure = true;

        final instance1 = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );
        final instance2 = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );

        final result1 = await instance1.refreshSchedulesIfNeeded(force: false);
        expect(result1.isSuccess, isFalse);
        expect(result1.failed, greaterThan(0));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('prayer_schedule_fingerprint'), isNull);

        // Instance 2 attempts recovery
        notificationService.simulateFailure = false;
        final result2 = await instance2.refreshSchedulesIfNeeded(force: false);
        expect(result2.isSuccess, isTrue);
        expect(result2.failed, equals(0));
        expect(prefs.getString('prayer_schedule_fingerprint'), isNotNull);
      },
    );

    test(
      'location change while refresh is pending updates to new city with fresh fingerprint',
      () async {
        final instance1 = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );
        final instance2 = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );

        // Run initial schedule for Algiers
        await instance1.refreshSchedulesIfNeeded(force: false);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('prayer_schedule_location'), equals('الجزائر العاصمة'));

        // Change location to Oran
        prayerTimeService.currentCity = 'وهران';

        // Run second instance with forced refresh to simulate location update
        final result2 = await instance2.refreshSchedulesIfNeeded(force: true);
        expect(result2.isSuccess, isTrue);
        expect(prefs.getString('prayer_schedule_location'), equals('وهران'));
      },
    );

    test(
      'permission denied outcome does NOT store success fingerprint and flags failure',
      () async {
        notificationService.simulateFailure = true;
        notificationService.failureType = ScheduleOutcomeStatus.permissionDenied;

        final instance = PrayerScheduleService(
          notificationService: notificationService,
          prayerTimeService: prayerTimeService,
          adhanSettingsService: adhanSettingsService,
          now: () => fixedNow,
        );

        final result = await instance.refreshSchedulesIfNeeded(force: true);
        expect(result.isSuccess, isFalse);
        expect(result.failed, greaterThan(0));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('prayer_schedule_fingerprint'), isNull);
      },
    );
  });
}
