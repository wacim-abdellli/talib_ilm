import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../core/utils/arabic_search_utils.dart';
import '../models/shamela_models.dart';

class ShamelaService {
  static Database? _db;
  static const String _tableNamePages = 'shamela_pages';
  static const String _tableNameFihris = 'shamela_fihris';
  static const String _lastReadPrefix = 'shamela_last_read_';
  static const String _bookmarksKey = 'shamela_bookmarks';

  static final http.Client _httpClient = http.Client();

  /// Curated Top Categories in Shamela
  static const List<ShamelaCategory> categories = [
    ShamelaCategory(id: 0, name: 'الكل'),
    ShamelaCategory(id: 1, name: 'العقيدة', count: 808),
    ShamelaCategory(id: 6, name: 'كتب السنة', count: 1245),
    ShamelaCategory(id: 7, name: 'شروح الحديث', count: 265),
    ShamelaCategory(id: 10, name: 'علوم الحديث', count: 320),
    ShamelaCategory(id: 11, name: 'أصول الفقه', count: 253),
    ShamelaCategory(id: 17, name: 'الفقه الحنبلي', count: 153),
    ShamelaCategory(id: 16, name: 'الفقه الشافعي', count: 90),
    ShamelaCategory(id: 15, name: 'الفقه المالكي', count: 89),
    ShamelaCategory(id: 14, name: 'الفقه الحنفي', count: 87),
    ShamelaCategory(id: 3, name: 'التفسير', count: 274),
    ShamelaCategory(id: 4, name: 'علوم القرآن', count: 312),
    ShamelaCategory(id: 23, name: 'الرقائق والآداب والأذكار', count: 625),
    ShamelaCategory(id: 24, name: 'السيرة النبوية', count: 187),
    ShamelaCategory(id: 31, name: 'النحو والصرف', count: 213),
  ];

