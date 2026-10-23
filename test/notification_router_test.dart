import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/app.dart';
import 'package:talib_ilm/core/services/foreground_prayer_service.dart';
import 'package:talib_ilm/core/services/notification_router.dart';
import 'package:talib_ilm/features/adhkar/presentation/adhkar_session_page.dart';
import 'package:talib_ilm/features/adhkar/presentation/after_prayer_athkar_page.dart';
import 'package:talib_ilm/features/adhkar/presentation/duas_misc_page.dart';
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
    NotificationRouter.resetStateForTesting();
  });

  tearDown(() {
    ForegroundPrayerService().stop();
    NotificationRouter.resetStateForTesting();
  });

  group('T06: Authoritative Destination Parsing (C13)', () {
    test('Parses all supported Adhkar payload formats accurately', () {
      expect(
        NotificationRouter.parseDestination('morning'),
        equals(NotificationDestination.morningAthkar),
      );
      expect(
        NotificationRouter.parseDestination('adhkar_morning'),
        equals(NotificationDestination.morningAthkar),
      );
      expect(
        NotificationRouter.parseDestination('أذكار الصباح'),
        equals(NotificationDestination.morningAthkar),
      );

      expect(
        NotificationRouter.parseDestination('evening'),
        equals(NotificationDestination.eveningAthkar),
      );
      expect(
        NotificationRouter.parseDestination('adhkar_evening'),
        equals(NotificationDestination.eveningAthkar),
      );
      expect(
        NotificationRouter.parseDestination('أذكار المساء'),
        equals(NotificationDestination.eveningAthkar),
      );

      expect(
        NotificationRouter.parseDestination('sleep'),
        equals(NotificationDestination.sleepingAthkar),
      );
      expect(
        NotificationRouter.parseDestination('adhkar_sleeping'),
        equals(NotificationDestination.sleepingAthkar),
      );
      expect(
        NotificationRouter.parseDestination('أذكار النوم'),
        equals(NotificationDestination.sleepingAthkar),
      );

      expect(
        NotificationRouter.parseDestination('after_prayer'),
        equals(NotificationDestination.afterPrayerAthkar),
      );
      expect(
        NotificationRouter.parseDestination('أذكار بعد الصلاة'),
        equals(NotificationDestination.afterPrayerAthkar),
      );

      expect(
        NotificationRouter.parseDestination('tasbeeh'),
        equals(NotificationDestination.tasbeeh),
      );
      expect(
        NotificationRouter.parseDestination('istighfar'),
        equals(NotificationDestination.istighfar),
      );
      expect(
        NotificationRouter.parseDestination('duas'),
        equals(NotificationDestination.duasMisc),
      );
      expect(
        NotificationRouter.parseDestination('adhkar_waking'),
        equals(NotificationDestination.dynamicAthkar),
      );
    });

    test('Parses prayer and quran payloads accurately', () {
      expect(
        NotificationRouter.parseDestination('prayer_fajr'),
        equals(NotificationDestination.prayer),
      );
      expect(
        NotificationRouter.parseDestination('adhan_dhuhr'),
        equals(NotificationDestination.prayer),
      );
      expect(
        NotificationRouter.parseDestination('surah_18'),
        equals(NotificationDestination.surahKahf),
      );
      expect(
        NotificationRouter.parseDestination('talibilm://quran/page/100'),
        equals(NotificationDestination.quranDeepLink),
      );
    });

    test('Safely returns unknown for null, empty, or unmapped payloads without throwing', () {
      expect(NotificationRouter.parseDestination(null), equals(NotificationDestination.unknown));
      expect(NotificationRouter.parseDestination(''), equals(NotificationDestination.unknown));
      expect(NotificationRouter.parseDestination('   '), equals(NotificationDestination.unknown));
      expect(NotificationRouter.parseDestination('unrecognized_random_string'), equals(NotificationDestination.unknown));
    });
  });

  group('T06: Cold Start & Pending Payload Delivery', () {
    test('Stores pending payload when AppShell is not ready', () {
      expect(AppShell.isAppShellReady, isFalse);

      NotificationRouter.handlePayload('morning');

      expect(NotificationRouter.pendingPayload, equals('morning'));
    });

    testWidgets('Cold start consumes pending payload upon AppShell mount and clears it', (tester) async {
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

      expect(find.byType(MorningAthkarPage), findsOneWidget);
      expect(NotificationRouter.pendingPayload, isNull);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });
  });

  group('T06: Navigation Invariants & Selected Tab After Pop (C13 Acceptance)', () {
    testWidgets('MorningAthkar routes to page AND selects Adhkar tab 3, not Ilm tab 2', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(AppShell.currentTabIndex, equals(AppShellTab.home.index));

      NotificationRouter.handlePayload('morning');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Page is displayed
      expect(find.byType(MorningAthkarPage), findsOneWidget);
      // Shell tab is Adhkar (3), NOT Ilm (2)
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
      expect(AppShell.currentTabIndex, isNot(equals(AppShellTab.ilm.index)));

      // Pop the pushed route
      rootNavigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Page is gone, and user lands on the Adhkar tab
      expect(find.byType(MorningAthkarPage), findsNothing);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });

    testWidgets('EveningAthkar routes to page AND selects Adhkar tab 3, not Ilm tab 2', (tester) async {
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
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));

      rootNavigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(EveningAthkarPage), findsNothing);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });

    testWidgets('SleepingAthkar routes to page AND selects Adhkar tab 3', (tester) async {
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
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));

      rootNavigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });

    testWidgets('AfterPrayerAthkar routes to page AND selects Adhkar tab 3', (tester) async {
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
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));

      rootNavigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });

    testWidgets('Tasbeeh routes to page AND selects Adhkar tab 3', (tester) async {
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
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });

    testWidgets('Istighfar routes to TasbeehIstighfarPage with tab 1 AND selects Adhkar tab 3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      NotificationRouter.handlePayload('istighfar');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(TasbeehIstighfarPage), findsOneWidget);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });

    testWidgets('Duas & misc routes to DuasMiscPage AND selects Adhkar tab 3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      NotificationRouter.handlePayload('duas');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DuasMiscPage), findsOneWidget);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });

    testWidgets('Dynamic category routes to AdhkarSessionPage AND selects Adhkar tab 3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      NotificationRouter.handlePayload('adhkar_waking');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AdhkarSessionPage), findsOneWidget);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });

    testWidgets('Prayer notification pops routes and switches to Prayer tab 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Push morning page first
      NotificationRouter.handlePayload('morning');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(MorningAthkarPage), findsOneWidget);

      // Reset test rate limiting
      NotificationRouter.resetStateForTesting();

      // Now prayer arrives: must pop the morning page and switch to prayer tab
      NotificationRouter.handlePayload('prayer_الظهر');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(MorningAthkarPage), findsNothing);
      expect(find.byType(PrayerPage), findsOneWidget);
      expect(AppShell.currentTabIndex, equals(AppShellTab.prayer.index));
    });

    testWidgets('Surah Kahf routes to MushafPageViewer with surah 18', (tester) async {
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

    testWidgets('Duplicate rapid tap is suppressed without stacking duplicate routes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Two consecutive taps within 10ms
      NotificationRouter.handlePayload('morning');
      NotificationRouter.handlePayload('morning');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Exactly one instance pushed
      expect(find.byType(MorningAthkarPage), findsOneWidget);

      // Single pop returns to AppShell
      rootNavigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MorningAthkarPage), findsNothing);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });

    testWidgets('Unknown and malformed payloads are safely ignored without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final initialIndex = AppShell.currentTabIndex;

      NotificationRouter.handlePayload('some_garbage_payload_here!@#');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // App remains intact and on initial tab
      expect(AppShell.currentTabIndex, equals(initialIndex));
    });
  });
}
