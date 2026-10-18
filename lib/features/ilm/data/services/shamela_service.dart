import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../app/theme/app_palette.dart';
import '../catalogs/turath_catalog.dart';
import '../models/shamela_models.dart';

class ShamelaService {
  static Database? _db;
  static const String _tableNamePages = 'shamela_pages';
  static const String _tableNameFihris = 'shamela_fihris';
  static const String _lastReadPrefix = 'shamela_last_read_';
  static const String _bookmarksKey = 'shamela_bookmarks';
  static const String _totalPagesPrefix = 'shamela_total_pages_';

  static final Map<int, int> _knownTotalPages = {};
  static final http.Client _httpClient = http.Client();

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
  }) {
    return TurathCatalog.search(
      query: query,
      categoryId: categoryId,
      level: level,
      rootOnly: rootOnly,
    );
  }

  /// Get verified commentaries (شروح وحواشي) for a mother book
  static List<ShamelaBook> getShuruh(int parentId) {
    return TurathCatalog.getShuruh(parentId);
  }

  /// Get parent mother book for a commentary
  static ShamelaBook? getParentBook(int parentId) {
    return TurathCatalog.getParentBook(parentId);
  }

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

    // 2. Fetch over network
    final url = Uri.parse('https://shamela.ws/book/$bookId/$pageNumber');
    final response = await _httpClient.get(
      url,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'ar,en;q=0.9',
      },
    ).timeout(AppMotion.networkTimeout);

    if (response.statusCode == 404) {
      throw Exception('صفحة غير متوفرة في الكتاب (404)');
    }
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الصفحة من المكتبة الشاملة (${response.statusCode})');
    }

    final html = utf8.decode(response.bodyBytes, allowMalformed: true);
    final parsed = _parsePageHtml(bookId, pageNumber, html);

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

  /// Parse raw Shamela HTML into clean structured Arabic text
  static ShamelaPage _parsePageHtml(int bookId, int pageNumber, String html) {
    // Extract nass container
    final nassRegex = RegExp(
      r"""<div[^>]*class=["'][^"']*nass[^"']*["'][^>]*>(.*?)</div>""",
      dotAll: true,
    );
    final match = nassRegex.firstMatch(html);
    String rawBody = match != null ? match.group(1)! : html;

    // Check for printed page and volume
    int? partNum;
    final partMatch = RegExp(r'الجزء\s*:?\s*(\d+)').firstMatch(html);
    if (partMatch != null) {
      partNum = int.tryParse(partMatch.group(1)!);
    }

    // Extract active chapter title if available
    String? chapterTitle;
    final chapterMatch = RegExp(
      r'<h6>مسار الصفحة الحالية:</h6>.*?<a[^>]*>(.*?)</a>',
      dotAll: true,
    ).firstMatch(html);
    if (chapterMatch != null) {
      chapterTitle = _cleanHtml(chapterMatch.group(1)!);
    }

    // Extract footnotes (hamesh)
    String? hamesh;
    final hameshRegex = RegExp(r'<hr\s*/?>\s*<p class="hamesh">(.*?)</p>', dotAll: true);
    final hameshMatch = hameshRegex.firstMatch(rawBody);
    if (hameshMatch != null) {
      hamesh = _cleanHtml(hameshMatch.group(1)!);
      rawBody = rawBody.replaceRange(hameshMatch.start, hameshMatch.end, '');
    } else {
      // Split on separator line _________
      final sepIndex = rawBody.indexOf('_________');
      if (sepIndex != -1) {
        hamesh = _cleanHtml(rawBody.substring(sepIndex + 9));
        rawBody = rawBody.substring(0, sepIndex);
      }
    }

    final cleanContent = _cleanHtml(rawBody);
    final detectedTotal = extractTotalPagesFromHtml(bookId, html);

    return ShamelaPage(
      bookId: bookId,
      pageNumber: pageNumber,
      partNumber: partNum,
      chapterTitle: chapterTitle,
      content: cleanContent,
      hamesh: hamesh,
      detectedTotalPages: detectedTotal,
    );
  }

  /// Extract total pages dynamically from Maktaba Shamela page navigation HTML
  static int? extractTotalPagesFromHtml(int bookId, String html) {
    if (html.isEmpty) return null;

    final idStr = bookId.toString();

    // Direct regex for pagination links:
    // Matches: <a ... href=".../book/11126/12..." ...>...>>...</a>
    final lastLinkRegex = RegExp(
      r'''<a\s+[^>]*href=["'](?:https?://shamela\.ws)?/book/''' +
          idStr +
          r'''/(\d+)(?:#[^"']*)?["'][^>]*>(.*?)</a>''',
      caseSensitive: false,
      dotAll: true,
    );

    int? candidate;
    for (final m in lastLinkRegex.allMatches(html)) {
      final page = int.tryParse(m.group(1)!);
      if (page == null) continue;
      final fullTag = m.group(0) ?? '';
      final inner = m.group(2) ?? '';

      // High confidence: this link has >>, &gt;&gt;, », or says 'أخيرة' / 'last'
      if (inner.contains('>>') ||
          inner.contains('&gt;&gt;') ||
          inner.contains('»') ||
          fullTag.contains('أخيرة') ||
          fullTag.contains('last') ||
          fullTag.contains('الصفحة الأخيرة')) {
        return page;
      }

      // Track max page number linked
      if (candidate == null || page > candidate) {
        candidate = page;
      }
    }

    // Also check if there's any button/input with data-page or data-last
    final dataLastRegex = RegExp(
      r'''data-(?:last|total|max-page)=["'](\d+)["']''',
      caseSensitive: false,
    );
    final dataMatch = dataLastRegex.firstMatch(html);
    if (dataMatch != null) {
      final val = int.tryParse(dataMatch.group(1)!);
      if (val != null && val > 0) return val;
    }

    return candidate;
  }

  /// Clean HTML tags, brackets, and extra spaces
  static String _cleanHtml(String html) {
    var text = sanitizeBookText(html)
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return sanitizeBookText(text);
  }

  /// Sanitize book content and footnotes by stripping email protection artifacts
  /// (e.g. Cloudflare [email&#160;protected], [email protected], etc.)
  static String sanitizeBookText(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(
          RegExp(
            r"""<a[^>]*class=["'][^"']*__cf_email__[^"']*["'][^>]*>.*?</a>""",
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r"""<a[^>]*href=["'][^"']*/cdn-cgi/l/email-protection[^"']*["'][^>]*>.*?</a>""",
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'/cdn-cgi/l/email-protection#?[a-f0-9]*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\[\s*email(?:\s*|&#\d+;|&nbsp;)*protected\s*\]',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\[\s*email[^\]]*\]', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'email&#\d+;protected', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'email&nbsp;protected', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\([ \t]*\)'), '')
        .replaceAll(RegExp(r'\[[ \t]*\]'), '')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
  }

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

    // 2. Fetch from shamela.ws
    try {
      final url = Uri.parse('https://shamela.ws/book/$bookId');
      final response = await _httpClient.get(url, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      }).timeout(AppMotion.networkTimeout);

      if (response.statusCode == 200) {
        final html = utf8.decode(response.bodyBytes, allowMalformed: true);
        final linkRegex = RegExp(
          r"""<a[^>]+href=["'](?:https://shamela\.ws)?/book/\d+/(\d+)["'][^>]*>(.*?)</a>""",
        );

        final Map<int, String> chaptersMap = {};

        // A. Extract all direct chapters on cover page
        for (final m in linkRegex.allMatches(html)) {
          final pageNum = int.tryParse(m.group(1)!);
          final rawTitle = _cleanHtml(m.group(2)!);

          if (pageNum != null &&
              rawTitle.isNotEmpty &&
              rawTitle != '*' &&
              !rawTitle.contains('تصفح') &&
              !rawTitle.contains('الرئيسية')) {
            chaptersMap[pageNum] = rawTitle;
          }
        }

        // B. Check for expandable tree nodes (exp_bu buttons)
        final rootMatches = RegExp(
          r"""data-id=["'](\d+)["'][^>]*data-book-id=["'](\d+)["']""",
        ).allMatches(html);

        if (rootMatches.isNotEmpty) {
          final futures = rootMatches.map((rm) async {
            final dataId = rm.group(1)!;
            final bId = rm.group(2)!;
            try {
              final childUrl =
                  Uri.parse('https://shamela.ws/ajax/titlechilds/$bId/$dataId');
              final childResp = await _httpClient.get(childUrl, headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'X-Requested-With': 'XMLHttpRequest',
              }).timeout(AppMotion.networkTimeout);

              if (childResp.statusCode == 200) {
                final childHtml =
                    utf8.decode(childResp.bodyBytes, allowMalformed: true);
                for (final cm in linkRegex.allMatches(childHtml)) {
                  final cp = int.tryParse(cm.group(1)!);
                  var ct = _cleanHtml(cm.group(2)!);
                  if (ct.startsWith('-')) ct = ct.substring(1).trim();
                  if (cp != null && ct.isNotEmpty && ct != '*') {
                    chaptersMap[cp] = ct;
                  }
                }
              }
            } catch (_) {}
          });

          await Future.wait(futures);
        }

        final sortedPages = chaptersMap.keys.toList()..sort();
        final List<ShamelaChapter> chapters = sortedPages
            .map((p) => ShamelaChapter(title: chaptersMap[p]!, pageNumber: p))
            .toList();

        final maxChapterPage =
            chaptersMap.keys.fold<int>(0, (prev, elem) => elem > prev ? elem : prev);
        if (maxChapterPage > 0) {
          final current = _knownTotalPages[bookId] ?? 0;
          if (maxChapterPage > current) {
            unawaited(saveDiscoveredTotalPages(bookId, maxChapterPage));
          }
        }

        if (chapters.isNotEmpty) {
          // Clear old fihris and cache new chapters in SQLite
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
    } catch (_) {}

    return [];
  }

  /// Download entire book for full offline access
  static Future<void> downloadBook(
    ShamelaBook book, {
    Function(int current, int total)? onProgress,
  }) async {
    // Try to use dynamically discovered total first
    int total = await getDiscoveredTotalPages(book.id) ?? 0;
    // If not known, fetch page 1 to discover it
    if (total <= 0) {
      try {
        final firstPage = await fetchPage(bookId: book.id, pageNumber: 1);
        total = firstPage.detectedTotalPages ?? book.totalPages;
        if (total > 0) {
          await saveDiscoveredTotalPages(book.id, total);
        }
      } catch (_) {
        total = book.totalPages;
      }
    }
    if (total <= 0) total = book.totalPages;
    if (total <= 0) total = 50; // absolute fallback
    for (int p = 1; p <= total; p++) {
      try {
        await fetchPage(bookId: book.id, pageNumber: p);
        onProgress?.call(p, total);
        await Future.delayed(AppMotion.microPause);
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shamela_downloaded_${book.id}', true);
  }

  /// Check if book is fully downloaded
  static Future<bool> isBookDownloaded(int bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('shamela_downloaded_$bookId') ?? false;
  }

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
