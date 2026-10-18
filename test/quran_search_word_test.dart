import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:quran/quran.dart' as quran;
import 'package:talib_ilm/core/utils/arabic_search_utils.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_ayah_search_card.dart';

List<Map<String, dynamic>> _performAyahSearch(String query) {
  final searchResult = searchWords(query, limit: 100);
  final rawList = searchResult['result'] as List? ?? const [];
  final results = <Map<String, dynamic>>[];
  for (final raw in rawList) {
    if (raw is Map) {
      results.add({
        'sora': (raw['sora'] as num).toInt(),
        'aya_no': (raw['aya_no'] as num).toInt(),
        'text': raw['text']?.toString(),
      });
    }
  }
  return results;
}

void main() {
  group('Quran Word & Ayah Search Tests', () {
    test('compute background search works without blocking', () async {
      final res = await compute(_performAyahSearch, 'الكوثر');
      expect(res.isNotEmpty, isTrue);
      expect(res.first['sora'], 108);
      expect(res.first['aya_no'], 1);
    });

    test('Arabic word matching in ayah finds Al-Kawthar', () {
      final res = searchWords('الكوثر', limit: 5);
      expect(res['occurences'], greaterThan(0));
      final first = (res['result'] as List).first as Map<String, dynamic>;
      final sora = (first['sora'] as num).toInt();
      final aya = (first['aya_no'] as num).toInt();
      expect(sora, 108);
      expect(aya, 1);

      final verseText = quran.getVerse(sora, aya, verseEndSymbol: false);
      final words = verseText.split(RegExp(r'\s+'));
      final matchedWords = words
          .where((w) => ArabicSearchUtils.matches(w, 'الكوثر'))
          .toList();
      expect(matchedWords.length, 1);
      expect(matchedWords.first, contains('الْكَوْثَرَ'));
    });

    test('Phrase search works for multi-word queries', () {
      final res = searchWords('إياك نعبد', limit: 5);
      expect(res['occurences'], greaterThan(0));
      final first = (res['result'] as List).first as Map<String, dynamic>;
      final sora = (first['sora'] as num).toInt();
      final aya = (first['aya_no'] as num).toInt();
      expect(sora, 1);
      expect(aya, 5);
    });

    test('QuranAyahMatch model holds expected metadata and page numbers', () {
      final match = QuranAyahMatch(
        surahNumber: 1,
        ayahNumber: 5,
        pageNumber: quran.getPageNumber(1, 5),
        juzNumber: quran.getJuzNumber(1, 5),
        surahName: quran.getSurahNameArabic(1),
        verseText: quran.getVerse(1, 5, verseEndSymbol: false),
        query: 'إياك',
      );

      expect(match.surahNumber, 1);
      expect(match.ayahNumber, 5);
      expect(match.pageNumber, 1);
      expect(match.juzNumber, 1);
      expect(match.surahName, 'الفاتحة');
      expect(match.query, 'إياك');
    });

    test('Diacritic agnostic search matches variants with and without tashkeel', () {
      final resWithTashkeel = searchWords('الرَّحْمَٰنِ', limit: 10);
      final resWithoutTashkeel = searchWords('الرحمن', limit: 10);
      expect(resWithTashkeel['occurences'], greaterThan(0));
      expect(resWithoutTashkeel['occurences'], greaterThan(0));
    });
  });
}
