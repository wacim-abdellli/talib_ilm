import 'dart:async';
import 'dart:convert';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/async_lock.dart';
import '../models/bookmark_models.dart';

export '../models/bookmark_models.dart';

class BookmarkService {
  static const String _bookmarksKey = 'bookmarks_v2';
  static const String _lastReadKey = 'last_read_v2';

  // Legacy keys to migrate from
  static const String _legacyFavSurahsKey = 'dashboard_fav_surahs';
  static const String _legacyLastSurahKey = 'dashboard_last_surah';
  static const String _legacyLastAyahKey = 'dashboard_last_ayah';
  static const String _legacyLastPageKey = 'dashboard_last_page';
  static const String _legacyBookmarksKey = 'bookmarks';

  static final AsyncLock _lock = AsyncLock();

  /// Executes a read-modify-write repository transaction under [_lock].
  ///
  /// The [action] callback receives the mutable list of [Bookmark]s,
  /// performs reads, decisions, and mutations, and writes the resulting list
  /// back to storage before releasing the lock if [save] is true.
  static Future<T> _transaction<T>(
    FutureOr<T> Function(List<Bookmark> bookmarks) action, {
    bool save = true,
  }) async {
    return _lock.synchronized(() async {
      final bookmarks = await _loadBookmarksRaw();
      final result = await action(bookmarks);
      if (save) {
        await _saveBookmarks(bookmarks);
      }
      return result;
    });
  }

  /// Add or update a bookmark (Max 200) atomically under [_lock].
  static Future<void> addBookmark(
    int surah,
    int ayah, {
    String? note,
    bool isSurah = false,
  }) {
    if (!Bookmark.isValidCoordinates(surah, ayah)) {
      throw ArgumentError('Invalid Quran coordinates: surah $surah, ayah $ayah');
    }
    return _transaction((bookmarks) {
      bookmarks.removeWhere((b) => b.surah == surah && b.ayah == ayah && b.isSurah == isSurah);

      final page = quran.getPageNumber(surah, ayah);
      final newBookmark = Bookmark(
        surah: surah,
        ayah: ayah,
        page: page,
        note: note,
        timestamp: DateTime.now(),
        isSurah: isSurah,
      );

      bookmarks.insert(0, newBookmark);
      if (bookmarks.length > 200) {
        bookmarks.removeLast();
      }
    });
  }

  /// Remove a bookmark atomically under [_lock].
  static Future<void> removeBookmark(int surah, int ayah, {bool isSurah = false}) {
    return _transaction((bookmarks) {
      bookmarks.removeWhere(
        (b) => b.surah == surah && (isSurah ? b.isSurah : (b.ayah == ayah && !b.isSurah)),
      );
    });
  }

  /// Toggle Surah bookmark atomically under [_lock].
  static Future<bool> toggleSurahBookmark(int surah) {
    if (surah < 1 || surah > 114) {
      throw ArgumentError('Invalid Quran surah: $surah');
    }
    return _transaction((bookmarks) {
      final index = bookmarks.indexWhere((b) => b.surah == surah && b.isSurah);
      if (index != -1) {
        bookmarks.removeAt(index);
        return false;
      } else {
        final page = quran.getPageNumber(surah, 1);
        bookmarks.insert(
          0,
          Bookmark(
            surah: surah,
            ayah: 1,
            page: page,
            note: null,
            timestamp: DateTime.now(),
            isSurah: true,
          ),
        );
        if (bookmarks.length > 200) {
          bookmarks.removeLast();
        }
        return true;
      }
    });
  }

