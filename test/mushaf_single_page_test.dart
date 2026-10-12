import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_single_page.dart';
import 'package:talib_ilm/app/theme/app_ui.dart';

void main() {
  testWidgets('MushafSinglePage renders page 1, 2, and 3 without error', (tester) async {
    for (final page in [1, 2, 3]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 392,
              height: 800,
              child: MushafSinglePage(
                pageNumber: page,
                themeMode: MushafThemeMode.white,
                isTajweedEnabled: true,
                fontSize: 24.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MushafSinglePage), findsOneWidget);
    }
  });

  testWidgets('MushafSinglePage renders with Tajweed enabled and disabled', (tester) async {
    for (final isTajweed in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 392,
              height: 800,
              child: MushafSinglePage(
                pageNumber: 3,
                themeMode: MushafThemeMode.white,
                isTajweedEnabled: isTajweed,
                fontSize: 24.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MushafSinglePage), findsOneWidget);
    }
  });
}
