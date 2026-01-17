import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Bookmark data model
class QuranBookmark {
  final String id;
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final int pageNumber;
  final int juzNumber;
  final String versePreview;
  final String? note;
  final DateTime createdAt;

  const QuranBookmark({
    required this.id,
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.pageNumber,
    required this.juzNumber,
    required this.versePreview,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'surahName': surahName,
    'verseNumber': verseNumber,
    'pageNumber': pageNumber,
    'juzNumber': juzNumber,
    'versePreview': versePreview,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory QuranBookmark.fromJson(Map<String, dynamic> json) => QuranBookmark(
    id: json['id'] as String,
    surahNumber: json['surahNumber'] as int,
    surahName: json['surahName'] as String,
    verseNumber: json['verseNumber'] as int,
    pageNumber: json['pageNumber'] as int,
    juzNumber: json['juzNumber'] as int,
    versePreview: json['versePreview'] as String,
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Last read position data
class LastReadPosition {
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final int pageNumber;
  final int juzNumber;
  final DateTime timestamp;
  final double surahProgress;

  const LastReadPosition({
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.pageNumber,
    required this.juzNumber,
    required this.timestamp,
    this.surahProgress = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'surahName': surahName,
    'verseNumber': verseNumber,
    'pageNumber': pageNumber,
    'juzNumber': juzNumber,
    'timestamp': timestamp.toIso8601String(),
    'surahProgress': surahProgress,
  };

  factory LastReadPosition.fromJson(Map<String, dynamic> json) =>
      LastReadPosition(
        surahNumber: json['surahNumber'] as int,
        surahName: json['surahName'] as String,
        verseNumber: json['verseNumber'] as int,
        pageNumber: json['pageNumber'] as int,
        juzNumber: json['juzNumber'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        surahProgress: (json['surahProgress'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Bookmark service for Quran
class QuranBookmarkService {
  static const String _bookmarksKey = 'quran_bookmarks';
  static const String _lastReadKey = 'quran_last_read';
  static const int _maxBookmarks = 50;

  final SharedPreferences _prefs;

  QuranBookmarkService(this._prefs);

  List<QuranBookmark> getAllBookmarks() {
    final jsonString = _prefs.getString(_bookmarksKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => QuranBookmark.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<bool> addBookmark(QuranBookmark bookmark) async {
    final bookmarks = getAllBookmarks();
    if (bookmarks.any(
      (b) =>
          b.surahNumber == bookmark.surahNumber &&
          b.verseNumber == bookmark.verseNumber,
    )) {
      return false;
    }
    if (bookmarks.length >= _maxBookmarks) {
      bookmarks.removeLast();
    }
    bookmarks.insert(0, bookmark);
    return _saveBookmarks(bookmarks);
  }

  Future<bool> removeBookmark(String id) async {
    final bookmarks = getAllBookmarks();
    bookmarks.removeWhere((b) => b.id == id);
    return _saveBookmarks(bookmarks);
  }

  bool isBookmarked(int surahNumber, int verseNumber) {
    final bookmarks = getAllBookmarks();
    return bookmarks.any(
      (b) => b.surahNumber == surahNumber && b.verseNumber == verseNumber,
    );
  }

  Future<bool> _saveBookmarks(List<QuranBookmark> bookmarks) async {
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    return _prefs.setString(_bookmarksKey, jsonEncode(jsonList));
  }

  LastReadPosition? getLastRead() {
    final jsonString = _prefs.getString(_lastReadKey);
    if (jsonString == null) return null;
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return LastReadPosition.fromJson(json);
  }

  Future<bool> saveLastRead(LastReadPosition position) async {
    return _prefs.setString(_lastReadKey, jsonEncode(position.toJson()));
  }

  Future<bool> clearLastRead() async {
    return _prefs.remove(_lastReadKey);
  }
}
