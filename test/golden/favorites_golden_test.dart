import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/models/favorite_item.dart';
import 'package:talib_ilm/features/favorites/presentation/favorites_page.dart';
import 'golden_test_helper.dart';

void main() {
  group('Favorites Golden Tests', () {
    testWidgets('FavoritesPage populated - light 1.0 and dark 1.5', (tester) async {
      final items = [
        const FavoriteItem(
          type: FavoriteType.hadith,
          id: '1',
          title: 'إنما الأعمال بالنيات',
          subtitle: 'صحيح البخاري',
        ),
        const FavoriteItem(
          type: FavoriteType.dhikr,
          id: '2',
          title: 'أذكار الصباح',
          subtitle: 'آية الكرسي والمعوذات',
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'favorites_items': items.map((i) => jsonEncode(i.toJson())).toList(),
      });

      await testGoldenWidget(
        tester: tester,
        widget: const SizedBox(
          width: 390,
          height: 844,
          child: FavoritesPage(),
        ),
        fileName: 'goldens/favorites_page_populated_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: const SizedBox(
          width: 390,
          height: 844,
          child: FavoritesPage(),
        ),
        fileName: 'goldens/favorites_page_populated_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('FavoritesPage empty - light 1.0 and dark 1.5', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorites_items': <String>[],
      });

      await testGoldenWidget(
        tester: tester,
        widget: const SizedBox(
          width: 390,
          height: 844,
          child: FavoritesPage(),
        ),
        fileName: 'goldens/favorites_page_empty_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: const SizedBox(
          width: 390,
          height: 844,
          child: FavoritesPage(),
        ),
        fileName: 'goldens/favorites_page_empty_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });
  });
}