  /// Curated Starter Classics Library (Authentic Shamela Book IDs)
  static final List<ShamelaBook> curatedClassics = [
    // ── العقيدة ──
    const ShamelaBook(
      id: 21644,
      title: 'الأصول الثلاثة وأدلتها',
      author: 'محمد بن عبد الوهاب',
      authorDeath: 'ت ١٢٠٦ هـ',
      category: 'العقيدة',
      categoryId: 1,
      muhaqqiq: 'د. فهد بن عبد الرحمن الرومي',
      publisher: 'مؤسسة الرسالة',
      totalPages: 32,
      description: 'رسالة نافعة في معرفة العبد ربه ودينه ونبيه محمد صلى الله عليه وسلم.',
    ),
    const ShamelaBook(
      id: 9781,
      title: 'كتاب التوحيد الذي هو حق الله على العبيد',
      author: 'محمد بن عبد الوهاب',
      authorDeath: 'ت ١٢٠٦ هـ',
      category: 'العقيدة',
      categoryId: 1,
      muhaqqiq: 'د. دغش بن شبيب العجمي',
      publisher: 'مكتبة أهل الأثر',
      totalPages: 168,
      description: 'عمدة كتب التوحيد المتضمن لآيات وأحاديث وآثار إفراد الله بالعبادة.',
    ),
    const ShamelaBook(
      id: 21746,
      title: 'العقيدة الواسطية',
      author: 'ابن تيمية',
      authorDeath: 'ت ٧٢٨ هـ',
      category: 'العقيدة',
      categoryId: 1,
      muhaqqiq: 'أشرف بن عبد المقصود',
      publisher: 'أضواء السلف',
      totalPages: 60,
      description: 'مختصر جليل في مجمل اعتقاد أهل السنة والجماعة في أسماء الله وصفاته.',
    ),
    const ShamelaBook(
      id: 21748,
      title: 'العقيدة الطحاوية',
      author: 'أبو جعفر الطحاوي',
      authorDeath: 'ت ٣٢١ هـ',
      category: 'العقيدة',
      categoryId: 1,
      muhaqqiq: 'عبد الله بن عبد المحسن التركي',
      publisher: 'مؤسسة الرسالة',
      totalPages: 88,
      description: 'بيان عقيدة أهل السنة والجماعة على مذهب فقهاء الملة.',
    ),
    const ShamelaBook(
      id: 21745,
      title: 'لمعة الاعتقاد الهادي إلى سبيل الرشاد',
      author: 'ابن قدامة المقدسي',
      authorDeath: 'ت ٦٢٠ هـ',
      category: 'العقيدة',
      categoryId: 1,
      muhaqqiq: 'بدر بن عبد الله البدر',
      publisher: 'الدار السلفية',
      totalPages: 40,
      description: 'متن نفيس في إثبات صفات الرب والإيمان بالقدر واليوم الآخر.',
    ),

    // ── كتب السنة والحديث ──
    const ShamelaBook(
      id: 21643,
      title: 'الأربعون النووية',
      author: 'يحيى بن شرف النووي',
      authorDeath: 'ت ٦٧٦ هـ',
      category: 'كتب السنة',
      categoryId: 6,
      muhaqqiq: 'قصي محمد نورس الحلاق',
      publisher: 'دار المأمون للتراث',
      totalPages: 64,
      description: 'جوامع كلم النبي صلى الله عليه وسلم التي عليها مدار الإسلام.',
    ),
    const ShamelaBook(
      id: 21749,
      title: 'عمدة الأحكام من كلام خير الأنام',
      author: 'عبد الغني المقدسي',
      authorDeath: 'ت ٦٠٠ هـ',
      category: 'كتب السنة',
      categoryId: 6,
      muhaqqiq: 'محمود الأرناؤوط',
      publisher: 'دار الثقافة العربية',
      totalPages: 180,
      description: 'أحاديث الأحكام المتفق عليها في صحيحي البخاري ومسلم مرتبة على أبواب الفقه.',
    ),
    const ShamelaBook(
      id: 21750,
      title: 'بلوغ المرام من أدلة الأحكام',
      author: 'ابن حجر العسقلاني',
      authorDeath: 'ت ٨٥٢ هـ',
      category: 'كتب السنة',
      categoryId: 6,
      muhaqqiq: 'سمير بن أمين الزهيري',
      publisher: 'دار الفلق',
      totalPages: 360,
      description: 'جمع فيه الحافظ أدلة الأحكام الفقهية مع بيان درجتها وصحتها وضعفها.',
    ),
    const ShamelaBook(
      id: 21751,
      title: 'رياض الصالحين من كلام سيد المرسلين',
      author: 'يحيى بن شرف النووي',
      authorDeath: 'ت ٦٧٦ هـ',
      category: 'الرقائق والآداب والأذكار',
      categoryId: 23,
      muhaqqiq: 'ماهر ياسين الفحل',
      publisher: 'دار ابن كثير',
      totalPages: 600,
      description: 'كتاب جامع للأحاديث الصحيحة في الرقائق والأخلاق والمعاملات والسلوك.',
    ),

    // ── علوم الحديث ──
    const ShamelaBook(
      id: 21752,
      title: 'المنظومة البيقونية',
      author: 'عمر بن محمد البيقوني',
      authorDeath: 'ت ١٠٨٠ هـ',
      category: 'علوم الحديث',
      categoryId: 10,
      totalPages: 16,
      description: 'منظومة لطيفة من أربعة وثلاثين بيتا في مصطلح الحديث وأنواعه.',
    ),
    const ShamelaBook(
      id: 21753,
      title: 'نخبة الفكر في مصطلح أهل الأثر',
      author: 'ابن حجر العسقلاني',
      authorDeath: 'ت ٨٥٢ هـ',
      category: 'علوم الحديث',
      categoryId: 10,
      totalPages: 32,
      description: 'أدق وأجمع متن مختصر في علوم الحديث وتقسيم طرقه ورتب رواته.',
    ),

    // ── الفقه وأصوله ──
    const ShamelaBook(
      id: 21754,
      title: 'زاد المستقنع في اختصار المقنع',
      author: 'موسى بن أحمد الحجاوي',
      authorDeath: 'ت ٩٦٨ هـ',
      category: 'الفقه الحنبلي',
      categoryId: 17,
      muhaqqiq: 'عبد الرحمن بن علي العسكر',
      publisher: 'دار ابن الجوزي',
      totalPages: 240,
      description: 'المتن المعتمد للمتأخرين في الفقه الحنبلي المعول عليه في التدريس والإفتاء.',
    ),
    const ShamelaBook(
      id: 21755,
      title: 'عمدة الفقه',
      author: 'ابن قدامة المقدسي',
      authorDeath: 'ت ٦٢٠ هـ',
      category: 'الفقه الحنبلي',
      categoryId: 17,
      totalPages: 160,
      description: 'متن مبسط في الفقه يقتصر فيه المؤلف على قول واحد معتمد.',
    ),
    const ShamelaBook(
      id: 21756,
      title: 'الورقات في أصول الفقه',
      author: 'أبو المعالي الجويني (إمام الحرمين)',
      authorDeath: 'ت ٤٧٨ هـ',
      category: 'أصول الفقه',
      categoryId: 11,
      totalPages: 24,
      description: 'مقدمة موجزة محررة في مبادئ وأصول الفقه الإسلامي.',
    ),
    const ShamelaBook(
      id: 21757,
      title: 'القواعد والأصول الجامعة والفروق والتقاسيم البديعة النافعة',
      author: 'عبد الرحمن بن ناصر السعدي',
      authorDeath: 'ت ١٣٧٦ هـ',
      category: 'أصول الفقه',
      categoryId: 11,
      totalPages: 90,
      description: 'قواعد فقهية أصلية وضوابط جامعة تعين على ضبط الفروع الفقهية.',
    ),

    // ── الفرائض واللغة ──
    const ShamelaBook(
      id: 21758,
      title: 'متن الرحبية في علم الفرائض',
      author: 'محمد بن علي الرحبي',
      authorDeath: 'ت ٥٧٧ هـ',
      category: 'الفقه العام',
      categoryId: 18,
      totalPages: 28,
      description: 'أشهر منظومة رائية في حساب المواريث وقسمة التركات.',
    ),
    const ShamelaBook(
      id: 21759,
      title: 'الآجرومية في قواعد الإعراب',
      author: 'ابن آجروم الصنهاجي',
      authorDeath: 'ت ٧٢٣ هـ',
      category: 'النحو والصرف',
      categoryId: 31,
      totalPages: 30,
      description: 'المدخل الأيسر والأرسخ لتعلم علم النحو وقواعد الإعراب للمبتدئين.',
    ),
  ];

