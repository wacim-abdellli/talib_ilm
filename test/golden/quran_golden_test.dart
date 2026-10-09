import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/surah_card.dart';
import 'golden_test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Quran Widgets Golden Tests', () {
    testWidgets('SurahCard - unbookmarked light 1.0 and dark 1.5', (tester) async {
      final widget = SurahCard(
        surahNumber: 1,
        isBookmarked: false,
        onTap: () {},
        onBookmarkTap: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: SizedBox(
          width: 360,
          child: widget,
        ),
        fileName: 'goldens/quran_surah_card_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: SizedBox(
          width: 360,
          child: widget,
        ),
        fileName: 'goldens/quran_surah_card_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('SurahCard - bookmarked light 1.0 and dark 1.5', (tester) async {
      final widget = SurahCard(
        surahNumber: 2,
        isBookmarked: true,
        onTap: () {},
        onBookmarkTap: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: SizedBox(
          width: 360,
          child: widget,
        ),
        fileName: 'goldens/quran_surah_card_fav_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: SizedBox(
          width: 360,
          child: widget,
        ),
        fileName: 'goldens/quran_surah_card_fav_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('SurahNumberMedallion - light 1.0 and dark 1.5', (tester) async {
      const widget = Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SurahNumberMedallion(number: 1),
            SizedBox(width: 16),
            SurahNumberMedallion(number: 18),
            SizedBox(width: 16),
            SurahNumberMedallion(number: 114),
          ],
        ),
      );

      await testGoldenWidget(
        tester: tester,
        widget: const SizedBox(
          width: 240,
          height: 80,
          child: widget,
        ),
        fileName: 'goldens/quran_medallion_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: const SizedBox(
          width: 240,
          height: 80,
          child: widget,
        ),
        fileName: 'goldens/quran_medallion_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });
  });
}
