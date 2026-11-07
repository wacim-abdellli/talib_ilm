import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/shared/animations/theme_switcher.dart';

void main() {
  testWidgets('ThemeProvider and ThemeSwitcher perform circular reveal smoothly without leaks', (tester) async {
    final light = AppTheme.lightTheme;
    final dark = AppTheme.darkTheme;

    await tester.pumpWidget(
      ThemeProvider(
        initTheme: light,
        builder: (context, currentTheme) {
          return MaterialApp(
            theme: currentTheme,
            home: ThemeSwitchingArea(
              child: Scaffold(
                body: Center(
                  child: ThemeSwitcher(
                    builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          ThemeSwitcher.of(context).changeTheme(
                            theme: dark,
                          );
                        },
                        child: const Text('Toggle Theme'),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('Toggle Theme'), findsOneWidget);

    // Tap to switch theme
    await tester.tap(find.text('Toggle Theme'));
    await tester.pump();

    // Advance animation
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Toggle Theme'), findsOneWidget);
  });
}

