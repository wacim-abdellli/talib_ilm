import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_palette.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/ilm/data/models/book_progress_model.dart';
import 'package:talib_ilm/features/ilm/data/models/mutun_models.dart';
import 'package:talib_ilm/features/ilm/data/models/shamela_models.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_discipline_section.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_header.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_mutun_section_view.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/study_resume_pill.dart';

Widget _wrapWithPhoneDimensions({
  required Widget Function(BuildContext context) builder,
  required double width,
  required double height,
  double textScale = 1.0,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
        child: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}

void main() {
  const phoneWidths = [320.0, 360.0, 375.0, 390.0, 412.0];

  group('IlmHeader Resolution Adaptation', () {
    for (final width in phoneWidths) {
      testWidgets('renders title and daily microcopy cleanly at ${width}dp',
          (tester) async {
        await tester.pumpWidget(
          _wrapWithPhoneDimensions(
            width: width,
            height: 800,
            textScale: 1.0,
            builder: (context) => IlmHeader(
              dailyMicrocopy: 'العلم صيد والكتابة قيد',
              totalBooksCount: 284,
              completedBooksCount: 5,
              onDownloadsTap: () {},
              onStatsTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('المكتبة العلمية'), findsOneWidget);
        expect(find.text('العلم صيد والكتابة قيد'), findsOneWidget);
        expect(find.text('5/284'), findsOneWidget);
      });
    }

    testWidgets('survives high text scales 1.5 and 2.0 without overflow',
        (tester) async {
      for (final scale in [1.5, 2.0]) {
        await tester.pumpWidget(
          _wrapWithPhoneDimensions(
            width: 360,
            height: 800,
            textScale: scale,
            builder: (context) => IlmHeader(
              dailyMicrocopy: 'إنما العلم بالتعلم والحلم بالتحلم',
              totalBooksCount: 284,
              completedBooksCount: 0,
              onDownloadsTap: () {},
              onStatsTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('المكتبة العلمية'), findsOneWidget);
      }
    });
  });

  group('IlmMutunSectionView Resolution Adaptation', () {
    final mockMutun = [
      IlmBook(
        id: 'adab_azkar',
        title: 'الآداب والأذكار',
        author: 'مجموعة من كبار العلماء',
        description: 'آداب المسلم وأذكاره',
        subject: 'آداب',
        totalPages: 100,
        level: '1',
        shuruh: const [],
      ),
      IlmBook(
        id: 'nawaqid_islam',
        title: 'نواقض الإسلام',
        author: 'الشيخ محمد بن عبد الوهاب',
        description: 'نواقض الإسلام العشرة',
        subject: 'عقيدة',
        totalPages: 2,
        level: '1',
        shuruh: const [],
      ),
    ];

    for (final width in phoneWidths) {
      testWidgets('renders title and view all without squeezing at ${width}dp',
          (tester) async {
        await tester.pumpWidget(
          _wrapWithPhoneDimensions(
            width: width,
            height: 800,
            builder: (context) => CustomScrollView(
              slivers: IlmMutunSectionView.buildSlivers(
                context: context,
                palette: AppPalette.light,
                allBooks: mockMutun,
                sortedLevels: const [],
                isFocused: false,
                selectedMutunLevel: null,
                onSelectLevel: (_) {},
                favoriteBookIds: const {},
                onToggleFavorite: (_) {},
                progressById: {
                  'adab_azkar': BookProgress(
                    bookId: 'adab_azkar',
                    bookTitle: 'الآداب والأذكار',
                    level: '1',
                    currentPage: 1,
                    totalPages: 100,
                    startedDate: DateTime.now(),
                    lastReadDate: DateTime.now(),
                  ),
                  'nawaqid_islam': BookProgress(
                    bookId: 'nawaqid_islam',
                    bookTitle: 'نواقض الإسلام',
                    level: '1',
                    currentPage: 1,
                    totalPages: 2,
                    startedDate: DateTime.now(),
                    lastReadDate: DateTime.now(),
                  ),
                },
                onNavigateToBook: (_) {},
                onViewAll: () {},
                onBackToAll: () {},
                onOpenCurriculumQuiz: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('متون طالب العلم'), findsOneWidget);
        expect(find.text('عرض الكل'), findsOneWidget);
        expect(find.text('الآداب والأذكار'), findsOneWidget);
        expect(find.text('مجموعة من كبار العلماء'), findsOneWidget);
        expect(find.text('صفحة 1 من 100'), findsOneWidget);
        expect(find.text('نواقض الإسلام'), findsOneWidget);
        expect(find.text('الشيخ محمد بن عبد الوهاب'), findsOneWidget);
        expect(find.text('صفحة 1 من 2'), findsOneWidget);
      });
    }
  });

  group('IlmDisciplineSection Resolution Adaptation', () {
    const mockBooks = [
      ShamelaBook(
        id: 1001,
        title: 'أصول الإيمان في ضوء الكتاب والسنة',
        author: 'نخبة من العلماء (إشراف: صالح بن عبد العزيز آل الشيخ)',
        authorDeath: 'معاصر',
        category: 'aqidah',
        categoryId: 1,
        totalPages: 320,
      ),
    ];

    for (final width in phoneWidths) {
      testWidgets('renders discipline header and book list at ${width}dp',
          (tester) async {
        await tester.pumpWidget(
          _wrapWithPhoneDimensions(
            width: width,
            height: 800,
            builder: (context) => CustomScrollView(
              slivers: IlmDisciplineSection.buildSlivers(
                context: context,
                palette: AppPalette.light,
                title: 'العقيدة والتوحيد',
                subtitle: 'أصول الإيمان والتوحيد والرد على الشبهات',
                books: mockBooks,
                categoryKey: 'aqidah',
                isFocused: false,
                fan: null,
                onOpenBook: (_) {},
                onOpenShuruh: (a, b) {},
                onViewAll: () {},
                onBackToAll: () {},
                onOpenQuiz: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('العقيدة والتوحيد'), findsOneWidget);
        expect(find.text('عرض الكل'), findsOneWidget);
        expect(find.text('1 كتاباً'), findsOneWidget);
        expect(find.text('أصول الإيمان في ضوء الكتاب والسنة'), findsOneWidget);
      });
    }
  });

  group('StudyResumePill Long Title Adaptation', () {
    testWidgets('renders long classical book title gracefully across 2 lines',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithPhoneDimensions(
          width: 360,
          height: 800,
          builder: (context) => StudyResumePill(
            continueReadingBook: BookProgress(
              bookId: 'tafsir_tabari',
              bookTitle: 'جامع البيان عن تأويل آي القرآن (تفسير الطبري)',
              level: '1',
              currentPage: 1,
              totalPages: 14619,
              startedDate: DateTime.now(),
              lastReadDate: DateTime.now(),
            ),
            recommendedFirstBook: null,
            bookCatalog: const {},
            dailyGoal: 10,
            pagesReadToday: 1,
            currentStreak: 3,
            onNavigateToBook: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('جامع البيان عن تأويل آي القرآن (تفسير الطبري)'),
        findsOneWidget,
      );
      expect(find.text('استئناف المدارسة'), findsOneWidget);
      expect(find.text('متوقف عند الصفحة 1 من 14619'), findsOneWidget);
    });
  });
}
