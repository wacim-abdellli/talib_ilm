import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/app/theme/app_ui.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/aqidah_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_audio_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_digital_catalog.dart';
import 'package:talib_ilm/features/ilm/data/models/mutun_models.dart';
import 'package:talib_ilm/features/ilm/data/services/mutun_audio_service.dart';
import 'package:talib_ilm/features/ilm/data/services/shamela_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/book_mutn_tab.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/mutn_curriculum_reader_view.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/mutun_audio_player_hud.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/scholarly_reader_hud.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_reader_top_bar.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_typography_sheet.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );
  }

  group('BookPageTapDetector Tests', () {
    testWidgets('Quick tap fires onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          BookPageTapDetector(
            onTap: () => tapped = true,
            child: Container(
              width: 300,
              height: 300,
              color: Colors.blue,
              child: const Text('Page Text'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Page Text'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('Drag gesture (scroll) does not trigger onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          BookPageTapDetector(
            onTap: () => tapped = true,
            child: Container(
              width: 300,
              height: 300,
              color: Colors.blue,
              child: const Text('Page Text'),
            ),
          ),
        ),
      );

      // Drag vertically 100 pixels
      await tester.drag(find.text('Page Text'), const Offset(0, -100));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('Long press (text selection) does not trigger onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          BookPageTapDetector(
            onTap: () => tapped = true,
            child: Container(
              width: 300,
              height: 300,
              color: Colors.blue,
              child: const Text('Page Text'),
            ),
          ),
        ),
      );

      // Long press over debounce duration
      final gesture = await tester.startGesture(tester.getCenter(find.text('Page Text')));
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      await tester.pump();

      expect(tapped, isFalse);
    });
  });

  group('ScholarlyReaderHud Tests', () {
    testWidgets('Renders all controls, indicators, and tools properly', (tester) async {
      bool prevTapped = false;
      bool nextTapped = false;
      bool fihrisTapped = false;
      bool bookmarkTapped = false;
      bool noteTapped = false;
      bool memorizationTapped = false;
      bool typographyTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          ScholarlyReaderHud(
            currentPage: 5,
            totalPages: 50,
            isBookmarked: false,
            memorizationMode: false,
            showControls: true,
            onPreviousPage: () => prevTapped = true,
            onNextPage: () => nextTapped = true,
            onPageIndicatorTap: () => fihrisTapped = true,
            onToggleBookmark: () => bookmarkTapped = true,
            onAddNote: () => noteTapped = true,
            onOpenFihris: () => fihrisTapped = true,
            onToggleMemorization: () => memorizationTapped = true,
            onOpenTypography: () => typographyTapped = true,
          ),
        ),
      );

      // Verify page indicator text
      expect(find.text('صفحة 5 من 50'), findsOneWidget);

      // Verify tool labels
      expect(find.text('إشارة'), findsOneWidget);
      expect(find.text('ملاحظة'), findsOneWidget);
      expect(find.text('الفهرس'), findsOneWidget);
      expect(find.text('تسميع'), findsOneWidget);
      expect(find.text('الخط'), findsOneWidget);

      // Test tap on page indicator
      await tester.tap(find.text('صفحة 5 من 50'));
      expect(fihrisTapped, isTrue);

      // Test tap on previous page button
      await tester.tap(find.byTooltip('الصفحة السابقة'));
      expect(prevTapped, isTrue);

      // Test tap on next page button
      await tester.tap(find.byTooltip('الصفحة التالية'));
      expect(nextTapped, isTrue);

      // Test tap on bookmark tool
      await tester.tap(find.text('إشارة'));
      expect(bookmarkTapped, isTrue);

      // Test tap on note tool
      await tester.tap(find.text('ملاحظة'));
      expect(noteTapped, isTrue);

      // Test tap on memorization tool
      await tester.tap(find.text('تسميع'));
      expect(memorizationTapped, isTrue);

      // Test tap on typography tool
      await tester.tap(find.text('الخط'));
      expect(typographyTapped, isTrue);
    });

    testWidgets('Bookmarked and Memorization mode active states render correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          ScholarlyReaderHud(
            currentPage: 10,
            totalPages: 100,
            isBookmarked: true,
            memorizationMode: true,
            showControls: true,
            onPreviousPage: () {},
            onNextPage: () {},
            onPageIndicatorTap: () {},
            onToggleBookmark: () {},
            onAddNote: () {},
            onOpenFihris: () {},
            onToggleMemorization: () {},
            onOpenTypography: () {},
          ),
        ),
      );

      // When bookmarked, label says محفوظة
      expect(find.text('محفوظة'), findsOneWidget);
      expect(find.text('إشارة'), findsNothing);

      // Memorization mode icon toggles
      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    });

    testWidgets('Collapses height to 0 when showControls is false', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          ScholarlyReaderHud(
            currentPage: 1,
            totalPages: 10,
            isBookmarked: false,
            memorizationMode: false,
            showControls: false,
            onPreviousPage: null,
            onNextPage: null,
            onPageIndicatorTap: () {},
            onToggleBookmark: () {},
            onAddNote: () {},
            onOpenFihris: () {},
            onToggleMemorization: () {},
            onOpenTypography: () {},
          ),
        ),
      );

      final animatedContainerFinder = find.byType(AnimatedContainer);
      expect(animatedContainerFinder, findsOneWidget);
      final container = tester.widget<AnimatedContainer>(animatedContainerFinder);
      expect(container.constraints?.maxHeight, equals(0.0));
    });
  });

  group('Reader Accent Colors & Typography Sheet Tests', () {
    test('ReaderAccentColors provides valid non-null tokens for all accents', () {
      for (final accent in ShamelaAccentColor.values) {
        final lightTokens = ReaderAccentColors.getTokens(accent, isDark: false);
        final darkTokens = ReaderAccentColors.getTokens(accent, isDark: true);

        expect(lightTokens.primary, isNotNull);
        expect(lightTokens.soft, isNotNull);
        expect(lightTokens.onSoft, isNotNull);
        expect(lightTokens.border, isNotNull);

        expect(darkTokens.primary, isNotNull);
        expect(darkTokens.soft, isNotNull);
        expect(darkTokens.onSoft, isNotNull);
        expect(darkTokens.border, isNotNull);
      }
    });

    testWidgets('ShamelaTypographySheet renders all 5 accent color options and selects', (tester) async {
      ShamelaAccentColor selectedAccent = ShamelaAccentColor.emerald;

      await tester.pumpWidget(
        buildTestableWidget(
          ShamelaTypographySheet(
            fontSizeDelta: 0.0,
            fontFamily: 'Amiri',
            lineHeight: 1.85,
            surface: ShamelaReaderSurface.normal,
            accentColor: selectedAccent,
            onFontSizeChanged: (_) {},
            onFontFamilyChanged: (_) {},
            onLineHeightChanged: (_) {},
            onSurfaceChanged: (_) {},
            onAccentColorChanged: (accent) {
              selectedAccent = accent;
            },
          ),
        ),
      );

      // Verify header for accent picker is rendered
      expect(find.text('لون تمييز الآيات والعناوين'), findsOneWidget);

      // Verify all 5 accent labels are rendered with easy Arabic names
      expect(find.text('أخضر'), findsOneWidget);
      expect(find.text('أحمر'), findsOneWidget);
      expect(find.text('أزرق'), findsOneWidget);
      expect(find.text('برتقالي'), findsOneWidget);
      expect(find.text('ذهبي'), findsOneWidget);

      // Verify all 3 surface environment options are rendered
      expect(find.text('الافتراضي'), findsOneWidget);
      expect(find.text('ورق الشاموا (بيج)'), findsOneWidget);
      expect(find.text('داكن هادئ'), findsOneWidget);

      // Tap on 'أزرق' (navy)
      await tester.tap(find.text('أزرق'));
      await tester.pump();

      expect(selectedAccent, equals(ShamelaAccentColor.navy));
    });

    test('ReaderSurfaceColors provides valid high-contrast tokens in light and dark modes', () {
      for (final surface in ShamelaReaderSurface.values) {
        final lightTokens = ReaderSurfaceColors.getTokens(surface, isDark: false);
        final darkTokens = ReaderSurfaceColors.getTokens(surface, isDark: true);

        expect(lightTokens.bg, isNotNull);
        expect(lightTokens.surfaceRaised, isNotNull);
        expect(lightTokens.text, isNotNull);
        expect(lightTokens.border, isNotNull);
        expect(lightTokens.label, isNotEmpty);

        expect(darkTokens.bg, isNotNull);
        expect(darkTokens.surfaceRaised, isNotNull);
        expect(darkTokens.text, isNotNull);
        expect(darkTokens.border, isNotNull);
        expect(darkTokens.label, isNotEmpty);
      }
    });

    testWidgets('ShamelaReaderTopBar renders title, author and triggers copy', (tester) async {
      bool copyTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          ShamelaReaderTopBar(
            title: 'ثلاثة الأصول',
            author: 'محمد بن عبد الوهاب',
            currentPage: 3,
            totalPages: 24,
            showControls: true,
            bgColor: Colors.black,
            surface: ShamelaReaderSurface.night,
            onBack: () {},
            onCopy: () => copyTapped = true,
          ),
        ),
      );

      // Verify book title is rendered
      expect(find.text('ثلاثة الأصول'), findsWidgets);
      // Verify copy button is present and functional
      final copyFinder = find.byTooltip('نسخ الصفحة');
      expect(copyFinder, findsOneWidget);

      await tester.tap(copyFinder);
      await tester.pump();

      expect(copyTapped, isTrue);
    });
  });

  group('Mutun Audio Sync & ±5s Controls Tests', () {
    test('AppMotion.seekStep is precisely 5 seconds', () {
      expect(AppMotion.seekStep.inSeconds, 5);
    });

    test('MutunAudioCatalog has verified timestamps for Level 1 books', () {
      final nawaqidTimestamps =
          MutunAudioCatalog.getParagraphTimestamps('bk_nawaqid_islam');
      expect(nawaqidTimestamps, isNotNull);
      expect(nawaqidTimestamps!.length, 10);
      expect(nawaqidTimestamps[0], 0);

      final qawaidTimestamps =
          MutunAudioCatalog.getParagraphTimestamps('bk_qawaid_arba');
      expect(qawaidTimestamps, isNotNull);
      expect(qawaidTimestamps!.length, 8);
      expect(qawaidTimestamps[0], 0);

      final usulTimestamps =
          MutunAudioCatalog.getParagraphTimestamps('bk_usul_thalatha');
      expect(usulTimestamps, isNotNull);
      expect(usulTimestamps!.length, 28);
      expect(usulTimestamps[0], 0);
      expect(usulTimestamps[1], 30000);
    });

    test('MutunDigitalCatalog has startPage checkpoint for bk_usul_thalatha', () {
      final entry = MutunDigitalCatalog.getEntry('bk_usul_thalatha');
      expect(entry, isNotNull);
      expect(entry!.startPage, 2);
    });

    testWidgets('BookMutnTab prioritizes authentic MutnCurriculumReaderView for syllabus books', (tester) async {
      final book = IlmBook(
        id: 'bk_usul_thalatha',
        title: 'ثلاثة الأصول وأدلتها',
        author: 'محمد بن عبد الوهاب',
        level: 'المستوى الأول',
        subject: 'العقيدة',
        description: 'متن ثلاثة الأصول وأدلتها',
        totalPages: 25,
        shuruh: const [],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          BookMutnTab(
            book: book,
            mutunInitialPage: Future.value(1),
            onPageChanged: (_, _) async {},
            showControls: true,
            onToggleControls: () {},
            isBookmarked: false,
            onToggleBookmark: () {},
            onAddNote: () {},
            onShowBookmarks: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: renders MutnCurriculumReaderView (not Shamela)
      expect(find.byType(MutnCurriculumReaderView), findsOneWidget);
      // Starts directly on the first line the reciter says, without fahras
      expect(find.textContaining('المسائل الأربع التي يجب تعلمها'), findsOneWidget);
    });

    testWidgets('MutunAudioPlayerHud renders seek slider, ±5s skip buttons and controls', (tester) async {
      final audioService = MutunAudioService();

      await tester.pumpWidget(
        buildTestableWidget(
          MutunAudioPlayerHud(
            audioService: audioService,
            bookId: 'bk_nawaqid_islam',
            onOpenQuickJump: () {},
          ),
        ),
      );

      // Verify ±5s skip buttons
      expect(find.byTooltip('رجوع 5 ثوانٍ'), findsOneWidget);
      expect(find.byTooltip('تقديم 5 ثوانٍ'), findsOneWidget);
      expect(find.byIcon(Icons.replay_5_rounded), findsOneWidget);
      expect(find.byIcon(Icons.forward_5_rounded), findsOneWidget);

      // Verify seek slider
      expect(find.byType(Slider), findsOneWidget);

      // Verify play button
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    test('AqidahCatalog has verified totalPages for classic texts', () {
      final usulThalatha =
          AqidahCatalog.books.firstWhere((b) => b.id == 11126);
      expect(usulThalatha.totalPages, 12);

      final qawaidArba =
          AqidahCatalog.books.firstWhere((b) => b.id == 8524);
      expect(qawaidArba.totalPages, 4);
    });

    test('ShamelaService extracts true total pages from page navigation HTML', () {
      const mockShamelaPage1Html = '''
<div class="nass">
<p>بسم الله الرحمن الرحيم</p>
</div>
<div class="pagination">
  <a href="/book/11126/2#p1">&gt;</a>
  <a href="/book/11126/12#p1">&gt;&gt;</a>
</div>
''';
      final detected =
          ShamelaService.extractTotalPagesFromHtml(11126, mockShamelaPage1Html);
      expect(detected, 12);
    });

    test('ShamelaService resolves effective total pages dynamically', () {
      // Fallback if not discovered
      expect(ShamelaService.getEffectiveTotalPages(999999, 50), 50);

      // Save discovered total pages
      ShamelaService.saveDiscoveredTotalPages(999999, 12);
      expect(ShamelaService.getEffectiveTotalPages(999999, 50), 12);
    });
  });
}