  /// Initialize local database for caching pages and table of contents
  static Future<Database> _getDatabase() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'shamela_library_v1.db');

    _db = await openDatabase(
      path,
      version: 1,
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
    );

    return _db!;
  }

  /// Search books across curated collection
  static List<ShamelaBook> searchCatalog({
    String query = '',
    int categoryId = 0,
  }) {
    List<ShamelaBook> list = curatedClassics;

    if (categoryId > 0) {
      list = list.where((b) => b.categoryId == categoryId).toList();
    }

    if (query.trim().isEmpty) {
      return list;
    }

    final q = query.trim();
    return list.where((b) {
      return ArabicSearchUtils.matches(b.title, q) ||
          ArabicSearchUtils.matches(b.author, q) ||
          ArabicSearchUtils.matches(b.category, q) ||
          ArabicSearchUtils.matches(b.description, q);
    }).toList();
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
      return ShamelaPage(
        bookId: bookId,
        pageNumber: pageNumber,
        partNumber: row['part_num'] as int?,
        chapterTitle: row['chapter_title'] as String?,
        content: row['content'] as String,
        hamesh: row['hamesh'] as String?,
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

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الصفحة من المكتبة الشاملة (${response.statusCode})');
    }

    final html = utf8.decode(response.bodyBytes, allowMalformed: true);
    final parsed = _parsePageHtml(bookId, pageNumber, html);

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

    return ShamelaPage(
      bookId: bookId,
      pageNumber: pageNumber,
      partNumber: partNum,
      chapterTitle: chapterTitle,
      content: cleanContent,
      hamesh: hamesh,
    );
  }

  /// Clean HTML tags, brackets, and extra spaces
  static String _cleanHtml(String html) {
    var text = html
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

    return text;
  }

  /// Fetch or load Table of Contents (الفهرس)
  static Future<List<ShamelaChapter>> fetchTableOfContents(int bookId) async {
    final db = await _getDatabase();

    // 1. Check local cache
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

        final matches = linkRegex.allMatches(html);
        final List<ShamelaChapter> chapters = [];
        final seenPages = <int>{};

        for (final m in matches) {
          final pageNum = int.tryParse(m.group(1)!);
          final rawTitle = _cleanHtml(m.group(2)!);

          if (pageNum != null &&
              rawTitle.isNotEmpty &&
              !seenPages.contains(pageNum) &&
              !rawTitle.contains('تصفح') &&
              !rawTitle.contains('الرئيسية')) {
            seenPages.add(pageNum);
            chapters.add(ShamelaChapter(title: rawTitle, pageNumber: pageNum));
          }
        }

        // Cache in SQLite
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
    final total = book.totalPages > 0 ? book.totalPages : 50;

    for (int p = 1; p <= total; p++) {
      try {
        await fetchPage(bookId: book.id, pageNumber: p);
        onProgress?.call(p, total);
        // Micro yield to keep UI silky smooth
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
}
