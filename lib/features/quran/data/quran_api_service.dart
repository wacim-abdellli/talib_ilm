import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;
import '../../../core/constants/app_policy.dart';
import 'catalogs/surah_fallback_catalog.dart';
import 'models/quran_models.dart';
import 'services/quran_http_streamer.dart';

/// Quran API Service using alquran.cloud & quran.com API v4
/// Supports: Surahs, Verses, Translations, Audio, Search, Pages, Juzs
/// Hardened with streaming byte limits, input validation, HTTP seams, and concurrency deduplication.
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
  // HTTP TEST SEAM & DEDUPLICATION STATE
  // ═══════════════════════════════════════════════════════════════════════════

  @visibleForTesting
  static void setHttpClient(http.Client client) {
    QuranHttpStreamer.setHttpClient(client);
  }

  @visibleForTesting
  static void resetHttpClient() {
    QuranHttpStreamer.resetHttpClient();
  }

  static Future<List<SurahMeta>>? _inFlightAllSurahs;
  static Future<List<Juz>>? _inFlightAllJuzs;
  static final Map<String, Future<Surah?>> _inFlightSurahs = {};
  static final Map<String, Future<List<Ayah>>> _inFlightPages = {};
  static final Map<String, Future<Juz?>> _inFlightJuzs = {};
  static final Map<String, Future<List<QuranSearchResult>>> _inFlightSearches =
      {};
  static final Map<String, Future<Ayah?>> _inFlightAyahs = {};

  @visibleForTesting
  static void resetForTesting() {
    resetHttpClient();
    _inFlightAllSurahs = null;
    _inFlightAllJuzs = null;
    _inFlightSurahs.clear();
    _inFlightPages.clear();
    _inFlightJuzs.clear();
    _inFlightSearches.clear();
    _inFlightAyahs.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INPUT BOUNDS VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  static bool isValidSurahNumber(int number) => number >= 1 && number <= 114;

  static bool isValidPageNumber(int number) => number >= 1 && number <= 604;

  static bool isValidJuzNumber(int number) => number >= 1 && number <= 30;

  static bool isValidAyah(int surahNumber, int ayahNumber) {
    if (!isValidSurahNumber(surahNumber)) return false;
    final totalVerses = quran.getVerseCount(surahNumber);
    return ayahNumber >= 1 && ayahNumber <= totalVerses;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. GET ALL SURAHS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch all 114 surahs metadata using quran.com API v4
  static Future<List<SurahMeta>> getAllSurahs() async {
    if (_inFlightAllSurahs != null) return _inFlightAllSurahs!;

    final future = _fetchAllSurahsInternal();
    _inFlightAllSurahs = future;
    try {
      return await future;
    } finally {
      _inFlightAllSurahs = null;
    }
  }

  static Future<List<SurahMeta>> _fetchAllSurahsInternal() async {
    try {
      final body = await QuranHttpStreamer.fetchStreamedStringWithLimit(
        Uri.parse('https://api.quran.com/api/v4/chapters'),
        maxBytes: AppPolicy.maxQuranSurahsCatalogBytes,
        timeout: AppPolicy.networkMedium,
      );

      final data = jsonDecode(body);
      final List<dynamic> chapters = data['chapters'] ?? [];
      if (chapters.isNotEmpty) {
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

    return SurahFallbackCatalog.getSurahs();
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
    if (!isValidSurahNumber(number)) return null;

    final key = '$number:$edition';
    if (_inFlightSurahs.containsKey(key)) return _inFlightSurahs[key]!;

    final future = _fetchSurahWithEditionInternal(number, edition);
    _inFlightSurahs[key] = future;
    try {
      return await future;
    } finally {
      _inFlightSurahs.remove(key);
    }
  }

  static Future<Surah?> _fetchSurahWithEditionInternal(
    int number,
    String edition,
  ) async {
    // Quick load strategy for Al-Fatiha
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
        final timeout =
            attempts == 0 ? AppPolicy.networkFast : AppPolicy.networkRetry;
        final body = await QuranHttpStreamer.fetchStreamedStringWithLimit(
          Uri.parse('$_baseUrl/surah/$number/$edition'),
          maxBytes: AppPolicy.maxQuranSurahResponseBytes,
          timeout: timeout,
        );

        final data = jsonDecode(body);
        if (data['data'] != null) {
          return Surah.fromJson(data['data']);
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
    } catch (_) {}

    // FINAL FALLBACK: Local Assets
    return _loadSurahFromAssets(number);
  }

  /// Load surah from local assets (only Al-Fatiha available)
  static Future<Surah?> _loadSurahFromAssets(int number) async {
    try {
      final surahMeta = SurahFallbackCatalog.getSurahs().firstWhere((s) => s.number == number);

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
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. GET SURAH WITH TRANSLATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Private helper: Fetch from quran.com API v4 as fallback
  static Future<Surah> _fetchFromQuranComV4(int surahNumber) async {
    if (!isValidSurahNumber(surahNumber)) {
      throw ArgumentError('Invalid surah number: $surahNumber');
    }

    final body = await QuranHttpStreamer.fetchStreamedStringWithLimit(
      Uri.parse(
        'https://api.quran.com/api/v4/quran/verses/uthmani?chapter_number=$surahNumber',
      ),
      maxBytes: AppPolicy.maxQuranSurahResponseBytes,
      timeout: AppPolicy.networkMedium,
    );

    final json = jsonDecode(body);
    final List<dynamic> verses = json['verses'] ?? [];

    final surahs = await getAllSurahs();
    final meta = surahs.firstWhere(
      (s) => s.number == surahNumber,
      orElse: () => SurahFallbackCatalog.getSurahs()
          .firstWhere((s) => s.number == surahNumber),
    );

    final ayahs = verses.map((v) {
      final verseKey = v['verse_key'] as String;
      final ayahNum = int.parse(verseKey.split(':')[1]);

      return Ayah(
        number: v['id'],
        text: v['text_uthmani'] ?? '',
        numberInSurah: ayahNum,
        juz: 0,
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
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final sanitizedQuery = trimmed.length > AppPolicy.maxQuranSearchQueryLength
        ? trimmed.substring(0, AppPolicy.maxQuranSearchQueryLength)
        : trimmed;

    final key = '$edition:$sanitizedQuery';
    if (_inFlightSearches.containsKey(key)) return _inFlightSearches[key]!;

    final future = _searchQuranInternal(sanitizedQuery, edition);
    _inFlightSearches[key] = future;
    try {
      return await future;
    } finally {
      _inFlightSearches.remove(key);
    }
  }

  static Future<List<QuranSearchResult>> _searchQuranInternal(
    String query,
    String edition,
  ) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final body = await QuranHttpStreamer.fetchStreamedStringWithLimit(
        Uri.parse('$_baseUrl/search/$encodedQuery/all/$edition'),
        maxBytes: AppPolicy.maxQuranSearchResponseBytes,
        timeout: AppPolicy.networkLong,
      );

      final data = jsonDecode(body);
      if (data['data'] != null && data['data']['matches'] != null) {
        final List<dynamic> matches = data['data']['matches'];
        return matches
            .map((json) => QuranSearchResult.fromJson(json))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. AUDIO URL GENERATION
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
    final parts = reference.split(':');
    if (parts.length != 2) return null;
    final surahNum = int.tryParse(parts[0]);
    final ayahNum = int.tryParse(parts[1]);
    if (surahNum == null ||
        ayahNum == null ||
        !isValidAyah(surahNum, ayahNum)) {
      return null;
    }

    final key = '$reference:$edition';
    if (_inFlightAyahs.containsKey(key)) return _inFlightAyahs[key]!;

    final future = _getAyahInternal(reference, edition);
    _inFlightAyahs[key] = future;
    try {
      return await future;
    } finally {
      _inFlightAyahs.remove(key);
    }
  }

  static Future<Ayah?> _getAyahInternal(
    String reference,
    String edition,
  ) async {
    try {
      final body = await QuranHttpStreamer.fetchStreamedStringWithLimit(
        Uri.parse('$_baseUrl/ayah/$reference/$edition'),
        maxBytes: AppPolicy.maxQuranAyahResponseBytes,
        timeout: AppPolicy.networkLong,
      );

      final data = jsonDecode(body);
      if (data['data'] != null) {
        return Ayah.fromJson(data['data']);
      }
      return null;
    } catch (_) {
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
    if (_inFlightAllJuzs != null) return _inFlightAllJuzs!;

    final future = _getAllJuzsInternal();
    _inFlightAllJuzs = future;
    try {
      return await future;
    } finally {
      _inFlightAllJuzs = null;
    }
  }

  static Future<List<Juz>> _getAllJuzsInternal() async {
    try {
      final body = await QuranHttpStreamer.fetchStreamedStringWithLimit(
        Uri.parse('$_baseUrl/juz'),
        maxBytes: AppPolicy.maxQuranJuzResponseBytes,
        timeout: AppPolicy.networkMedium,
      );

      final data = jsonDecode(body);
      final List<dynamic> juzsJson = data['data'] ?? [];
      return juzsJson.map((json) => Juz.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Juz?> getJuz(
    int number, {
    String edition = editionUthmani,
  }) async {
    if (!isValidJuzNumber(number)) return null;

    final key = '$number:$edition';
    if (_inFlightJuzs.containsKey(key)) return _inFlightJuzs[key]!;

    final future = _getJuzInternal(number, edition);
    _inFlightJuzs[key] = future;
    try {
      return await future;
    } finally {
      _inFlightJuzs.remove(key);
    }
  }

  static Future<Juz?> _getJuzInternal(int number, String edition) async {
    try {
      final body = await QuranHttpStreamer.fetchStreamedStringWithLimit(
        Uri.parse('$_baseUrl/juz/$number/$edition'),
        maxBytes: AppPolicy.maxQuranJuzResponseBytes,
        timeout: AppPolicy.networkLong,
      );

      final data = jsonDecode(body);
      if (data['data'] != null) {
        return Juz.fromJson(data['data']);
      }
      return null;
    } catch (_) {
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
    if (!isValidPageNumber(pageNumber)) return [];

    final key = '$pageNumber:$edition';
    if (_inFlightPages.containsKey(key)) return _inFlightPages[key]!;

    final future = _getPageInternal(pageNumber, edition);
    _inFlightPages[key] = future;
    try {
      return await future;
    } finally {
      _inFlightPages.remove(key);
    }
  }

  static Future<List<Ayah>> _getPageInternal(
    int pageNumber,
    String edition,
  ) async {
    try {
      final body = await QuranHttpStreamer.fetchStreamedStringWithLimit(
        Uri.parse('$_baseUrl/page/$pageNumber/$edition'),
        maxBytes: AppPolicy.maxQuranPageResponseBytes,
        timeout: AppPolicy.networkLong,
      );

      final data = jsonDecode(body);
      final dataMap = data['data'] as Map<String, dynamic>?;
      if (dataMap != null && dataMap['ayahs'] != null) {
        final List<dynamic> ayahsJson = dataMap['ayahs'];
        return ayahsJson.map((json) => Ayah.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
