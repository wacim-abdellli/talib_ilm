import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../../../core/constants/app_policy.dart';
import 'catalogs/surah_fallback_catalog.dart';
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

  /// Fetch all 114 surahs metadata using quran.com API v4
  static Future<List<SurahMeta>> getAllSurahs() async {
    try {
      // Use quran.com API v4 (more reliable)
      final response = await http
          .get(Uri.parse('https://api.quran.com/api/v4/chapters'))
          .timeout(AppPolicy.networkMedium);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> chapters = data['chapters'] ?? [];
        return chapters
            .map(
              (json) => SurahMeta(
                number: json['id'],
                name: json['name_arabic'] ?? json['name_simple'],
                englishName: json['name_simple'] ?? '',
                englishNameTranslation: json['translated_name']?['name'] ?? '',
                numberOfAyahs: json['verses_count'] ?? 0,
                revelationType: json['revelation_place'] == 'makkah'
                    ? 'Meccan'
                    : 'Medinan',
              ),
            )
            .toList();
      }
    } catch (_) {}

    // Fallback to hardcoded list
    return SurahFallbackCatalog.getSurahs();
  }


  /// Load surahs from local JSON assets as fallback
  static Future<List<SurahMeta>> _loadSurahsFromAssets() async {
    // Try different paths (web vs mobile can have different requirements)
    final possiblePaths = [
      'data/quran/surahs.json',
      'assets/data/quran/surahs.json',
    ];

    for (final path in possiblePaths) {
      try {
        final String jsonString = await rootBundle.loadString(path);
        final List<dynamic> surahsJson = jsonDecode(jsonString);

        return surahsJson.map((json) {
          // Map local JSON format to SurahMeta format
          return SurahMeta(
            number: json['id'],
            name: json['nameArabic'],
            englishName: json['nameEnglish'],
            englishNameTranslation: json['nameEnglish'],
            numberOfAyahs: json['ayahCount'],
            revelationType: json['revelationType'] == 'makkah'
                ? 'Meccan'
                : 'Medinan',
          );
        }).toList();
      } catch (e) {
        // Try next path
        continue;
      }
    }

    // If all paths failed
    throw Exception(
      'Failed to load surahs from assets. Tried paths: $possiblePaths',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. GET SINGLE SURAH WITH VERSES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch a single surah with all its verses (Uthmani script)
  static Future<Surah?> getSurah(int number) async {
    try {
      return await getSurahWithEdition(number, editionUthmani);
    } catch (e) {
      // Try to load from local assets if API fails
      return _loadSurahFromAssets(number);
    }
  }

  /// Fetch surah with specific edition
  static Future<Surah?> getSurahWithEdition(int number, String edition) async {
    // QUICK LOAD STRATEGY FOR FATIHA (Surah 1)
    // Always try local asset first for Surah 1 to ensure instant load
    if (number == 1) {
      try {
        final localFatiha = await _loadSurahFromAssets(1);
        if (localFatiha != null) return localFatiha;
      } catch (_) {}
    }

    // PRIMARY SOURCE: AlQuran.Cloud API
    int attempts = 0;
    while (attempts < 2) {
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/surah/$number/$edition'))
            .timeout(
              attempts == 0 ? AppPolicy.networkFast : AppPolicy.networkRetry,
            ); // FAST TIMEOUT FIRST

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return Surah.fromJson(data['data']);
        } else {
          if (response.statusCode < 500) {
            throw Exception('Failed to load surah $number');
          }
        }
      } catch (e) {
        attempts++;
        if (attempts >= 2) break;
        await Future.delayed(AppPolicy.debounce);
      }
    }

    // SECONDARY SOURCE: Quran.com API v4
    try {
      return await _fetchFromQuranComV4(number);
    } catch (_) {
      // Ignore
    }

    // FINAL FALLBACK: Local Assets
    return _loadSurahFromAssets(number);
  }

  /// Load surah from local assets (only Al-Fatiha available)
  static Future<Surah?> _loadSurahFromAssets(int number) async {
    try {
      // Get surah metadata first (handle errors gracefully)
      SurahMeta surahMeta;
      try {
        final surahsList = await _loadSurahsFromAssets();
        surahMeta = surahsList.firstWhere((s) => s.number == number);
      } catch (_) {
        // Fallback metadata if asset list load fails
        final allHardcoded = SurahFallbackCatalog.getSurahs();
        surahMeta = allHardcoded.firstWhere((s) => s.number == number);
      }

      // Try to load local ayahs file
      for (final path in [
        'data/quran/surah_$number.json',
        'assets/data/quran/surah_$number.json',
      ]) {
        try {
          final String jsonString = await rootBundle.loadString(path);
          final List<dynamic> ayahsJson = jsonDecode(jsonString);

          final ayahs = ayahsJson.map((json) {
            return Ayah(
              number: json['id'],
              numberInSurah: json['ayahNumber'],
              text: json['textUthmani'] ?? json['textSimple'],
              juz: json['juzNumber'] ?? 1,
              page: json['pageNumber'] ?? 1,
              hizbQuarter: json['hizbNumber'] ?? 1,
              sajda: false,
              translation: json['translations']?['en'],
            );
          }).toList();

          return Surah(
            number: number,
            name: surahMeta.name,
            englishName: surahMeta.englishName,
            englishNameTranslation: surahMeta.englishNameTranslation,
            revelationType: surahMeta.revelationType,
            numberOfAyahs: ayahs.length,
            ayahs: ayahs,
          );
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. GET SURAH WITH TRANSLATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Private helper: Fetch from quran.com API v4 as fallback
  static Future<Surah> _fetchFromQuranComV4(int surahNumber) async {
    final response = await http
        .get(
          Uri.parse(
            'https://api.quran.com/api/v4/quran/verses/uthmani?chapter_number=$surahNumber',
          ),
        )
        .timeout(AppPolicy.networkMedium);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> verses = json['verses'];

      // Get Surah metadata for details
      final surahs = await getAllSurahs();
      final meta = surahs.firstWhere((s) => s.number == surahNumber);

      final ayahs = verses.map((v) {
        final verseKey = v['verse_key'] as String;
        final ayahNum = int.parse(verseKey.split(':')[1]);

        return Ayah(
          number: v['id'],
          text: v['text_uthmani'],
          numberInSurah: ayahNum,
          juz:
              0, // Not provided directly, will be approximated or updated later
          page: 0,
          sajda: false,
        );
      }).toList();

      return Surah(
        number: surahNumber,
        name: meta.name,
        englishName: meta.englishName,
        englishNameTranslation: meta.englishNameTranslation,
        numberOfAyahs: ayahs.length,
        revelationType: meta.revelationType,
        ayahs: ayahs,
      );
    }
    throw Exception('Failed to load from quran.com');
  }

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
          .timeout(AppPolicy.networkLong);

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
          .timeout(AppPolicy.networkLong);

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
          .timeout(AppPolicy.networkMedium);

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
          .timeout(AppPolicy.networkLong);

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
          .timeout(AppPolicy.networkLong);

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
