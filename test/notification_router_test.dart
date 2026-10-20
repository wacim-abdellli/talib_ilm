import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/app.dart';
import 'package:talib_ilm/core/services/foreground_prayer_service.dart';
import 'package:talib_ilm/core/services/notification_router.dart';
import 'package:talib_ilm/features/adhkar/presentation/after_prayer_athkar_page.dart';
import 'package:talib_ilm/features/adhkar/presentation/evening_athkar_page.dart';
import 'package:talib_ilm/features/adhkar/presentation/morning_athkar_page.dart';
import 'package:talib_ilm/features/adhkar/presentation/sleeping_athkar_page.dart';
import 'package:talib_ilm/features/adhkar/presentation/tasbeeh_istighfar_page.dart';
import 'package:talib_ilm/features/prayer/presentation/prayer_page.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/mushaf_page_viewer.dart';
import 'package:talib_ilm/shared/navigation/app_shell.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationRouter.pendingPayload = null;
  });

  tearDown(() {
    ForegroundPrayerService().stop();
  });

  group('NotificationRouter Cold Start & Pending Payload Tests', () {
    test('Stores pending payload when AppShell is not ready', () {
      expect(AppShell.isAppShellReady, isFalse);

      NotificationRouter.handlePayload('morning');

      expect(NotificationRouter.pendingPayload, equals('morning'));
    });

    test('Stores pending payload for evening and prayer payloads as well', () {
      NotificationRouter.handlePayload('adhkar_evening');
      expect(NotificationRouter.pendingPayload, equals('adhkar_evening'));

      NotificationRouter.handlePayload('prayer_fajr');
      expect(NotificationRouter.pendingPayload, equals('prayer_fajr'));
    });
  });

  group('NotificationRouter In-App Navigation Tests', () {
    testWidgets('Tapping morning notification opens MorningAthkarPage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(AppShell.isAppShellReady, isTrue);

      NotificationRouter.handlePayload('morning');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MorningAthkarPage), findsOneWidget);
    });

    testWidgets('Tapping evening notification opens EveningAthkarPage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      NotificationRouter.handlePayload('evening');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(EveningAthkarPage), findsOneWidget);
    });

    testWidgets('Tapping sleeping notification opens SleepingAthkarPage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      NotificationRouter.handlePayload('sleeping');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SleepingAthkarPage), findsOneWidget);
    });

    testWidgets('Arabic string "أذكار الصباح" routes to MorningAthkarPage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      NotificationRouter.handlePayload('أذكار الصباح');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MorningAthkarPage), findsOneWidget);
    });

    testWidgets('Arabic string "أذكار المساء" routes to EveningAthkarPage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      NotificationRouter.handlePayload('أذكار المساء');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(EveningAthkarPage), findsOneWidget);
    });

    testWidgets('Tapping after_prayer notification opens AfterPrayerAthkarPage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      NotificationRouter.handlePayload('after_prayer');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AfterPrayerAthkarPage), findsOneWidget);
    });

    testWidgets('Tapping tasbeeh notification opens TasbeehIstighfarPage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      NotificationRouter.handlePayload('tasbeeh');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(TasbeehIstighfarPage), findsOneWidget);
    });

    testWidgets('Tapping surah_18 notification opens MushafPageViewer for Kahf',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      NotificationRouter.handlePayload('surah_18');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MushafPageViewer), findsOneWidget);
    });

    testWidgets('Tapping prayer notification switches to prayer tab',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Start on tab 0 (Home)
      NotificationRouter.handlePayload('prayer_الظهر');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // AppShell should now have switched to tab 1 (Prayer)
      expect(find.byType(PrayerPage), findsOneWidget);
    });

    testWidgets('Cold start consumes pending payload upon AppShell mount',
        (tester) async {
      // Set pending payload as if cold-started from notification
      NotificationRouter.pendingPayload = 'morning';

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Should automatically have consumed the pending payload and pushed MorningAthkarPage
      expect(find.byType(MorningAthkarPage), findsOneWidget);
      expect(NotificationRouter.pendingPayload, isNull);
    });
  });
}
