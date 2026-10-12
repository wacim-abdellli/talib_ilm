import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

enum TafsirScholar {
  muyassar, // التفسير الميسر (مجمع الملك فهد)
  saadi, // تفسير السعدي
  ibnKathir, // تفسير ابن كثير
  baghawi, // تفسير البغوي
  englishIbnKathir, // English Ibn Kathir & Translation
}

const Duration _kApiTimeout = Duration(seconds: 4); // ui-lint: allow network timeout

class WordMeaning {
  final String word;
  final String meaning;
  final String? morphology;
  final String? transliteration;

  const WordMeaning({
    required this.word,
    required this.meaning,
    this.morphology,
    this.transliteration,
  });
}

class QuranTafsirService {
  static final Map<String, String> _memCache = {};

  static String getScholarName(TafsirScholar scholar) {
    switch (scholar) {
      case TafsirScholar.muyassar:
        return 'التفسير الميسر';
      case TafsirScholar.saadi:
        return 'تفسير السعدي';
      case TafsirScholar.ibnKathir:
        return 'تفسير ابن كثير';
      case TafsirScholar.englishIbnKathir:
        return 'English (Tafsir & Translation)';
      case TafsirScholar.baghawi:
        return 'تفسير البغوي';
    }
  }

  static String getScholarAuthor(TafsirScholar scholar) {
    switch (scholar) {
      case TafsirScholar.muyassar:
        return 'مجمع الملك فهد لطباعة المصحف الشريف';
      case TafsirScholar.saadi:
        return 'الشيخ عبد الرحمن بن ناصر السعدي';
      case TafsirScholar.ibnKathir:
        return 'الحافظ ابن كثير الدمشقي';
      case TafsirScholar.englishIbnKathir:
        return 'Hafiz Ibn Kathir (English translation)';
      case TafsirScholar.baghawi:
        return 'الإمام الحسين بن مسعود البغوي';
    }
  }

  /// Quran.com v4 tafsir resource IDs (see /resources/tafsirs).
  static int _getTafsirId(TafsirScholar scholar) {
    switch (scholar) {
      case TafsirScholar.muyassar:
        return 16;
      case TafsirScholar.saadi:
        return 91;
      case TafsirScholar.ibnKathir:
        return 14;
      case TafsirScholar.englishIbnKathir:
        return 169;
      case TafsirScholar.baghawi:
        return 94;
    }
  }

  /// Fetches Tafsir for an Ayah with multi-layer caching (RAM -> SharedPreferences -> Network)
  static Future<String> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    TafsirScholar scholar = TafsirScholar.muyassar,
  }) async {
    final cacheKey =
        'tafsir_v2_${scholar.name}_${surahNumber}_$ayahNumber';

    // 1. In-memory RAM cache (instant 0ms)
    if (_memCache.containsKey(cacheKey)) {
      return _memCache[cacheKey]!;
    }

    // 2. Persistent SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      _memCache[cacheKey] = cached;
      return cached;
    }

    // 3. High-speed Quran API with clean text parsing
    try {
      final tafsirId = _getTafsirId(scholar);
      final url = Uri.parse(
        'https://api.quran.com/api/v4/tafsirs/$tafsirId/by_ayah/$surahNumber:$ayahNumber',
      );

      final response = await http
          .get(url, headers: {
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 talib_ilm/1.0',
          })
          .timeout(_kApiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawText = data['tafsir']?['text'] as String? ?? '';
        final cleanText = _cleanHtml(rawText);

        if (cleanText.isNotEmpty) {
          _memCache[cacheKey] = cleanText;
          await prefs.setString(cacheKey, cleanText);
          return cleanText;
        }
      }
    } catch (_) {}

    // 4. Offline fallback using local bundled Quran translations
    final fallback = quran.getVerseTranslation(surahNumber, ayahNumber);
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'تفسير هذه الآية الكريمة: ${quran.getVerse(surahNumber, ayahNumber, verseEndSymbol: false)}';
  }

  static final Map<String, List<WordMeaning>> _wordsCache = {};

  /// Fetches real word-by-word data from Quran.com API with dual RAM + storage caching.
  static Future<List<WordMeaning>> fetchWordMeanings(
    int surahNumber,
    int ayahNumber,
  ) async {
    final cacheKey = 'wbw_${surahNumber}_$ayahNumber';
    if (_wordsCache.containsKey(cacheKey)) {
      return _wordsCache[cacheKey]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final decoded = json.decode(cachedJson) as List;
        final list = decoded
            .map((item) => WordMeaning(
                  word: item['w'] as String,
                  meaning: item['m'] as String,
                  transliteration: item['t'] as String?,
                ))
            .toList();
        if (list.isNotEmpty) {
          _wordsCache[cacheKey] = list;
          return list;
        }
      } catch (_) {}
    }

    try {
      final url = Uri.parse(
        'https://api.quran.com/api/v4/verses/by_key/$surahNumber:$ayahNumber?words=true&word_fields=text_uthmani,translation',
      );
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 talib_ilm/1.0',
      }).timeout(_kApiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawWords = data['verse']?['words'] as List? ?? [];
        final List<WordMeaning> result = [];
        final List<Map<String, String?>> forStorage = [];

        for (final w in rawWords) {
          if (w['char_type_name'] == 'end') continue;
          final arabic =
              w['text_uthmani'] as String? ?? w['text'] as String? ?? '';
          final translation = w['translation']?['text'] as String? ?? '';
          final translit = w['transliteration']?['text'] as String?;

          if (arabic.isNotEmpty) {
            result.add(WordMeaning(
              word: arabic,
              meaning: translation,
              transliteration: translit,
            ));
            forStorage.add({'w': arabic, 'm': translation, 't': translit});
          }
        }

        if (result.isNotEmpty) {
          _wordsCache[cacheKey] = result;
          await prefs.setString(cacheKey, json.encode(forStorage));
          return result;
        }
      }
    } catch (_) {}

    return getWordMeanings(surahNumber, ayahNumber);
  }

  /// Extracts word-by-word list for an Ayah (sync fallback)
  static List<WordMeaning> getWordMeanings(int surahNumber, int ayahNumber) {
    final cacheKey = 'wbw_${surahNumber}_$ayahNumber';
    if (_wordsCache.containsKey(cacheKey)) {
      return _wordsCache[cacheKey]!;
    }

    final verse = quran.getVerse(surahNumber, ayahNumber, verseEndSymbol: false);
    final words = verse.split(' ');
    final translation = quran.getVerseTranslation(surahNumber, ayahNumber);

    return words.map((w) {
      return WordMeaning(
        word: w,
        meaning: translation,
        morphology: 'سورة ${quran.getSurahNameArabic(surahNumber)}: آية $ayahNumber',
      );
    }).toList();
  }

  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