  /// Check if a Surah is specifically bookmarked
  static Future<bool> isSurahBookmarked(int surah) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.surah == surah && b.isSurah);
  }

  /// Check if an Ayah is specifically bookmarked
  static Future<bool> isAyahBookmarked(int surah, int ayah) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.surah == surah && b.ayah == ayah && !b.isSurah);
  }

  /// Check if an ayah is bookmarked
  static Future<bool> isBookmarked(int surah, int ayah) => isAyahBookmarked(surah, ayah);

  /// Toggle bookmark status for an ayah atomically under [_lock].
  static Future<bool> toggleBookmark(int surah, int ayah, {String? note}) {
    if (!Bookmark.isValidCoordinates(surah, ayah)) {
      throw ArgumentError('Invalid Quran coordinates: surah $surah, ayah $ayah');
    }
    return _transaction((bookmarks) {
      final index = bookmarks.indexWhere((b) => b.surah == surah && b.ayah == ayah && !b.isSurah);
      if (index != -1) {
        bookmarks.removeAt(index);
        return false;
      } else {
        final page = quran.getPageNumber(surah, ayah);
        bookmarks.insert(
          0,
          Bookmark(
            surah: surah,
            ayah: ayah,
            page: page,
            note: note,
            timestamp: DateTime.now(),
            isSurah: false,
          ),
        );
        if (bookmarks.length > 200) {
          bookmarks.removeLast();
        }
        return true;
      }
    });
  }

  /// Update note for a bookmark atomically under [_lock].
  static Future<void> updateNote(int surah, int ayah, String? note) {
    if (!Bookmark.isValidCoordinates(surah, ayah)) {
      throw ArgumentError('Invalid Quran coordinates: surah $surah, ayah $ayah');
    }
    return _transaction((bookmarks) {
      final index = bookmarks.indexWhere((b) => b.surah == surah && b.ayah == ayah && !b.isSurah);
      if (index != -1) {
        final old = bookmarks[index];
        bookmarks[index] = Bookmark(
          surah: old.surah,
          ayah: old.ayah,
          page: old.page,
          note: note,
          timestamp: DateTime.now(),
          isSurah: false,
        );
      } else {
        final page = quran.getPageNumber(surah, ayah);
        bookmarks.insert(
          0,
          Bookmark(
            surah: surah,
            ayah: ayah,
            page: page,
            note: note,
            timestamp: DateTime.now(),
            isSurah: false,
          ),
        );
        if (bookmarks.length > 200) {
          bookmarks.removeLast();
        }
      }
    });
  }

  /// Atomically merges imported bookmarks and optional lastRead into storage under [_lock].
  ///
  /// Guarantees that:
  /// 1. Bookmarks list is read, deduplicated, capped at 200, and saved in one transaction.
  /// 2. If [importedLastRead] is newer than stored last read, it is updated atomically
  ///    before releasing the lock.
  /// 3. Concurrent add/remove/toggle/update operations cannot interleave between
  ///    read and write.
  static Future<MergeResult> atomicMergeBookmarks({
    required List<Bookmark> importedBookmarks,
    required bool overwriteExistingNotes,
    LastRead? importedLastRead,
  }) async {
    return _lock.synchronized(() async {
      final current = await _loadBookmarksRaw();
      int added = 0;
      int updated = 0;
      int skipped = 0;

      for (final imported in importedBookmarks) {
        final existingIndex = current.indexWhere(
          (b) =>
              b.surah == imported.surah &&
              b.ayah == imported.ayah &&
              b.isSurah == imported.isSurah,
        );

        if (existingIndex == -1) {
          current.add(imported);
          added++;
        } else {
          final existing = current[existingIndex];
          if (overwriteExistingNotes) {
            current[existingIndex] = Bookmark(
              surah: imported.surah,
              ayah: imported.ayah,
              page: imported.page,
              note: imported.note ?? existing.note,
              timestamp: imported.timestamp,
              isSurah: imported.isSurah,
            );
            updated++;
          } else {
            skipped++;
          }
        }
      }

      while (current.length > 200) {
        current.removeLast();
      }

      await _saveBookmarks(current);

      if (importedLastRead != null) {
        final prefs = await SharedPreferences.getInstance();
        final currentLastRead = await _getLastReadRaw(prefs);
        if (importedLastRead.timestamp.isAfter(currentLastRead.timestamp)) {
          await _saveLastReadRaw(
            prefs,
            surah: importedLastRead.surah,
            ayah: importedLastRead.ayah,
            page: importedLastRead.page,
            timestamp: importedLastRead.timestamp,
          );
        }
      }

      return MergeResult(
        addedCount: added,
        updatedCount: updated,
        skippedCount: skipped,
      );
    });
  }

  /// Deprecated: Callers should not read a snapshot outside the lock and overwrite it.
  /// Use [_transaction], [atomicMergeBookmarks], or dedicated mutation methods instead.
  @Deprecated('Use atomic mutation methods or atomicMergeBookmarks to avoid lost updates.')
  static Future<void> saveAllBookmarks(List<Bookmark> bookmarks) {
    return _transaction((list) {
      list
        ..clear()
        ..addAll(bookmarks);
      if (list.length > 200) {
        list.removeRange(200, list.length);
      }
    });
  }

  /// Get all bookmarks with automatic legacy migration. Serialized under [_lock].
  static Future<List<Bookmark>> getBookmarks() async {
    return _lock.synchronized(() => _loadBookmarksRaw());
  }

  static Future<List<Bookmark>> _loadBookmarksRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_bookmarksKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is List) {
          final List<Bookmark> list = [];
          for (final item in decoded) {
            if (item is Map) {
              try {
                final map = item.map((k, v) => MapEntry(k.toString(), v));
                list.add(Bookmark.fromJson(map));
              } catch (_) {
                // Skip corrupt single entry
              }
            }
          }
          if (list.isNotEmpty) {
            return list;
          }
        }
      } catch (_) {}
    }

    // Attempt migration from v1 bookmarks
    final v1String = prefs.getString(_legacyBookmarksKey);
    if (v1String != null && v1String.isNotEmpty) {
      try {
        final decoded = jsonDecode(v1String);
        if (decoded is List) {
          final List<Bookmark> migrated = [];
          for (final item in decoded) {
            if (item is Map) {
              try {
                final map = item.map((k, v) => MapEntry(k.toString(), v));
                migrated.add(Bookmark.fromJson(map));
              } catch (_) {}
            }
          }
          if (migrated.isNotEmpty) {
            await _saveBookmarks(migrated);
            return migrated;
          }
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
              isSurah: true,
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

  static Future<void> _saveBookmarks(List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    final success = await prefs.setString(_bookmarksKey, jsonEncode(jsonList));
    if (!success) {
      throw StateError('Failed to persist bookmarks to storage');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAST READ POSITION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save last read position with surah, ayah, and page atomically under [_lock].
  static Future<void> saveLastRead({
    required int surah,
    required int ayah,
    int? page,
  }) {
    if (!Bookmark.isValidCoordinates(surah, ayah, page)) {
      throw ArgumentError('Invalid Quran coordinates: surah $surah, ayah $ayah, page $page');
    }
    return _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final p = page ?? quran.getPageNumber(surah, ayah);
      await _saveLastReadRaw(
        prefs,
        surah: surah,
        ayah: ayah,
        page: p,
        timestamp: DateTime.now(),
      );
    });
  }

  static Future<void> _saveLastReadRaw(
    SharedPreferences prefs, {
    required int surah,
    required int ayah,
    required int page,
    required DateTime timestamp,
  }) async {
    final lastRead = LastRead(
      surah: surah,
      ayah: ayah,
      page: page,
      timestamp: timestamp,
    );
    final success = await prefs.setString(_lastReadKey, jsonEncode(lastRead.toJson()));
    if (!success) {
      throw StateError('Failed to persist last read to storage');
    }
    // Also update legacy keys for maximum backward compatibility
    await prefs.setInt(_legacyLastSurahKey, surah);
    await prefs.setInt(_legacyLastAyahKey, ayah);
    await prefs.setInt(_legacyLastPageKey, page);
  }

  /// Check whether an explicit last read position has been recorded
  static Future<bool> hasSavedLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_lastReadKey) || prefs.containsKey(_legacyLastSurahKey);
  }

  /// Get last read position with automatic legacy fallback. Serialized under [_lock].
  static Future<LastRead> getLastRead() async {
    return _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      return _getLastReadRaw(prefs);
    });
  }

  static Future<LastRead> _getLastReadRaw(SharedPreferences prefs) async {
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
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
