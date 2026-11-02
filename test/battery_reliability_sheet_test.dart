import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/battery_reliability_sheet.dart';

Widget wrapWithTheme(Widget child, {bool isDark = false, double textScale = 1.0}) {
  final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
  return MaterialApp(
    theme: theme,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(child: child),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BatteryReliabilitySheet Tests', () {
    testWidgets('renders cleanly in Light theme and displays OEM guidance', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const BatteryReliabilitySheet(), isDark: false));
      await tester.pumpAndSettle();

      expect(find.text('ضمان دقة الأذان والتنبيهات'), findsOneWidget);
      expect(find.textContaining('شاومي / ريدمي / بوكو (Xiaomi / POCO)'), findsOneWidget);
      expect(find.textContaining('سامسونج (Samsung)'), findsOneWidget);
      expect(find.textContaining('هواوي / هونر (Huawei / Honor)'), findsOneWidget);
      expect(find.text('فتح إعدادات النظام للتطبيق'), findsOneWidget);
    });

    testWidgets('renders cleanly in Dark theme', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const BatteryReliabilitySheet(), isDark: true));
      await tester.pumpAndSettle();

      expect(find.text('ضمان دقة الأذان والتنبيهات'), findsOneWidget);
      expect(find.byType(BatteryReliabilitySheet), findsOneWidget);
    });

    testWidgets('survives text scale 1.5 and 2.0 without overflow', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          wrapWithTheme(const BatteryReliabilitySheet(), isDark: false, textScale: scale),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Failed at text scale $scale');
      }
    });
  });
}
