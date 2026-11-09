import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_service.dart';
import 'package:talib_ilm/features/quran/data/services/quran_reader_preferences.dart';
import 'package:talib_ilm/features/quran/presentation/quran_page.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_page_viewer.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_single_page.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_stats_banner.dart';
import 'helpers/mushaf_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadMushafTestAssets);

  setUp(() {
    SharedPreferences.setMockInitialValues({
      QuranReaderPreferences.lastPageKey: 3,
    });
  });

  Future<void> openContinue(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const QuranPage()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QuranLastReadBanner), findsOneWidget);
    await tester.tap(find.text('تابع القراءة'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Continue resumes last page and highlights its first ayah without a fasila',
    (tester) async {
      await openContinue(tester);

      final page = tester.widget<MushafSinglePage>(
        find.byType(MushafSinglePage),
      );
      final firstAyahOnPage = quran.getPageData(3).first;
      expect(find.byType(MushafPageViewer), findsOneWidget);
      expect(find.textContaining('الصفحة 3'), findsOneWidget);
      expect(page.activeSurah, firstAyahOnPage['surah']);
      expect(page.activeAyah, firstAyahOnPage['start']);
      expect(page.activeAyahOpacity, greaterThan(0.99));

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 350));
      final fadedPage = tester.widget<MushafSinglePage>(
        find.byType(MushafSinglePage),
      );
      expect(fadedPage.activeAyahOpacity, lessThan(0.01));
    },
  );

  testWidgets('Continue highlights a fasila when it is on the last page', (
    tester,
  ) async {
    await BookmarkService.saveLastRead(surah: 2, ayah: 10, page: 3);
    await openContinue(tester);

    final page = tester.widget<MushafSinglePage>(find.byType(MushafSinglePage));
    expect(find.textContaining('الصفحة 3'), findsOneWidget);
    expect(page.activeSurah, 2);
    expect(page.activeAyah, 10);
    expect(page.activeAyahOpacity, greaterThan(0.99));
  });

  testWidgets('a fasila from another page does not replace the latest page', (
    tester,
  ) async {
    await BookmarkService.saveLastRead(surah: 2, ayah: 10, page: 3);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(QuranReaderPreferences.lastPageKey, 4);
    await openContinue(tester);

    final page = tester.widget<MushafSinglePage>(find.byType(MushafSinglePage));
    final firstAyahOnPage = quran.getPageData(4).first;
    expect(find.textContaining('الصفحة 4'), findsOneWidget);
    expect(page.activeSurah, firstAyahOnPage['surah']);
    expect(page.activeAyah, firstAyahOnPage['start']);
    expect(page.activeAyahOpacity, greaterThan(0.99));
  });
}
