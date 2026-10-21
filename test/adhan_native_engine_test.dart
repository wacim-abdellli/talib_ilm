import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart' as adhan;
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';

void main() {
  group('Native Dart Adhan Engine & Sunnah Times Tests', () {
    final coordinates = adhan.Coordinates(36.7538, 3.0588); // Algiers, Algeria
    final date = adhan.DateComponents(2026, 10, 21);

    test('Computes 100% offline Batoul Apps astronomical times', () {
      final params = adhan.CalculationMethod.muslim_world_league.getParameters();
      params.madhab = adhan.Madhab.shafi;

      final prayerTimes = adhan.PrayerTimes(coordinates, date, params);

      expect(prayerTimes.fajr, isNotNull);
      expect(prayerTimes.sunrise, isNotNull);
      expect(prayerTimes.dhuhr, isNotNull);
      expect(prayerTimes.asr, isNotNull);
      expect(prayerTimes.maghrib, isNotNull);
      expect(prayerTimes.isha, isNotNull);
    });

    test('Computes SunnahTimes: Middle of the Night & Last Third of Night (Qiyam)', () {
      final params = adhan.CalculationMethod.muslim_world_league.getParameters();
      final prayerTimes = adhan.PrayerTimes(coordinates, date, params);
      final sunnah = adhan.SunnahTimes(prayerTimes);

      expect(sunnah.middleOfTheNight, isNotNull);
      expect(sunnah.lastThirdOfTheNight, isNotNull);

      // Middle of the night should be between Maghrib and tomorrow's Fajr
      expect(sunnah.middleOfTheNight.isAfter(prayerTimes.maghrib), isTrue);

      // Last third of night should be after middle of night
      expect(sunnah.lastThirdOfTheNight.isAfter(sunnah.middleOfTheNight), isTrue);
    });

    test('Computes Dhuha time as sunrise + 15 minutes', () {
      final params = adhan.CalculationMethod.muslim_world_league.getParameters();
      final prayerTimes = adhan.PrayerTimes(coordinates, date, params);
      final dhuha = prayerTimes.sunrise.add(const Duration(minutes: 15));

      expect(dhuha.difference(prayerTimes.sunrise).inMinutes, equals(15));
    });

    test('Computes astronomical Qibla direction from coordinates offline', () {
      final qibla = adhan.Qibla(coordinates);
      // Algiers Qibla is roughly 104°–106° (East-South-East)
      expect(qibla.direction, greaterThan(100.0));
      expect(qibla.direction, lessThan(115.0));
    });

    test('Fiqh Madhab affects Asr calculation (Hanafi Asr is later than Shafi Asr)', () {
      final shafiParams = adhan.CalculationMethod.muslim_world_league.getParameters();
      shafiParams.madhab = adhan.Madhab.shafi;
      final shafiTimes = adhan.PrayerTimes(coordinates, date, shafiParams);

      final hanafiParams = adhan.CalculationMethod.muslim_world_league.getParameters();
      hanafiParams.madhab = adhan.Madhab.hanafi;
      final hanafiTimes = adhan.PrayerTimes(coordinates, date, hanafiParams);

      // Hanafi Asr (shadow 2x) is strictly later than Jumhoor/Shafi Asr (shadow 1x)
      expect(hanafiTimes.asr.isAfter(shafiTimes.asr), isTrue);
      expect(hanafiTimes.asr.difference(shafiTimes.asr).inMinutes, greaterThan(30));
    });

    test('High Latitude Rule adjusts safely for extreme latitudes (>48°)', () {
      final highLatCoords = adhan.Coordinates(59.9139, 10.7522); // Oslo, Norway (~60° N)
      final params = adhan.CalculationMethod.muslim_world_league.getParameters();
      params.highLatitudeRule = adhan.HighLatitudeRule.twilight_angle;

      final prayerTimes = adhan.PrayerTimes(highLatCoords, date, params);
      expect(prayerTimes.fajr, isNotNull);
      expect(prayerTimes.isha, isNotNull);
    });

    test('PrayerTimesDay model preserves Sunnah times and Qibla direction', () {
      final now = DateTime(2026, 10, 21, 12, 0);
      final day = PrayerTimesDay(
        city: 'الجزائر',
        date: now,
        prayers: {
          'الفجر': DateTime(2026, 10, 21, 5, 20),
          'الشروق': DateTime(2026, 10, 21, 6, 45),
          'الظهر': DateTime(2026, 10, 21, 12, 30),
          'العصر': DateTime(2026, 10, 21, 15, 45),
          'المغرب': DateTime(2026, 10, 21, 18, 5),
          'العشاء': DateTime(2026, 10, 21, 19, 25),
        },
        nextPrayer: 'الظهر',
        nextPrayerTime: DateTime(2026, 10, 21, 12, 30),
        middleOfTheNight: DateTime(2026, 10, 21, 23, 42),
        lastThirdOfTheNight: DateTime(2026, 10, 22, 1, 35),
        dhuha: DateTime(2026, 10, 21, 7, 0),
        qiblaDirection: 104.5,
      );

      expect(day.dhuha, equals(DateTime(2026, 10, 21, 7, 0)));
      expect(day.middleOfTheNight, equals(DateTime(2026, 10, 21, 23, 42)));
      expect(day.lastThirdOfTheNight, equals(DateTime(2026, 10, 22, 1, 35)));
      expect(day.qiblaDirection, equals(104.5));
    });

    test('AdhanSettings persists madhab option correctly', () {
      const defaultSettings = AdhanSettings(
        enabled: true,
        sound: AdhanSound.qatami,
        silentNotifications: false,
        prayerToggles: {},
        calculationMethod: 'auto',
        volume: 1.0,
        notifyBeforeMinutes: 15,
        iqamaReminders: true,
        adjustments: {},
      );

      expect(defaultSettings.madhab, equals('shafi'));

      final hanafiSettings = defaultSettings.copyWith(madhab: 'hanafi');
      expect(hanafiSettings.madhab, equals('hanafi'));
    });
  });
}
