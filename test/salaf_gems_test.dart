import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/salaf_gems/data/models/salaf_gem.dart';
import 'package:talib_ilm/features/salaf_gems/data/repositories/salaf_gems_repository.dart';
import 'package:talib_ilm/features/salaf_gems/presentation/salaf_gems_explorer_page.dart';
import 'package:talib_ilm/features/salaf_gems/presentation/widgets/home_salaf_gem_card.dart';
import 'package:talib_ilm/features/salaf_gems/presentation/widgets/salaf_gem_share_sheet.dart';

Widget _wrapWithTheme(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.light,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          size: const Size(400, 900),
        ),
        child: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testGem1 = SalafGem(
    id: 'gem_test_01',
    author: 'عمر بن الخطاب رضي الله عنه',
    role: 'صحابي جليل',
    category: 'أقوال الصحابة',
    topic: 'الصدق والأمانة',
    text: 'لا تنظروا إلى صيام أحد ولا صلاته، ولكن انظروا إلى صدق حديثه إذا حدث، وأمانته إذا ائتمن.',
    sourceRef: 'حلية الأولياء (3/ 27)',
  );

  const testGem2 = SalafGem(
    id: 'gem_test_02',
    author: 'الإمام ابن القيم',
    role: 'إمام ومحقق',
    category: 'فوائد المحققين',
    topic: 'أعمال القلوب',
    text: 'القلب يمرض كما يمرض البدن، وشفاؤه في التوبة والحمية، ويصدأ كما تصدأ المرآة، وجلاؤه بالذكر.',
    sourceRef: 'الفوائد لابن القيم',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SalafGemsRepository.instance.setMockGems([testGem1, testGem2]);
    SalafGemsRepository.instance.setMockFavorites({});
  });

  group('SalafGem Model Tests', () {
    test('SalafGem serializes and deserializes correctly', () {
      final json = testGem1.toJson();
      final parsed = SalafGem.fromJson(json);

      expect(parsed.id, testGem1.id);
      expect(parsed.author, testGem1.author);
      expect(parsed.text, testGem1.text);
      expect(parsed.sourceRef, testGem1.sourceRef);
    });

    test('shareableText contains attribution and source reference', () {
      final shareText = testGem1.shareableText;
      expect(shareText, contains('عمر بن الخطاب'));
      expect(shareText, contains('حلية الأولياء'));
      expect(shareText, contains('طالب العلم'));
    });
  });

  group('SalafGemsRepository Tests', () {
    test('getDailyGem returns deterministic gem based on date', () async {
      final repo = SalafGemsRepository.instance;
      final gemDay1 = await repo.getDailyGem(customDate: DateTime(2026, 1, 1));
      final gemDay1Again = await repo.getDailyGem(customDate: DateTime(2026, 1, 1));

      expect(gemDay1.id, gemDay1Again.id);
    });

    test('searchGems filters by author, category, and text query', () async {
      final repo = SalafGemsRepository.instance;

      final byAuthor = await repo.searchGems(author: 'ابن القيم');
      expect(byAuthor.length, 1);
      expect(byAuthor.first.id, testGem2.id);

      final byCategory = await repo.searchGems(category: 'أقوال الصحابة');
      expect(byCategory.length, 1);
      expect(byCategory.first.id, testGem1.id);

      final byQuery = await repo.searchGems(query: 'القلب يمرض');
      expect(byQuery.length, 1);
      expect(byQuery.first.id, testGem2.id);
    });

    test('toggleFavorite updates favorite state correctly', () async {
      final repo = SalafGemsRepository.instance;

      expect(await repo.isFavorite(testGem1.id), false);
      final added = await repo.toggleFavorite(testGem1.id);
      expect(added, true);
      expect(await repo.isFavorite(testGem1.id), true);

      final removed = await repo.toggleFavorite(testGem1.id);
      expect(removed, false);
      expect(await repo.isFavorite(testGem1.id), false);
    });
  });

  group('Salaf Gems UI Scaling & Responsive Tests', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('HomeSalafGemCard renders cleanly without overflow at textScale $scale',
          (tester) async {
        await tester.pumpWidget(_wrapWithTheme(
          const Padding(
            padding: EdgeInsets.all(16),
            child: HomeSalafGemCard(),
          ),
          textScale: scale,
        ));
        await tester.pumpAndSettle();

        expect(find.text('قَبَسٌ مِنَ السَّلَفِ'), findsOneWidget);
        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
        expect(find.text('تصفح الموسوعة ←'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('SalafGemShareSheet renders correctly at textScale $scale', (tester) async {
        await tester.pumpWidget(_wrapWithTheme(
          const SalafGemShareSheet(gem: testGem1),
          textScale: scale,
        ));
        await tester.pumpAndSettle();

        expect(find.text('بطاقة درر السلف'), findsOneWidget);
        expect(find.text('نسخ الأثر'), findsOneWidget);
        expect(find.text('مشاركة'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('SalafGemsExplorerPage renders and searches at textScale $scale',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(scale),
                size: const Size(400, 900),
              ),
              child: const SalafGemsExplorerPage(),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('موسوعة درر السلف والآثار'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
