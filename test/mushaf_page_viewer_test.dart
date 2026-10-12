import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_page_viewer.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_continuous_list_view.dart';

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

  group('MushafPageViewer Dual-Mode Fast Switching Tests', () {
    testWidgets('Renders with IndexedStack keeping both modes active', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MushafPageViewer(
            initialPage: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // IndexedStack holds both Page mode and Continuous list mode
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);

      final indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, 0); // starts in Mushaf page mode
      expect(indexedStack.children.length, 2);

      // Top bar mode switch buttons
      expect(find.text('مصحف'), findsOneWidget);
      expect(find.text('قائمة'), findsOneWidget);
    });

    testWidgets('Instant smooth switch between Page mode and List mode', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MushafPageViewer(
            initialPage: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'قائمة' (Continuous list mode)
      await tester.tap(find.text('قائمة'));
      await tester.pumpAndSettle();

      // IndexedStack switched index to 1 instantly
      final indexedStack1 = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack1.index, 1);
      expect(find.byType(QuranContinuousListView), findsOneWidget);

      // Tap 'مصحف' (Page mode)
      await tester.tap(find.text('مصحف'));
      await tester.pumpAndSettle();

      // IndexedStack switched index back to 0 instantly without destroying state
      final indexedStack0 = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack0.index, 0);
    });
  });
}
