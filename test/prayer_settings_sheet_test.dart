import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/adhan_service.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/features/prayer/presentation/prayer_settings_sheet.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/iqama_interval_settings.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_muezzin_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'adhan_enabled': true,
      'adhan_sound': 0, // Qatami
      'adhan_volume': 80.0,
      'adhan_default_mode': 0, // Adhan
    });
  });

  Widget buildTestableWidget({
    required Widget child,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 850),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('PrayerSettingsSheet & Muezzin Voices UI Tests', () {
    testWidgets('Iqama interval selector emits the chosen exact minute', (
      tester,
    ) async {
      const settings = AdhanSettings(
        enabled: true,
        sound: AdhanSound.qatami,
        silentNotifications: false,
        prayerToggles: {},
        calculationMethod: 'auto',
        volume: 80.0,
        notifyBeforeMinutes: 15.0,
        iqamaReminders: true,
        adjustments: {},
      );
      AdhanSettings? updatedSettings;

      await tester.pumpWidget(
        buildTestableWidget(
          child: SingleChildScrollView(
            child: IqamaIntervalSettings(
              settings: settings,
              onSettingsChanged: (value) => updatedSettings = value,
            ),
          ),
        ),
      );

      final fajrDropdown = find.byType(DropdownButton<int>).first;
      await tester.ensureVisible(fajrDropdown);
      await tester.tap(fajrDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('26 دقيقة'));
      await tester.pumpAndSettle();

      expect(updatedSettings?.iqamaMinutesAfterAdhan['الفجر'], 26);
    });

    testWidgets('PrayerMuezzinSelector renders all 6 grand muezzins and 2 alternative voices',
        (tester) async {
      const settings = AdhanSettings(
        enabled: true,
        sound: AdhanSound.qatami,
        silentNotifications: false,
        prayerToggles: {},
        calculationMethod: 'auto',
        volume: 80.0,
        notifyBeforeMinutes: 15.0,
        iqamaReminders: true,
        adjustments: {},
      );

      final adhanService = AdhanService();

      await tester.pumpWidget(
        buildTestableWidget(
          child: SingleChildScrollView(
            child: PrayerMuezzinSelector(
              settings: settings,
              adhanService: adhanService,
              onSettingsChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 6 full adhan muezzins are present
      expect(find.text('أذان الشيخ ناصر القطامي', skipOffstage: false), findsOneWidget);
      expect(find.text('أذان الحرم المكي الشريف', skipOffstage: false), findsOneWidget);
      expect(find.text('أذان المسجد النبوي الشريف', skipOffstage: false), findsOneWidget);
      expect(find.text('أذان الشيخ مشاري راشد العفاسي', skipOffstage: false), findsOneWidget);
      expect(find.text('أذان الشيخ عبد الباسط عبد الصمد', skipOffstage: false), findsOneWidget);
      expect(find.text('أذان المسجد الأقصى المبارك', skipOffstage: false), findsOneWidget);

      // Verify the 2 alternative voices are present
      expect(find.text('تكبيرات الأذان فقط', skipOffstage: false), findsOneWidget);
      expect(find.text('نداء وقت الصلاة الوقور', skipOffstage: false), findsOneWidget);

      // Verify volume controls are present
      expect(find.text('مستوى صوت الأذان والتنبيه', skipOffstage: false), findsOneWidget);
      expect(find.text('80%', skipOffstage: false), findsOneWidget);
    });

    testWidgets('PrayerSettingsSheet renders segmented 4 tabs and survives text scales without overflow',
        (tester) async {
      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
        originalOnError?.call(details);
      };

      for (final scale in [1.0, 1.5, 2.0]) {
        caughtDetails = null;
        await tester.pumpWidget(
          buildTestableWidget(
            child: const PrayerSettingsSheet(),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();

        // Verify the 4 segmented tabs exist
        expect(find.text('المؤذن والأصوات'), findsOneWidget);
        expect(find.text('التنبيهات والأذان'), findsOneWidget);
        expect(find.text('الحساب والضبط'), findsOneWidget);
        expect(find.text('أداة الشاشة'), findsOneWidget);

        // Switch to Tab 1 (Notifications)
        await tester.tap(find.text('التنبيهات والأذان'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('الفاصل من الأذان إلى الإقامة حسب مسجدك'), findsOneWidget);
        expect(find.text('الجمعة'), findsOneWidget);
        expect(find.byType(DropdownButton<int>), findsNWidgets(6));

        // Switch to Tab 2 (Calculation)
        await tester.tap(find.text('الحساب والضبط'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Switch to Tab 3 (Widget)
        await tester.tap(find.text('أداة الشاشة'), warnIfMissed: false);
        await tester.pumpAndSettle();

        final exc = tester.takeException();
        if (exc != null) {
          // ignore: avoid_print
          print('SCALE $scale EXCEPTION: $exc');
          // ignore: avoid_print
          print('DETAILS: ${caughtDetails?.toString()}');
        }
        expect(exc, isNull);
      }
      FlutterError.onError = originalOnError;
    });
  });
}
