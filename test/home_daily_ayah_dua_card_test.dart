import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/home/presentation/widgets/home_daily_ayah_dua_card.dart';

void main() {
  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ),
    );
  }

  testWidgets('renders daily ayah and dua card properly', (tester) async {
    await tester.pumpWidget(wrapWithTheme(const HomeDailyAyahDuaCard()));
    await tester.pumpAndSettle();

    expect(find.text('آية ودعاء اليوم'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

    // Tap refresh / cycle next
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();
    expect(find.text('آية ودعاء اليوم'), findsOneWidget);
  });
}
