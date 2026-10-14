import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerNotificationMode & AdhanSettings Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('PrayerNotificationMode enum has all required options', () {
      expect(PrayerNotificationMode.values, contains(PrayerNotificationMode.adhan));
      expect(PrayerNotificationMode.values, contains(PrayerNotificationMode.takbeer));
      expect(PrayerNotificationMode.values, contains(PrayerNotificationMode.tone));
      expect(PrayerNotificationMode.values, contains(PrayerNotificationMode.silent));
      expect(PrayerNotificationMode.values, contains(PrayerNotificationMode.off));
    });

    test('AdhanSettings modeForPrayer returns correct mode per prayer', () {
      final settings = AdhanSettings(
        enabled: true,
        sound: AdhanSound.takbeer,
        silentNotifications: false,
        prayerToggles: {
          'الفجر': true,
          'الظهر': false,
          'العصر': true,
          'المغرب': true,
          'العشاء': true,
        },
        calculationMethod: 'mwl',
        volume: 80.0,
        notifyBeforeMinutes: 15.0,
        iqamaReminders: false,
        adjustments: {},
        defaultMode: PrayerNotificationMode.takbeer,
        prayerModes: {
          'الفجر': PrayerNotificationMode.adhan,
          'العصر': PrayerNotificationMode.tone,
          'المغرب': PrayerNotificationMode.silent,
        },
      );

      // Explicit custom modes
      expect(settings.modeForPrayer('الفجر'), PrayerNotificationMode.adhan);
      expect(settings.modeForPrayer('العصر'), PrayerNotificationMode.tone);
      expect(settings.modeForPrayer('المغرب'), PrayerNotificationMode.silent);

      // Fallback to defaultMode when not explicitly customized
      expect(settings.modeForPrayer('العشاء'), PrayerNotificationMode.takbeer);

      // Toggled off
      expect(settings.modeForPrayer('الظهر'), PrayerNotificationMode.off);

      // When global enabled = false, everything is off
      final disabledSettings = settings.copyWith(enabled: false);
      expect(disabledSettings.modeForPrayer('الفجر'), PrayerNotificationMode.off);
      expect(disabledSettings.modeForPrayer('العشاء'), PrayerNotificationMode.off);
    });

    test('AdhanSettingsService saves and retrieves full notification configuration', () async {
      final service = AdhanSettingsService();
      final initial = await service.getSettings();
      expect(initial.defaultMode, PrayerNotificationMode.adhan);

      final updated = initial.copyWith(
        enabled: true,
        sound: AdhanSound.takbeer,
        defaultMode: PrayerNotificationMode.takbeer,
        prayerModes: {
          'الفجر': PrayerNotificationMode.adhan,
          'الظهر': PrayerNotificationMode.silent,
          'العصر': PrayerNotificationMode.tone,
        },
      );

      await service.saveSettings(updated);

      final loaded = await service.getSettings();
      expect(loaded.enabled, true);
      expect(loaded.sound, AdhanSound.takbeer);
      expect(loaded.defaultMode, PrayerNotificationMode.takbeer);
      expect(loaded.modeForPrayer('الفجر'), PrayerNotificationMode.adhan);
      expect(loaded.modeForPrayer('الظهر'), PrayerNotificationMode.silent);
      expect(loaded.modeForPrayer('العصر'), PrayerNotificationMode.tone);
    });
  });
}
