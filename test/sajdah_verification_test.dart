import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

/// Official 15 Sajdah Tilawah verses in the Holy Quran according to the
/// King Fahd Glorious Quran Printing Complex (KFGQPC, Madinah Munawwarah)
/// and the classical consensus of Muslim scholars.
class OfficialSajdahVerse {
  final int surah;
  final int ayah;
  final int expectedPage;
  final String surahName;

  const OfficialSajdahVerse({
    required this.surah,
    required this.ayah,
    required this.expectedPage,
    required this.surahName,
  });
}

const List<OfficialSajdahVerse> kOfficial15SajdahVerses = [
  OfficialSajdahVerse(surah: 7, ayah: 206, expectedPage: 176, surahName: 'الأعراف'),
  OfficialSajdahVerse(surah: 13, ayah: 15, expectedPage: 251, surahName: 'الرعد'),
  OfficialSajdahVerse(surah: 16, ayah: 50, expectedPage: 272, surahName: 'النحل'),
  OfficialSajdahVerse(surah: 17, ayah: 109, expectedPage: 293, surahName: 'الإسراء'),
  OfficialSajdahVerse(surah: 19, ayah: 58, expectedPage: 309, surahName: 'مريم'),
  OfficialSajdahVerse(surah: 22, ayah: 18, expectedPage: 334, surahName: 'الحج'),
  OfficialSajdahVerse(surah: 22, ayah: 77, expectedPage: 341, surahName: 'الحج'),
  OfficialSajdahVerse(surah: 25, ayah: 60, expectedPage: 365, surahName: 'الفرقان'),
  OfficialSajdahVerse(surah: 27, ayah: 26, expectedPage: 379, surahName: 'النمل'),
  OfficialSajdahVerse(surah: 32, ayah: 15, expectedPage: 416, surahName: 'السجدة'),
  OfficialSajdahVerse(surah: 38, ayah: 24, expectedPage: 454, surahName: 'ص'),
  OfficialSajdahVerse(surah: 41, ayah: 38, expectedPage: 480, surahName: 'فصلت'),
  OfficialSajdahVerse(surah: 53, ayah: 62, expectedPage: 528, surahName: 'النجم'),
  OfficialSajdahVerse(surah: 84, ayah: 21, expectedPage: 589, surahName: 'الانشقاق'),
  OfficialSajdahVerse(surah: 96, ayah: 19, expectedPage: 598, surahName: 'العلق'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await QuranRepository.instance.ensureLoaded(604);
  });

  group('Sajdah Tilawah Verification Tests (KFGQPC Madinah Benchmark)', () {
    test('contains exactly 15 official Sajdah verses in benchmark catalog', () {
      expect(kOfficial15SajdahVerses.length, equals(15));
    });

    test('each of the 15 official Sajdah pages in QuranRepository contains the verse and triggers hasSajda', () {
      final pages = QuranRepository.instance.pages;
      expect(pages.length, equals(604));

      for (final s in kOfficial15SajdahVerses) {
        final pageIndex = s.expectedPage - 1;
        final page = pages[pageIndex];

        expect(
          page.hasSajda,
          isTrue,
          reason:
              'Page ${s.expectedPage} containing Sajdah verse ${s.surahName} (${s.surah}:${s.ayah}) must have hasSajda == true',
        );

        final containsVerse = page.ayahs.any(
          (a) => a.surahNumber == s.surah && a.ayahNumber == s.ayah,
        );
        expect(
          containsVerse,
          isTrue,
          reason:
              'Page ${s.expectedPage} in QuranRepository must contain verse ${s.surahName} (${s.surah}:${s.ayah})',
        );
      }
    });

    test('no extra unverified pages have hasSajda set to true', () {
      final pages = QuranRepository.instance.pages;
      final expectedPages = kOfficial15SajdahVerses.map((s) => s.expectedPage).toSet();

      final actualSajdaPages = <int>{};
      for (int i = 0; i < pages.length; i++) {
        if (pages[i].hasSajda) {
          actualSajdaPages.add(i + 1);
        }
      }

      // Check difference
      final unexpected = actualSajdaPages.difference(expectedPages);
      expect(
        unexpected,
        isEmpty,
        reason: 'Pages $unexpected have hasSajda flag without being in the 15 official Sajdahs',
      );

      expect(actualSajdaPages.length, equals(15));
    });
  });
}
