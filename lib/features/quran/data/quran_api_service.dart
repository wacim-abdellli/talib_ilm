import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
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

  /// Fetch all 114 surahs metadata using quran.com API v4
  static Future<List<SurahMeta>> getAllSurahs() async {
    try {
      // Use quran.com API v4 (more reliable)
      final response = await http
          .get(Uri.parse('https://api.quran.com/api/v4/chapters'))
          .timeout(const Duration(seconds: 5));

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
    return _getHardcodedSurahs();
  }

  /// Hardcoded surah list as ultimate fallback
  static List<SurahMeta> _getHardcodedSurahs() {
    const names = [
      '',
      'الفاتحة',
      'البقرة',
      'آل عمران',
      'النساء',
      'المائدة',
      'الأنعام',
      'الأعراف',
      'الأنفال',
      'التوبة',
      'يونس',
      'هود',
      'يوسف',
      'الرعد',
      'إبراهيم',
      'الحجر',
      'النحل',
      'الإسراء',
      'الكهف',
      'مريم',
      'طه',
      'الأنبياء',
      'الحج',
      'المؤمنون',
      'النور',
      'الفرقان',
      'الشعراء',
      'النمل',
      'القصص',
      'العنكبوت',
      'الروم',
      'لقمان',
      'السجدة',
      'الأحزاب',
      'سبأ',
      'فاطر',
      'يس',
      'الصافات',
      'ص',
      'الزمر',
      'غافر',
      'فصلت',
      'الشورى',
      'الزخرف',
      'الدخان',
      'الجاثية',
      'الأحقاف',
      'محمد',
      'الفتح',
      'الحجرات',
      'ق',
      'الذاريات',
      'الطور',
      'النجم',
      'القمر',
      'الرحمن',
      'الواقعة',
      'الحديد',
      'المجادلة',
      'الحشر',
      'الممتحنة',
      'الصف',
      'الجمعة',
      'المنافقون',
      'التغابن',
      'الطلاق',
      'التحريم',
      'الملك',
      'القلم',
      'الحاقة',
      'المعارج',
      'نوح',
      'الجن',
      'المزمل',
      'المدثر',
      'القيامة',
      'الإنسان',
      'المرسلات',
      'النبأ',
      'النازعات',
      'عبس',
      'التكوير',
      'الانفطار',
      'المطففين',
      'الانشقاق',
      'البروج',
      'الطارق',
      'الأعلى',
      'الغاشية',
      'الفجر',
      'البلد',
      'الشمس',
      'الليل',
      'الضحى',
      'الشرح',
      'التين',
      'العلق',
      'القدر',
      'البينة',
      'الزلزلة',
      'العاديات',
      'القارعة',
      'التكاثر',
      'العصر',
      'الهمزة',
      'الفيل',
      'قريش',
      'الماعون',
      'الكوثر',
      'الكافرون',
      'النصر',
      'المسد',
      'الإخلاص',
      'الفلق',
      'الناس',
    ];
    const ayahCounts = [
      0,
      7,
      286,
      200,
      176,
      120,
      165,
      206,
      75,
      129,
      109,
      123,
      111,
      43,
      52,
      99,
      128,
      111,
      110,
      98,
      135,
      112,
      78,
      118,
      64,
      77,
      227,
      93,
      88,
      69,
      60,
      34,
      30,
      73,
      54,
      45,
      83,
      182,
      88,
      75,
      85,
      54,
      53,
      89,
      59,
      37,
      35,
      38,
      29,
      18,
      45,
      60,
      49,
      62,
      55,
      78,
      96,
      29,
      22,
      24,
      13,
      14,
      11,
      11,
      18,
      12,
      12,
      30,
      52,
      52,
      44,
      28,
      28,
      20,
      56,
      40,
      31,
      50,
      40,
      46,
      42,
      29,
      19,
      36,
      25,
      22,
      17,
      19,
      26,
      30,
      20,
      15,
      21,
      11,
      8,
      8,
      19,
      5,
      8,
      8,
      11,
      11,
      8,
      3,
      9,
      5,
      4,
      7,
      3,
      6,
      3,
      5,
      4,
      5,
      6,
    ];
    const revelations = [
      '',
      'Meccan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Meccan',
      'Meccan',
      'Medinan',
      'Medinan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Medinan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Medinan',
      'Meccan',
      'Medinan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Medinan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Medinan',
      'Meccan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Medinan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Medinan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Medinan',
      'Medinan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Medinan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
      'Meccan',
    ];

    return List.generate(
      114,
      (i) => SurahMeta(
        number: i + 1,
        name: names[i + 1],
        englishName: 'Surah ${i + 1}',
        englishNameTranslation: '',
        numberOfAyahs: ayahCounts[i + 1],
        revelationType: revelations[i + 1],
      ),
    );
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
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/surah/$number/$edition'))
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Surah.fromJson(data['data']);
      } else {
        throw Exception('Failed to load surah $number: ${response.statusCode}');
      }
    } catch (e) {
      // API failed, try local fallback
      return _loadSurahFromAssets(number);
    }
  }

  /// Load surah from local assets (only Al-Fatiha available)
  static Future<Surah?> _loadSurahFromAssets(int number) async {
    // Get surah metadata first
    final surahsList = await _loadSurahsFromAssets();
    final surahMeta = surahsList.firstWhere(
      (s) => s.number == number,
      orElse: () => throw Exception('Surah $number not found'),
    );

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

    // No local file for this surah
    return null;
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
          .timeout(const Duration(seconds: 7));

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
          .timeout(const Duration(seconds: 5));

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
          .timeout(const Duration(seconds: 5));

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
          .timeout(const Duration(seconds: 7));

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
          .timeout(const Duration(seconds: 7));

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
