import 'dart:convert';

import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../services/quran_page_service.dart';

class QuranDatabase {
  static final QuranDatabase instance = QuranDatabase._init();
  static Database? _database;

  QuranDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quran_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError('SQFLite not supported on Web'); // Placeholder
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pages (
        page_number INTEGER PRIMARY KEY,
        json_data TEXT NOT NULL
      )
    ''');
  }

  Future<void> savePage(int pageNumber, QuranPageData data) async {
    if (kIsWeb) return; // Skip for web
    final db = await database;
    final jsonStr = jsonEncode(data.toJson());

    await db.insert('pages', {
      'page_number': pageNumber,
      'json_data': jsonStr,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<QuranPageData?> getPage(int pageNumber) async {
    if (kIsWeb) return null; // Skip for web
    final db = await database;

    final maps = await db.query(
      'pages',
      columns: ['json_data'],
      where: 'page_number = ?',
      whereArgs: [pageNumber],
    );

    if (maps.isNotEmpty) {
      final jsonStr = maps.first['json_data'] as String;
      return QuranPageData.fromJson(jsonDecode(jsonStr));
    }
    return null;
  }

  Future<List<int>> getStoredPageNumbers() async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query('pages', columns: ['page_number']);
    return result.map((e) => e['page_number'] as int).toList();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
