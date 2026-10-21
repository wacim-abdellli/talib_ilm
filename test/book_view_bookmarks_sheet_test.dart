import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/book_view_bookmarks_sheet.dart';

void main() {
  final sampleEntries = [
    BookmarkEntry(
      bookId: 'bk_qawaid_arba',
      title: 'القواعد الأربع',
      subtitle: 'مقدمة ودعاء المصنف لطالب العلم',
      page: 1,
      totalPages: 4,
      isBookmark: true,
      note: 'ملاحظة تدبرية أولى في التوحيد والرسالة',
    ),
    BookmarkEntry(
      bookId: 'bk_usul_thalatha',
      title: 'الأصول الثلاثة وأدلتها',
      subtitle: 'المقدمة: المسائل الأربع التي يجب تعلمها',
      page: 2,
      totalPages: 25,
      isBookmark: false,
      note: 'سبحان الله وبحمده سبحان الله العظيم، فوائد جليلة',
    ),
  ];

  Widget buildTestableSheet({
    required List<BookmarkEntry> entries,
    int initialTab = 0,
    ThemeData? theme,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: BookViewBookmarksSheet(
              entries: entries,
              initialTab: initialTab,
            ),
          ),
        ),
      ),
    );
  }

  group('BookViewBookmarksSheet UI & Overflow Tests', () {
    testWidgets('Renders bookmarks tab with page pill and title cleanly', (tester) async {
      await tester.pumpWidget(
        buildTestableSheet(entries: sampleEntries, initialTab: 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('القواعد الأربع'), findsOneWidget);
      expect(find.text('صفحة 1 من 4'), findsOneWidget);
      expect(find.text('مقدمة ودعاء المصنف لطالب العلم'), findsOneWidget);
    });

    testWidgets('Renders notes tab without horizontal or vertical overflow', (tester) async {
      await tester.pumpWidget(
        buildTestableSheet(entries: sampleEntries, initialTab: 1),
      );
      await tester.pumpAndSettle();

      expect(find.text('الأصول الثلاثة وأدلتها'), findsOneWidget);
      expect(find.text('صفحة 2 من 25'), findsOneWidget);
      expect(find.text('سبحان الله وبحمده سبحان الله العظيم، فوائد جليلة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Filter chip counts accurately reflect active tab items', (tester) async {
      // 3 entries:
      // Entry 1: usul_thalatha: isBookmark=true, note='سبحان الله'
      // Entry 2: usul_thalatha: isBookmark=false, note='فائدة ثانية'
      // Entry 3: qawaid_arba: isBookmark=true, note=null
      // Total for usul_thalatha: 1 bookmark, 2 notes.
      // Total for all books: 2 bookmarks, 2 notes.
      final mixedEntries = [
        const BookmarkEntry(
          bookId: 'bk_usul_thalatha',
          title: 'الأصول الثلاثة',
          subtitle: 'المسألة الأولى',
          page: 1,
          isBookmark: true,
          note: 'سبحان الله',
        ),
        const BookmarkEntry(
          bookId: 'bk_usul_thalatha',
          title: 'الأصول الثلاثة',
          subtitle: 'المسألة الثانية',
          page: 3,
          isBookmark: false,
          note: 'فائدة ثانية',
        ),
        const BookmarkEntry(
          bookId: 'bk_qawaid_arba',
          title: 'القواعد الأربع',
          subtitle: 'المقدمة',
          page: 1,
          isBookmark: true,
          note: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: BookViewBookmarksSheet(
                entries: mixedEntries,
                currentBookId: 'bk_usul_thalatha',
                initialTab: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On Tab 0 (Bookmarks):
      // Bookmarks for usul_thalatha = 1; for all books = 2
      expect(find.text('هذا الكتاب (1)'), findsOneWidget);
      expect(find.text('جميع الكتب (2)'), findsOneWidget);

      // Switch to Tab 1 (Notes):
      await tester.tap(find.text('الملاحظات (2)'));
      await tester.pumpAndSettle();

      // On Tab 1 (Notes):
      // Notes for usul_thalatha = 2; for all books = 2
      expect(find.text('هذا الكتاب (2)'), findsOneWidget);
      expect(find.text('جميع الكتب (2)'), findsOneWidget);
    });

    testWidgets('Survives text scale 1.5 and 2.0 without overflow or crash', (tester) async {
      for (final scale in [1.5, 2.0]) {
        await tester.pumpWidget(
          buildTestableSheet(
            entries: sampleEntries,
            initialTab: 1,
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('الأصول الثلاثة وأدلتها'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
