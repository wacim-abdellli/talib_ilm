import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_solar_stations_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PrayerTimeService.clearCache();
  });

  group('Shuruk, Dhuha, Middle of Night & Last Third Audit', () {
    test('Computes exact Shuruk, Dhuha start/end, Middle of Night, Last Third across major cities', () async {
      final cities = [
        (name: 'صفاقس', code: 'TN', lat: 34.7406, lon: 10.7603, method: 'tunisia', dhuhrMargin: 6),
        (name: 'تونس', code: 'TN', lat: 36.8065, lon: 10.1815, method: 'tunisia', dhuhrMargin: 6),
        (name: 'مكة المكرمة', code: 'SA', lat: 21.4225, lon: 39.8262, method: 'umm_al_qura', dhuhrMargin: 0),
        (name: 'الجزائر العاصمة', code: 'DZ', lat: 36.7538, lon: 3.0588, method: 'algeria', dhuhrMargin: 1),
        (name: 'القاهرة', code: 'EG', lat: 30.0444, lon: 31.2357, method: 'egyptian', dhuhrMargin: 1),
      ];

      for (final c in cities) {
        SharedPreferences.setMockInitialValues({
          'last_city': c.name,
          'last_country_code': c.code,
          'last_lat': c.lat,
          'last_lon': c.lon,
          'adhan_calc_method': c.method,
        });
        PrayerTimeService.clearCache();

        final service = PrayerTimeService(now: () => DateTime(2026, 11, 16, 8, 0));
        final today = await service.getPrayerTimesDay(date: DateTime(2026, 11, 16));
        final tomorrow = await service.getPrayerTimesDay(date: DateTime(2026, 11, 17));

        final fajrToday = today.prayers[AppStrings.prayerFajr]!;
        final maghribToday = today.prayers[AppStrings.prayerMaghrib]!;
        final dhuhrToday = today.prayers[AppStrings.prayerDhuhr]!;
        final fajrTomorrow = tomorrow.prayers[AppStrings.prayerFajr]!;

        final sunrise = today.sunrise!;
        final dhuha = today.dhuha!;
        final dhuhaEnd = today.dhuhaEnd!;
        final mid = today.middleOfTheNight!;
        final third = today.lastThirdOfTheNight!;

        final nightSecs = fajrTomorrow.difference(maghribToday).inSeconds;
        final expectedMid = maghribToday.add(Duration(seconds: nightSecs ~/ 2));
        final expectedThird = fajrTomorrow.subtract(Duration(seconds: nightSecs ~/ 3));

        expect(sunrise.isAfter(fajrToday), isTrue);
        expect(dhuha.difference(sunrise).inMinutes, 15);
        expect(dhuhrToday.difference(dhuhaEnd).inMinutes, 10 + c.dhuhrMargin);
        expect((mid.difference(expectedMid).inMinutes).abs(), lessThanOrEqualTo(1));
        expect((third.difference(expectedThird).inMinutes).abs(), lessThanOrEqualTo(1));
      }
    });

    test('Pre-Fajr live evaluation (00:00 -> Fajr) uses active current Islamic night (yesterday Maghrib -> today Fajr)', () async {
      SharedPreferences.setMockInitialValues({
        'last_city': 'صفاقس',
        'last_country_code': 'TN',
        'last_lat': 34.7406,
        'last_lon': 10.7603,
        'adhan_calc_method': 'tunisia',
      });
      PrayerTimeService.clearCache();

      // 02:30 AM on Nov 16 (before Fajr ~05:24)
      final preFajrService = PrayerTimeService(now: () => DateTime(2026, 11, 16, 2, 30));
      final liveDay = await preFajrService.getPrayerTimesDay();
      final fajrToday = liveDay.prayers[AppStrings.prayerFajr]!;

      expect(liveDay.middleOfTheNight!.day, 15);
      expect(liveDay.middleOfTheNight!.isBefore(DateTime(2026, 11, 16, 2, 30)), isTrue);
      expect(liveDay.lastThirdOfTheNight!.day, 16);
      expect(liveDay.lastThirdOfTheNight!.isBefore(fajrToday), isTrue);
      expect(liveDay.lastThirdOfTheNight!.isBefore(DateTime(2026, 11, 16, 2, 30)), isTrue);
    });

    testWidgets('PrayerSolarStationsCard marks Dhuha active at 08:30 AM and passed at 12:30 PM cleanly at scale 2.0', (tester) async {
      final sunrise = DateTime(2026, 11, 16, 6, 52);
      final dhuha = DateTime(2026, 11, 16, 7, 7);
      final dhuhaEnd = DateTime(2026, 11, 16, 11, 52);
      final sunset = DateTime(2026, 11, 16, 17, 14);
      final mid = DateTime(2026, 11, 16, 23, 20);
      final third = DateTime(2026, 11, 17, 1, 21);

      // 08:30 AM -> Shuruk passed, Dhuha active ("الآن")
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: PrayerSolarStationsCard(
                    sunrise: sunrise,
                    sunset: sunset,
                    dhuha: dhuha,
                    dhuhaEnd: dhuhaEnd,
                    middleOfTheNight: mid,
                    lastThirdOfTheNight: third,
                    nowOverride: DateTime(2026, 11, 16, 8, 30),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('الآن'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 12:30 PM -> Dhuha passed ("الآن" gone)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: PrayerSolarStationsCard(
                sunrise: sunrise,
                sunset: sunset,
                dhuha: dhuha,
                dhuhaEnd: dhuhaEnd,
                middleOfTheNight: mid,
                lastThirdOfTheNight: third,
                nowOverride: DateTime(2026, 11, 16, 12, 30),
              ),
            ),
          ),
        ),
      );

      expect(find.text('الآن'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PrayerSolarStationsCard marks Last Third active during Qiyam (02:00 AM)', (tester) async {
      final fajr = DateTime(2026, 11, 16, 5, 24);
      final sunrise = DateTime(2026, 11, 16, 6, 52);
      final dhuha = DateTime(2026, 11, 16, 7, 7);
      final dhuhaEnd = DateTime(2026, 11, 16, 11, 52);
      final mid = DateTime(2026, 11, 15, 23, 19);
      final third = DateTime(2026, 11, 16, 1, 21);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: PrayerSolarStationsCard(
                sunrise: sunrise,
                dhuha: dhuha,
                dhuhaEnd: dhuhaEnd,
                fajr: fajr,
                middleOfTheNight: mid,
                lastThirdOfTheNight: third,
                nowOverride: DateTime(2026, 11, 16, 2, 0),
              ),
            ),
          ),
        ),
      );

      expect(find.text('الآن'), findsOneWidget);
      expect(find.text('الآن · قيام الليل والسحر'), findsOneWidget);
    });
  });
}
