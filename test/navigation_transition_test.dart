import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_palette.dart';
import 'package:talib_ilm/shared/navigation/app_shell.dart';

void main() {
  testWidgets('AnimatedIndexedStack crossfade transitions between children',
      (WidgetTester tester) async {
    int index = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: AnimatedIndexedStack(
                index: index,
                children: const [
                  Text('Page 0 Home', key: ValueKey('page_0')),
                  Text('Page 1 Salat', key: ValueKey('page_1')),
                  Text('Page 2 Ilm', key: ValueKey('page_2')),
                ],
              ),
              bottomNavigationBar: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => index = 0),
                    child: const Text('Tab 0'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => index = 1),
                    child: const Text('Tab 1'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => index = 2),
                    child: const Text('Tab 2'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Initial state: Page 0 is visible
    expect(find.text('Page 0 Home'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Page 0 Home')), Offset.zero);

    // Switch to Tab 1
    await tester.tap(find.text('Tab 1'));
    // Pump 1 frame to trigger transition start
    await tester.pump();

    // Both previous (Page 0) and current (Page 1) should be present during crossfade
    expect(find.text('Page 0 Home'), findsOneWidget);
    expect(find.text('Page 1 Salat'), findsOneWidget);

    // Advance halfway through transition
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Page 0 Home'), findsOneWidget);
    expect(find.text('Page 1 Salat'), findsOneWidget);

    // Advance to complete transition
    await tester.pump(AppMotion.base);
    await tester.pumpAndSettle();

    // Now transition is complete: Page 1 is on stage
    expect(find.text('Page 1 Salat'), findsOneWidget);

    // Switch to Tab 2
    await tester.tap(find.text('Tab 2'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Page 2 Ilm'), findsOneWidget);
  });
}
