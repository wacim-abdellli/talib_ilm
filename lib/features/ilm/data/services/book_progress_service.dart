import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/async_lock.dart';
import '../catalogs/mutun_curriculum_catalog.dart';
import '../catalogs/mutun_digital_catalog.dart';
import '../models/book_progress_model.dart';

class BookProgressService {
  static const String _progressKey = 'book_progress_data';
  static const String _sharhBookmarksKey = 'sharh_bookmarks';
  static const String _sharhNotesKey = 'sharh_notes';

  static final AsyncLock _lock = AsyncLock();

  final SharedPreferences _prefs;

  BookProgressService(this._prefs);

  // ═══════════════════════════════════════════
  // BOOK PROGRESS MANAGEMENT
  // ═══════════════════════════════════════════
  Future<int> getCompletedCount() async {
    final all = await getAllProgress();
    return all
        .where((p) =>
            p.totalPages > 1 &&
            p.currentPage >= p.totalPages &&
            p.completedDate != null)
        .length;
  }

  Future<bool> markCompleted(String bookId) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return false;

    if (progress.isCompleted && progress.completedDate != null) {
      return false; // already completed
    }

    final targetPage =
        progress.totalPages > 0 ? progress.totalPages : progress.currentPage;

    await saveBookProgress(progress.copyWith(
      currentPage: targetPage,
      completedDate: DateTime.now(),
    ));

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

  static String canonicalTitleFor(String bookId, [String? preferredTitle]) {
    if (preferredTitle != null &&
        preferredTitle.isNotEmpty &&
        !preferredTitle.startsWith('bk_') &&
        !preferredTitle.contains('_') &&
        preferredTitle != bookId) {
      return preferredTitle;
    }
    final curriculum = MutunCurriculumCatalog.getBook(bookId);
    if (curriculum != null && curriculum.title.isNotEmpty) {
      return curriculum.title;
    }
    final digital = MutunDigitalCatalog.getEntry(bookId);
    if (digital != null && digital.title.isNotEmpty) {
      return digital.title;
    }
    return (preferredTitle != null && preferredTitle.isNotEmpty)
        ? preferredTitle
        : bookId;
  }

