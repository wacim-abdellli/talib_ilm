import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/core/services/home_widget_snapshot.dart';
import 'package:talib_ilm/core/utils/app_share.dart';
import 'package:talib_ilm/features/prayer/presentation/qibla_page.dart';
import 'package:talib_ilm/shared/navigation/fade_page_route.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue 5: iOS Edge-Swipe Pop Gesture (FadePageRoute)', () {
    test('buildFadeRoute returns AppFadePageRoute with CupertinoRouteTransitionMixin', () {
      final route = buildFadeRoute<void>(
        page: const Scaffold(body: Text('Test Page')),
      );

      expect(route, isA<AppFadePageRoute<void>>());
      expect(route, isA<CupertinoRouteTransitionMixin<void>>());
    });

    testWidgets('AppFadePageRoute allows swipe-back gesture when route can pop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      buildFadeRoute(
                        page: const Scaffold(
                          body: Text('Second Page Screen'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Page'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Page'));
      await tester.pumpAndSettle();

      expect(find.text('Second Page Screen'), findsOneWidget);

      final ModalRoute<dynamic>? modalRoute = ModalRoute.of(
        tester.element(find.text('Second Page Screen')),
      );
      expect(modalRoute, isNotNull);
      if (modalRoute is CupertinoRouteTransitionMixin) {
        expect(modalRoute.popGestureEnabled, isTrue);
      }
    });
  });

  group('Issue 3: iOS AppShare with Anchored Origin Rect', () {
    testWidgets('AppShare.resolveOrigin resolves exact bounding box from mounted renderBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                height: 48,
                child: Text('Anchor Target'),
              ),
            ),
          ),
        ),
      );

      final context = tester.element(find.text('Anchor Target'));
      final origin = AppShare.resolveOrigin(context);

      expect(origin.width, greaterThan(0));
      expect(origin.height, greaterThan(0));
      expect(origin.left, greaterThanOrEqualTo(0));
      expect(origin.top, greaterThanOrEqualTo(0));
    });

    test('AppShare.resolveOrigin without context falls back cleanly to safe origin rect', () {
      final origin = AppShare.resolveOrigin(null);

      expect(origin.width, equals(320));
      expect(origin.height, equals(200));
      expect(origin.top, equals(200));
    });
  });

  group('Issue 2: Qibla Page Direct Capital Resolution', () {
    testWidgets('QiblaPage directly loads without blocking permission view', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QiblaPage(),
        ),
      );
      await tester.pump();

      expect(find.text('منح إذن الموقع'), findsNothing);
      expect(find.text('استخدام المدينة المحددة في التطبيق'), findsNothing);
    });
  });

  group('Issue 1: HomeWidgetSnapshot iOS keys', () {
    test('Theme and keys are defined', () {
      expect(HomeWidgetSnapshot.themeModeKey, equals('prayer_widget_theme_mode'));
    });
  });
}
