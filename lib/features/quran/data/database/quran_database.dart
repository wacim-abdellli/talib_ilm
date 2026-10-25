import 'dart:convert';

import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../services/quran_page_service.dart';

class QuranDatabase {
  static final QuranDatabase instance = QuranDatabase._init();
  static Database? _database;

  QuranDatabase._init();

  /// Canonical maximum pages in the Medina Mushaf
  static const int maxPages = 604;

  /// Validates that a Quran page number is within canonical Mushaf bounds (1..604)
  static bool isValidPageNumber(int pageNumber) =>
      pageNumber >= 1 && pageNumber <= maxPages;

  @visibleForTesting
  static void setDatabaseForTesting(Database? db) => _database = db;

  @visibleForTesting
  static void resetForTesting() => _database = null;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quran_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError('SQFLite not supported on Web');
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pages (
        page_number INTEGER PRIMARY KEY,
        json_data TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration hook for future schema upgrades
  }

  /// Saves a single page to the database with bounds validation.
  Future<void> savePage(int pageNumber, QuranPageData data) async {
    if (kIsWeb) return;
    if (!isValidPageNumber(pageNumber)) {
      throw ArgumentError(
        'Invalid Quran page number: $pageNumber (must be 1..$maxPages)',
      );
    }

    final db = await database;
    final jsonStr = jsonEncode(data.toJson());

    await db.insert('pages', {
      'page_number': pageNumber,
      'json_data': jsonStr,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Atomically saves multiple pages within a single SQLite transaction.
  Future<void> savePagesBatch(Map<int, QuranPageData> pages) async {
    if (kIsWeb || pages.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in pages.entries) {
        if (!isValidPageNumber(entry.key)) continue;
        final jsonStr = jsonEncode(entry.value.toJson());
        batch.insert('pages', {
          'page_number': entry.key,
          'json_data': jsonStr,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Retrieves a Quran page from the database with corruption self-healing.
  Future<QuranPageData?> getPage(int pageNumber) async {
    if (kIsWeb || !isValidPageNumber(pageNumber)) return null;
    final db = await database;

    final maps = await db.query(
      'pages',
      columns: ['json_data'],
      where: 'page_number = ?',
      whereArgs: [pageNumber],
    );

    if (maps.isNotEmpty) {
      final jsonStr = maps.first['json_data'] as String;
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          return QuranPageData.fromJson(decoded);
        }
      } catch (_) {
        // Corrupted JSON row; delete to heal database and enable clean re-fetch
        try {
          await db.delete(
            'pages',
            where: 'page_number = ?',
            whereArgs: [pageNumber],
          );
        } catch (_) {}
      }
    }
    return null;
  }

  /// Retrieves all stored page numbers.
  Future<List<int>> getStoredPageNumbers() async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query('pages', columns: ['page_number']);
    return result.map((e) => e['page_number'] as int).toList();
  }

  /// Safely deletes all cached Quran pages.
  Future<void> clearAllPages() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('pages');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