  Future<List<BookProgress>> getAllProgress() async {
    final jsonString = _prefs.getString(_progressKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    dynamic decoded;
    try {
      decoded = json.decode(jsonString);
    } catch (_) {
      return [];
    }
    if (decoded is! List) return [];

    bool changed = false;
    final List<BookProgress> list = [];
    for (final jsonItem in decoded) {
      if (jsonItem is Map) {
        try {
          final typedItem = jsonItem.map((k, v) => MapEntry(k.toString(), v));
          final p = BookProgress.fromJson(typedItem);
          if (p.bookId.trim().isEmpty) {
            continue;
          }
          final isRaw = p.bookTitle.isEmpty ||
              p.bookTitle == p.bookId ||
              p.bookTitle.startsWith('bk_') ||
              p.bookTitle.contains('_');
          if (isRaw) {
            final canonical = canonicalTitleFor(p.bookId, p.bookTitle);
            if (canonical != p.bookTitle && canonical != p.bookId) {
              changed = true;
              list.add(p.copyWith(bookTitle: canonical));
              continue;
            }
          }
          list.add(p);
        } catch (_) {
          // Per-record recovery: ignore single corrupted book record
        }
      }
    }

    if (changed) {
      final encoded = json.encode(list.map((p) => p.toJson()).toList());
      await _prefs.setString(_progressKey, encoded);
    }

    return list;
  }

  Future<BookProgress?> getBookProgress(String bookId) async {
    final allProgress = await getAllProgress();
    try {
      return allProgress.firstWhere((progress) => progress.bookId == bookId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBookProgress(BookProgress progress) {
    return _lock.synchronized(() async {
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
        allProgress.map((p) => p.toJson()).toList(),
      );
      await _prefs.setString(_progressKey, jsonString);
    });
  }

  Future<void> updateCurrentPage(
    String bookId,
    int page, {
    int? totalPages,
    String? title,
    String? level,
  }) async {
    final resolvedTitle = canonicalTitleFor(bookId, title);
    final progress = await getBookProgress(bookId);
    if (progress == null) {
      final now = DateTime.now();
      final effectiveTotal = totalPages ?? 1;
      final isActuallyCompleted = effectiveTotal > 1 && page >= effectiveTotal;
      final newProgress = BookProgress(
        bookId: bookId,
        bookTitle: resolvedTitle,
        level: level ?? 'المكتبة الإسلامية',
        totalPages: effectiveTotal > 0 ? effectiveTotal : 1,
        currentPage: page,
        lastReadDate: now,
        startedDate: now,
        completedDate: isActuallyCompleted ? now : null,
      );
      await saveBookProgress(newProgress);
      return;
    }

    final effectiveTotal = (totalPages != null && totalPages > 0)
        ? totalPages
        : progress.totalPages;

    final isActuallyCompleted = effectiveTotal > 1 && page >= effectiveTotal;

    final isExistingRaw = progress.bookTitle.isEmpty ||
        progress.bookTitle == progress.bookId ||
        progress.bookTitle.startsWith('bk_') ||
        progress.bookTitle.contains('_');

    final updatedProgress = progress.copyWith(
      bookTitle: isExistingRaw ? resolvedTitle : progress.bookTitle,
      totalPages: effectiveTotal > 0 ? effectiveTotal : null,
      currentPage: page,
      lastReadDate: DateTime.now(),
      clearCompletedDate: !isActuallyCompleted,
      completedDate: isActuallyCompleted
          ? (progress.completedDate ?? DateTime.now())
          : null,
    );

    await saveBookProgress(updatedProgress);
  }

  Future<void> updateTotalPages(String bookId, int totalPages) async {
    if (totalPages <= 0) return;
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    if (totalPages != progress.totalPages) {
      final isCompleted = totalPages > 1 && progress.currentPage >= totalPages;
      await saveBookProgress(progress.copyWith(
        totalPages: totalPages,
        clearCompletedDate: !isCompleted,
      ));
    }
  }

  Future<void> addBookmark(String bookId, int page, {String? title}) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    final bookmarks = List<int>.from(progress.bookmarkedPages);
    if (!bookmarks.contains(page)) {
      bookmarks.add(page);
      bookmarks.sort();
    }

    final resolvedTitle = canonicalTitleFor(bookId, title ?? progress.bookTitle);
    final isExistingRaw = progress.bookTitle.isEmpty ||
        progress.bookTitle == progress.bookId ||
        progress.bookTitle.startsWith('bk_') ||
        progress.bookTitle.contains('_');

    final updatedProgress = progress.copyWith(
      bookTitle: isExistingRaw ? resolvedTitle : progress.bookTitle,
      bookmarkedPages: bookmarks,
    );
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

  Future<void> saveNote(String bookId, int page, String note, {String? title}) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) return;

    final notes = Map<int, String>.from(progress.notes);
    notes[page] = note;

    final resolvedTitle = canonicalTitleFor(bookId, title ?? progress.bookTitle);
    final isExistingRaw = progress.bookTitle.isEmpty ||
        progress.bookTitle == progress.bookId ||
        progress.bookTitle.startsWith('bk_') ||
        progress.bookTitle.contains('_');

    final updatedProgress = progress.copyWith(
      bookTitle: isExistingRaw ? resolvedTitle : progress.bookTitle,
      notes: notes,
    );
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

  Future<void> toggleFavorite(String bookId, {String? title, String? level}) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) {
      final now = DateTime.now();
      final initial = BookProgress(
        bookId: bookId,
        bookTitle: title ?? bookId,
        level: level ?? 'المستوى التمهيدي',
        totalPages: 1,
        currentPage: 1,
        lastReadDate: now,
        startedDate: now,
        isFavorite: true,
      );
      await saveBookProgress(initial);
      return;
    }

    final updatedProgress = progress.copyWith(isFavorite: !progress.isFavorite);
    await saveBookProgress(updatedProgress);
  }

