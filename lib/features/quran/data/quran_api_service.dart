import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/quran_models.dart';

/// Quran API Service using alquran.cloud
/// Supports: Surahs, Verses, Translations, Audio, Search
/// Responsible ONLY for network requests. Caching is handled by QuranRepository.
class QuranApiService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  // Available editions
  static const String editionUthmani = 'quran-uthmani';
  static const String editionSimple = 'quran-simple';
  static const String editionEnglish = 'en.sahih';
  static const String editionFrench = 'fr.hamidullah';

  // Available reciters
  static const String reciterAlafasy = 'ar.alafasy';
  static const String reciterMinshawi = 'ar.minshawi';
  static const String reciterHusary = 'ar.husary';
  static const String reciterAbdulbasit = 'ar.abdulbasit';

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. GET ALL SURAHS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch all 114 surahs metadata
  static Future<List<SurahMeta>> getAllSurahs() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/surah'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> surahsJson = data['data'];
      return surahsJson.map((json) => SurahMeta.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load surahs: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. GET SINGLE SURAH WITH VERSES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch a single surah with all its verses (Uthmani script)
  static Future<Surah?> getSurah(int number) async {
    return getSurahWithEdition(number, editionUthmani);
  }

  /// Fetch surah with specific edition
  static Future<Surah?> getSurahWithEdition(int number, String edition) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/surah/$number/$edition'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Surah.fromJson(data['data']);
    } else {
      throw Exception('Failed to load surah $number');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. GET SURAH WITH TRANSLATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch surah with translation
  static Future<Surah?> getSurahWithTranslation(
    int number, {
    String edition = editionEnglish,
  }) async {
    return getSurahWithEdition(number, edition);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. SEARCH QURAN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search for a keyword in the Quran
  static Future<List<QuranSearchResult>> searchQuran(
    String query, {
    String edition = editionUthmani,
  }) async {
    if (query.isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await http
          .get(Uri.parse('$_baseUrl/search/$encodedQuery/all/$edition'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['matches'] != null) {
          final List<dynamic> matches = data['data']['matches'];
          return matches
              .map((json) => QuranSearchResult.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. AUDIO URL
  // ═══════════════════════════════════════════════════════════════════════════

  static String getAudioUrl(
    int surahNumber,
    int ayahNumber, {
    String reciter = reciterAlafasy,
  }) {
    return 'https://cdn.islamic.network/quran/audio/128/$reciter/$surahNumber$ayahNumber.mp3';
  }

  static String getAudioUrlByGlobalNumber(
    int globalAyahNumber, {
    String reciter = reciterAlafasy,
  }) {
    return 'https://cdn.islamic.network/quran/audio/128/$reciter/$globalAyahNumber.mp3';
  }

  static String getSurahAudioUrl(
    int surahNumber, {
    String reciter = reciterAlafasy,
  }) {
    return 'https://cdn.islamic.network/quran/audio-surah/128/$reciter/$surahNumber.mp3';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. GET SPECIFIC AYAH
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Ayah?> getAyah(
    String reference, {
    String edition = editionUthmani,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/ayah/$reference/$edition'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Ayah.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Ayah?> getAyahByNumber(
    int surahNumber,
    int ayahNumber, {
    String edition = editionUthmani,
  }) async {
    return getAyah('$surahNumber:$ayahNumber', edition: edition);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. GET JUZS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<Juz>> getAllJuzs() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/juz'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> juzsJson = data['data'];
        return juzsJson.map((json) => Juz.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Juz?> getJuz(
    int number, {
    String edition = editionUthmani,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/juz/$number/$edition'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Juz.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. GET PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get specific page (1-604)
  static Future<List<Ayah>> getPage(
    int pageNumber, {
    String edition = editionUthmani,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/page/$pageNumber/$edition'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataMap = data['data'] as Map<String, dynamic>;
        final List<dynamic> ayahsJson = dataMap['ayahs'];
        return ayahsJson.map((json) => Ayah.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
