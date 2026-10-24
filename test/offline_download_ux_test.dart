import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/ilm/data/models/shamela_models.dart';
import 'package:talib_ilm/features/ilm/data/services/shamela_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_book_card.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_reader_top_bar.dart';

/// In-memory fake SQLite database to back Shamela page queries in tests
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

  const testBook = ShamelaBook(
    id: 11266,
    title: 'شروط الصلاة وأركانها وواجباتها',
    author: 'محمد بن عبد الوهاب',
    category: 'فقه حنبلي',
    categoryId: 1,
    totalPages: 10,
  );

  void seedBookPages({required int bookId, required int totalPages, required int cachedCount}) {
    ShamelaService.saveDiscoveredTotalPages(bookId, totalPages);
    for (int p = 1; p <= cachedCount; p++) {
      fakeDb.pages.putIfAbsent(bookId, () => {})[p] = 'نص الصفحة $p للكتاب $bookId';
    }
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeDb = FakeShamelaDatabase();
    ShamelaService.setMockDatabase(fakeDb);
  });

  tearDown(() {
    ShamelaService.setMockDatabase(null);
  });

  Widget buildTestable(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.dark() : AppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );
  }

  group('Stage D4 Offline Download UX Tests', () {
    testWidgets('ShamelaReaderTopBar displays download button when not downloaded',
        (tester) async {
      await tester.pumpWidget(
        buildTestable(
          ShamelaReaderTopBar(
            book: testBook,
            title: testBook.title,
            author: testBook.author,
            currentPage: 1,
            totalPages: 10,
            showControls: true,
            bgColor: Colors.white,
            onBack: () {},
            onCopy: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
      expect(find.byTooltip('حفظ الكتاب للقراءة دون اتصال'), findsOneWidget);
    });

    testWidgets('ShamelaReaderTopBar displays download_done icon when book is offline with complete pages',
        (tester) async {
      // Seed all 10 pages in SQLite storage
      seedBookPages(bookId: 11266, totalPages: 10, cachedCount: 10);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shamela_downloaded_11266', true);

      await tester.pumpWidget(
        buildTestable(
          ShamelaReaderTopBar(
            book: testBook,
            title: testBook.title,
            author: testBook.author,
            currentPage: 1,
            totalPages: 10,
            showControls: true,
            bgColor: Colors.white,
            onBack: () {},
            onCopy: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_done_outlined), findsOneWidget);
    });

    testWidgets('ShamelaReaderTopBar rejects stale pref flag and shows download button when pages are missing',
        (tester) async {
      // Incomplete download: total is 10, but only 5 pages in SQLite storage
      seedBookPages(bookId: 11266, totalPages: 10, cachedCount: 5);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shamela_downloaded_11266', true);

      await tester.pumpWidget(
        buildTestable(
          ShamelaReaderTopBar(
            book: testBook,
            title: testBook.title,
            author: testBook.author,
            currentPage: 1,
            totalPages: 10,
            showControls: true,
            bgColor: Colors.white,
            onBack: () {},
            onCopy: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Because manifest is incomplete, download button must be shown, NOT download_done
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
      expect(find.byIcon(Icons.download_done_outlined), findsNothing);
      expect(prefs.getBool('shamela_downloaded_11266'), isFalse);
    });

    testWidgets('ShamelaBookCard displays محفوظ badge when book is fully downloaded and verified',
        (tester) async {
      // Seed all 10 pages in SQLite storage
      seedBookPages(bookId: 11266, totalPages: 10, cachedCount: 10);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shamela_downloaded_11266', true);

      await tester.pumpWidget(
        buildTestable(
          ShamelaBookCard(
            book: testBook,
            isDownloaded: true,
            downloadProgress: null,
            onOpen: () {},
            onDownload: () {},
            onOpenShuruh: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('محفوظ'), findsOneWidget);
    });

    testWidgets('ShamelaBookCard hides محفوظ badge when book is incomplete despite stale flag',
        (tester) async {
      // Incomplete: total is 10, but only 3 pages in SQLite
      seedBookPages(bookId: 11266, totalPages: 10, cachedCount: 3);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shamela_downloaded_11266', true);

      await tester.pumpWidget(
        buildTestable(
          ShamelaBookCard(
            book: testBook,
            isDownloaded: true,
            downloadProgress: null,
            onOpen: () {},
            onDownload: () {},
            onOpenShuruh: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Honest manifest check must revoke badge
      expect(find.text('محفوظ'), findsNothing);
      expect(prefs.getBool('shamela_downloaded_11266'), isFalse);
    });

    testWidgets('ShamelaBookCard hides محفوظ badge when book is not downloaded',
        (tester) async {
      await tester.pumpWidget(
        buildTestable(
          ShamelaBookCard(
            book: testBook,
            isDownloaded: false,
            downloadProgress: null,
            onOpen: () {},
            onDownload: () {},
            onOpenShuruh: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('محفوظ'), findsNothing);
    });
  });
}
