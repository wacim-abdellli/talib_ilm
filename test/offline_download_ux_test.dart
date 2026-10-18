import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/ilm/data/models/shamela_models.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_book_card.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_reader_top_bar.dart';

void main() {
  const testBook = ShamelaBook(
    id: 11266,
    title: 'شروط الصلاة وأركانها وواجباتها',
    author: 'محمد بن عبد الوهاب',
    category: 'فقه حنبلي',
    categoryId: 1,
    totalPages: 10,
  );

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
      SharedPreferences.setMockInitialValues({});

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

    testWidgets('ShamelaReaderTopBar displays download_done icon when book is offline',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'shamela_downloaded_11266': true,
      });

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

    testWidgets('ShamelaBookCard displays محفوظ badge when book is downloaded',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'shamela_downloaded_11266': true,
      });

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

    testWidgets('ShamelaBookCard hides محفوظ badge when book is not downloaded',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

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
