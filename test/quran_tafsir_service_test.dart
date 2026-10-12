import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/services/quran_tafsir_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranTafsirService WordMeanings Tests', () {
    test('does not return fake placeholder verse translations when cache is empty', () async {
      SharedPreferences.setMockInitialValues({});

      // In an offline/mock environment where network is not returning words,
      // it must return empty list, NOT repeated verse translations.
      final words = await QuranTafsirService.fetchWordMeanings(1, 1);
      for (final w in words) {
        expect(w.meaning, isNot(equals('In the name of Allah, the Entirely Merciful, the Especially Merciful.')));
      }
    });

    test('loads cached word meanings from SharedPreferences', () async {
      final sampleWords = [
        {'w': 'بِسْمِ', 'm': 'In the name', 't': "bis'mi"},
        {'w': 'اللَّهِ', 'm': 'of Allah', 't': 'Allahi'},
      ];
      SharedPreferences.setMockInitialValues({
        'wbw_1_1': json.encode(sampleWords),
      });

      final words = await QuranTafsirService.fetchWordMeanings(1, 1);
      expect(words.length, 2);
      expect(words[0].word, 'بِسْمِ');
      expect(words[0].meaning, 'In the name');
      expect(words[0].transliteration, "bis'mi");
      expect(words[1].word, 'اللَّهِ');
      expect(words[1].meaning, 'of Allah');

      // Check synchronous RAM cache helper
      final cached = QuranTafsirService.getCachedWordMeanings(1, 1);
      expect(cached, isNotNull);
      expect(cached!.length, 2);
    });
  });
}
