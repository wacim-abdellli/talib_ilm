import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
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
  });
}
