import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/asset_service.dart';
import 'package:talib_ilm/features/adhkar/data/adhkar_service.dart';
import 'package:talib_ilm/features/hadith/data/services/hadith_service.dart';
import 'package:talib_ilm/features/home/presentation/home_page.dart';
import 'package:talib_ilm/features/home/presentation/widgets/continue_learning_card.dart';
import 'package:talib_ilm/features/home/presentation/widgets/home_header.dart';
import 'package:talib_ilm/features/home/presentation/widgets/home_hero_card.dart';
import 'package:talib_ilm/features/home/presentation/widgets/home_quick_actions.dart';
import 'golden/golden_test_helper.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'last_activity_book': 'bk_adhkar_adab',
      'last_activity_tab': 'mutn',
      'pdf_page:bk_adhkar_adab:mutn:page': 14,
      'pdf_page:bk_adhkar_adab:mutn:total': 60,
      'book_progress': jsonEncode({
        'bk_adhkar_adab': {
          'bookId': 'bk_adhkar_adab',
          'bookTitle': 'الآداب والأذكار',
          'currentPage': 14,
          'totalPages': 60,
          'percent': 23.3,
          'totalLessons': 10,
          'completedLessons': 2,
        }
      }),
      'manual_location_enabled': true,
      'manual_city': 'مكة المكرمة',
      'manual_province': 'مكة المكرمة',
      'manual_country': 'المملكة العربية السعودية',
      'manual_country_code': 'SA',
      'manual_lat': 21.4225,
      'manual_lon': 39.8262,
    });
  });

  Widget createTestWidget({
    double textScale = 1.0,
    bool isDark = false,
    Size surfaceSize = const Size(390, 844),
    DateTime? testTime,
  }) {
    final theme = isDark ? AppTheme.dark() : AppTheme.light();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: HomePage(currentTime: testTime ?? DateTime(2026, 10, 24, 11, 5)),
        ),
      ),
    );
  }

  Future<void> pumpHomePage(
    WidgetTester tester, {
    double textScale = 1.0,
    bool isDark = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.runAsync(() async {
      await ensureBundledFontsLoaded();
      await HadithService().getAllHadiths();
      await AthkarService().loadCatalog();
      await AssetService.loadMutunProgram();
    });

    await tester.pumpWidget(createTestWidget(textScale: textScale, isDark: isDark));

    for (final element in find.byType(Image).evaluate()) {
      final img = element.widget as Image;
      await tester.runAsync(() => precacheImage(img.image, element));
    }
    await tester.pumpAndSettle();
  }

  group('HomePage Module Hierarchy Integration Tests', () {
    testWidgets('proves strict 4-module sequence and above-the-fold fit at text scale 1.0', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpHomePage(tester, textScale: 1.0);

      // Find primary components in initial above-the-fold viewport
      final headerFinder = find.byType(HomeHeader);
      final heroFinder = find.byType(HomeHeroCard);
      final continueFinder = find.byType(LearningPulseCard);
      final quickActionsFinder = find.byType(HomeQuickActions);

      expect(headerFinder, findsOneWidget);
      expect(heroFinder, findsOneWidget);
      expect(continueFinder, findsOneWidget);
      expect(quickActionsFinder, findsOneWidget);

      final headerBottom = tester.getBottomRight(headerFinder).dy;
      final heroTop = tester.getTopLeft(heroFinder).dy;
      final heroBottom = tester.getBottomRight(heroFinder).dy;
      final continueTop = tester.getTopLeft(continueFinder).dy;
      final continueBottom = tester.getBottomRight(continueFinder).dy;
      final quickActionsTop = tester.getTopLeft(quickActionsFinder).dy;
      final quickActionsBottom = tester.getBottomRight(quickActionsFinder).dy;

      // Hierarchy proof: strictly descending vertical positions
      expect(headerBottom, lessThan(heroTop), reason: 'Module 1 (Hero) must be below Header');
      expect(heroBottom, lessThan(continueTop), reason: 'Modules 2/3 (Continue/Progress) must be below Hero');
      expect(continueBottom, lessThan(quickActionsTop), reason: 'Module 4 (Quick Actions) must be below Continue');

      // Above-the-fold proof: Module 4 finishes within viewport height (844px)
      expect(
        quickActionsBottom,
        lessThanOrEqualTo(844.0),
        reason: 'All four primary modules must fit above the fold on standard 390x844 viewport',
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('survives text scale 1.5 without layout overflow in above-the-fold modules', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpHomePage(tester, textScale: 1.5, isDark: true);

      final heroFinder = find.byType(HomeHeroCard);
      final continueFinder = find.byType(LearningPulseCard);
      final quickActionsFinder = find.byType(HomeQuickActions);

      expect(heroFinder, findsOneWidget);
      expect(continueFinder, findsOneWidget);

      // Verify that Hero and Continue maintain hierarchy order
      final heroTop = tester.getTopLeft(heroFinder).dy;
      final continueTop = tester.getTopLeft(continueFinder).dy;
      expect(heroTop, lessThan(continueTop));

      // Scroll to reveal quick actions at 1.5 text scale
      await tester.scrollUntilVisible(quickActionsFinder, 200);
      expect(quickActionsFinder, findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('survives text scale 2.0 without layout overflow in initial view', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpHomePage(tester, textScale: 2.0);

      final heroFinder = find.byType(HomeHeroCard);
      final continueFinder = find.byType(LearningPulseCard);

      expect(heroFinder, findsOneWidget);
      expect(continueFinder, findsOneWidget);

      final heroTop = tester.getTopLeft(heroFinder).dy;
      final continueTop = tester.getTopLeft(continueFinder).dy;
      expect(heroTop, lessThan(continueTop));

      expect(tester.takeException(), isNull);
    });
  });
}
