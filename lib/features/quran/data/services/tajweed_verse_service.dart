import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches `text_uthmani_tajweed` from Quran.com (cached per surah/ayah).
class TajweedVerseService {
  TajweedVerseService._();

  static final Map<String, String> _ayahCache = {};
  static final Map<int, Map<int, String>> _surahCache = {};

  static Future<String?> getAyahMarkup(int surah, int ayah) async {
    final key = '$surah:$ayah';
    if (_ayahCache.containsKey(key)) {
      return _ayahCache[key];
    }

    final surahMap = await getSurahMarkups(surah);
    return surahMap[ayah];
  }

  static Future<Map<int, String>> getSurahMarkups(int surah) async {
    if (_surahCache.containsKey(surah)) {
      return _surahCache[surah]!;
    }

    final map = <int, String>{};
    try {
      final uri = Uri.parse(
        'https://api.quran.com/api/v4/verses/by_chapter/$surah'
        '?per_page=300&words=false&fields=text_uthmani_tajweed',
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8)); // ui-lint: allow network timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final verses = data['verses'] as List<dynamic>? ?? [];
        for (final raw in verses) {
          final verse = raw as Map<String, dynamic>;
          final ayah = verse['verse_number'] as int?;
          final markup = verse['text_uthmani_tajweed'] as String?;
          if (ayah != null && markup != null && markup.isNotEmpty) {
            map[ayah] = markup;
            _ayahCache['$surah:$ayah'] = markup;
          }
        }
      }
    } catch (_) {}

    _surahCache[surah] = map;
    return map;
  }

  static void clearMemoryCache() {
    _ayahCache.clear();
    _surahCache.clear();
  }
}
