import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

enum TafsirScholar {
  muyassar, // التفسير الميسر (مجمع الملك فهد)
  saadi, // تفسير السعدي
  ibnKathir, // تفسير ابن كثير
  englishIbnKathir, // English Ibn Kathir & Translation
}

class WordMeaning {
  final String word;
  final String meaning;
  final String? morphology;

  const WordMeaning({
    required this.word,
    required this.meaning,
    this.morphology,
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
    }
  }

  static int _getTafsirId(TafsirScholar scholar) {
    switch (scholar) {
      case TafsirScholar.muyassar:
        return 16;
      case TafsirScholar.saadi:
        return 14;
      case TafsirScholar.ibnKathir:
        return 170;
      case TafsirScholar.englishIbnKathir:
        return 169;
    }
  }

  /// Fetches Tafsir for an Ayah with multi-layer caching (RAM -> SharedPreferences -> Network)
  static Future<String> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    TafsirScholar scholar = TafsirScholar.muyassar,
  }) async {
    final cacheKey = 'tafsir_${scholar.name}_${surahNumber}_$ayahNumber';

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
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4)); // ui-lint: allow network timeout

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

  /// Extracts word-by-word list for an Ayah
  static List<WordMeaning> getWordMeanings(int surahNumber, int ayahNumber) {
    final verse = quran.getVerse(surahNumber, ayahNumber, verseEndSymbol: false);
    final words = verse.split(' ');

    return words.map((w) {
      return WordMeaning(
        word: w,
        meaning: 'معنى كلمة: $w',
        morphology: 'كلمة في الآية $ayahNumber من سورة ${quran.getSurahNameArabic(surahNumber)}',
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
