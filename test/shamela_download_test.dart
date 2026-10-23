import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:talib_ilm/features/ilm/data/models/shamela_models.dart';
import 'package:talib_ilm/features/ilm/data/services/shamela_service.dart';

/// In-memory fake database implementing SQLite queries for Shamela offline tests.
class FakeShamelaDatabase implements Database {
  final Map<int, Map<int, String>> pages = {}; // bookId -> (pageNumber -> content)

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final bookId = whereArgs?.first as int?;
    if (bookId != null && pages.containsKey(bookId)) {
      return pages[bookId]!.entries.map((e) {
        return {
          'page_num': e.key,
          'content': e.value,
        };
      }).toList();
    }
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return pages.entries.map((e) {
      final validCount = e.value.values.where((c) => c.trim().isNotEmpty).length;
      return {
        'book_id': e.key,
        'cnt': validCount,
      };
    }).toList();
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final bookId = values['book_id'] as int?;
    final pageNum = values['page_num'] as int?;
    final content = values['content'] as String? ?? '';
    if (bookId != null && pageNum != null) {
      pages.putIfAbsent(bookId, () => {})[pageNum] = content;
    }
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeShamelaDatabase fakeDb;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeDb = FakeShamelaDatabase();
    ShamelaService.setMockDatabase(fakeDb);
    ShamelaDownloadManager.mockPageFetcher = null;
  });

  tearDown(() {
    ShamelaService.setMockDatabase(null);
    ShamelaDownloadManager.mockPageFetcher = null;
  });

  final testBook = ShamelaBook(
    id: 100,
    title: 'كتاب الاختبار الفقهي',
    author: 'عالم الاختبار',
    description: 'شرح فقهي للتأكد من اكتمال التنزيل',
    totalPages: 5,
    categoryId: 1,
    category: 'الفقه',
  );

  group('Shamela Download Truthful Verification (T08 / C09 / C10)', () {
    test('Bundled book (50001) is always verified downloaded and completes immediately', () async {
      final isDownloaded = await ShamelaService.isBookDownloaded(50001);
      expect(isDownloaded, isTrue);

      final bundledBook = ShamelaBook(
        id: 50001,
        title: 'منهاج المسلم',
        author: 'أبو بكر الجزائري',
        description: 'كتاب أصيل مدرج محلياً',
        totalPages: 100,
        categoryId: 1,
        category: 'العقيدة',
      );

      int progressCalled = 0;
      await ShamelaService.downloadBook(
        bundledBook,
        onProgress: (current, total) {
          progressCalled++;
          expect(current, equals(100));
          expect(total, equals(100));
        },
      );

      expect(progressCalled, equals(1));
    });

    test('Missing middle page: book is marked NOT downloaded and missing page is detected', () async {
      // Setup pages 1, 2, 4, 5 (page 3 missing)
      fakeDb.pages[testBook.id] = {
        1: 'محتوى الصفحة 1',
        2: 'محتوى الصفحة 2',
        4: 'محتوى الصفحة 4',
        5: 'محتوى الصفحة 5',
      };

      // Corrupted / premature preference set previously
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shamela_downloaded_${testBook.id}', true);

      final cached = await ShamelaService.getCachedPageNumbers(testBook.id);
      expect(cached, equals({1, 2, 4, 5}));

      final missing = await ShamelaService.getMissingPages(testBook.id, testBook.totalPages);
      expect(missing, equals([3]));

      // Truthful check must report FALSE and repair the false preference
      final isDownloaded = await ShamelaService.isBookDownloaded(
        testBook.id,
        totalPages: testBook.totalPages,
      );
      expect(isDownloaded, isFalse);
      expect(prefs.getBool('shamela_downloaded_${testBook.id}'), isFalse);
    });

    test('Fully downloaded book with all pages present returns true', () async {
      await ShamelaService.saveDiscoveredTotalPages(testBook.id, 5);
      fakeDb.pages[testBook.id] = {
        1: 'محتوى 1',
        2: 'محتوى 2',
        3: 'محتوى 3',
        4: 'محتوى 4',
        5: 'محتوى 5',
      };

      final missing = await ShamelaService.getMissingPages(testBook.id, 5);
      expect(missing, isEmpty);

      final isDownloaded = await ShamelaService.isBookDownloaded(testBook.id);
      expect(isDownloaded, isTrue);
    });

    test('Unknown total pages throws ShamelaDownloadException with Arabic message', () async {
      final invalidBook = ShamelaBook(
        id: 101,
        title: 'كتاب مجهول الصفحات',
        author: 'مؤلف',
        description: 'وصف',
        totalPages: 0,
        categoryId: 1,
        category: 'عام',
      );

      ShamelaDownloadManager.mockPageFetcher = ({required int bookId, required int pageNumber}) async {
        throw Exception('Network unreachable');
      };

      await expectLater(
        ShamelaService.downloadBook(invalidBook),
        throwsA(isA<ShamelaDownloadException>().having(
          (e) => e.message,
          'message',
          contains('تعذر تحديد عدد صفحات الكتاب'),
        )),
      );

      final isDownloaded = await ShamelaService.isBookDownloaded(invalidBook.id);
      expect(isDownloaded, isFalse);
    });

    test('All pages fail: throws ShamelaDownloadException with full failed pages list', () async {
      ShamelaDownloadManager.mockPageFetcher = ({required int bookId, required int pageNumber}) async {
        throw Exception('Server error 500');
      };

      await expectLater(
        ShamelaService.downloadBook(testBook),
        throwsA(isA<ShamelaDownloadException>().having(
          (e) => e.failedPages,
          'failedPages',
          equals([1, 2, 3, 4, 5]),
        )),
      );

      final isDownloaded = await ShamelaService.isBookDownloaded(testBook.id);
      expect(isDownloaded, isFalse);
    });

    test('Gap retry: only downloads missing pages without re-downloading valid cached pages', () async {
      // Pages 1, 2, 4 already present
      fakeDb.pages[testBook.id] = {
        1: 'صفحة 1 موجودة',
        2: 'صفحة 2 موجودة',
        4: 'صفحة 4 موجودة',
      };

      final fetchedPages = <int>[];
      ShamelaDownloadManager.mockPageFetcher = ({required int bookId, required int pageNumber}) async {
        fetchedPages.add(pageNumber);
        final page = ShamelaPage(
          bookId: bookId,
          pageNumber: pageNumber,
          content: 'نص الصفحة المحملة $pageNumber',
        );
        fakeDb.pages[bookId]![pageNumber] = page.content;
        return page;
      };

      await ShamelaService.downloadBook(testBook);

      // Must ONLY fetch pages 3 and 5!
      expect(fetchedPages, equals([3, 5]));

      // Now all 5 pages exist
      final isDownloaded = await ShamelaService.isBookDownloaded(testBook.id);
      expect(isDownloaded, isTrue);
    });

    test('Cancellation: cancelDownload interrupts download and prevents false completion', () async {
      ShamelaDownloadManager.mockPageFetcher = ({required int bookId, required int pageNumber}) async {
        if (pageNumber == 2) {
          ShamelaService.cancelDownload(bookId);
        }
        return ShamelaPage(
          bookId: bookId,
          pageNumber: pageNumber,
          content: 'نص صفحة $pageNumber',
        );
      };

      await expectLater(
        ShamelaService.downloadBook(testBook),
        throwsA(isA<ShamelaDownloadException>().having(
          (e) => e.message,
          'message',
          contains('تم إلغاء'),
        )),
      );

      expect(ShamelaService.isDownloading(testBook.id), isFalse);
    });

    test('Empty or whitespace page content is treated as failure', () async {
      ShamelaDownloadManager.mockPageFetcher = ({required int bookId, required int pageNumber}) async {
        return ShamelaPage(
          bookId: bookId,
          pageNumber: pageNumber,
          content: pageNumber == 3 ? '    ' : 'نص صحيح للصفحة $pageNumber',
        );
      };

      await expectLater(
        ShamelaService.downloadBook(testBook),
        throwsA(isA<ShamelaDownloadException>().having(
          (e) => e.failedPages,
          'failedPages',
          contains(3),
        )),
      );

      final isDownloaded = await ShamelaService.isBookDownloaded(testBook.id);
      expect(isDownloaded, isFalse);
    });

    test('Concurrent download requests share identical Future and do not duplicate network work', () async {
      int fetchCount = 0;
      ShamelaDownloadManager.mockPageFetcher = ({required int bookId, required int pageNumber}) async {
        fetchCount++;
        fakeDb.pages.putIfAbsent(bookId, () => {})[pageNumber] = 'محتوى الصفحة $pageNumber';
        return ShamelaPage(
          bookId: bookId,
          pageNumber: pageNumber,
          content: 'محتوى الصفحة $pageNumber',
        );
      };

      final future1 = ShamelaService.downloadBook(testBook);
      final future2 = ShamelaService.downloadBook(testBook);

      await Future.wait([future1, future2]);

      // Exactly 5 pages fetched, not 10!
      expect(fetchCount, equals(5));
      expect(await ShamelaService.isBookDownloaded(testBook.id), isTrue);
    });

    test('getDownloadedBooksMap returns correct map across curated and local books', () async {
      await ShamelaService.saveDiscoveredTotalPages(testBook.id, 5);
      fakeDb.pages[testBook.id] = {
        1: 'محتوى 1',
        2: 'محتوى 2',
        3: 'محتوى 3',
        4: 'محتوى 4',
        5: 'محتوى 5',
      };

      final map = await ShamelaService.getDownloadedBooksMap();
      expect(map[50001], isTrue); // Bundled book
      expect(map[testBook.id], isTrue); // Complete book
      expect(map[999] ?? false, isFalse); // Non-existent book
    });
  });
}
