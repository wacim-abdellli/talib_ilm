import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_section_header.dart';
import 'package:talib_ilm/app/theme/app_ui.dart';

void main() {
  testWidgets('MushafSurahBanner renders all sample surahs cleanly', (tester) async {
    for (final surah in [1, 2, 3, 50, 114]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MushafSurahBanner(
                surahNumber: surah,
                themeMode: MushafThemeMode.white,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MushafSurahBanner), findsOneWidget);
    }
  });
}
