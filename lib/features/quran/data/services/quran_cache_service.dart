import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_models.dart';
import '../quran_api_service.dart';

/// Quran Cache Service
/// Uses SharedPreferences for persistent caching
/// Strategy: Check cache first -> Fetch from API if expired -> Save to cache
class QuranCacheService {
  static const String _surahListKey = 'quran_cache_surah_list';
  static const String _surahPrefix = 'quran_cache_surah_';
  static const String _pagePrefix = 'quran_cache_page_';
  static const String _progressKey = 'quran_cache_progress';
  static const String _bookmarksKey = 'quran_cache_bookmarks';
  static const String _timestampSuffix = '_timestamp';

  // Cache validity duration (30 days)
  static const Duration cacheValidity = Duration(days: 30);

  // ═══════════════════════════════════════════════════════════════════════════
  // SURAH LIST CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cache surah list (metadata only)
  static Future<void> cacheSurahList(List<SurahMeta> surahs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = surahs.map((s) => s.toJson()).toList();
    await prefs.setString(_surahListKey, jsonEncode(jsonList));
    await prefs.setString(
      '$_surahListKey$_timestampSuffix',
      DateTime.now().toIso8601String(),
    );
  }

  /// Get cached surah list
  static Future<List<SurahMeta>?> getCachedSurahList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_surahListKey);

    if (jsonString == null) return null;

    // Check if cache is valid
    if (!await isSurahListCacheValid()) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => SurahMeta.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Check if surah list cache is valid
  static Future<bool> isSurahListCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString('$_surahListKey$_timestampSuffix');
    return _isTimestampValid(timestampStr);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SINGLE SURAH CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cache a full surah with ayahs
  static Future<void> cacheSurah(Surah surah) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_surahPrefix${surah.number}';
    await prefs.setString(key, jsonEncode(surah.toJson()));
    await prefs.setString(
      '$key$_timestampSuffix',
      DateTime.now().toIso8601String(),
    );
  }

  /// Get cached surah
  static Future<Surah?> getCachedSurah(int number) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_surahPrefix$number';
    final jsonString = prefs.getString(key);

    if (jsonString == null) return null;

    // Check if cache is valid
    if (!await isSurahCacheValid(number)) return null;

    try {
      final json = jsonDecode(jsonString);
      return Surah.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Check if surah cache is valid
  static Future<bool> isSurahCacheValid(int number) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_surahPrefix$number';
    final timestampStr = prefs.getString('$key$_timestampSuffix');
    return _isTimestampValid(timestampStr);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE CACHE REMOVED (Migrated to QuranDatabase)
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // READING PROGRESS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> saveProgress(ReadingProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  static Future<ReadingProgress?> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_progressKey);

    if (jsonString == null) return null;

    try {
      return ReadingProgress.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKMARKS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> saveBookmarks(List<QuranBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    await prefs.setString(_bookmarksKey, jsonEncode(jsonList));
  }

  static Future<List<QuranBookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_bookmarksKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => QuranBookmark.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addBookmark(QuranBookmark bookmark) async {
    final bookmarks = await getBookmarks();

    // Remove existing if same surah:ayah
    bookmarks.removeWhere((b) => b.id == bookmark.id);

    // Add new bookmark at the beginning
    bookmarks.insert(0, bookmark);

    // Limit to 100 bookmarks
    if (bookmarks.length > 100) {
      bookmarks.removeLast();
    }

    await saveBookmarks(bookmarks);
  }

  static Future<void> removeBookmark(String id) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.id == id);
    await saveBookmarks(bookmarks);
  }

  static Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    final bookmarks = await getBookmarks();
    final id = QuranBookmark.generateId(surahNumber, ayahNumber);
    return bookmarks.any((b) => b.id == id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('quran_cache_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<void> clearSurahCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (k) => k.startsWith(_surahPrefix) || k == _surahListKey,
    );
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<int> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    int size = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith('quran_cache_')) {
        final value = prefs.getString(key);
        if (value != null) {
          size += value.length;
        }
      }
    }
    return size;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  static bool _isTimestampValid(String? timestampStr) {
    if (timestampStr == null) return false;

    try {
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      return now.difference(timestamp) < cacheValidity;
    } catch (e) {
      return false;
    }
  }

  static Future<void> invalidateCache() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampKeys = prefs.getKeys().where(
      (k) => k.endsWith(_timestampSuffix),
    );
    for (final key in timestampKeys) {
      await prefs.remove(key);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CACHED QURAN REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════

class QuranRepository {
  /// Get surah list (cache-first strategy)
  static Future<List<SurahMeta>> getSurahList({
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = await QuranCacheService.getCachedSurahList();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    // Fetch from API
    try {
      final surahs = await QuranApiService.getAllSurahs();

      // Save to cache
      await QuranCacheService.cacheSurahList(surahs);

      return surahs;
    } catch (e) {
      // Return cached even if expired on error
      final cached = await QuranCacheService.getCachedSurahList();
      return cached ?? [];
    }
  }

  /// Get single surah with verses
  static Future<Surah?> getSurah(
    int number, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await QuranCacheService.getCachedSurah(number);
      if (cached != null) return cached;
    }

    try {
      final surah = await QuranApiService.getSurah(number);
      if (surah != null) {
        await QuranCacheService.cacheSurah(surah);
      }
      return surah;
    } catch (e) {
      return await QuranCacheService.getCachedSurah(number);
    }
  }

  /// Get page ayahs
  static Future<List<Ayah>> getPage(
    int pageNumber, {
    bool forceRefresh = false,
  }) async {
    // Page caching moved to QuranPageService (SQLite).
    // This legacy repository just fetches from API if used.
    try {
      return await QuranApiService.getPage(pageNumber);
    } catch (e) {
      return [];
    }
  }

  /// Update reading progress
  static Future<void> updateProgress({
    required int surahNumber,
    required int ayahNumber,
    required int pageNumber,
    required int juzNumber,
  }) async {
    final progress = ReadingProgress(
      lastSurah: surahNumber,
      lastAyah: ayahNumber,
      lastPage: pageNumber,
      lastJuz: juzNumber,
      timestamp: DateTime.now(),
    );
    await QuranCacheService.saveProgress(progress);
  }

  /// Get last reading position
  static Future<ReadingProgress> getLastPosition() async {
    final progress = await QuranCacheService.getProgress();
    return progress ?? ReadingProgress.initial();
  }
}
