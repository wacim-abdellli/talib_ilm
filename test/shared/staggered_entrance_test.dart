import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_palette.dart';
import 'package:talib_ilm/shared/animations/staggered_entrance.dart';

void main() {
  Widget buildTestHost({
    required Widget child,
    bool disableAnimations = false,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    );
  }

  group('StaggeredEntrance Tests', () {
    testWidgets('renders child content immediately when index is 0', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          child: const StaggeredEntrance(
            index: 0,
            child: Text('العلم نور'),
          ),
        ),
      );

      // Child is in tree
      expect(find.text('العلم نور'), findsOneWidget);

      // Fast forward
      await tester.pump(AppMotion.staggerDuration);
      expect(find.text('العلم نور'), findsOneWidget);
    });

    testWidgets('staggers subsequent indices with calculated delay', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          child: const Column(
            children: [
              StaggeredEntrance(index: 0, child: Text('الصف الأول')),
              StaggeredEntrance(index: 1, child: Text('الصف الثاني')),
              StaggeredEntrance(index: 2, child: Text('الصف الثالث')),
            ],
          ),
        ),
      );

      // Initially, all texts exist in tree
      expect(find.text('الصف الأول'), findsOneWidget);
      expect(find.text('الصف الثاني'), findsOneWidget);
      expect(find.text('الصف الثالث'), findsOneWidget);

      // Advance by 100ms
      await tester.pump(const Duration(milliseconds: 100));

      // Advance to full completion
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('الصف الثالث'), findsOneWidget);
    });

    testWidgets('bypasses animations when disableAnimations is enabled', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          disableAnimations: true,
          child: const StaggeredEntrance(
            index: 5,
            child: Text('بدون حركات'),
          ),
        ),
      );

      expect(find.text('بدون حركات'), findsOneWidget);
    });

    testWidgets('survives large text scales (1.5x and 2.0x) without overflow', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          buildTestHost(
            textScale: scale,
            child: Column(
              children: List.generate(
                4,
                (i) => StaggeredEntrance(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('سطر علمي رقم $i'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}

