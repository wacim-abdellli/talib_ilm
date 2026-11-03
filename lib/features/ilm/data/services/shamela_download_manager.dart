import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_policy.dart';
import '../models/shamela_models.dart';
import 'shamela_service.dart';

/// Exception thrown when book download fails or cannot be completed truth-verified.
class ShamelaDownloadException implements Exception {
  final String message;
  final int bookId;
  final List<int> failedPages;

  const ShamelaDownloadException(
    this.message, {
    this.bookId = 0,
    this.failedPages = const [],
  });

  @override
  String toString() => message;
}

/// Truthful, resilient download manager for Maktaba Shamela books.
/// Enforces complete offline page verification, gap detection, and concurrent guards.
class ShamelaDownloadManager {
  const ShamelaDownloadManager._();

  static final Map<int, Future<void>> _activeDownloads = {};
  static final Map<int, bool> _cancelFlags = {};

  @visibleForTesting
  static Future<ShamelaPage> Function({required int bookId, required int pageNumber})?
      mockPageFetcher;

  /// Check if a download is currently running for [bookId]
  static bool isDownloading(int bookId) => _activeDownloads.containsKey(bookId);

  /// Signal cancellation for [bookId]
  static void cancelDownload(int bookId) {
    _cancelFlags[bookId] = true;
  }

  /// Get set of cached valid page numbers for [bookId]
  static Future<Set<int>> getCachedPageNumbers(int bookId) async {
    final db = await ShamelaService.getDatabase();
    final rows = await db.query(
      ShamelaService.tableNamePages,
      columns: ['page_num'],
      where: 'book_id = ? AND content IS NOT NULL AND length(trim(content)) > 0',
      whereArgs: [bookId],
    );
    return rows.map((r) => r['page_num'] as int).toSet();
  }

  /// Get list of missing page numbers in range 1..totalPages
  static Future<List<int>> getMissingPages(int bookId, int totalPages) async {
    if (totalPages <= 0) return const [];
    final cached = await getCachedPageNumbers(bookId);
    final missing = <int>[];
    for (int p = 1; p <= totalPages; p++) {
      if (!cached.contains(p)) {
        missing.add(p);
      }
    }
    return missing;
  }

