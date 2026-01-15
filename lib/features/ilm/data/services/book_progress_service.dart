import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_progress_model.dart';

class BookProgressService {
  static const String _progressKey = 'book_progress_data';
  static const String _sharhBookmarksKey = 'sharh_bookmarks';
  static const String _sharhNotesKey = 'sharh_notes';

  final SharedPreferences _prefs;

  BookProgressService(this._prefs);

  // ═══════════════════════════════════════════
  // BOOK PROGRESS MANAGEMENT
  // ═══════════════════════════════════════════
  Future<int> getCompletedCount() async {
    final all = await getAllProgress();
    return all.where((p) => p.isCompleted).length;
  }

  Future<bool> markCompleted(String bookId) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return false;

    if (progress.isCompleted && progress.completedDate != null) {
      return false; // already completed
    }

    await saveBookProgress(progress.copyWith(completedDate: DateTime.now()));

    return true;
  }

  Future<void> resetBook(String bookId) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    final reset = BookProgress(
      bookId: progress.bookId,
      bookTitle: progress.bookTitle,
      level: progress.level,
      totalPages: progress.totalPages,
      currentPage: 1,
      lastReadDate: DateTime.now(),
      startedDate: DateTime.now(),
      bookmarkedPages: const [],
      notes: const {},
      totalReadingTimeMinutes: 0,
      isFavorite: progress.isFavorite,
      completedDate: null,
    );

    await saveBookProgress(reset);
  }

  Future<List<BookProgress>> getAllProgress() async {
    final jsonString = _prefs.getString(_progressKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((jsonItem) => BookProgress.fromJson(jsonItem)).toList();
  }

  Future<BookProgress?> getBookProgress(String bookId) async {
    final allProgress = await getAllProgress();
    try {
      return allProgress.firstWhere((progress) => progress.bookId == bookId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBookProgress(BookProgress progress) async {
    final allProgress = await getAllProgress();
    final index = allProgress.indexWhere(
      (existing) => existing.bookId == progress.bookId,
    );

    if (index >= 0) {
      allProgress[index] = progress;
    } else {
      allProgress.add(progress);
    }

    final jsonString = json.encode(
      allProgress.map((progress) => progress.toJson()).toList(),
    );
    await _prefs.setString(_progressKey, jsonString);
  }

  Future<void> updateCurrentPage(String bookId, int page) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    final updatedProgress = progress.copyWith(
      currentPage: page,
      lastReadDate: DateTime.now(),
    );

    await saveBookProgress(updatedProgress);
  }

  Future<void> addBookmark(String bookId, int page) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    final bookmarks = List<int>.from(progress.bookmarkedPages);
    if (!bookmarks.contains(page)) {
      bookmarks.add(page);
      bookmarks.sort();
    }

    final updatedProgress = progress.copyWith(bookmarkedPages: bookmarks);
    await saveBookProgress(updatedProgress);
  }

  Future<void> removeBookmark(String bookId, int page) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    final bookmarks = List<int>.from(progress.bookmarkedPages);
    bookmarks.remove(page);

    final updatedProgress = progress.copyWith(bookmarkedPages: bookmarks);
    await saveBookProgress(updatedProgress);
  }

  Future<void> saveNote(String bookId, int page, String note) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    final notes = Map<int, String>.from(progress.notes);
    notes[page] = note;

    final updatedProgress = progress.copyWith(notes: notes);
    await saveBookProgress(updatedProgress);
  }

  Future<void> deleteNote(String bookId, int page) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    final notes = Map<int, String>.from(progress.notes);
    notes.remove(page);

    final updatedProgress = progress.copyWith(notes: notes);
    await saveBookProgress(updatedProgress);
  }

  Future<void> toggleFavorite(String bookId) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    final updatedProgress = progress.copyWith(isFavorite: !progress.isFavorite);
    await saveBookProgress(updatedProgress);
  }

  Future<void> addReadingTime(String bookId, int minutes) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    final updatedProgress = progress.copyWith(
      totalReadingTimeMinutes: progress.totalReadingTimeMinutes + minutes,
    );
    await saveBookProgress(updatedProgress);
  }

  // ═══════════════════════════════════════════
  // STATISTICS & QUERIES
  // ═══════════════════════════════════════════

  Future<List<BookProgress>> getRecentlyRead() async {
    final allProgress = await getAllProgress();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    return allProgress
        .where((progress) => progress.lastReadDate.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));
  }

  Future<List<BookProgress>> getCurrentlyReading() async {
    final allProgress = await getAllProgress();
    return allProgress
        .where((progress) => !progress.isCompleted && progress.currentPage > 1)
        .toList()
      ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));
  }

  Future<List<BookProgress>> getCompletedBooks() async {
    final allProgress = await getAllProgress();

    final completed = allProgress
        .where((p) => p.isCompleted && p.completedDate != null)
        .toList();

    completed.sort((a, b) => b.completedDate!.compareTo(a.completedDate!));

    return completed;
  }

  Future<List<BookProgress>> getFavoriteBooks() async {
    final allProgress = await getAllProgress();
    return allProgress.where((progress) => progress.isFavorite).toList();
  }

  Future<List<BookProgress>> getBooksByLevel(String level) async {
    final allProgress = await getAllProgress();
    return allProgress.where((progress) => progress.level == level).toList();
  }

  Future<int> getTotalReadingTime() async {
    final allProgress = await getAllProgress();
    return allProgress.fold<int>(
      0,
      (sum, progress) => sum + progress.totalReadingTimeMinutes,
    );
  }

  Future<double> getOverallProgress() async {
    final allProgress = await getAllProgress();
    if (allProgress.isEmpty) return 0.0;

    final totalProgress = allProgress.fold(
      0.0,
      (sum, progress) => sum + progress.progressPercentage,
    );

    return totalProgress / allProgress.length;
  }

  Future<int> getCurrentStreak() async {
    final allProgress = await getAllProgress();
    if (allProgress.isEmpty) return 0;

    final sorted = allProgress.toList()
      ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));

    var streak = 0;
    var checkDate = DateTime.now();

    for (final progress in sorted) {
      if (_isSameDay(progress.lastReadDate, checkDate) ||
          _isSameDay(
            progress.lastReadDate,
            checkDate.subtract(const Duration(days: 1)),
          )) {
        streak++;
        checkDate = progress.lastReadDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ═══════════════════════════════════════════
  // SHARH BOOKMARKS & NOTES
  // ═══════════════════════════════════════════

  String _sharhKey(String bookId, String sharhFile) => '$bookId|$sharhFile';

  Future<Map<String, List<int>>> _loadSharhBookmarks() async {
    final jsonString = _prefs.getString(_sharhBookmarksKey);
    if (jsonString == null) return {};
    final raw = json.decode(jsonString) as Map<String, dynamic>;
    return {
      for (final entry in raw.entries)
        entry.key: (entry.value as List<dynamic>)
            .map((value) => value is int ? value : int.tryParse('$value') ?? 0)
            .where((page) => page > 0)
            .toList(),
    };
  }

  Future<void> _saveSharhBookmarks(Map<String, List<int>> data) async {
    final jsonString = json.encode(data);
    await _prefs.setString(_sharhBookmarksKey, jsonString);
  }

  Future<List<int>> getSharhBookmarks(String bookId, String sharhFile) async {
    final data = await _loadSharhBookmarks();
    return data[_sharhKey(bookId, sharhFile)] ?? <int>[];
  }

  Future<void> addSharhBookmark(
    String bookId,
    String sharhFile,
    int page,
  ) async {
    final data = await _loadSharhBookmarks();
    final key = _sharhKey(bookId, sharhFile);
    final pages = List<int>.from(data[key] ?? <int>[]);
    if (!pages.contains(page)) {
      pages.add(page);
      pages.sort();
    }
    data[key] = pages;
    await _saveSharhBookmarks(data);
  }

  Future<void> removeSharhBookmark(
    String bookId,
    String sharhFile,
    int page,
  ) async {
    final data = await _loadSharhBookmarks();
    final key = _sharhKey(bookId, sharhFile);
    final pages = List<int>.from(data[key] ?? <int>[])..remove(page);
    data[key] = pages;
    await _saveSharhBookmarks(data);
  }

  Future<Map<String, Map<int, String>>> _loadSharhNotes() async {
    final jsonString = _prefs.getString(_sharhNotesKey);
    if (jsonString == null) return {};
    final raw = json.decode(jsonString) as Map<String, dynamic>;
    final result = <String, Map<int, String>>{};
    for (final entry in raw.entries) {
      final notesRaw = entry.value as Map<String, dynamic>;
      result[entry.key] = {
        for (final note in notesRaw.entries)
          int.tryParse(note.key) ?? 0: note.value?.toString() ?? '',
      }..removeWhere((key, value) => key == 0 || value.isEmpty);
    }
    return result;
  }

  Future<void> _saveSharhNotes(Map<String, Map<int, String>> data) async {
    final encoded = {
      for (final entry in data.entries)
        entry.key: {
          for (final note in entry.value.entries)
            note.key.toString(): note.value,
        },
    };
    await _prefs.setString(_sharhNotesKey, json.encode(encoded));
  }

  Future<Map<int, String>> getSharhNotes(
    String bookId,
    String sharhFile,
  ) async {
    final data = await _loadSharhNotes();
    return data[_sharhKey(bookId, sharhFile)] ?? <int, String>{};
  }

  Future<void> saveSharhNote(
    String bookId,
    String sharhFile,
    int page,
    String note,
  ) async {
    final data = await _loadSharhNotes();
    final key = _sharhKey(bookId, sharhFile);
    final notes = Map<int, String>.from(data[key] ?? <int, String>{});
    notes[page] = note;
    data[key] = notes;
    await _saveSharhNotes(data);
  }

  Future<void> deleteSharhNote(
    String bookId,
    String sharhFile,
    int page,
  ) async {
    final data = await _loadSharhNotes();
    final key = _sharhKey(bookId, sharhFile);
    final notes = Map<int, String>.from(data[key] ?? <int, String>{});
    notes.remove(page);
    data[key] = notes;
    await _saveSharhNotes(data);
  }

  Future<Map<String, List<int>>> getAllSharhBookmarks() async {
    return _loadSharhBookmarks();
  }

  Future<Map<String, Map<int, String>>> getAllSharhNotes() async {
    return _loadSharhNotes();
  }

  Future<void> initializeBook({
    required String bookId,
    required String bookTitle,
    required String level,
    required int totalPages,
  }) async {
    final existing = await getBookProgress(bookId);
    if (existing != null) return;

    final now = DateTime.now();
    final newProgress = BookProgress(
      bookId: bookId,
      bookTitle: bookTitle,
      level: level,
      totalPages: totalPages,
      currentPage: 1,
      lastReadDate: now,
      startedDate: now,
    );

    await saveBookProgress(newProgress);
  }
}
