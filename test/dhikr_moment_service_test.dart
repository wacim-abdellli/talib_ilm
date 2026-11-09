import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/dhikr_moment_service.dart';
import 'package:talib_ilm/core/services/notification_service.dart';
import 'package:talib_ilm/features/more/presentation/dhikr_moment_settings_sheet.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationService.resetSharedStateForTesting();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (call) async {
            if (call.method == 'initialize') return true;
            if (call.method == 'areNotificationsEnabled') return true;
            if (call.method == 'cancel') return true;
            if (call.method == 'zonedSchedule') return true;
            if (call.method == 'getNotificationAppLaunchDetails') return null;
            return true;
          },
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (call) async => 'Africa/Algiers',
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.talibilm.app/dhikr_overlay'),
          (call) async {
            if (call.method == 'hasOverlayPermission') return true;
            return true;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.talibilm.app/dhikr_overlay'),
          null,
        );
  });

  group('DhikrMomentService Tests', () {
    test('maxAppearancesPerDay is at least 50', () {
      expect(DhikrMomentService.maxAppearancesPerDay, greaterThanOrEqualTo(50));
    });

    test('itemsFor returns rich collections for all content types', () {
      final names = DhikrMomentService.itemsFor(DhikrMomentContent.names);
      final adhkar = DhikrMomentService.itemsFor(DhikrMomentContent.adhkar);
      final duas = DhikrMomentService.itemsFor(DhikrMomentContent.duas);
      final quran = DhikrMomentService.itemsFor(DhikrMomentContent.quran);
      final hadith = DhikrMomentService.itemsFor(DhikrMomentContent.hadith);
      final mixed = DhikrMomentService.itemsFor(DhikrMomentContent.mixed);

      expect(names.length, greaterThanOrEqualTo(20));
      expect(adhkar.length, greaterThanOrEqualTo(20));
      expect(duas.length, greaterThanOrEqualTo(15));
      expect(quran.length, greaterThanOrEqualTo(15));
      expect(hadith.length, greaterThanOrEqualTo(10));
      expect(mixed.length, equals(names.length + adhkar.length + duas.length + quran.length + hadith.length));

      for (final item in mixed) {
        expect(item.text.trim().isNotEmpty, isTrue);
        expect(item.meaning.trim().isNotEmpty, isTrue);
        expect(item.notificationBody.contains(item.text), isTrue);
      }
    });

    test('getItemForSlot returns distinct items for consecutive slots', () {
      final item0 = DhikrMomentService.getItemForSlot(DhikrMomentContent.mixed, 0);
      final item1 = DhikrMomentService.getItemForSlot(DhikrMomentContent.mixed, 1);
      final item2 = DhikrMomentService.getItemForSlot(DhikrMomentContent.mixed, 2);

      expect(item0.text, isNot(equals(item1.text)));
      expect(item1.text, isNot(equals(item2.text)));
    });

    test('scheduledMinutes guarantees zero duplicate minutes', () {
      const settings = DhikrMomentSettings(
        enabled: true,
        timesPerDay: 50,
        startMinutes: 8 * 60,
        endMinutes: 22 * 60,
      );

      final minutes = DhikrMomentService.scheduledMinutes(settings);
      expect(minutes.isNotEmpty, isTrue);

      final set = minutes.toSet();
      expect(minutes.length, equals(set.length));

      for (var i = 0; i < minutes.length - 1; i++) {
        expect(minutes[i], lessThan(minutes[i + 1]));
      }
    });

    test('scheduledMinutes does not duplicate even when span is very small', () {
      const tightSettings = DhikrMomentSettings(
        enabled: true,
        timesPerDay: 30,
        startMinutes: 60,
        endMinutes: 65,
      );

      final minutes = DhikrMomentService.scheduledMinutes(tightSettings);
      final set = minutes.toSet();
      expect(minutes.length, equals(set.length));
    });

    test('load and save persist settings with timesPerDay up to 50', () async {
      final settings = const DhikrMomentSettings().copyWith(
        enabled: true,
        timesPerDay: 45,
        content: DhikrMomentContent.quran,
      );

      await DhikrMomentService.save(settings);
      final loaded = await DhikrMomentService.load();

      expect(loaded.enabled, isTrue);
      expect(loaded.timesPerDay, equals(45));
      expect(loaded.content, equals(DhikrMomentContent.quran));
    });
  });

  group('DhikrMomentSettingsSheet UI Tests', () {
    testWidgets('Renders sheet with preset chips and frequency description', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DhikrMomentSettingsSheet.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('لحظة ذكر'), findsOneWidget);
      expect(find.text('متى تحب أن تراها؟'), findsOneWidget);

      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      await tester.tap(find.text('10'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('10 مرات'), findsOneWidget);
    });
  });
}