  /// One-time cleanup for any legacy flags that falsely marked bundled books as downloaded.
  static Future<void> _cleanLegacyBundledPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('shamela_legacy_cleaned_v5')) {
      for (final id in ShamelaService.bundledBookIds) {
        await prefs.remove('shamela_downloaded_$id');
      }
      await prefs.setBool('shamela_legacy_cleaned_v5', true);
    }
  }

  /// Check if book is fully downloaded and verified offline
  static Future<bool> isBookDownloaded(int bookId, {int? totalPages}) async {
    await _cleanLegacyBundledPrefs();
    final prefs = await SharedPreferences.getInstance();

    // Bundled books are available in assets, but only reported as downloaded
    // if the user explicitly downloaded/saved them to their offline list.
    if (ShamelaService.isBundled(bookId)) {
      return prefs.getBool('shamela_downloaded_$bookId') == true;
    }

    int total = totalPages ?? await ShamelaService.getDiscoveredTotalPages(bookId) ?? 0;
    if (total <= 0) {
      final catalogBook = ShamelaService.curatedClassics.cast<ShamelaBook?>().firstWhere(
        (b) => b?.id == bookId,
        orElse: () => null,
      );
      total = catalogBook?.totalPages ?? 0;
    }

    if (total <= 0) {
      if (prefs.getBool('shamela_downloaded_$bookId') == true) {
        await prefs.setBool('shamela_downloaded_$bookId', false);
      }
      return false;
    }

    final cachedPages = await getCachedPageNumbers(bookId);
    if (cachedPages.length < total) {
      if (prefs.getBool('shamela_downloaded_$bookId') == true) {
        await prefs.setBool('shamela_downloaded_$bookId', false);
      }
      return false;
    }

    for (int p = 1; p <= total; p++) {
      if (!cachedPages.contains(p)) {
        if (prefs.getBool('shamela_downloaded_$bookId') == true) {
          await prefs.setBool('shamela_downloaded_$bookId', false);
        }
        return false;
      }
    }

    // Fully verified! Sync SharedPreferences flag.
    if (prefs.getBool('shamela_downloaded_$bookId') != true) {
      await prefs.setBool('shamela_downloaded_$bookId', true);
    }
    return true;
  }

  /// Returns a map of bookId -> isDownloaded for fast batch checking in catalog views
  static Future<Map<int, bool>> getDownloadedBooksMap() async {
    await _cleanLegacyBundledPrefs();
    final map = <int, bool>{};
    final prefs = await SharedPreferences.getInstance();

    // Bundled books only show up if explicitly downloaded/saved by user
    for (final id in ShamelaService.bundledBookIds) {
      map[id] = prefs.getBool('shamela_downloaded_$id') == true;
    }

    final db = await ShamelaService.getDatabase();
    final rows = await db.rawQuery(
      'SELECT book_id, COUNT(page_num) as cnt FROM ${ShamelaService.tableNamePages} '
      'WHERE content IS NOT NULL AND length(trim(content)) > 0 '
      'GROUP BY book_id',
    );

    final counts = <int, int>{};
    for (final row in rows) {
      final bId = row['book_id'] as int;
      final cnt = row['cnt'] as int;
      counts[bId] = cnt;
    }

    for (final book in ShamelaService.curatedClassics) {
      if (map.containsKey(book.id)) continue;
      final isMarked = prefs.getBool('shamela_downloaded_${book.id}') == true;
      final cachedCount = counts[book.id] ?? 0;
      final total = await ShamelaService.getDiscoveredTotalPages(book.id) ?? book.totalPages;
      if (isMarked || (cachedCount > 0 && total > 0 && cachedCount >= total)) {
        map[book.id] = true;
      } else {
        map[book.id] = false;
      }
    }

    // Include any downloaded books discovered via search/catalog
    for (final entry in counts.entries) {
      if (map.containsKey(entry.key)) continue;
      final isMarked = prefs.getBool('shamela_downloaded_${entry.key}') == true;
      final total = await ShamelaService.getDiscoveredTotalPages(entry.key);
      if (isMarked || (total != null && total > 0 && entry.value >= total)) {
        map[entry.key] = true;
      } else {
        map[entry.key] = false;
      }
    }

    return map;
  }

  /// Delete all downloaded and cached pages for [bookId] and reset downloaded status
  static Future<void> deleteBook(int bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shamela_downloaded_$bookId');
    await prefs.setBool('shamela_downloaded_$bookId', false);

    final db = await ShamelaService.getDatabase();
    await db.delete(
      ShamelaService.tableNamePages,
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }

  /// Download entire book for full offline access with truthful completeness verification
  static Future<void> downloadBook(
    ShamelaBook book, {
    Function(int current, int total)? onProgress,
  }) async {
    // If a download is already running for this book, join it
    if (_activeDownloads.containsKey(book.id)) {
      return _activeDownloads[book.id]!;
    }

    final completer = Completer<void>();
    _activeDownloads[book.id] = completer.future;
    // Attach error sink so if completer fails without concurrent listeners,
    // Dart doesn't treat it as an unhandled Zone error.
    completer.future.ignore();

    try {
      _cancelFlags[book.id] = false;

      // Bundled books are bundled in assets; user downloading marks it as saved offline
      if (ShamelaService.isBundled(book.id)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('shamela_downloaded_${book.id}', true);
        onProgress?.call(book.totalPages, book.totalPages);
        completer.complete();
        return;
      }

      // 1. Determine truthful total pages
      int total = await ShamelaService.getDiscoveredTotalPages(book.id) ?? book.totalPages;
      if (total <= 0) {
        try {
          final firstPage = mockPageFetcher != null
              ? await mockPageFetcher!(bookId: book.id, pageNumber: 1)
              : await ShamelaService.fetchPage(bookId: book.id, pageNumber: 1);
          total = firstPage.detectedTotalPages ?? book.totalPages;
          if (total > 0) {
            await ShamelaService.saveDiscoveredTotalPages(book.id, total);
          }
        } catch (_) {
          total = book.totalPages;
        }
      }

      if (total <= 0) {
        throw ShamelaDownloadException(
          'تعذر تحديد عدد صفحات الكتاب لتحميله، يرجى التحقق من الاتصال بالإنترنت والمحاولة مجدداً',
          bookId: book.id,
        );
      }

      // 2. Query already cached valid pages
      final cachedPages = await getCachedPageNumbers(book.id);

      // If already completely downloaded, ensure flag and exit
      if (cachedPages.length >= total &&
          List.generate(total, (i) => i + 1).every(cachedPages.contains)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('shamela_downloaded_${book.id}', true);
        onProgress?.call(total, total);
        completer.complete();
        return;
      }

      final failedPages = <int>[];
      int completedCount = 0;
      for (int p = 1; p <= total; p++) {
        if (cachedPages.contains(p)) completedCount++;
      }
      onProgress?.call(completedCount, total);

      // 3. Download missing pages
      for (int p = 1; p <= total; p++) {
        if (_cancelFlags[book.id] == true) {
          throw ShamelaDownloadException(
            'تم إلغاء تحميل الكتاب',
            bookId: book.id,
          );
        }

        // Skip pages that are already validated in local cache
        if (cachedPages.contains(p)) {
          continue;
        }

        try {
          final page = mockPageFetcher != null
              ? await mockPageFetcher!(bookId: book.id, pageNumber: p)
              : await ShamelaService.fetchPage(bookId: book.id, pageNumber: p);
          if (page.content.trim().isEmpty) {
            failedPages.add(p);
          } else {
            if (mockPageFetcher != null) {
              final db = await ShamelaService.getDatabase();
              await db.insert(
                ShamelaService.tableNamePages,
                {
                  'book_id': page.bookId,
                  'page_num': page.pageNumber,
                  'content': page.content,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            cachedPages.add(p);
            completedCount++;
            onProgress?.call(completedCount, total);
          }
          await Future.delayed(AppPolicy.microPause);
        } catch (_) {
          failedPages.add(p);
        }
      }

      // 4. Verify completeness truth against database
      final missing = await getMissingPages(book.id, total);
      if (missing.isNotEmpty || failedPages.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('shamela_downloaded_${book.id}', false);
        throw ShamelaDownloadException(
          'فشل تحميل ${missing.length} صفحة من أصل $total، يمكنك إعادة المحاولة لاستكمال النواقص',
          bookId: book.id,
          failedPages: missing,
        );
      }

      // All pages validated and cached successfully!
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shamela_downloaded_${book.id}', true);
      onProgress?.call(total, total);
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _activeDownloads.remove(book.id);
      _cancelFlags.remove(book.id);
    }
  }
}
