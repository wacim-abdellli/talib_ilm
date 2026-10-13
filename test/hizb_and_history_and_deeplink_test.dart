import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/models/hizb_catalog.dart';
import 'package:talib_ilm/features/quran/data/services/quran_deep_link_service.dart';
import 'package:talib_ilm/features/quran/data/services/reading_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Hizb Navigation & Boundary Tests (King Fahd Complex Benchmark)', () {
    test('Contains exactly 60 Ahzab across the Holy Quran', () {
      final hizbs = HizbCatalog.getAllHizbs();
      expect(hizbs.length, equals(60));

      for (int i = 1; i <= 60; i++) {
        final hizb = hizbs[i - 1];
        expect(hizb.hizbNumber, equals(i));
        expect(hizb.nameArabic, isNotEmpty);
        expect(hizb.startSurah, inInclusiveRange(1, 114));
        expect(hizb.startPage, inInclusiveRange(1, 604));
        expect(hizb.firstVerseSnippet, isNotEmpty);
        expect(hizb.quarters.length, equals(4)); // Each Hizb has 4 quarters
      }
    });

    test('Each Hizb contains exactly 4 Rub el Hizb quarters totaling 240 quarters', () {
      final hizbs = HizbCatalog.getAllHizbs();
      int totalQuarters = 0;

      for (final h in hizbs) {
        totalQuarters += h.quarters.length;
        for (int q = 1; q <= 4; q++) {
          final quarter = h.quarters[q - 1];
          expect(quarter.quarterInHizb, equals(q));
          expect(quarter.hizbNumber, equals(h.hizbNumber));
          expect(quarter.page, inInclusiveRange(1, 604));
          expect(quarter.titleArabic, isNotEmpty);
        }
      }

      expect(totalQuarters, equals(240));
    });

    test('Milestone Hizb boundaries match King Fahd Complex Madinah Mushaf', () {
      final h1 = HizbCatalog.getHizb(1);
      expect(h1.startSurah, equals(1)); // Al-Fatihah
      expect(h1.startAyah, equals(1));
      expect(h1.startPage, equals(1));
      expect(h1.juzNumber, equals(1));

      final h2 = HizbCatalog.getHizb(2);
      expect(h2.startSurah, equals(2)); // Al-Baqarah 75
      expect(h2.startAyah, equals(75));
      expect(h2.startPage, equals(11));
      expect(h2.juzNumber, equals(1));

      final h3 = HizbCatalog.getHizb(3); // Start of Juz 2
      expect(h3.startSurah, equals(2));
      expect(h3.startAyah, equals(142));
      expect(h3.startPage, equals(22));
      expect(h3.juzNumber, equals(2));

      final h60 = HizbCatalog.getHizb(60); // Surah Al-A'la
      expect(h60.startSurah, equals(87));
      expect(h60.startAyah, equals(1));
      expect(h60.startPage, equals(591));
      expect(h60.juzNumber, equals(30));
    });

    test('getHizb throws RangeError on invalid numbers', () {
      expect(() => HizbCatalog.getHizb(0), throwsRangeError);
      expect(() => HizbCatalog.getHizb(61), throwsRangeError);
    });
  });

  group('ReadingHistoryService Tests', () {
    test('Records reading item and caps entries at 50', () async {
      await ReadingHistoryService.clearHistory();

      for (int i = 1; i <= 60; i++) {
        await ReadingHistoryService.recordReading(
          surah: (i % 114) + 1,
          ayah: 1,
          page: i,
        );
      }

      final history = await ReadingHistoryService.getHistory();
      expect(history.length, equals(50)); // Capped at max 50
      expect(history.first.page, equals(60)); // Most recent on top
    });

    test('clearHistory removes all entries and resets state', () async {
      await ReadingHistoryService.recordReading(surah: 1, ayah: 1, page: 1);
      expect((await ReadingHistoryService.getHistory()).isNotEmpty, isTrue);

      await ReadingHistoryService.clearHistory();
      expect((await ReadingHistoryService.getHistory()).isEmpty, isTrue);
    });
  });

  group('QuranDeepLinkService Tests', () {
    test('parses valid page deep link', () {
      final res = QuranDeepLinkService.parse(Uri.parse('talibilm://quran/page/42'));
      expect(res.isValid, isTrue);
      expect(res.page, equals(42));
    });

    test('parses valid surah deep link', () {
      final res = QuranDeepLinkService.parse(Uri.parse('talibilm://quran/surah/18'));
      expect(res.isValid, isTrue);
      expect(res.surah, equals(18));
      expect(res.page, equals(293)); // Al-Kahf starts at page 293
    });

    test('parses valid surah and ayah deep link', () {
      final res = QuranDeepLinkService.parse(Uri.parse('talibilm://quran/surah/2/ayah/255'));
      expect(res.isValid, isTrue);
      expect(res.surah, equals(2));
      expect(res.ayah, equals(255));
      expect(res.page, equals(42)); // Ayat al-Kursi is on page 42
    });

    test('parses valid juz deep link', () {
      final res = QuranDeepLinkService.parse(Uri.parse('talibilm://quran/juz/30'));
      expect(res.isValid, isTrue);
      expect(res.surah, equals(78)); // An-Naba
      expect(res.page, equals(582));
    });

    test('parses valid hizb deep link', () {
      final res = QuranDeepLinkService.parse(Uri.parse('talibilm://quran/hizb/60'));
      expect(res.isValid, isTrue);
      expect(res.surah, equals(87));
      expect(res.page, equals(591));
    });

    test('rejects out of bounds and malformed deep links', () {
      // Invalid scheme
      final r1 = QuranDeepLinkService.parse(Uri.parse('https://quran/page/1'));
      expect(r1.isValid, isFalse);

      // Page out of bounds (605)
      final r2 = QuranDeepLinkService.parse(Uri.parse('talibilm://quran/page/605'));
      expect(r2.isValid, isFalse);
      expect(r2.errorMessage, contains('الصفحة غير صالح'));

      // Surah out of bounds (115)
      final r3 = QuranDeepLinkService.parse(Uri.parse('talibilm://quran/surah/115'));
      expect(r3.isValid, isFalse);

      // Ayah out of bounds for Al-Fatihah (8 when max is 7)
      final r4 = QuranDeepLinkService.parse(Uri.parse('talibilm://quran/surah/1/ayah/8'));
      expect(r4.isValid, isFalse);
      expect(r4.errorMessage, contains('الآية غير صالح'));

      // Juz out of bounds (31)
      final r5 = QuranDeepLinkService.parse(Uri.parse('talibilm://quran/juz/31'));
      expect(r5.isValid, isFalse);

      // Hizb out of bounds (61)
      final r6 = QuranDeepLinkService.parse(Uri.parse('talibilm://quran/hizb/61'));
      expect(r6.isValid, isFalse);
    });
  });
}
