import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_palette.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_search_bar.dart';

void main() {
  Widget buildTestableWidget({
    required TextEditingController controller,
    required ValueChanged<String> onSearchChanged,
    VoidCallback? onClear,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: IlmSearchBar(
            controller: controller,
            onSearchChanged: onSearchChanged,
            onClear: onClear,
          ),
        ),
      ),
    );
  }

  testWidgets('IlmSearchBar renders with search icon and placeholder', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      buildTestableWidget(
        controller: controller,
        onSearchChanged: (_) {},
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.text('ابحث في المتون والكتب والشروح...'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('IlmSearchBar shows clear button when text typed and debounces search', (tester) async {
    final controller = TextEditingController();
    String query = '';
    bool clearCalled = false;

    await tester.pumpWidget(
      buildTestableWidget(
        controller: controller,
        onSearchChanged: (val) => query = val,
        onClear: () => clearCalled = true,
      ),
    );

    await tester.enterText(find.byType(TextField), 'أصول');
    await tester.pump(); // update UI

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    // Before debounce duration, search query has not fired yet
    expect(query, '');

    // Advance by debounce duration (AppMotion.base = 200ms)
    await tester.pump(AppMotion.base);
    expect(query, 'أصول');

    // Tap clear button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(controller.text, '');
    expect(query, '');
    expect(clearCalled, isTrue);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}
