import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final int surah;
  final int ayah;
  final String? note;
  final DateTime timestamp;

  const Bookmark({
    required this.surah,
    required this.ayah,
    this.note,
    required this.timestamp,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      note: json['note'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'surah': surah,
    'ayah': ayah,
    'note': note,
    'timestamp': timestamp.toIso8601String(),
  };
}

class LastRead {
  final int surah;
  final int ayah;

  const LastRead({required this.surah, required this.ayah});

  factory LastRead.fromJson(Map<String, dynamic> json) {
    return LastRead(surah: json['surah'] as int, ayah: json['ayah'] as int);
  }

  Map<String, dynamic> toJson() => {'surah': surah, 'ayah': ayah};
}

class BookmarkService {
  static const String _bookmarksKey = 'bookmarks';
  static const String _lastReadKey = 'last_read';

  /// Add a bookmark (Max 100)
  static Future<void> addBookmark(int surah, int ayah, {String? note}) async {
    final bookmarks = await getBookmarks();

    // Check if already exists to prevent duplicates (update note/timestamp if matches?)
    // Prompt says "Add new". Usually we avoid dupes.
    // I'll remove existing first if logic matches surah+ayah
    bookmarks.removeWhere((b) => b.surah == surah && b.ayah == ayah);

    // Create new
    final newBookmark = Bookmark(
      surah: surah,
      ayah: ayah,
      note: note,
      timestamp: DateTime.now(),
    );

    // Add to top
    bookmarks.insert(0, newBookmark);

    // Limit to 100
    if (bookmarks.length > 100) {
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

  /// Get all bookmarks
  static Future<List<Bookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_bookmarksKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Bookmark.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if bookmarked
  static Future<bool> isBookmarked(int surah, int ayah) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.surah == surah && b.ayah == ayah);
  }

  /// Save list to prefs
  static Future<void> _saveBookmarks(List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    await prefs.setString(_bookmarksKey, jsonEncode(jsonList));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAST READ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save last read position
  static Future<void> saveLastRead(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRead = LastRead(surah: surah, ayah: ayah);
    await prefs.setString(_lastReadKey, jsonEncode(lastRead.toJson()));
  }

  /// Get last read position
  static Future<LastRead?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_lastReadKey);

    if (jsonString == null) return null;

    try {
      return LastRead.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }
}
