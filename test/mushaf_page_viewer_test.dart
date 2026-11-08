import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_service.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_page_viewer.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_single_page.dart';
import 'helpers/mushaf_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadMushafTestAssets);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: child,
        ),
      ),
    );
  }

  group('MushafPageViewer Authentic Medina Mushaf Tests', () {
    testWidgets('Renders PageView with 604 authentic Mushaf pages', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(const MushafPageViewer(initialPage: 1)),
      );
      await tester.pumpAndSettle();

      // PageView holds the 604 authentic pages
      expect(find.byType(PageView), findsOneWidget);
      expect(
        tester
            .widget<PageView>(find.byType(PageView))
            .childrenDelegate
            .estimatedChildCount,
        604,
      );
      expect(find.byType(MushafSinglePage), findsOneWidget);

      // Top bar title displays current Surah and Page
      expect(find.text('سُورَةُ الفَاتِحَةِ'), findsWidgets);
      expect(find.textContaining('الصفحة 1'), findsOneWidget);
    });

    testWidgets('Quick jump changes page correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const MushafPageViewer(initialPage: 1)),
      );
      await tester.pumpAndSettle();

      expect(find.text('سُورَةُ الفَاتِحَةِ'), findsWidgets);
      await tester.tap(find.byTooltip('انتقال سريع وفهرس السور'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2');
      await tester.tap(find.text('انتقال'));
      await tester.pumpAndSettle();

      expect(find.textContaining('الصفحة 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('mushaf_page_2')), findsOneWidget);
    });

    testWidgets('Fasila (lastRead) on Ayah 10 is preserved and not overwritten to Ayah 6', (
      tester,
    ) async {
      await BookmarkService.saveLastRead(surah: 2, ayah: 10, page: 3);

      await tester.pumpWidget(
        buildTestApp(const MushafPageViewer(initialPage: 3)),
      );
      await tester.pumpAndSettle();

      // Header chip correctly indicates the user's placed fasila on Ayah 10
      expect(find.text('فاصل القراءة • آية 10'), findsOneWidget);

      // Advance clock past 1 second highlight and fade
      await tester.pump(const Duration(milliseconds: 1050));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Ensure the saved fasila in storage was NEVER overwritten to Ayah 6
      final currentLastRead = await BookmarkService.getLastRead();
      expect(currentLastRead.surah, 2);
      expect(currentLastRead.ayah, 10);
      expect(currentLastRead.page, 3);
    });
  });
}
