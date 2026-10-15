import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_section_switcher.dart';

void main() {
  Widget buildTestableWidget(
    Widget child, {
    bool isDark = false,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('IlmSectionSwitcher Widget Tests', () {
    testWidgets('Displays mutun and maktaba titles correctly', (tester) async {
      IlmSection selected = IlmSection.mutun;

      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return IlmSectionSwitcher(
                selectedSection: selected,
                onSectionChanged: (sec) => setState(() => selected = sec),
              );
            },
          ),
        ),
      );

      expect(find.text('متون طالب العلم'), findsOneWidget);
      expect(find.text('المكتبة'), findsOneWidget);
      expect(find.text('خزانة التراث'), findsNothing);
    });

    testWidgets('Tapping Maktaba switches section with haptic', (tester) async {
      IlmSection selected = IlmSection.mutun;

      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return IlmSectionSwitcher(
                selectedSection: selected,
                onSectionChanged: (sec) => setState(() => selected = sec),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('المكتبة'));
      await tester.pumpAndSettle();

      expect(selected, equals(IlmSection.shamela));

      await tester.tap(find.text('متون طالب العلم'));
      await tester.pumpAndSettle();

      expect(selected, equals(IlmSection.mutun));
    });

    testWidgets('Survives text scaling 1.0, 1.5, and 2.0 without overflow', (
      tester,
    ) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          buildTestableWidget(
            IlmSectionSwitcher(
              selectedSection: IlmSection.mutun,
              onSectionChanged: (_) {},
            ),
            textScale: scale,
          ),
        );

        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Failed at textScale $scale',
        );
        expect(find.text('متون طالب العلم'), findsOneWidget);
        expect(find.text('المكتبة'), findsOneWidget);
      }
    });

    testWidgets('Renders properly in both light and dark modes', (
      tester,
    ) async {
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          buildTestableWidget(
            IlmSectionSwitcher(
              selectedSection: IlmSection.shamela,
              onSectionChanged: (_) {},
            ),
            isDark: dark,
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('المكتبة'), findsOneWidget);
      }
    });
  });
}
