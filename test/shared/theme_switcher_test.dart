import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/shared/animations/theme_switcher.dart';

void main() {
  testWidgets('ThemeProvider and ThemeSwitcher perform forward and reverse circular reveal smoothly without leaks', (tester) async {
    final light = AppTheme.lightTheme;
    final dark = AppTheme.darkTheme;
    bool isDark = false;

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
                          isDark = !isDark;
                          ThemeSwitcher.of(context).changeTheme(
                            theme: isDark ? dark : light,
                            isReversed: !isDark, // reverse when returning to light
                          );
                        },
                        child: Text(isDark ? 'Switch to Light' : 'Switch to Dark'),
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

    expect(find.text('Switch to Dark'), findsOneWidget);

    // 1. Forward circular reveal (Light -> Dark)
    await tester.tap(find.text('Switch to Dark'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Switch to Light'), findsOneWidget);

    // 2. Reverse circular reveal (Dark -> Light)
    await tester.tap(find.text('Switch to Light'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Switch to Dark'), findsOneWidget);
  });
}
