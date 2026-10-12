import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:talib_ilm/features/quran/data/models/quran_reader_index.dart';

void main() {
  group('QuranReaderIndex Tests', () {
    final index = QuranReaderIndex.instance;

    test('Contains exactly 6236 ayahs and 114 surahs', () {
      expect(index.ayahItems.length, equals(6236));
      expect(quran.totalSurahCount, equals(114));

      // Check all 114 Surahs have indices
      for (int s = 1; s <= 114; s++) {
        final surahIdx = index.indexOfSurah(s);
        expect(surahIdx, isNotNull);
        expect(surahIdx! >= 0, isTrue);

        final verseCount = quran.getVerseCount(s);
        for (int a = 1; a <= verseCount; a++) {
          final ayahIdx = index.indexOfAyah(s, a);
          expect(ayahIdx, isNotNull);
          final item = index[ayahIdx!];
          expect(item, isA<QuranReaderAyahItem>());
          final ayahItem = item as QuranReaderAyahItem;
          expect(ayahItem.surahNumber, equals(s));
          expect(ayahItem.ayahNumber, equals(a));
        }
      }
    });

    test('Contains exactly 30 Juz headers across the Quran', () {
      final juzHeaders = index.items.whereType<QuranReaderJuzHeaderItem>().toList();
      expect(juzHeaders.length, equals(30));
      for (int j = 1; j <= 30; j++) {
        expect(juzHeaders.any((h) => h.juzNumber == j), isTrue);
      }
    });

    test('Basmalah present for all surahs except Al-Fatihah (1) and At-Tawbah (9)', () {
      final basmalahs = index.items.whereType<QuranReaderBasmalahItem>().toList();
      expect(basmalahs.length, equals(112));
      expect(basmalahs.any((b) => b.surahNumber == 1), isFalse);
      expect(basmalahs.any((b) => b.surahNumber == 9), isFalse);
    });

    test('getPageNumber consistency on milestone verses', () {
      // Al-Fatihah 1:1 -> page 1
      final idxFatihah = index.indexOfAyah(1, 1)!;
      final posFatihah = index.positionAt(idxFatihah);
      expect(posFatihah.surah, equals(1));
      expect(posFatihah.ayah, equals(1));
      expect(posFatihah.page, equals(1));
      expect(posFatihah.juz, equals(1));

      // Ayat al-Kursi (2:255) -> page 42
      final idxKursi = index.indexOfAyah(2, 255)!;
      final posKursi = index.positionAt(idxKursi);
      expect(posKursi.surah, equals(2));
      expect(posKursi.ayah, equals(255));
      expect(posKursi.page, equals(42));
      expect(posKursi.juz, equals(3));

      // Surat An-Nas (114:6) -> page 604
      final idxNas = index.indexOfAyah(114, 6)!;
      final posNas = index.positionAt(idxNas);
      expect(posNas.surah, equals(114));
      expect(posNas.ayah, equals(6));
      expect(posNas.page, equals(604));
      expect(posNas.juz, equals(30));
    });

    test('offsetForAyah and indexForOffset monotonic consistency', () {
      final offsetFatihah = index.offsetForAyah(1, 1)!;
      final offsetKursi = index.offsetForAyah(2, 255)!;
      final offsetNas = index.offsetForAyah(114, 6)!;

      expect(offsetFatihah < offsetKursi, isTrue);
      expect(offsetKursi < offsetNas, isTrue);

      final idxFound = index.indexForOffset(offsetKursi);
      final kursiIdx = index.indexOfAyah(2, 255)!;
      expect(idxFound, equals(kursiIdx));
    });
  });
}
