import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/models/favorite_item.dart';
import 'package:talib_ilm/features/adhkar/presentation/duas_misc_page.dart';
import 'package:talib_ilm/features/adhkar/presentation/morning_athkar_page.dart';
import 'package:talib_ilm/features/favorites/presentation/favorites_page.dart';
import 'package:talib_ilm/features/hadith/presentation/pages/hadith_explorer_page.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_page_viewer.dart';
import 'package:talib_ilm/shared/widgets/app_dialog.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FavoritesPage displays back button and pops route on tap',
      (tester) async {
    SharedPreferences.setMockInitialValues({'favorites_items': <String>[]});

    var popped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(builder: (_) => const FavoritesPage()),
                    )
                    .then((_) => popped = true);
              },
              child: const Text('Open Favorites'),
            ),
          ),
        ),
      ),
    );

    // Tap to open favorites page
    await tester.tap(find.text('Open Favorites'));
    await tester.pumpAndSettle();

    // Verify FavoritesPage is presented and back button exists
    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    // Verify route was popped
    expect(popped, isTrue);
    expect(find.byType(FavoritesPage), findsNothing);
  });

  testWidgets('Tapping Hadith favorite item opens HadithExplorerPage', (tester) async {
    final item = const FavoriteItem(
      type: FavoriteType.hadith,
      id: 'h1',
      title: 'إنما الأعمال بالنيات',
      subtitle: 'صحيح البخاري',
    );
    SharedPreferences.setMockInitialValues({
      'favorites_items': [jsonEncode(item.toJson())],
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FavoritesPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إنما الأعمال بالنيات'), findsOneWidget);

    // Tap the item card
    await tester.tap(find.text('إنما الأعمال بالنيات'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(HadithExplorerPage), findsOneWidget);
  });

  testWidgets('Tapping Dua favorite item opens DuasMiscPage', (tester) async {
    final item = const FavoriteItem(
      type: FavoriteType.dua,
      id: 'd1',
      title: 'اللهم إني أسألك الهدى والتقى',
      subtitle: 'صحيح مسلم',
    );
    SharedPreferences.setMockInitialValues({
      'favorites_items': [jsonEncode(item.toJson())],
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FavoritesPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اللهم إني أسألك الهدى والتقى'), findsOneWidget);

    // Tap the item card
    await tester.tap(find.text('اللهم إني أسألك الهدى والتقى'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DuasMiscPage), findsOneWidget);
  });

  testWidgets('Tapping Dhikr morning favorite item opens MorningAthkarPage', (tester) async {
    final item = const FavoriteItem(
      type: FavoriteType.dhikr,
      id: 'morning',
      title: 'أذكار الصباح كاملة',
      subtitle: 'حصن المسلم',
    );
    SharedPreferences.setMockInitialValues({
      'favorites_items': [jsonEncode(item.toJson())],
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FavoritesPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أذكار الصباح كاملة'), findsOneWidget);

    // Tap the item card
    await tester.tap(find.text('أذكار الصباح كاملة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MorningAthkarPage), findsOneWidget);
  });

  testWidgets('Tapping Quran favorite item opens MushafPageViewer', (tester) async {
    final item = const FavoriteItem(
      type: FavoriteType.quran,
      id: '293',
      title: 'سورة الكهف',
      subtitle: 'الصفحة 293',
    );
    SharedPreferences.setMockInitialValues({
      'favorites_items': [jsonEncode(item.toJson())],
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FavoritesPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('سورة الكهف'), findsOneWidget);

    // Tap the item card
    await tester.tap(find.text('سورة الكهف'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MushafPageViewer), findsOneWidget);
  });


  testWidgets('Tapping Quote favorite item shows detail dialog with copy and share actions',
      (tester) async {
    final item = const FavoriteItem(
      type: FavoriteType.quote,
      id: 'q1',
      title: 'القلب يعرض له مرضان عظيمان إن لم يتداركهما صاحبه تراميا به إلى التلف',
      subtitle: 'ابن القيم',
    );
    SharedPreferences.setMockInitialValues({
      'favorites_items': [jsonEncode(item.toJson())],
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FavoritesPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(item.title), findsOneWidget);

    // Tap the item card
    await tester.tap(find.text(item.title));
    await tester.pumpAndSettle();

    // Verify detail dialog is displayed
    expect(find.byType(AppDialog), findsOneWidget);
    expect(find.text('نسخ'), findsOneWidget);
    expect(find.text('مشاركة'), findsOneWidget);
    expect(find.text('إغلاق'), findsOneWidget);
  });
}
