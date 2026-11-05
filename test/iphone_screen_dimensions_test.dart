import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/book_view_header.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_reader_top_bar.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_sliver_header.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_stats_banner.dart';
import 'package:talib_ilm/features/salaf_gems/data/models/salaf_gem.dart';
import 'package:talib_ilm/features/salaf_gems/presentation/widgets/salaf_gem_card.dart';
import 'package:talib_ilm/shared/widgets/app_tag.dart';
import 'package:talib_ilm/shared/widgets/nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHostWidget({
    required Widget child,
    required double width,
    required double height,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  group('iPhone Compact Screen Precision Tests (375dp & 390dp)', () {
    testWidgets('Quran Pinned Tabs render completely without truncation on iPhone SE / 13 Mini (375dp)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final searchController = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        buildHostWidget(
          width: 375,
          height: 667,
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: QuranPinnedHeaderDelegate(
                  selectedTabIndex: 3,
                  bookmarksCount: 0,
                  onTabSelected: (_) {},
                  searchController: searchController,
                  searchFocusNode: focusNode,
                  onSearchChanged: () {},
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify that 'المحفوظات' is fully rendered as text
      expect(find.text('المحفوظات'), findsOneWidget);
      expect(find.text('السور (114)'), findsOneWidget);
      expect(find.text('الأجزاء (30)'), findsOneWidget);
      expect(find.text('الأحزاب (60)'), findsOneWidget);

      // 2. Verify RenderParagraph instances: none of them should exceed max lines
      final renderParagraphs = tester.renderObjectList<RenderParagraph>(find.byType(RichText));
      for (final rp in renderParagraphs) {
        final text = rp.text.toPlainText();
        if (text == 'المحفوظات') {
          expect(rp.didExceedMaxLines, isFalse, reason: 'Tab $text must not be truncated');
        }
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Quran Pinned Tabs render completely with non-zero bookmarks on iPhone 12/13/14 (390dp)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final searchController = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        buildHostWidget(
          width: 390,
          height: 844,
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: QuranPinnedHeaderDelegate(
                  selectedTabIndex: 3,
                  bookmarksCount: 12,
                  onTabSelected: (_) {},
                  searchController: searchController,
                  searchFocusNode: focusNode,
                  onSearchChanged: () {},
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that 'المحفوظات (12)' is present
      expect(find.text('المحفوظات (12)'), findsOneWidget);

      // Check overflow flag
      final renderParagraphs = tester.renderObjectList<RenderParagraph>(find.byType(RichText));
      for (final rp in renderParagraphs) {
        final text = rp.text.toPlainText();
        if (text == 'المحفوظات (12)') {
          expect(rp.didExceedMaxLines, isFalse, reason: 'Tab $text must not overflow');
        }
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('QuranStatCard renders 3-column stats without overflow on iPhone SE (375dp)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildHostWidget(
          width: 375,
          height: 667,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: QuranStatCard(
                    label: 'أيام التتابع',
                    value: '7',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.amber,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: QuranStatCard(
                    label: 'قراءة اليوم',
                    value: '15 د',
                    icon: Icons.timer_outlined,
                    iconColor: Colors.teal,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: QuranStatCard(
                    label: 'المحفوظات',
                    value: '24',
                    icon: Icons.bookmark_rounded,
                    iconColor: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('أيام التتابع'), findsOneWidget);
      expect(find.text('قراءة اليوم'), findsOneWidget);
      expect(find.text('المحفوظات'), findsOneWidget);
    });

    testWidgets('NavBar renders all 5 tabs without truncation on iPhone SE (375dp)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const items = [
        NavBarItem(icon: Icons.home_rounded, label: 'الرئيسية'),
        NavBarItem(icon: Icons.menu_book_rounded, label: 'المصحف'),
        NavBarItem(icon: Icons.school_rounded, label: 'المتون'),
        NavBarItem(icon: Icons.favorite_rounded, label: 'الأذكار'),
        NavBarItem(icon: Icons.bookmark_rounded, label: 'المفضلة'),
      ];

      await tester.pumpWidget(
        buildHostWidget(
          width: 375,
          height: 667,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: NavBar(
              currentIndex: 0,
              onTap: (_) {},
              items: items,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final item in items) {
        expect(find.text(item.label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppTag scales down long subject labels without truncation on 375dp',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildHostWidget(
          width: 375,
          height: 667,
          child: const SizedBox(
            width: 100,
            child: AppTag(label: 'أصول الفقه والقواعد الفقهية'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('أصول الفقه والقواعد الفقهية'), findsOneWidget);
      final renderParagraphs = tester.renderObjectList<RenderParagraph>(find.byType(RichText));
      for (final rp in renderParagraphs) {
        if (rp.text.toPlainText() == 'أصول الفقه والقواعد الفقهية') {
          expect(rp.didExceedMaxLines, isFalse, reason: 'AppTag must not truncate');
        }
      }
    });

    testWidgets('SalafGemCard header renders scholar name without truncation on iPhone SE (375dp)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const gem = SalafGem(
        id: '1',
        author: 'عبد الله بن مسعود رضي الله عنه',
        role: 'صحابي جليل وفقيه الأمة',
        text: 'إنكم في زمان كثير علماؤه قليل خطباؤه',
        category: 'الصحابة',
        topic: 'طلب العلم',
        sourceRef: 'صحيح البخاري',
      );

      await tester.pumpWidget(
        buildHostWidget(
          width: 375,
          height: 667,
          child: SingleChildScrollView(
            child: SalafGemCard(
              gem: gem,
              isFavorite: false,
              onToggleFavorite: () {},
              onCopy: () {},
              onShare: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('عبد الله بن مسعود رضي الله عنه'), findsOneWidget);
      final renderParagraphs = tester.renderObjectList<RenderParagraph>(find.byType(RichText));
      for (final rp in renderParagraphs) {
        if (rp.text.toPlainText() == 'عبد الله بن مسعود رضي الله عنه') {
          expect(rp.didExceedMaxLines, isFalse, reason: 'Scholar name must not truncate');
        }
      }
    });

    testWidgets('Android Standard (360dp) renders Quran tabs, NavBar and Cards without truncation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final searchController = TextEditingController();
      final focusNode = FocusNode();

      // 1. Test Quran Pinned Tabs on Android 360dp
      await tester.pumpWidget(
        buildHostWidget(
          width: 360,
          height: 800,
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: QuranPinnedHeaderDelegate(
                  selectedTabIndex: 3,
                  bookmarksCount: 5,
                  onTabSelected: (_) {},
                  searchController: searchController,
                  searchFocusNode: focusNode,
                  onSearchChanged: () {},
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('المحفوظات (5)'), findsOneWidget);
      expect(find.text('السور (114)'), findsOneWidget);
      expect(find.text('الأجزاء (30)'), findsOneWidget);
      expect(find.text('الأحزاب (60)'), findsOneWidget);

      final renderParagraphs = tester.renderObjectList<RenderParagraph>(find.byType(RichText));
      for (final rp in renderParagraphs) {
        final text = rp.text.toPlainText();
        if (text == 'المحفوظات (5)') {
          expect(rp.didExceedMaxLines, isFalse, reason: 'Android 360dp tab $text must not truncate');
        }
      }

      // 2. Test NavBar on Android 360dp
      const items = [
        NavBarItem(icon: Icons.home_rounded, label: 'الرئيسية'),
        NavBarItem(icon: Icons.menu_book_rounded, label: 'المصحف'),
        NavBarItem(icon: Icons.school_rounded, label: 'المتون'),
        NavBarItem(icon: Icons.favorite_rounded, label: 'الأذكار'),
        NavBarItem(icon: Icons.bookmark_rounded, label: 'المفضلة'),
      ];

      await tester.pumpWidget(
        buildHostWidget(
          width: 360,
          height: 800,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: NavBar(
              currentIndex: 0,
              onTap: (_) {},
              items: items,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final item in items) {
        expect(find.text(item.label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Android with Accessibility Text Scale (1.25x on 360dp) retains integrity',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final searchController = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        buildHostWidget(
          width: 360,
          height: 800,
          textScale: 1.25,
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: QuranPinnedHeaderDelegate(
                  selectedTabIndex: 0,
                  bookmarksCount: 0,
                  onTabSelected: (_) {},
                  searchController: searchController,
                  searchFocusNode: focusNode,
                  onSearchChanged: () {},
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('السور (114)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('BookViewHeader renders long title without truncation on 360dp Android',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const longTitle = 'شرح العقيدة الواسطية لشيخ الإسلام ابن تيمية';

      await tester.pumpWidget(
        buildHostWidget(
          width: 360,
          height: 800,
          child: Column(
            children: [
              DefaultTabController(
                length: 3,
                child: Builder(
                  builder: (context) {
                    return BookViewHeader(
                      showControls: false,
                      bookTitle: longTitle,
                      currentPage: 15,
                      totalPages: 120,
                      isFavorite: false,
                      onToggleFavorite: () {},
                      onResetProgress: () {},
                      onShowBookmarksAndNotes: () {},
                      tabController: DefaultTabController.of(context),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(longTitle), findsNWidgets(2));
      final renderParagraphs = tester.renderObjectList<RenderParagraph>(find.byType(RichText));
      for (final rp in renderParagraphs) {
        if (rp.text.toPlainText() == longTitle) {
          expect(rp.didExceedMaxLines, isFalse, reason: 'BookViewHeader must not truncate on 360dp');
        }
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('ShamelaReaderTopBar renders long title without truncation on 360dp Android',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const longTitle = 'شرح العقيدة الواسطية لشيخ الإسلام ابن تيمية';

      await tester.pumpWidget(
        buildHostWidget(
          width: 360,
          height: 800,
          child: Column(
            children: [
              ShamelaReaderTopBar(
                title: longTitle,
                author: 'الإمام ابن تيمية',
                currentPage: 25,
                totalPages: 300,
                showControls: false,
                bgColor: Colors.white,
                onBack: () {},
                onCopy: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(longTitle), findsNWidgets(2));
      final renderParagraphs = tester.renderObjectList<RenderParagraph>(find.byType(RichText));
      for (final rp in renderParagraphs) {
        if (rp.text.toPlainText() == longTitle) {
          expect(rp.didExceedMaxLines, isFalse, reason: 'ShamelaReaderTopBar must not truncate on 360dp');
        }
      }
      expect(tester.takeException(), isNull);
    });
  });
}
