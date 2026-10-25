import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../catalogs/turath_catalog.dart';
import '../models/shamela_models.dart';
import 'shamela_download_manager.dart';
import 'shamela_html_parser.dart';
import 'shamela_remote_fetcher.dart';

export 'shamela_download_manager.dart'
    show ShamelaDownloadException, ShamelaDownloadManager;
export 'shamela_remote_fetcher.dart' show ShamelaRemoteFetcher;

class ShamelaService {
  static Database? _db;
  static const String _tableNamePages = 'shamela_pages';
  static const String _tableNameFihris = 'shamela_fihris';
  static const String _lastReadPrefix = 'shamela_last_read_';
  static const String _bookmarksKey = 'shamela_bookmarks';
  static const String _totalPagesPrefix = 'shamela_total_pages_';

  static const String tableNamePages = _tableNamePages;
  static bool isBundled(int bookId) => _bundledBookAssets.containsKey(bookId);
  static Iterable<int> get bundledBookIds => _bundledBookAssets.keys;
  static Future<Database> getDatabase() => _getDatabase();

  @visibleForTesting
  static void setMockDatabase(Database? db) => _db = db;

  static const Map<int, String> _bundledBookAssets = {
    50001: 'assets/data/minhaj_al_muslim.json',
  };
  static final Map<int, Map<String, dynamic>> _loadedBundledBooks = {};

  static final Map<int, int> _knownTotalPages = {};

  @visibleForTesting
  static http.Client get httpClient => ShamelaRemoteFetcher.httpClient;

  @visibleForTesting
  static void setHttpClient(http.Client? client) =>
      ShamelaRemoteFetcher.setHttpClient(client);

  @visibleForTesting
  static void resetHttpClient() => ShamelaRemoteFetcher.resetHttpClient();

  static Future<Map<String, dynamic>?> _getBundledBookData(int bookId) async {
    if (_loadedBundledBooks.containsKey(bookId)) {
      return _loadedBundledBooks[bookId];
    }
    final assetPath = _bundledBookAssets[bookId];
    if (assetPath == null) return null;
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      _loadedBundledBooks[bookId] = data;
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Curated Top Disciplines in the Heritage Library
  static List<ShamelaCategory> get categories => TurathCatalog.disciplines;

  /// Curated Classics Library across all disciplines
  static List<ShamelaBook> get curatedClassics => TurathCatalog.books;

  /// Get in-memory or fallback total pages for a book synchronously
  static int getEffectiveTotalPages(int bookId, int fallbackPages) {
    final cached = _knownTotalPages[bookId];
    if (cached != null && cached > 0) return cached;
    return fallbackPages;
  }

  /// Get discovered total pages from memory or SharedPreferences asynchronously
  static Future<int?> getDiscoveredTotalPages(int bookId) async {
    if (_knownTotalPages.containsKey(bookId) && _knownTotalPages[bookId]! > 0) {
      return _knownTotalPages[bookId];
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('$_totalPagesPrefix$bookId');
      if (saved != null && saved > 0) {
        _knownTotalPages[bookId] = saved;
        return saved;
      }
    } catch (_) {}
    return null;
  }

  /// Save discovered total pages to memory and SharedPreferences
  static Future<void> saveDiscoveredTotalPages(int bookId, int totalPages) async {
    if (totalPages <= 0) return;
    _knownTotalPages[bookId] = totalPages;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_totalPagesPrefix$bookId', totalPages);
    } catch (_) {}
  }

