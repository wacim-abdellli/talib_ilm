import 'dart:convert';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final int surah;
  final int ayah;
  final int page;
  final String? note;
  final DateTime timestamp;

  const Bookmark({
    required this.surah,
    required this.ayah,
    required this.page,
    this.note,
    required this.timestamp,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    final s = json['surah'] as int;
    final a = json['ayah'] as int;
    return Bookmark(
      surah: s,
      ayah: a,
      page: json['page'] as int? ?? quran.getPageNumber(s, a),
      note: json['note'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'page': page,
        'note': note,
        'timestamp': timestamp.toIso8601String(),
      };
}

class LastRead {
  final int surah;
  final int ayah;
  final int page;
  final DateTime timestamp;

  const LastRead({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.timestamp,
  });

  factory LastRead.fromJson(Map<String, dynamic> json) {
    final s = json['surah'] as int;
    final a = json['ayah'] as int;
    return LastRead(
      surah: s,
      ayah: a,
      page: json['page'] as int? ?? quran.getPageNumber(s, a),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'page': page,
        'timestamp': timestamp.toIso8601String(),
      };
}

class BookmarkService {
  static const String _bookmarksKey = 'bookmarks_v2';
  static const String _lastReadKey = 'last_read_v2';

  // Legacy keys to migrate from
  static const String _legacyFavSurahsKey = 'dashboard_fav_surahs';
  static const String _legacyLastSurahKey = 'dashboard_last_surah';
  static const String _legacyLastAyahKey = 'dashboard_last_ayah';
  static const String _legacyLastPageKey = 'dashboard_last_page';
  static const String _legacyBookmarksKey = 'bookmarks';

  /// Add or update a bookmark (Max 200)
  static Future<void> addBookmark(int surah, int ayah, {String? note}) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.surah == surah && b.ayah == ayah);

    final page = quran.getPageNumber(surah, ayah);
    final newBookmark = Bookmark(
      surah: surah,
      ayah: ayah,
      page: page,
      note: note,
      timestamp: DateTime.now(),
    );

    bookmarks.insert(0, newBookmark);
    if (bookmarks.length > 200) {
      bookmarks.removeLast();
    }

    await _saveBookmarks(bookmarks);
  }

  /// Remove a bookmark
  static Future<void> removeBookmark(int surah, int ayah) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.surah == surah && b.ayah == ayah);
    await _saveBookmarks(bookmarks);
  }

  /// Update note for a bookmark
  static Future<void> updateNote(int surah, int ayah, String? note) async {
    final bookmarks = await getBookmarks();
    final index = bookmarks.indexWhere((b) => b.surah == surah && b.ayah == ayah);
    if (index != -1) {
      final old = bookmarks[index];
      bookmarks[index] = Bookmark(
        surah: old.surah,
        ayah: old.ayah,
        page: old.page,
        note: note,
        timestamp: DateTime.now(),
      );
      await _saveBookmarks(bookmarks);
    } else {
      await addBookmark(surah, ayah, note: note);
    }
  }

  /// Get all bookmarks with automatic legacy migration
  static Future<List<Bookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_bookmarksKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => Bookmark.fromJson(json)).toList();
      } catch (_) {}
    }

    // Attempt migration from v1 bookmarks
    final v1String = prefs.getString(_legacyBookmarksKey);
    if (v1String != null && v1String.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(v1String);
        final migrated = jsonList.map((json) => Bookmark.fromJson(json)).toList();
        if (migrated.isNotEmpty) {
          await _saveBookmarks(migrated);
          return migrated;
        }
      } catch (_) {}
    }

    // Attempt migration from legacy favorites list
    final legacySurahs = prefs.getStringList(_legacyFavSurahsKey);
    if (legacySurahs != null && legacySurahs.isNotEmpty) {
      final migrated = <Bookmark>[];
      for (final sStr in legacySurahs) {
        final sNum = int.tryParse(sStr);
        if (sNum != null && sNum >= 1 && sNum <= 114) {
          migrated.add(
            Bookmark(
              surah: sNum,
              ayah: 1,
              page: quran.getPageNumber(sNum, 1),
              note: null,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
      if (migrated.isNotEmpty) {
        await _saveBookmarks(migrated);
        return migrated;
      }
    }

    return [];
  }

  /// Check if an ayah is bookmarked
  static Future<bool> isBookmarked(int surah, int ayah) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.surah == surah && b.ayah == ayah);
  }

  /// Toggle bookmark status
  static Future<bool> toggleBookmark(int surah, int ayah, {String? note}) async {
    final exists = await isBookmarked(surah, ayah);
    if (exists) {
      await removeBookmark(surah, ayah);
      return false;
    } else {
      await addBookmark(surah, ayah, note: note);
      return true;
    }
  }

  /// Save all bookmarks list directly
  static Future<void> saveAllBookmarks(List<Bookmark> bookmarks) async {
    await _saveBookmarks(bookmarks);
  }

  static Future<void> _saveBookmarks(List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    await prefs.setString(_bookmarksKey, jsonEncode(jsonList));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAST READ POSITION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save last read position with surah, ayah, and page
  static Future<void> saveLastRead({
    required int surah,
    required int ayah,
    int? page,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final p = page ?? quran.getPageNumber(surah, ayah);
    final lastRead = LastRead(
      surah: surah,
      ayah: ayah,
      page: p,
      timestamp: DateTime.now(),
    );

    await prefs.setString(_lastReadKey, jsonEncode(lastRead.toJson()));
    // Also update legacy keys for maximum backward compatibility
    await prefs.setInt(_legacyLastSurahKey, surah);
    await prefs.setInt(_legacyLastAyahKey, ayah);
    await prefs.setInt(_legacyLastPageKey, p);
  }

  /// Get last read position with automatic legacy fallback
  static Future<LastRead> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_lastReadKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return LastRead.fromJson(jsonDecode(jsonString));
      } catch (_) {}
    }

    // Legacy fallback
    final surah = prefs.getInt(_legacyLastSurahKey) ?? 1;
    final ayah = prefs.getInt(_legacyLastAyahKey) ?? 1;
    final page = prefs.getInt(_legacyLastPageKey) ?? quran.getPageNumber(surah, ayah);

    return LastRead(
      surah: surah,
      ayah: ayah,
      page: page,
      timestamp: DateTime.now(),
    );
  }
}
