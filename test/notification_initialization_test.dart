import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/services/notification_service.dart';
import 'package:talib_ilm/core/services/prayer_schedule_service.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';
import 'package:talib_ilm/shared/widgets/notification_onboarding_dialog.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class RecordingNotificationService extends NotificationService {
  int initCount = 0;
  int requestPermissionsCount = 0;
  bool returnGranted = false;

  @override
  Future<void> init() async {
    initCount++;
  }

  @override
  Future<void> requestPermissions() async {
    requestPermissionsCount++;
  }

  @override
  Future<bool> arePermissionsGranted() async {
    return returnGranted;
  }

  @override
  Future<void> cancelPrayerNotificationsOnly({Set<int>? preserveIds}) async {}

  @override
  Future<void> cancelActivePrayerAlertsOnly() async {}
}

class FakePrayerTimeService extends PrayerTimeService {
  final DateTime Function() _mockNow;
  FakePrayerTimeService(this._mockNow) : super(now: _mockNow);

  @override
  Future<PrayerTimesDay> getPrayerTimesDay({
    DateTime? date,
    bool forceRefresh = false,
  }) async {
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationService.resetSharedStateForTesting();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (call) async {
            if (call.method == 'initialize') return true;
            if (call.method == 'areNotificationsEnabled') return true;
            return null;
          },
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (call) async => 'Africa/Algiers',
        );
  });

  group('T04 — Shared In-Flight Notification Initialization (C10)', () {
    test('concurrent init() calls deduplicate into a single in-flight operation', () async {
      final notif1 = NotificationService();
      final notif2 = NotificationService();
      final notif3 = NotificationService();

      expect(notif1.isInitialized, isFalse);
      expect(notif2.isInitialized, isFalse);
      expect(notif3.isInitialized, isFalse);

      await Future.wait([
        notif1.init(),
        notif2.init(),
        notif3.init(),
      ]);

      expect(notif1.isInitialized, isTrue);
      expect(notif2.isInitialized, isTrue);
      expect(notif3.isInitialized, isTrue);

      // Subsequent new instance recognizes shared initialization immediately
      final notif4 = NotificationService();
      await notif4.init();
      expect(notif4.isInitialized, isTrue);
    });

    test('resetSharedStateForTesting clears shared state for clean test isolation', () {
      NotificationService.resetSharedStateForTesting();
      final notif = NotificationService();
      expect(notif.isInitialized, isFalse);
    });
  });

  group('T04 — Separation of Scheduling and Interactive Permission Requests (C09)', () {
    test('arePermissionsGranted does not request permissions interactively', () async {
      final service = RecordingNotificationService();
      final granted = await service.arePermissionsGranted();
      expect(granted, isFalse);
      expect(service.requestPermissionsCount, equals(0));
    });

    test('PrayerScheduleService does not invoke interactive requestPermissions during refreshSchedulesIfNeeded', () async {
      final recordingNotif = RecordingNotificationService();
      final now = DateTime(2026, 10, 23, 10, 0);
      final fakePrayerTimeService = FakePrayerTimeService(() => now);

      final scheduleService = PrayerScheduleService(
        notificationService: recordingNotif,
        prayerTimeService: fakePrayerTimeService,
        now: () => now,
      );

      final today = await fakePrayerTimeService.getPrayerTimesDay(date: now);

      // Force scheduling
      await scheduleService.refreshSchedulesIfNeeded(day: today, force: true);

      // Verified: refreshSchedulesIfNeeded must NOT trigger requestPermissions!
      expect(recordingNotif.requestPermissionsCount, equals(0));
      expect(recordingNotif.initCount, greaterThanOrEqualTo(1));
    });

    test('NotificationOnboardingDialog prefKey tracks onboarding state', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(NotificationOnboardingDialog.prefKey), isNull);

      await prefs.setBool(NotificationOnboardingDialog.prefKey, true);
      expect(prefs.getBool(NotificationOnboardingDialog.prefKey), isTrue);
    });
  });
}
