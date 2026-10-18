import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/ilm/data/models/shamela_models.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_bookmarks_sheet.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_page_content.dart';
import 'golden_test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'shamela_bookmarks': ['11266_1', '11266_5', '11266_10'],
    });
  });

  group('Shamela Reader Golden Tests', () {
    const samplePageWithHamesh = ShamelaPage(
      bookId: 11266,
      pageNumber: 1,
      chapterTitle: 'شروط الصلاة وأركانها وواجباتها',
      content:
          'شروط الصلاة تسعة: الإسلام، والعقل، والتمييز، ورفع الحدث، وإزالة النجاسة، وستر العورة، ودخول الوقت، واستقبال القبلة، والنية.',
      hamesh:
          '١ انظر: الشرح الممتع على زاد المستقنع للعلامة ابن عثيمين (٢/ ٩٥).\n٢ شروط الصلاة جمع شرط، وهو في اللغة: العلامة، وفي الاصطلاح: ما يلزم من عدمه العدم ولا يلزم من وجوده وجود ولا عدم لذاته.',
      detectedTotalPages: 10,
    );

    testWidgets('ShamelaBookmarksSheet - light 1.0 and dark 1.5', (tester) async {
      final widget = ShamelaBookmarksSheet(
        bookId: 11266,
        onNavigate: (_) {},
        initialPages: const [1, 5, 10],
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/shamela_bookmarks_sheet_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/shamela_bookmarks_sheet_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('ShamelaPageContent with hamesh closed/open - light and dark',
        (tester) async {
      // 1. Collapsed in light mode
      await testGoldenWidget(
        tester: tester,
        widget: const ShamelaPageContent(
          page: samplePageWithHamesh,
          memorizationMode: false,
          fontFamily: 'Amiri',
          fontSizeDelta: 0.0,
          lineHeight: 1.6,
        ),
        fileName: 'goldens/shamela_page_content_closed_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      // 2. Collapsed in dark mode
      await testGoldenWidget(
        tester: tester,
        widget: const ShamelaPageContent(
          page: samplePageWithHamesh,
          memorizationMode: false,
          fontFamily: 'Amiri',
          fontSizeDelta: 0.0,
          lineHeight: 1.6,
        ),
        fileName: 'goldens/shamela_page_content_closed_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );

      // 3. Open in light mode
      await testGoldenWidget(
        tester: tester,
        widget: const ShamelaPageContent(
          page: samplePageWithHamesh,
          memorizationMode: false,
          fontFamily: 'Amiri',
          fontSizeDelta: 0.0,
          lineHeight: 1.6,
          initialHameshExpanded: true,
        ),
        fileName: 'goldens/shamela_page_content_open_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      // 4. Open in dark mode
      await testGoldenWidget(
        tester: tester,
        widget: const ShamelaPageContent(
          page: samplePageWithHamesh,
          memorizationMode: false,
          fontFamily: 'Amiri',
          fontSizeDelta: 0.0,
          lineHeight: 1.6,
          initialHameshExpanded: true,
        ),
        fileName: 'goldens/shamela_page_content_open_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });
  });
}
