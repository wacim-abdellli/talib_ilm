import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/favorites/presentation/favorites_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FavoritesPage displays AppBackButton and pops route on tap',
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
}