  /// Initialize local database for caching pages and table of contents
  static Future<Database> _getDatabase() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'shamela_library_v2.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableNamePages (
            book_id INTEGER,
            page_num INTEGER,
            part_num INTEGER,
            chapter_title TEXT,
            content TEXT,
            hamesh TEXT,
            cached_at INTEGER,
            detected_total_pages INTEGER,
            PRIMARY KEY (book_id, page_num)
          )
        ''');

        await db.execute('''
          CREATE TABLE $_tableNameFihris (
            book_id INTEGER,
            page_num INTEGER,
            title TEXT,
            PRIMARY KEY (book_id, page_num)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute(
              'ALTER TABLE $_tableNamePages ADD COLUMN detected_total_pages INTEGER',
            );
          } catch (_) {}
        }
      },
    );

    return _db!;
  }

  /// Search books across curated collection with level & rootOnly filtering
  static List<ShamelaBook> searchCatalog({
    String query = '',
    int categoryId = 0,
    int level = 0,
    bool rootOnly = false,
  }) =>
      TurathCatalog.search(
        query: query,
        categoryId: categoryId,
        level: level,
        rootOnly: rootOnly,
      );

  /// Get verified commentaries (شروح وحواشي) for a mother book
  static List<ShamelaBook> getShuruh(int parentId) =>
      TurathCatalog.getShuruh(parentId);

  /// Get parent mother book for a commentary
  static ShamelaBook? getParentBook(int parentId) =>
      TurathCatalog.getParentBook(parentId);

  /// Fetch single page content from local cache or stream from shamela.ws
  static Future<ShamelaPage> fetchPage({
    required int bookId,
    required int pageNumber,
  }) async {
    final db = await _getDatabase();

    // 1. Check local cache
    final localRows = await db.query(
      _tableNamePages,
      where: 'book_id = ? AND page_num = ?',
      whereArgs: [bookId, pageNumber],
      limit: 1,
    );

    if (localRows.isNotEmpty) {
      final row = localRows.first;
      final rawContent = row['content'] as String;
      final rawHamesh = row['hamesh'] as String?;
      final detected = row['detected_total_pages'] as int?;
      if (detected != null && detected > 0) {
        _knownTotalPages[bookId] = detected;
      }
      return ShamelaPage(
        bookId: bookId,
        pageNumber: pageNumber,
        partNumber: row['part_num'] as int?,
        chapterTitle: row['chapter_title'] as String?,
        content: sanitizeBookText(rawContent),
        hamesh: rawHamesh != null ? sanitizeBookText(rawHamesh) : null,
        detectedTotalPages: detected ?? _knownTotalPages[bookId],
      );
    }

    // 2. Check bundled assets for offline/local books
    if (_bundledBookAssets.containsKey(bookId)) {
      final bundled = await _getBundledBookData(bookId);
      if (bundled != null) {
        final pagesList = bundled['pages'] as List<dynamic>? ?? [];
        final totalP = bundled['totalPages'] as int? ?? pagesList.length;
        _knownTotalPages[bookId] = totalP;

        final pageMap = pagesList.cast<Map<String, dynamic>?>().firstWhere(
          (p) => p?['pageNumber'] == pageNumber,
          orElse: () => null,
        );

        if (pageMap != null) {
          final parsed = ShamelaPage(
            bookId: bookId,
            pageNumber: pageNumber,
            partNumber: null,
            chapterTitle: pageMap['chapterTitle'] as String?,
            content: sanitizeBookText(pageMap['content'] as String? ?? ''),
            hamesh: pageMap['hamesh'] != null
                ? sanitizeBookText(pageMap['hamesh'] as String)
                : null,
            detectedTotalPages: totalP,
          );

          await db.insert(
            _tableNamePages,
            {
              'book_id': bookId,
              'page_num': pageNumber,
              'part_num': parsed.partNumber,
              'chapter_title': parsed.chapterTitle,
              'content': parsed.content,
              'hamesh': parsed.hamesh,
              'cached_at': DateTime.now().millisecondsSinceEpoch,
              'detected_total_pages': totalP,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          return parsed;
        }
      }
      throw Exception('صفحة غير متوفرة في الكتاب');
    }

    // 3. Fetch over network
    final parsed = await ShamelaRemoteFetcher.fetchRemotePage(
      bookId: bookId,
      pageNumber: pageNumber,
    );

    // Save discovered total pages if parsed from page navigation
    if (parsed.detectedTotalPages != null && parsed.detectedTotalPages! > 0) {
      unawaited(saveDiscoveredTotalPages(bookId, parsed.detectedTotalPages!));
    }

    // 3. Save to local cache
    await db.insert(
      _tableNamePages,
      {
        'book_id': bookId,
        'page_num': pageNumber,
        'part_num': parsed.partNumber,
        'chapter_title': parsed.chapterTitle,
        'content': parsed.content,
        'hamesh': parsed.hamesh,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'detected_total_pages': parsed.detectedTotalPages,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return parsed;
  }

  /// Extract total pages dynamically from Maktaba Shamela page navigation HTML
  static int? extractTotalPagesFromHtml(int bookId, String html) =>
      ShamelaHtmlParser.extractTotalPagesFromHtml(bookId, html);

  /// Sanitize book content and footnotes by stripping email protection artifacts
  /// (e.g. Cloudflare [email&#160;protected], [email protected], etc.)
  static String sanitizeBookText(String text) =>
      ShamelaHtmlParser.sanitizeBookText(text);



  /// Fetch or load Table of Contents (الفهرس)
  static Future<List<ShamelaChapter>> fetchTableOfContents(
    int bookId, {
    bool forceRefresh = false,
  }) async {
    final db = await _getDatabase();

    // 1. Check local cache
    if (!forceRefresh) {
      final localRows = await db.query(
        _tableNameFihris,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'page_num ASC',
      );

      if (localRows.isNotEmpty) {
        return localRows
            .map((r) => ShamelaChapter(
                  title: r['title'] as String,
                  pageNumber: r['page_num'] as int,
                ))
            .toList();
      }
    }

    // 2. Check bundled asset
    if (_bundledBookAssets.containsKey(bookId)) {
      final bundled = await _getBundledBookData(bookId);
      if (bundled != null) {
        final rawChapters = bundled['chapters'] as List<dynamic>? ?? [];
        final chapters = rawChapters.map((c) {
          final map = c as Map<String, dynamic>;
          return ShamelaChapter(
            title: map['title'] as String? ?? '',
            pageNumber: map['pageNumber'] as int? ?? 1,
          );
        }).toList();

        final totalP = bundled['totalPages'] as int? ??
            (chapters.isNotEmpty ? chapters.last.pageNumber : 0);
        if (totalP > 0) {
          _knownTotalPages[bookId] = totalP;
          unawaited(saveDiscoveredTotalPages(bookId, totalP));
        }

        if (chapters.isNotEmpty) {
          await db.delete(
            _tableNameFihris,
            where: 'book_id = ?',
            whereArgs: [bookId],
          );
          final batch = db.batch();
          for (final c in chapters) {
            batch.insert(
              _tableNameFihris,
              {
                'book_id': bookId,
                'page_num': c.pageNumber,
                'title': c.title,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        }
        return chapters;
      }
    }

    // 3. Fetch from shamela.ws
    return await ShamelaRemoteFetcher.fetchRemoteTableOfContents(
      bookId: bookId,
      onDiscoveredTotalPages: (maxChapterPage) {
        final current = _knownTotalPages[bookId] ?? 0;
        if (maxChapterPage > current) {
          unawaited(saveDiscoveredTotalPages(bookId, maxChapterPage));
        }
      },
      onCommitValidFihris: (chapters) async {
        await db.delete(
          _tableNameFihris,
          where: 'book_id = ?',
          whereArgs: [bookId],
        );
        final batch = db.batch();
        for (final c in chapters) {
          batch.insert(
            _tableNameFihris,
            {
              'book_id': bookId,
              'page_num': c.pageNumber,
              'title': c.title,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
    );
  }

  /// Download entire book for full offline access with truthful completeness verification
  static Future<void> downloadBook(
    ShamelaBook book, {
    Function(int current, int total)? onProgress,
  }) =>
      ShamelaDownloadManager.downloadBook(book, onProgress: onProgress);

  /// Check if book is fully downloaded and verified offline
  static Future<bool> isBookDownloaded(int bookId, {int? totalPages}) =>
      ShamelaDownloadManager.isBookDownloaded(bookId, totalPages: totalPages);

  /// Returns a map of bookId -> isDownloaded for fast batch checking
  static Future<Map<int, bool>> getDownloadedBooksMap() =>
      ShamelaDownloadManager.getDownloadedBooksMap();

  /// Signal cancellation of download for [bookId]
  static void cancelDownload(int bookId) =>
      ShamelaDownloadManager.cancelDownload(bookId);

  /// Check if a download is currently active for [bookId]
  static bool isDownloading(int bookId) =>
      ShamelaDownloadManager.isDownloading(bookId);

  /// Get set of cached valid page numbers for [bookId]
  static Future<Set<int>> getCachedPageNumbers(int bookId) =>
      ShamelaDownloadManager.getCachedPageNumbers(bookId);

  /// Get list of missing page numbers in range 1..totalPages
  static Future<List<int>> getMissingPages(int bookId, int totalPages) =>
      ShamelaDownloadManager.getMissingPages(bookId, totalPages);

  /// Save last read position
  static Future<void> saveLastReadPage(int bookId, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_lastReadPrefix$bookId', page);
  }

  /// Get last read position
  static Future<int> getLastReadPage(int bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_lastReadPrefix$bookId') ?? 1;
  }

  /// Check if page is bookmarked
  static Future<bool> isPageBookmarked(int bookId, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_bookmarksKey) ?? [];
    return list.contains('${bookId}_$page');
  }

  /// Toggle bookmark for a page
  static Future<bool> toggleBookmark(int bookId, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_bookmarksKey) ?? [];
    final key = '${bookId}_$page';
    final exists = list.contains(key);

    if (exists) {
      list.remove(key);
      await prefs.setStringList(_bookmarksKey, list);
      return false;
    } else {
      list.add(key);
      await prefs.setStringList(_bookmarksKey, list);
      return true;
    }
  }

  /// Get all bookmarked page numbers for a book
  static Future<List<int>> getBookmarkedPages(int bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_bookmarksKey) ?? [];
    final prefix = '${bookId}_';
    final pages = <int>[];
    for (final item in list) {
      if (item.startsWith(prefix)) {
        final p = int.tryParse(item.substring(prefix.length));
        if (p != null) pages.add(p);
      }
    }
    pages.sort();
    return pages;
  }
}
