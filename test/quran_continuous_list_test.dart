import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_settings_sheet.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_continuous_list_view.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_section_header.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(Widget child, {double textScale = 1.0, bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.dark() : AppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('QuranContinuousListView Widget Tests', () {
    testWidgets('Renders Al-Fatihah headers and verses', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const QuranContinuousListView(
            initialSurah: 1,
            initialAyah: 1,
            themeMode: MushafThemeMode.white,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Surah header banner for Al-Fatihah
      expect(find.byType(MushafSurahBanner), findsWidgets);
      expect(find.text('سُورَةُ ${quran.getSurahNameArabic(1)}'), findsOneWidget);

      // Ayah items
      expect(find.byKey(const ValueKey('ayah_1_1')), findsOneWidget);
    });

    testWidgets('Scrolls smoothly across surah boundary and renders at textScale 2.0', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const QuranContinuousListView(
            initialSurah: 1,
            initialAyah: 1,
            themeMode: MushafThemeMode.dark,
          ),
          textScale: 2.0,
          isDark: true,
        ),
      );
      await tester.pumpAndSettle();

      // Drag list down to scroll into Al-Baqarah
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // No crash, RenderFlex errors, or exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Positions at requested initial verse (e.g. 2:255 Ayat al-Kursi)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const QuranContinuousListView(
            initialSurah: 2,
            initialAyah: 255,
            themeMode: MushafThemeMode.sepia,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ayah_2_255')), findsOneWidget);
    });
  });
}
