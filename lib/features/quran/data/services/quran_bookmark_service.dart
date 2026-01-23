import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Bookmark types
enum BookmarkType { ayah, page, surah }

/// Enhanced bookmark model with notes
class QuranBookmark {
  final int? id;
  final BookmarkType type;
  final int surah;
  final int? ayah;
  final int? page;
  final String? note;
  final DateTime createdAt;

  const QuranBookmark({
    this.id,
    required this.type,
    required this.surah,
    this.ayah,
    this.page,
    this.note,
    required this.createdAt,
  });

  factory QuranBookmark.fromMap(Map<String, dynamic> map) {
    return QuranBookmark(
      id: map['id'] as int?,
      type: BookmarkType.values[map['type'] as int],
      surah: map['surah'] as int,
      ayah: map['ayah'] as int?,
      page: map['page'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'surah': surah,
      'ayah': ayah,
      'page': page,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  QuranBookmark copyWith({String? note}) {
    return QuranBookmark(
      id: id,
      type: type,
      surah: surah,
      ayah: ayah,
      page: page,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}

/// Ayah note model
class AyahNote {
  final int? id;
  final int surah;
  final int ayah;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AyahNote({
    this.id,
    required this.surah,
    required this.ayah,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AyahNote.fromMap(Map<String, dynamic> map) {
    return AyahNote(
      id: map['id'] as int?,
      surah: map['surah'] as int,
      ayah: map['ayah'] as int,
      note: map['note'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surah': surah,
      'ayah': ayah,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }
}

/// Enhanced Bookmark Service with SQLite storage
class QuranBookmarkService {
  static final QuranBookmarkService instance = QuranBookmarkService._();
  QuranBookmarkService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quran_bookmarks.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Bookmarks table
        await db.execute('''
          CREATE TABLE bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type INTEGER NOT NULL,
            surah INTEGER NOT NULL,
            ayah INTEGER,
            page INTEGER,
            note TEXT,
            created_at INTEGER NOT NULL
          )
        ''');

        // Notes table
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah INTEGER NOT NULL,
            ayah INTEGER NOT NULL,
            note TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            UNIQUE(surah, ayah)
          )
        ''');

        // Last read table
        await db.execute('''
          CREATE TABLE last_read (
            id INTEGER PRIMARY KEY DEFAULT 1,
            surah INTEGER NOT NULL,
            ayah INTEGER NOT NULL,
            page INTEGER,
            updated_at INTEGER NOT NULL
          )
        ''');

        // Indexes
        await db.execute(
          'CREATE INDEX idx_bookmarks_surah ON bookmarks(surah)',
        );
        await db.execute(
          'CREATE INDEX idx_notes_surah_ayah ON notes(surah, ayah)',
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKMARKS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Add ayah bookmark
  Future<void> bookmarkAyah(int surah, int ayah, {String? note}) async {
    final db = await database;

    // Remove existing bookmark for this ayah
    await db.delete(
      'bookmarks',
      where: 'type = ? AND surah = ? AND ayah = ?',
      whereArgs: [BookmarkType.ayah.index, surah, ayah],
    );

    // Add new bookmark
    await db.insert(
      'bookmarks',
      QuranBookmark(
        type: BookmarkType.ayah,
        surah: surah,
        ayah: ayah,
        note: note,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  /// Add page bookmark
  Future<void> bookmarkPage(int page, int surah, {String? note}) async {
    final db = await database;

    // Remove existing bookmark for this page
    await db.delete(
      'bookmarks',
      where: 'type = ? AND page = ?',
      whereArgs: [BookmarkType.page.index, page],
    );

    // Add new bookmark
    await db.insert(
      'bookmarks',
      QuranBookmark(
        type: BookmarkType.page,
        surah: surah,
        page: page,
        note: note,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  /// Add surah bookmark
  Future<void> bookmarkSurah(int surah, {String? note}) async {
    final db = await database;

    // Remove existing bookmark for this surah
    await db.delete(
      'bookmarks',
      where: 'type = ? AND surah = ?',
      whereArgs: [BookmarkType.surah.index, surah],
    );

    // Add new bookmark
    await db.insert(
      'bookmarks',
      QuranBookmark(
        type: BookmarkType.surah,
        surah: surah,
        note: note,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  /// Remove bookmark by type and identifier
  Future<void> removeBookmark({
    required BookmarkType type,
    required int surah,
    int? ayah,
    int? page,
  }) async {
    final db = await database;

    switch (type) {
      case BookmarkType.ayah:
        await db.delete(
          'bookmarks',
          where: 'type = ? AND surah = ? AND ayah = ?',
          whereArgs: [type.index, surah, ayah],
        );
        break;
      case BookmarkType.page:
        await db.delete(
          'bookmarks',
          where: 'type = ? AND page = ?',
          whereArgs: [type.index, page],
        );
        break;
      case BookmarkType.surah:
        await db.delete(
          'bookmarks',
          where: 'type = ? AND surah = ?',
          whereArgs: [type.index, surah],
        );
        break;
    }
  }

  /// Get all bookmarks
  Future<List<QuranBookmark>> getBookmarks({BookmarkType? type}) async {
    final db = await database;

    List<Map<String, dynamic>> results;
    if (type != null) {
      results = await db.query(
        'bookmarks',
        where: 'type = ?',
        whereArgs: [type.index],
        orderBy: 'created_at DESC',
      );
    } else {
      results = await db.query('bookmarks', orderBy: 'created_at DESC');
    }

    return results.map((m) => QuranBookmark.fromMap(m)).toList();
  }

  /// Check if ayah is bookmarked
  Future<bool> isAyahBookmarked(int surah, int ayah) async {
    final db = await database;
    final results = await db.query(
      'bookmarks',
      where: 'type = ? AND surah = ? AND ayah = ?',
      whereArgs: [BookmarkType.ayah.index, surah, ayah],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Check if page is bookmarked
  Future<bool> isPageBookmarked(int page) async {
    final db = await database;
    final results = await db.query(
      'bookmarks',
      where: 'type = ? AND page = ?',
      whereArgs: [BookmarkType.page.index, page],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save note for ayah
  Future<void> saveNote(int surah, int ayah, String note) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('notes', {
      'surah': surah,
      'ayah': ayah,
      'note': note,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get note for ayah
  Future<AyahNote?> getNote(int surah, int ayah) async {
    final db = await database;
    final results = await db.query(
      'notes',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return AyahNote.fromMap(results.first);
  }

  /// Delete note for ayah
  Future<void> deleteNote(int surah, int ayah) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
    );
  }

  /// Get all notes
  Future<List<AyahNote>> getAllNotes() async {
    final db = await database;
    final results = await db.query('notes', orderBy: 'updated_at DESC');
    return results.map((m) => AyahNote.fromMap(m)).toList();
  }

  /// Check if ayah has note
  Future<bool> hasNote(int surah, int ayah) async {
    final note = await getNote(surah, ayah);
    return note != null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAST READ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save last read position
  Future<void> saveLastRead(int surah, int ayah, {int? page}) async {
    final db = await database;
    await db.insert('last_read', {
      'id': 1,
      'surah': surah,
      'ayah': ayah,
      'page': page,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get last read position
  Future<({int surah, int ayah, int? page})?> getLastRead() async {
    final db = await database;
    final results = await db.query('last_read', limit: 1);

    if (results.isEmpty) return null;

    final row = results.first;
    return (
      surah: row['surah'] as int,
      ayah: row['ayah'] as int,
      page: row['page'] as int?,
    );
  }
}
