import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/app.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/app/theme/reader_theme.dart';
import 'package:talib_ilm/features/ilm/data/models/book_progress_model.dart';
import 'package:talib_ilm/features/ilm/data/models/mutun_models.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_header.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_reading_tracker_sheet.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_typography_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapWidget(Widget child, {ThemeMode mode = ThemeMode.light}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );
  }

  group('IlmHeader Interactive Tests', () {
    testWidgets('Renders dynamic book counts and triggers onStatsTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWidget(
          IlmHeader(
            dailyMicrocopy: 'بداية الغيث قطرة',
            totalBooksCount: 96,
            completedBooksCount: 4,
            onStatsTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('4/96 مُنجز'), findsOneWidget);
      expect(find.byIcon(Icons.collections_bookmark_rounded), findsOneWidget);

      await tester.tap(find.text('4/96 مُنجز'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('IlmReadingTrackerSheet Tests', () {
    testWidgets('Renders in-progress books and metric summaries', (tester) async {
      final inProgress = [
        BookProgress(
          bookId: 'bk_adhkar_adab',
          bookTitle: 'حصن المسلم',
          level: 'الآداب والأذكار',
          totalPages: 153,
          currentPage: 42,
          lastReadDate: DateTime.now(),
          startedDate: DateTime.now(),
        ),
      ];

      final completed = [
        BookProgress(
          bookId: 'bk_nawaqid_islam',
          bookTitle: 'نواقض الإسلام',
          level: 'المستوى التمهيدي',
          totalPages: 2,
          currentPage: 2,
          lastReadDate: DateTime.now(),
          startedDate: DateTime.now(),
          completedDate: DateTime.now(),
        ),
      ];

      final catalog = <String, IlmBook>{
        'bk_adhkar_adab': IlmBook(
          id: 'bk_adhkar_adab',
          title: 'حصن المسلم',
          author: 'سعيد القحطاني',
          level: 'المستوى الأول',
          subject: 'الآداب والأذكار',
          description: '',
          totalPages: 153,
          shuruh: const [],
        ),
      };

      String? openedBookId;

      await tester.pumpWidget(
        wrapWidget(
          IlmReadingTrackerSheet(
            inProgressBooks: inProgress,
            completedBooks: completed,
            totalLibraryBooks: 96,
            bookCatalog: catalog,
            onOpenBook: (id) => openedBookId = id,
          ),
        ),
      );

      expect(find.text('سجل المدارسة والإنجاز'), findsOneWidget);
      expect(find.text('قيد المدارسة'), findsOneWidget);
      expect(find.text('المنجز'), findsOneWidget);
      expect(find.text('نسبة الإنجاز'), findsOneWidget);
      expect(find.text('حصن المسلم'), findsOneWidget);
      expect(find.text('صفحة 42 من 153'), findsOneWidget);

      await tester.tap(find.text('حصن المسلم'));
      await tester.pump();

      expect(openedBookId, 'bk_adhkar_adab');
    });

    testWidgets('Renders clean empty states when lists are empty', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          IlmReadingTrackerSheet(
            inProgressBooks: const [],
            completedBooks: const [],
            totalLibraryBooks: 96,
            bookCatalog: const {},
            onOpenBook: (_) {},
          ),
        ),
      );

      expect(find.text('لا توجد متون قيد المدارسة حالياً'), findsOneWidget);
      expect(find.text('0/96'), findsOneWidget);
    });
  });

  group('Typography Sheet & Theme Sync Tests', () {
    testWidgets('Tapping night surface synchronizes themeService to dark', (tester) async {
      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.isDark, isFalse);

      ShamelaReaderSurface? changedSurface;

      await tester.pumpWidget(
        wrapWidget(
          ShamelaTypographySheet(
            fontSizeDelta: 2.0,
            fontFamily: 'Amiri',
            lineHeight: 1.85,
            surface: ShamelaReaderSurface.normal,
            accentColor: ShamelaAccentColor.emerald,
            onFontSizeChanged: (_) {},
            onFontFamilyChanged: (_) {},
            onLineHeightChanged: (_) {},
            onSurfaceChanged: (s) => changedSurface = s,
            onAccentColorChanged: (_) {},
          ),
        ),
      );

      // Tap "داكن هادئ"
      final nightOption = find.text('داكن هادئ');
      expect(nightOption, findsOneWidget);

      await tester.tap(nightOption);
      await tester.pump();

      expect(changedSurface, ShamelaReaderSurface.night);
      expect(themeService.isDark, isTrue);

      // Tap "الافتراضي"
      final defaultOption = find.text('الافتراضي');
      expect(defaultOption, findsOneWidget);

      await tester.tap(defaultOption);
      await tester.pump();

      expect(changedSurface, ShamelaReaderSurface.normal);
      expect(themeService.isDark, isFalse);
    });
  });
}
