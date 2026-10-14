import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/core/services/foreground_prayer_service.dart';
import 'package:talib_ilm/core/services/location_service.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLocationService extends LocationService {
  final LocationResult result;
  MockLocationService(this.result);

  @override
  Future<LocationResult> getLocation({bool autoPrompt = true}) async {
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prayer Calculation Calibration Tests', () {
    test('Algeria (DZ) calculates Isha with 18° twilight matching official ministry calendar', () async {
      SharedPreferences.setMockInitialValues({});
      // Algiers coordinates
      final mockLocation = MockLocationService(
        const LocationResult(
          latitude: 36.7538,
          longitude: 3.0588,
          city: 'الجزائر العاصمة',
          country: 'الجزائر',
          countryCode: 'DZ',
          source: LocationSource.savedGps,
        ),
      );

      final service = PrayerTimeService(
        locationService: mockLocation,
        now: () => DateTime(2026, 10, 14, 12, 0),
      );

      final day = await service.getPrayerTimesDay(date: DateTime(2026, 10, 14));
      final isha = day.prayers[AppStrings.prayerIsha]!;

      // At 18.0° twilight on Oct 14 in Algiers (GMT+1), Isha is at 19:39 (rather than 19:34 at 17.0°)
      expect(isha.hour, 19);
      expect(isha.minute, 39);
    });

    test('AdhanSettings defaults to enabled with algeria calculation method option', () async {
      SharedPreferences.setMockInitialValues({});
      final settingsService = AdhanSettingsService();
      final settings = await settingsService.getSettings();

      expect(settings.enabled, isTrue);
      expect(AdhanSettingsService.calculationMethods.containsKey('algeria'), isTrue);
    });
  });

  group('ForegroundPrayerService Tests', () {
    test('ForegroundPrayerService singleton instantiates and dismissAlert resets activeAlert', () async {
      SharedPreferences.setMockInitialValues({});
      final foreground = ForegroundPrayerService();
      expect(foreground, isNotNull);

      foreground.activeAlert.value = ActivePrayerAlert(
        prayerName: AppStrings.prayerDhuhr,
        prayerTime: DateTime.now(),
        mode: PrayerNotificationMode.adhan,
        sound: AdhanSound.qatami,
      );

      expect(foreground.activeAlert.value, isNotNull);
      await foreground.dismissAlert();
      expect(foreground.activeAlert.value, isNull);
    });
  });
}
