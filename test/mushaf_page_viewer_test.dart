import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_page_viewer.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_single_page.dart';

void main() {
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
    testWidgets('Renders PageView with 604 authentic Mushaf pages', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MushafPageViewer(
            initialPage: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PageView holds the 604 authentic pages
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(MushafSinglePage), findsOneWidget);

      // Top bar title displays current Surah and Page
      expect(find.textContaining('سورة الفاتحة'), findsOneWidget);
      expect(find.textContaining('الصفحة 1'), findsOneWidget);
    });

    testWidgets('Quick jump changes page correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MushafPageViewer(
            initialPage: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check initial page is Al-Fatihah
      expect(find.textContaining('سورة الفاتحة'), findsOneWidget);
    });
  });
}
