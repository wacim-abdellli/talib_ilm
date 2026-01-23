import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tafsir_models.dart';

/// Tafsir Service - Offline-first tafsir loading
///
/// Strategy:
/// 1. Check local SQLite first
/// 2. If missing + online → fetch from API → save locally
/// 3. If missing + offline → return empty (no blocking)
class TafsirService {
  static final TafsirService instance = TafsirService._();
  TafsirService._();

  Database? _db;
  static const String _tableName = 'tafsir';
  static const String _baseUrl = 'https://api.quran.com/api/v4';

  /// Initialize database
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tafsir.db');

    return openDatabase(
      path,
      version: 2, // Bumped version to clear old cache
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ayah_id INTEGER NOT NULL,
            surah INTEGER NOT NULL,
            ayah INTEGER NOT NULL,
            source TEXT NOT NULL,
            text TEXT NOT NULL,
            language TEXT DEFAULT 'ar',
            created_at INTEGER DEFAULT (strftime('%s', 'now')),
            UNIQUE(ayah_id, source)
          )
        ''');
        // Index for fast lookups
        await db.execute(
          'CREATE INDEX idx_tafsir_lookup ON $_tableName(ayah_id, source)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Clear old cache when upgrading
        await db.execute('DROP TABLE IF EXISTS $_tableName');
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ayah_id INTEGER NOT NULL,
            surah INTEGER NOT NULL,
            ayah INTEGER NOT NULL,
            source TEXT NOT NULL,
            text TEXT NOT NULL,
            language TEXT DEFAULT 'ar',
            created_at INTEGER DEFAULT (strftime('%s', 'now')),
            UNIQUE(ayah_id, source)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_tafsir_lookup ON $_tableName(ayah_id, source)',
        );
      },
    );
  }

  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Get tafsir for an ayah - offline-first
  Future<TafsirData?> getTafsir({
    required int surah,
    required int ayah,
    required TafsirSource source,
  }) async {
    final ayahId = _calculateAyahId(surah, ayah);

    // 1. Check local DB first
    final cached = await _getFromCache(ayahId, source);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // 2. If online, fetch from API
    if (await _isOnline()) {
      final fetched = await _fetchFromApi(surah, ayah, source);
      if (fetched != null && fetched.isNotEmpty) {
        await _saveToCache(fetched);
        return fetched;
      }
    }

    // 3. Return null if not available
    return null;
  }

  /// Get from local cache
  Future<TafsirData?> _getFromCache(int ayahId, TafsirSource source) async {
    try {
      final db = await database;
      final results = await db.query(
        _tableName,
        where: 'ayah_id = ? AND source = ?',
        whereArgs: [ayahId, source.id],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return TafsirData.fromMap(results.first);
      }
    } catch (_) {
      // Silently fail - offline safety
    }
    return null;
  }

  /// Save to local cache
  Future<void> _saveToCache(TafsirData tafsir) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        tafsir.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Silently fail - don't block UI
    }
  }

  /// Fetch from quran.com API v4
  Future<TafsirData?> _fetchFromApi(
    int surah,
    int ayah,
    TafsirSource source,
  ) async {
    try {
      // quran.com API v4 endpoint: /tafsirs/{resource_id}/by_ayah/{verse_key}
      final url = '$_baseUrl/tafsirs/${source.id}/by_ayah/$surah:$ayah';
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final tafsirData = json['tafsir'];
        if (tafsirData != null) {
          // Extract text - may contain HTML, strip it
          String text = tafsirData['text'] ?? '';
          // Remove HTML tags if present
          text = text.replaceAll(RegExp(r'<[^>]*>'), '');
          // Clean up extra whitespace
          text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

          if (text.isNotEmpty) {
            return TafsirData(
              ayahId: _calculateAyahId(surah, ayah),
              surah: surah,
              ayah: ayah,
              source: source,
              text: text,
              language: 'ar',
            );
          }
        }
      }
    } catch (e) {
      // Network error - return null
      print('Tafsir fetch error: $e');
    }
    return null;
  }

  /// Calculate global ayah ID (1-6236)
  int _calculateAyahId(int surah, int ayah) {
    // Cumulative ayah counts per surah
    const ayahCounts = [
      0, 7, 286, 200, 176, 120, 165, 206, 75, 129, 109, // 1-10
      123, 111, 43, 52, 99, 128, 111, 110, 98, 135, // 11-20
      112, 78, 118, 64, 77, 227, 93, 88, 69, 60, // 21-30
      34, 30, 73, 54, 45, 83, 182, 88, 75, 85, // 31-40
      54, 53, 89, 59, 37, 35, 38, 29, 18, 45, // 41-50
      60, 49, 62, 55, 78, 96, 29, 22, 24, 13, // 51-60
      14, 11, 11, 18, 12, 12, 30, 52, 52, 44, // 61-70
      28, 28, 20, 56, 40, 31, 50, 40, 46, 42, // 71-80
      29, 19, 36, 25, 22, 17, 19, 26, 30, 20, // 81-90
      15, 21, 11, 8, 8, 19, 5, 8, 8, 11, // 91-100
      11, 8, 3, 9, 5, 4, 7, 3, 6, 3, // 101-110
      5, 4, 5, 6, // 111-114
    ];

    int total = 0;
    for (int i = 1; i < surah && i < ayahCounts.length; i++) {
      total += ayahCounts[i];
    }
    return total + ayah;
  }

  /// Check if tafsir is cached for an ayah
  Future<bool> isCached({
    required int surah,
    required int ayah,
    required TafsirSource source,
  }) async {
    final ayahId = _calculateAyahId(surah, ayah);
    final cached = await _getFromCache(ayahId, source);
    return cached != null && cached.isNotEmpty;
  }

  /// Get cache stats
  Future<int> getCacheCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      return result.first['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Clear all cached tafsir
  Future<void> clearCache() async {
    try {
      final db = await database;
      await db.delete(_tableName);
    } catch (_) {
      // Silently fail
    }
  }
}
