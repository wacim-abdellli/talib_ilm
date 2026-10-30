import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/salaf_gems/data/models/salaf_gem.dart';
import 'package:talib_ilm/features/salaf_gems/data/repositories/encyclopedia_sections_data.dart';
import 'package:talib_ilm/features/salaf_gems/data/repositories/salaf_gems_repository.dart';
import 'package:talib_ilm/features/salaf_gems/presentation/kalem_tayeb_portal_page.dart';
import 'package:talib_ilm/features/salaf_gems/presentation/salaf_gems_explorer_page.dart';

Widget _wrapPortal({double textScale = 1.0}) {
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
        child: const KalemTayebPortalPage(),
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
    topic: 'طب القلوب',
    text: 'صدأ القلب بأمرين: بالغفلة والذنب، وجلاؤه بشيئين: بالاستغفار والذكر.',
    sourceRef: 'الوابل الصيب من الكلم الطيب',
  );

  const sampleGem3 = SalafGem(
    id: 'gem_sample_03',
    author: 'عبد الله بن مسعود رضي الله عنه',
    role: 'صحابي جليل فقيه الأمة',
    category: 'أقوال الصحابة',
    topic: 'حال السلف مع القرآن',
    text: 'إذا أردتم العلم فانثروا القرآن، فإن فيه علم الأولين والآخرين.',
    sourceRef: 'مصنف ابن أبي شيبة (30018)',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SalafGemsRepository.instance.setMockGems([sampleGem1, sampleGem2, sampleGem3]);
    SalafGemsRepository.instance.setMockFavorites({});
  });

  group('Kalem Tayeb Encyclopedia Data & Model Tests', () {
    test('EncyclopediaGroups are non-empty and well-structured', () {
      final groups = EncyclopediaSectionsData.groups;
      expect(groups.isNotEmpty, isTrue);
      expect(groups.length, 5); // 5 Groups matching screenshots 1 & 2

      final allIds = <String>{};
      for (final group in groups) {
        expect(group.id.isNotEmpty, isTrue);
        expect(group.title.isNotEmpty, isTrue);
        expect(group.sections.isNotEmpty, isTrue);

        for (final sec in group.sections) {
          expect(allIds.contains(sec.id), isFalse, reason: 'Duplicate section ID: ${sec.id}');
          allIds.add(sec.id);
          expect(sec.title.isNotEmpty, isTrue);
          expect(sec.description.isNotEmpty, isTrue);
          expect(sec.groupKey, group.id);
        }
      }
      expect(allIds.length, 26); // Exactly 26 sections defined
    });

    test('SalafGemsRepository retrieves sections and filters correctly', () async {
      final repo = SalafGemsRepository.instance;
      final secTaymiyyah = repo.getSectionById('ibn_taymiyyah_treasury');
      expect(secTaymiyyah, isNotNull);

      final gemsTaymiyyah = await repo.getGemsForSection(secTaymiyyah!);
      expect(gemsTaymiyyah.length, 1);
      expect(gemsTaymiyyah.first.id, 'gem_sample_01');

      final secQayyim = repo.getSectionById('ibn_al_qayyim_treasury');
      expect(secQayyim, isNotNull);
      final gemsQayyim = await repo.getGemsForSection(secQayyim!);
      expect(gemsQayyim.length, 1);
      expect(gemsQayyim.first.id, 'gem_sample_02');

      final secQuran = repo.getSectionById('tadabbur_pauses');
      expect(secQuran, isNotNull);
      final gemsQuran = await repo.getGemsForSection(secQuran!);
      expect(gemsQuran.length, 1);
      expect(gemsQuran.first.id, 'gem_sample_03');
    });
  });

  group('KalemTayebPortalPage Widget Rendering & TextScale Tests', () {
    testWidgets('Renders portal with banner, hubs, and sections at textScale 1.0', (tester) async {
      await tester.pumpWidget(_wrapPortal(textScale: 1.0));
      await tester.pumpAndSettle();

      // Top App Bar
      expect(find.text('الكلم الطيب'), findsOneWidget);

      // Top Quranic Banner
      expect(find.textContaining('إِلَيْهِ يَصْعَدُ الْكَلِمُ الطَّيِّبُ'), findsOneWidget);

      // 4 Grand Hubs
      expect(find.text('فوائد وحكم'), findsOneWidget);
      expect(find.text('أدعية وأذكار'), findsOneWidget);
      expect(find.text('جوامع الكلم'), findsOneWidget);
      expect(find.text('مقالات إيمانية'), findsWidgets);

      // Daily Card
      expect(find.text('قطوف من الكلم الطيب'), findsOneWidget);

      // Scroll down to reveal grouped section panels
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Section titles
      expect(find.text('القرآن وأسماء الله الحسنى'), findsOneWidget);
      expect(find.text('معاني الأسماء الحسنى'), findsOneWidget);
    });

    testWidgets('Survives textScale 1.5 without overflow', (tester) async {
      await tester.pumpWidget(_wrapPortal(textScale: 1.5));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('الكلم الطيب'), findsOneWidget);
    });

    testWidgets('Survives textScale 2.0 without overflow', (tester) async {
      await tester.pumpWidget(_wrapPortal(textScale: 2.0));
      await tester.pumpAndSettle();

      final ex = tester.takeException();
      if (ex != null) {
        // ignore: avoid_print
        print('FLUTTER OVERFLOW DEBUG: $ex');
      }
      expect(ex, isNull);
      expect(find.text('الكلم الطيب'), findsOneWidget);
    });
  });

  group('SalafGemsExplorerPage with initialSectionId Tests', () {
    testWidgets('Opens explorer filtered to a specific section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: SalafGemsExplorerPage(
              pageTitle: 'فوائد من كتب ابن تيمية',
              initialSectionId: 'ibn_taymiyyah_treasury',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('فوائد من كتب ابن تيمية'), findsOneWidget);
      expect(find.textContaining('شيخ الإسلام ابن تيمية'), findsOneWidget);
      expect(find.textContaining('القلب لا يصلح'), findsOneWidget);
    });
  });
}
