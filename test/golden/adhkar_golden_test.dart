import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/adhkar/data/adhkar_models.dart';
import 'package:talib_ilm/features/adhkar/presentation/widgets/adhkar_category_tile.dart';
import 'package:talib_ilm/features/adhkar/presentation/widgets/adhkar_contextual_hero.dart';
import 'package:talib_ilm/features/adhkar/presentation/widgets/adhkar_header.dart';
import 'package:talib_ilm/features/adhkar/presentation/widgets/rosary_dial.dart';
import 'golden_test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Adhkar Widgets Golden Tests', () {
    testWidgets('AdhkarHeader - light 1.0 and dark 1.5', (tester) async {
      final widget = AdhkarHeader(
        streak: 7,
        selectedCategory: 'all',
        onSelectCategory: (_) {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/adhkar_header_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/adhkar_header_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('AdhkarCategoryTile - light 1.0 and dark 1.5', (tester) async {
      final widget = CategoryTile(
        data: CategoryCardData(
          id: 'morning',
          title: 'أذكار الصباح',
          total: 24,
          icon: Icons.wb_sunny_rounded,
          showProgress: true,
          onTap: () {},
        ),
      );

      await testGoldenWidget(
        tester: tester,
        widget: SizedBox(
          width: 170,
          height: 180,
          child: widget,
        ),
        fileName: 'goldens/adhkar_category_tile_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: SizedBox(
          width: 170,
          height: 180,
          child: widget,
        ),
        fileName: 'goldens/adhkar_category_tile_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('RosaryDial - light 1.0 and dark 1.5', (tester) async {
      final widget = SizedBox(
        width: 358,
        height: 650,
        child: RosaryDial(
          label: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
          count: 15,
          target: 33,
          onTap: () {},
          onReset: () {},
          onChangeDhikr: () {},
          onSetTarget: () {},
        ),
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/adhkar_rosary_dial_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/adhkar_rosary_dial_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('AdhkarContextualHero - light 1.0 and dark 1.5', (tester) async {
      const catalog = AthkarCatalog(categories: [
        AthkarCategoryData(
          id: 'morning',
          title: 'أذكار الصباح',
          subtitle: 'ابدأ يومك بنور الذكر',
          items: [],
        ),
        AthkarCategoryData(
          id: 'evening',
          title: 'أذكار المساء',
          subtitle: 'حصن يومك ومساءك',
          items: [],
        ),
        AthkarCategoryData(
          id: 'sleeping',
          title: 'أذكار النوم',
          subtitle: 'اختم يومك بالسكينة',
          items: [],
        ),
      ]);

      final widget = SizedBox(
        width: 358,
        child: AdhkarContextualHero(
          catalog: catalog,
          onOpenCategory: (c, cat) {},
        ),
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/adhkar_hero_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/adhkar_hero_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });
  });
}
