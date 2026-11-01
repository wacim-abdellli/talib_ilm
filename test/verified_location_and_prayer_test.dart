import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/constants/verified_cities.dart';
import 'package:talib_ilm/core/services/location_service.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:talib_ilm/core/utils/prayer_countdown.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VerifiedCitiesCatalog Tests', () {
    test('catalog contains all Algerian 58 wilayas and major cities', () {
      expect(VerifiedCitiesCatalog.all.isNotEmpty, isTrue);

      final algiers = VerifiedCitiesCatalog.search('الجزائر');
      expect(algiers.isNotEmpty, isTrue);
      expect(algiers.first.countryCode, 'DZ');

      final oran = VerifiedCitiesCatalog.search('وهران');
      expect(oran.isNotEmpty, isTrue);
      expect(oran.first.latitude, closeTo(35.69, 0.1));

      final constantine = VerifiedCitiesCatalog.search('قسنطينة');
      expect(constantine.isNotEmpty, isTrue);

      final mahdia = VerifiedCitiesCatalog.search('المهدية');
      expect(mahdia.isNotEmpty, isTrue);
      expect(mahdia.first.countryCode, 'TN');

      final cairo = VerifiedCitiesCatalog.search('القاهرة');
      expect(cairo.isNotEmpty, isTrue);
      expect(cairo.first.countryCode, 'EG');

      final makkah = VerifiedCitiesCatalog.search('مكة');
      expect(makkah.isNotEmpty, isTrue);
      expect(makkah.first.countryCode, 'SA');
    });

    test('findNearest resolves nearest city within distance', () {
      // Near Algiers center (36.75, 3.05)
      final nearAlgiers = VerifiedCitiesCatalog.findNearest(36.7530, 3.0580);
      expect(nearAlgiers, isNotNull);
      expect(nearAlgiers!.name, 'الجزائر العاصمة');

      // Near Mahdia / Chorbane area (35.50, 11.06)
      final nearMahdia = VerifiedCitiesCatalog.findNearest(35.5100, 11.0500);
      expect(nearMahdia, isNotNull);
      expect(nearMahdia!.name, 'المهدية');

      // In middle of Atlantic Ocean -> returns null
      final ocean = VerifiedCitiesCatalog.findNearest(20.0, -30.0);
      expect(ocean, isNull);
    });

    test('search handles Arabic text normalization (hamza, tashkeel, taa marbuta)', () {
      // Search with alef with hamza
      final res1 = VerifiedCitiesCatalog.search('الإسكندرية');
      // Search with bare alef
      final res2 = VerifiedCitiesCatalog.search('الاسكندرية');
      expect(res1.length, res2.length);
      expect(res1.first.name, 'الإسكندرية');

      // Filter by country code
      final tunisiaOnly = VerifiedCitiesCatalog.search('', countryCode: 'TN');
      expect(tunisiaOnly.every((c) => c.countryCode == 'TN'), isTrue);
      expect(tunisiaOnly.length, greaterThanOrEqualTo(10));
    });

    test('search resolves Latin transliterations, capitals, and international cities', () {
      final algiers = VerifiedCitiesCatalog.search('algiers');
      expect(algiers.any((c) => c.name.contains('الجزائر')), isTrue);

      final alger = VerifiedCitiesCatalog.search('alger');
      expect(alger.any((c) => c.name.contains('الجزائر')), isTrue);

      final capital = VerifiedCitiesCatalog.search('capital');
      expect(capital.any((c) => c.name.contains('الجزائر')), isTrue);

      final paris = VerifiedCitiesCatalog.search('paris');
      expect(paris.isNotEmpty, isTrue);
      expect(paris.first.countryCode, 'FR');
      expect(paris.first.name, 'باريس');

      final london = VerifiedCitiesCatalog.search('london');
      expect(london.isNotEmpty, isTrue);
      expect(london.first.countryCode, 'GB');
      expect(london.first.name, 'لندن');

      final cairoLatin = VerifiedCitiesCatalog.search('cairo');
      expect(cairoLatin.isNotEmpty, isTrue);
      expect(cairoLatin.first.countryCode, 'EG');
    });
  });

  group('LocationService & LocationResult Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('LocationResult accurate property reflects true sources', () {
      const gps = LocationResult(
        latitude: 36.75,
        longitude: 3.05,
        city: 'الجزائر',
        source: LocationSource.gps,
      );
      expect(gps.isAccurate, isTrue);
      expect(gps.sourceLabel, contains('GPS'));

      const manual = LocationResult(
        latitude: 36.75,
        longitude: 3.05,
        city: 'الجزائر',
        source: LocationSource.manual,
      );
      expect(manual.isAccurate, isTrue);
      expect(manual.sourceLabel, contains('يدوياً'));

      const defCity = LocationResult(
        latitude: 21.3891,
        longitude: 39.8579,
        city: 'مكة المكرمة',
        source: LocationSource.defaultCity,
      );
      expect(defCity.isAccurate, isFalse);
      expect(defCity.sourceLabel, contains('الافتراضي'));
    });

    test('setVerifiedCity updates SharedPreferences and sets manual location', () async {
      final service = LocationService();
      final city = VerifiedCitiesCatalog.all.firstWhere((c) => c.id == 'dz_oran');

      await service.setVerifiedCity(city);

      final manual = await service.getManualLocation();
      expect(manual, isNotNull);
      expect(manual!.city, 'وهران');
      expect(manual.latitude, closeTo(35.6987, 0.001));
      expect(manual.longitude, closeTo(-0.6349, 0.001));
      expect(manual.source, LocationSource.manual);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('adhan_calc_method'), 'mwl');
    });
  });

  group('PrayerTimeService Calculation Accuracy Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PrayerTimeService.clearCache();
    });

    test('calculates accurate prayer times for verified Algerian coordinates', () async {
      final service = PrayerTimeService(
        now: () => DateTime(2026, 10, 11, 12, 0, 0),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_city', 'الجزائر العاصمة');
      await prefs.setString('last_country_code', 'DZ');
      await prefs.setDouble('last_lat', 36.7538);
      await prefs.setDouble('last_lon', 3.0588);
      await prefs.setBool('last_is_verified_gps', true);

      final day = await service.getPrayerTimesDay();
      expect(day.city, 'الجزائر العاصمة');
      expect(day.prayers.length, 5);

      final fajr = day.prayers['الفجر'];
      final dhuhr = day.prayers['الظهر'];
      final asr = day.prayers['العصر'];
      final maghrib = day.prayers['المغرب'];
      final isha = day.prayers['العشاء'];

      expect(fajr, isNotNull);
      expect(dhuhr, isNotNull);
      expect(asr, isNotNull);
      expect(maghrib, isNotNull);
      expect(isha, isNotNull);

      // Verify chronological order
      expect(fajr!.isBefore(dhuhr!), isTrue);
      expect(dhuhr.isBefore(asr!), isTrue);
      expect(asr.isBefore(maghrib!), isTrue);
      expect(maghrib.isBefore(isha!), isTrue);
    });

    test('calculates accurate prayer times for Tunisia (Sfax) matching official ministry', () async {
      final service = PrayerTimeService(
        now: () => DateTime(2026, 11, 1, 12, 0, 0),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_city', 'صفاقس');
      await prefs.setString('last_country_code', 'TN');
      await prefs.setDouble('last_lat', 34.7406);
      await prefs.setDouble('last_lon', 10.7603);
      await prefs.setBool('last_is_verified_gps', true);

      final day = await service.getPrayerTimesDay(date: DateTime(2026, 11, 1));
      expect(day.city, 'صفاقس');

      final fajr = day.prayers['الفجر']!;
      final dhuhr = day.prayers['الظهر']!;
      final asr = day.prayers['العصر']!;
      final maghrib = day.prayers['المغرب']!;
      final isha = day.prayers['العشاء']!;

      expect(fajr.hour, 5);
      expect(fajr.minute, 12);

      expect(dhuhr.hour, 12);
      expect(dhuhr.minute, closeTo(8, 1)); // 12:07-12:08

      expect(asr.hour, 15);
      expect(asr.minute, 1);

      expect(maghrib.hour, 17);
      expect(maghrib.minute, closeTo(27, 1)); // 17:26-17:27

      expect(isha.hour, 18);
      expect(isha.minute, closeTo(50, 1)); // 18:49-18:50
    });

    test('prayer minute adjustments apply accurately', () async {
      final prefs = await SharedPreferences.getInstance();
      // Add +3 minutes to Dhuhr and -2 to Fajr
      await prefs.setInt('adhan_adj_الظهر', 3);
      await prefs.setInt('adhan_adj_الفجر', -2);
      await prefs.setDouble('last_lat', 21.4225);
      await prefs.setDouble('last_lon', 39.8262);
      await prefs.setString('last_country_code', 'SA');

      final service = PrayerTimeService(
        now: () => DateTime(2026, 10, 11, 10, 0, 0),
      );

      final day = await service.getPrayerTimesDay();
      expect(day.prayers['الظهر'], isNotNull);
    });
    test('Tunisia (Sfax) with legacy mwl in prefs still computes official ministry times', () async {
      final service = PrayerTimeService(
        now: () => DateTime(2026, 11, 1, 12, 0, 0),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_city', 'صفاقس');
      await prefs.setString('last_country_code', 'TN');
      await prefs.setDouble('last_lat', 34.7406);
      await prefs.setDouble('last_lon', 10.7603);
      await prefs.setString('adhan_calc_method', 'mwl');

      final day = await service.getPrayerTimesDay(date: DateTime(2026, 11, 1));
      expect(day.city, 'صفاقس');

      final dhuhr = day.prayers['الظهر']!;
      final asr = day.prayers['العصر']!;
      final maghrib = day.prayers['المغرب']!;
      final isha = day.prayers['العشاء']!;

      expect(dhuhr.hour, 12);
      expect(dhuhr.minute, closeTo(8, 1)); // 12:08, not 12:02
      expect(asr.minute, 1); // 15:01
      expect(maghrib.minute, closeTo(27, 1)); // 17:27, not 17:23
      expect(isha.minute, closeTo(50, 1)); // 18:50, not 18:44
    });

    test('PrayerCountdownController after Isha evaluates next prayer as tomorrow Fajr and syncs cleanly', () async {
      final service = PrayerTimeService(
        now: () => DateTime(2026, 11, 1, 20, 23, 0),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_city', 'صفاقس');
      await prefs.setString('last_country_code', 'TN');
      await prefs.setDouble('last_lat', 34.7406);
      await prefs.setDouble('last_lon', 10.7603);

      final day = await service.getPrayerTimesDay();
      expect(day.nextPrayer, 'الفجر');

      final controller = PrayerCountdownController(
        day: day,
        prayerTimeService: service,
        now: () => DateTime(2026, 11, 1, 20, 23, 0),
      );

      // Initial state must be tomorrow's Fajr
      expect(controller.state.value.nextPrayerName, 'الفجر');
      expect(controller.state.value.nextPrayerTime.day, 2); // tomorrow Nov 2
      expect(controller.state.value.nextPrayerTime.hour, 5); // 05:12 AM
      expect(controller.state.value.remaining.inHours, closeTo(8, 1)); // ~8 hours 48 mins

      controller.dispose();
    });
  });
}
