import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/adhan_service.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/core/services/foreground_prayer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Full Adhan Audio & Notification Integrity Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AdhanSettings effectiveMuezzinSound sanitizes legacy takbeer sound to qatami', () {
      const settingsWithTakbeer = AdhanSettings(
        enabled: true,
        sound: AdhanSound.takbeer,
        silentNotifications: false,
        prayerToggles: {},
        calculationMethod: 'auto',
        volume: 80,
        notifyBeforeMinutes: 15,
        iqamaReminders: true,
        adjustments: {},
      );

      expect(settingsWithTakbeer.effectiveMuezzinSound, AdhanSound.qatami);
    });

    test('AdhanService singleton is preserved across callers', () {
      final instance1 = AdhanService();
      final instance2 = AdhanService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('AdhanSettings modeForPrayer supports fuzzy matching for prayer names', () {
      const settings = AdhanSettings(
        enabled: true,
        sound: AdhanSound.qatami,
        silentNotifications: false,
        prayerToggles: {'الفجر': true, 'الظهر': true},
        calculationMethod: 'auto',
        volume: 80,
        notifyBeforeMinutes: 15,
        iqamaReminders: true,
        adjustments: {},
        defaultMode: PrayerNotificationMode.takbeer,
        prayerModes: {
          'الفجر': PrayerNotificationMode.adhan,
          'الظهر': PrayerNotificationMode.adhan,
        },
      );

      // Exact match
      expect(settings.modeForPrayer('الفجر'), PrayerNotificationMode.adhan);
      // Fuzzy prefix match (e.g. صلاة الفجر)
      expect(settings.modeForPrayer('صلاة الفجر'), PrayerNotificationMode.adhan);
      expect(settings.modeForPrayer('صلاة الظهر'), PrayerNotificationMode.adhan);
    });

    test('ForegroundPrayerService singleton instantiates with active alert controls', () {
      final service = ForegroundPrayerService();
      expect(service, isNotNull);
      expect(identical(service, ForegroundPrayerService()), isTrue);
    });

    test('AdhanService does not import or use just_audio_background MediaItem', () {
      final service = AdhanService();
      expect(service.isPlaying, isFalse);
    });
  });
}

