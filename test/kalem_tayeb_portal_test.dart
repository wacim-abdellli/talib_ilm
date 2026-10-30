import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/salaf_gems/data/models/salaf_filter_models.dart';
import 'package:talib_ilm/features/salaf_gems/data/models/salaf_gem.dart';
import 'package:talib_ilm/features/salaf_gems/data/repositories/salaf_gems_repository.dart';
import 'package:talib_ilm/features/salaf_gems/presentation/salaf_gems_explorer_page.dart';
import 'package:talib_ilm/features/salaf_gems/presentation/widgets/salaf_quick_jump_sheet.dart';

Widget _wrapExplorer({double textScale = 1.0}) {
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
        child: const SalafGemsExplorerPage(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleGem1 = SalafGem(
    id: 'gem_sample_01',
    author: 'شيخ الإسلام ابن تيمية',
    role: 'إمام ومجدد',
    category: 'فوائد المحققين',
    topic: 'التوحيد والاستقامة',
    text: 'القلب لا يصلح، ولا يفلح، ولا يسر ولا يطيب، ولا يلتذ، ولا يطمئن إلا بعبادة ربه وحبه والإنابة إليه.',
    sourceRef: 'مجموع الفتاوى (28/ 32)',
  );

  const sampleGem2 = SalafGem(
    id: 'gem_sample_02',
    author: 'الإمام ابن القيم',
    role: 'إمام رباني',
    category: 'فوائد المحققين',
    topic: 'الزهد والرقائق وتزكية النفوس',
    text: 'صدأ القلب بأمرين: بالغفلة والذنب، وجلاؤه بشيئين: بالاستغفار والذكر.',
    sourceRef: 'الوابل الصيب من الكلم الطيب',
  );

  const sampleGem3 = SalafGem(
    id: 'gem_sample_03',
    author: 'عبد الله بن مسعود رضي الله عنه',
    role: 'صحابي جليل فقيه الأمة',
    category: 'أقوال الصحابة',
    topic: 'حال السلف مع القرآن وتدبره',
    text: 'إذا أردتم العلم فانثروا القرآن، فإن فيه علم الأولين والآخرين.',
    sourceRef: 'مصنف ابن أبي شيبة (30018)',
  );

  const sampleGem4 = SalafGem(
    id: 'gem_sample_04',
    author: 'رسول الله ﷺ',
    role: 'سيد الخلق وإمام المتقين',
    category: 'وصايا نبوية',
    topic: 'فضائل الأعمال وجوامع الكلم',
    text: 'من كان آخر كلامه لا إله إلا الله دخل الجنة.',
    sourceRef: 'صححه الألباني',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SalafGemsRepository.instance.setMockGems([
      sampleGem1,
      sampleGem2,
      sampleGem3,
      sampleGem4,
    ]);
    SalafGemsRepository.instance.setMockFavorites({});
  });

  group('Salaf Filter Models & Data Integrity Tests', () {
    test('Scholars catalog contains authentic figures with unique IDs', () {
      final scholars = SalafFilterData.scholars;
      expect(scholars.isNotEmpty, isTrue);
      expect(scholars.length, greaterThanOrEqualTo(20));

      final ids = <String>{};
      for (final s in scholars) {
        expect(ids.contains(s.id), isFalse, reason: 'Duplicate scholar ID: ${s.id}');
        ids.add(s.id);
        expect(s.displayName.isNotEmpty, isTrue);
        expect(s.queryKeyword.isNotEmpty, isTrue);
        expect(s.role.isNotEmpty, isTrue);
      }
    });

    test('Topics catalog contains authentic themes with unique IDs', () {
      final topics = SalafFilterData.topics;
      expect(topics.isNotEmpty, isTrue);
      expect(topics.length, greaterThanOrEqualTo(10));

      final ids = <String>{};
      for (final t in topics) {
        expect(ids.contains(t.id), isFalse, reason: 'Duplicate topic ID: ${t.id}');
        ids.add(t.id);
        expect(t.title.isNotEmpty, isTrue);
      }
    });

    test('Strict scholar filtering guarantees no false attributions', () async {
      final repo = SalafGemsRepository.instance;

      // Filtering by Ibn Taymiyyah must ONLY return Ibn Taymiyyah
      final taymiyyahOnly = await repo.filterGems(scholarQuery: 'ابن تيمية');
      expect(taymiyyahOnly.length, 1);
      expect(taymiyyahOnly.first.id, 'gem_sample_01');
      expect(taymiyyahOnly.first.author, contains('ابن تيمية'));

      // Filtering by Ibn Al-Qayyim must ONLY return Ibn Al-Qayyim
      final qayyimOnly = await repo.filterGems(scholarQuery: 'ابن القيم');
      expect(qayyimOnly.length, 1);
      expect(qayyimOnly.first.id, 'gem_sample_02');

      // Citing 'الألباني' in sourceRef must NEVER mistakenly match as author
      final albaniSearch = await repo.filterGems(scholarQuery: 'الألباني');
      expect(albaniSearch.isEmpty, isTrue);

      // Filtering by Prophet ﷺ
      final prophetOnly = await repo.filterGems(scholarQuery: 'رسول الله ﷺ');
      expect(prophetOnly.length, 1);
      expect(prophetOnly.first.id, 'gem_sample_04');
    });

    test('Strict topic filtering returns thematic gems', () async {
      final repo = SalafGemsRepository.instance;

      final quranTopic = SalafFilterData.topics.firstWhere((t) => t.id == 'quran_tadabbur');
      final quranGems = await repo.filterGems(topic: quranTopic);
      expect(quranGems.length, 1);
      expect(quranGems.first.id, 'gem_sample_03');

      final zuhdTopic = SalafFilterData.topics.firstWhere((t) => t.id == 'zuhd_raqaeq');
      final zuhdGems = await repo.filterGems(topic: zuhdTopic);
      expect(zuhdGems.length, 1);
      expect(zuhdGems.first.id, 'gem_sample_02');
    });
  });

  group('SalafGemsExplorerPage Sovereign Rendering Tests', () {
    testWidgets('Renders Explorer page at textScale 1.0 without error', (tester) async {
      await tester.pumpWidget(_wrapExplorer(textScale: 1.0));
      await tester.pumpAndSettle();

      expect(find.text('موسوعة درر السلف والآثار'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('القائل ▾'), findsOneWidget);
      expect(find.text('الموضوع ▾'), findsOneWidget);
      expect(find.text('الكل'), findsAtLeastNWidgets(1));
    });

    testWidgets('Survives textScale 1.5 without overflow', (tester) async {
      await tester.pumpWidget(_wrapExplorer(textScale: 1.5));
      await tester.pumpAndSettle();

      expect(find.text('موسوعة درر السلف والآثار'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Survives textScale 2.0 without overflow', (tester) async {
      await tester.pumpWidget(_wrapExplorer(textScale: 2.0));
      await tester.pumpAndSettle();

      expect(find.text('موسوعة درر السلف والآثار'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SalafQuickJumpSheet renders and survives textScale 1.0, 1.5, 2.0', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(scale),
                  size: const Size(400, 900),
                ),
                child: Scaffold(
                  body: SalafQuickJumpSheet(
                    totalCount: 463,
                    gems: const [sampleGem1, sampleGem2, sampleGem3, sampleGem4],
                    onJumpToIndex: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('انتقال سريع بين الآثار'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
