import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_page_transitions.dart';
import 'package:talib_ilm/app/theme/app_palette.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/shared/navigation/app_shell.dart';
import 'package:talib_ilm/shared/navigation/fade_page_route.dart';
import 'package:talib_ilm/shared/widgets/app_dialog.dart';
import 'package:talib_ilm/shared/widgets/app_sheet.dart';

void main() {
  group('AppPageTransitions & Animation System Tests (R61)', () {
    test('ThemeData registers AppRtlPageTransitionsBuilder on Android & Windows', () {
      final theme = AppTheme.lightTheme;
      final builders = theme.pageTransitionsTheme.builders;

      expect(builders[TargetPlatform.android], isA<AppRtlPageTransitionsBuilder>());
      expect(builders[TargetPlatform.windows], isA<AppRtlPageTransitionsBuilder>());
      expect(builders[TargetPlatform.linux], isA<AppRtlPageTransitionsBuilder>());
      expect(builders[TargetPlatform.iOS], isA<CupertinoPageTransitionsBuilder>());
      expect(builders[TargetPlatform.macOS], isA<CupertinoPageTransitionsBuilder>());
    });

    testWidgets('AppRtlPageTransitionsBuilder builds Fade, Slide, and Scale transitions',
        (tester) async {
      const builder = AppRtlPageTransitionsBuilder();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final route = MaterialPageRoute<void>(
                builder: (_) => const Text('Target Page'),
              );
              final controller = AnimationController(
                vsync: const TestVSync(),
                duration: AppMotion.base,
              );
              final secondaryController = AnimationController(
                vsync: const TestVSync(),
                duration: AppMotion.base,
              );

              return builder.buildTransitions<void>(
                route,
                context,
                controller,
                secondaryController,
                const Text('Animated Content'),
              );
            },
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(ScaleTransition), findsWidgets);
      expect(find.text('Animated Content'), findsOneWidget);
    });

    testWidgets('AppFadePageRoute builds transitions with scale and slide on Android',
        (tester) async {
      final route = AppFadePageRoute<void>(
        builder: (_) => const Text('Fade Route Target'),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Builder(
            builder: (context) {
              final controller = AnimationController(
                vsync: const TestVSync(),
                duration: AppMotion.base,
              );
              final secondaryController = AnimationController(
                vsync: const TestVSync(),
                duration: AppMotion.base,
              );

              return route.buildTransitions(
                context,
                controller,
                secondaryController,
                const Text('Fade Route Child'),
              );
            },
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(ScaleTransition), findsWidgets);
      expect(find.text('Fade Route Child'), findsOneWidget);
    });

    testWidgets('AnimatedIndexedStack smoothly transitions on index change',
        (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: AnimatedIndexedStack(
                  index: activeIndex,
                  duration: AppMotion.base,
                  children: const [
                    Text('Tab 0 View'),
                    Text('Tab 1 View'),
                    Text('Tab 2 View'),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => activeIndex = 1),
                  child: const Icon(Icons.forward),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Tab 0 View'), findsOneWidget);

      // Trigger tab switch
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(); // start animation
      expect(
        find.descendant(
          of: find.byType(AnimatedIndexedStack),
          matching: find.byType(SlideTransition),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AnimatedIndexedStack),
          matching: find.byType(ScaleTransition),
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 100)); // mid animation
      await tester.pump(const Duration(milliseconds: 150)); // settle animation

      expect(find.text('Tab 1 View'), findsOneWidget);
    });

    testWidgets('AppDialog.show presents dialog with scale and fade transition',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppDialog.show<void>(
                      context: context,
                      builder: (ctx) => const AppDialog(
                        title: 'تأكيد الحذف',
                        content: Text('هل أنت متأكد من الحذف؟'),
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pump(); // frame 0 of transition
      expect(find.byType(ScaleTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);

      await tester.pumpAndSettle();
      expect(find.text('تأكيد الحذف'), findsOneWidget);
    });
  });
}
