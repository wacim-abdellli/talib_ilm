import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/core/services/location_service.dart';
import 'package:talib_ilm/core/services/prayer_notification_details_builder.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';

class _AlgiersLocationService extends LocationService {
  @override
  Future<LocationResult> getLocation({bool autoPrompt = false}) async =>
      const LocationResult(
        latitude: 36.7538,
        longitude: 3.0588,
        city: 'الجزائر العاصمة',
        country: 'الجزائر',
        countryCode: 'DZ',
        source: LocationSource.savedGps,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'iOS alert sounds are CAF resources selected by the notification builder',
    () async {
      const soundNames = [
        'adhan_makkah',
        'adhan_madinah',
        'adhan_alafasy',
        'adhan_abdulbasit',
        'adhan_qatami',
        'adhan_aqsa',
        'adhan_takbeer',
        'adhan_announcement_fajr',
        'adhan_announcement_dhuhr',
        'adhan_announcement_asr',
        'adhan_announcement_maghrib',
        'adhan_announcement_isha',
        'adhan_announcement_general',
      ];

      for (final name in soundNames) {
        final file = File('ios/Runner/NotificationSounds/$name.caf');
        expect(
          await file.exists(),
          isTrue,
          reason: '$name must be an iOS resource',
        );
        expect(
          await file.length(),
          lessThan(350000),
          reason: '$name must stay under the 30-second sound budget',
        );
        final header = await file
            .openRead(0, 4)
            .expand((bytes) => bytes)
            .toList();
        expect(
          String.fromCharCodes(header),
          'caff',
          reason: '$name must be CAF',
        );
      }

      expect(
        PrayerNotificationDetailsBuilder.buildDarwinPrayerDetails(
          mode: PrayerNotificationMode.adhan,
          sound: AdhanSound.qatami,
        ).sound,
        'adhan_qatami.caf',
      );
      expect(
        PrayerNotificationDetailsBuilder.buildDarwinPrayerDetails(
          mode: PrayerNotificationMode.announcement,
          sound: AdhanSound.qatami,
          prayerName: AppStrings.prayerFajr,
        ).sound,
        'adhan_announcement_fajr.caf',
      );
    },
  );

  test(
    'Algiers calculation stays within three minutes of an official ministry day',
    () async {
      SharedPreferences.setMockInitialValues({'adhan_calc_method': 'algeria'});
      final service = PrayerTimeService(
        locationService: _AlgiersLocationService(),
        now: () => DateTime(2022, 8, 12, 12),
      );
      final day = await service.getPrayerTimesDay(date: DateTime(2022, 8, 12));
      final officialMinutes = <String, int>{
        AppStrings.prayerFajr: 4 * 60 + 26,
        AppStrings.prayerDhuhr: 12 * 60 + 53,
        AppStrings.prayerAsr: 16 * 60 + 39,
        AppStrings.prayerMaghrib: 19 * 60 + 46,
        AppStrings.prayerIsha: 21 * 60 + 14,
      };

      // Official Ministry of Religious Affairs calendar, Algiers, 12 Aug 2022:
      // https://marw.gov.dz/media/calendrier/1444/alger.pdf
      final officialIsha = 21 * 60 + 14;
      final calculatedIsha =
          day.prayers[AppStrings.prayerIsha]!.hour * 60 +
          day.prayers[AppStrings.prayerIsha]!.minute;
      expect((calculatedIsha - officialIsha).abs(), lessThanOrEqualTo(1));

      for (final entry in officialMinutes.entries) {
        final actual = day.prayers[entry.key]!;
        final actualMinutes = actual.hour * 60 + actual.minute;
        expect(
          (actualMinutes - entry.value).abs(),
          lessThanOrEqualTo(3),
          reason: '${entry.key} differs from the published ministry calendar',
        );
      }
    },
  );
}