  Future<void> setFavorite(String bookId, bool isFavorite, {String? title, String? level}) async {
    final progress = await getBookProgress(bookId);
    if (progress == null) {
      final now = DateTime.now();
      final initial = BookProgress(
        bookId: bookId,
        bookTitle: title ?? bookId,
        level: level ?? 'المستوى التمهيدي',
        totalPages: 1,
        currentPage: 1,
        lastReadDate: now,
        startedDate: now,
        isFavorite: isFavorite,
      );
      await saveBookProgress(initial);
      return;
    }

    final updatedProgress = progress.copyWith(isFavorite: isFavorite);
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
        .where((progress) =>
            (!progress.isCompleted ||
                progress.currentPage < progress.totalPages) &&
            progress.currentPage >= 1)
        .toList()
      ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));
  }

  /// Retrieves the absolute last book touched by the user for real-time instant resume.
  Future<BookProgress?> getLastReadBook() async {
    final active = await getCurrentlyReading();
    if (active.isNotEmpty) return active.first;
    final all = await getAllProgress();
    if (all.isEmpty) return null;
    all.sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));
    return all.first;
  }

  Future<List<BookProgress>> getCompletedBooks() async {
    final allProgress = await getAllProgress();

    final completed = allProgress
        .where((p) =>
            p.totalPages > 1 &&
            p.currentPage >= p.totalPages &&
            p.completedDate != null)
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
    final resolvedTitle = canonicalTitleFor(bookId, bookTitle);
    final existing = await getBookProgress(bookId);
    if (existing != null) {
      final isExistingRaw = existing.bookTitle.isEmpty ||
          existing.bookTitle == bookId ||
          existing.bookTitle.startsWith('bk_') ||
          existing.bookTitle.contains('_');
      final targetTitle = isExistingRaw ? resolvedTitle : existing.bookTitle;
      final shouldUpdateTotal = totalPages > existing.totalPages;

      if (isExistingRaw || shouldUpdateTotal) {
        final targetTotal = shouldUpdateTotal ? totalPages : existing.totalPages;
        final isCompleted = targetTotal > 1 && existing.currentPage >= targetTotal;
        await saveBookProgress(existing.copyWith(
          bookTitle: targetTitle,
          totalPages: targetTotal,
          clearCompletedDate: !isCompleted,
        ));
      }
      return;
    }

    final now = DateTime.now();
    final newProgress = BookProgress(
      bookId: bookId,
      bookTitle: resolvedTitle,
      level: level,
      totalPages: totalPages > 0 ? totalPages : 1,
      currentPage: 1,
      lastReadDate: now,
      startedDate: now,
    );

    await saveBookProgress(newProgress);
  }

  Future<void> auditAndHealCatalogProgress(
    Map<String, int> catalogTotals,
  ) async {
    final all = await getAllProgress();
    bool changed = false;

    for (int i = 0; i < all.length; i++) {
      final p = all[i];
      final canonicalTotal = catalogTotals[p.bookId];
      if (canonicalTotal != null && canonicalTotal > 0) {
        final targetTotal = canonicalTotal;
        final clampedPage = p.currentPage > targetTotal ? targetTotal : p.currentPage;
        final isCompleted = targetTotal > 1 && clampedPage >= targetTotal;
        final shouldClearComplete = !isCompleted && p.completedDate != null;
        final shouldSetComplete = isCompleted && p.completedDate == null;
        final shouldUpdateTotal = targetTotal != p.totalPages || clampedPage != p.currentPage;

        if (shouldClearComplete || shouldSetComplete || shouldUpdateTotal) {
          all[i] = p.copyWith(
            totalPages: targetTotal,
            currentPage: clampedPage,
            clearCompletedDate: !isCompleted,
            completedDate: isCompleted ? (p.completedDate ?? DateTime.now()) : null,
          );
          changed = true;
        }
      }
    }

    if (changed) {
      final jsonString = json.encode(
        all.map((p) => p.toJson()).toList(),
      );
      await _prefs.setString(_progressKey, jsonString);
    }
  }
}
