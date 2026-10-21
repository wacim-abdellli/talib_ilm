import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/home_widget_service.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/widget_compact.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/widget_large.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/widget_ribbon.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/widget_standard.dart';

void main() {
  testWidgets('PrayerHomeScreenWidget renders 5 prayers and countdown correctly', (tester) async {
    final fixedNow = DateTime(2026, 10, 20, 4, 30); // 4:30 AM, before Fajr at 5:02 AM
    final prayerDay = PrayerTimesDay(
      city: 'الجزائر العاصمة',
      date: DateTime(2026, 10, 20),
      prayers: {
        AppStrings.prayerFajr: DateTime(2026, 10, 20, 5, 2),
        AppStrings.prayerDhuhr: DateTime(2026, 10, 20, 12, 3),
        AppStrings.prayerAsr: DateTime(2026, 10, 20, 15, 11),
        AppStrings.prayerMaghrib: DateTime(2026, 10, 20, 17, 38),
        AppStrings.prayerIsha: DateTime(2026, 10, 20, 19, 2),
      },
      nextPrayer: AppStrings.prayerFajr,
      nextPrayerTime: DateTime(2026, 10, 20, 5, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PrayerHomeScreenWidget(
            prayerDay: prayerDay,
            referenceTime: fixedNow,
          ),
        ),
      ),
    );

    // Verify Title
    expect(find.text('صلاة الفجر'), findsOneWidget);

    // Verify Western numerals in Next Time display
    expect(find.text('5:02 ص'), findsWidgets);

    // Verify countdown label
    expect(find.text('بقي على الأذان'), findsOneWidget);

    // Verify 5 daily prayers
    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('الظهر'), findsOneWidget);
    expect(find.text('العصر'), findsOneWidget);
    expect(find.text('المغرب'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);

    // Verify other formatted times
    expect(find.text('12:03 م'), findsOneWidget);
    expect(find.text('3:11 م'), findsOneWidget);
    expect(find.text('5:38 م'), findsOneWidget);
    expect(find.text('7:02 م'), findsOneWidget);
  });

  test('HomeWidgetService updatePrayerWidget handles invocation gracefully', () async {
    // Should run without unhandled exceptions even in test runner
    await expectLater(
      HomeWidgetService.updatePrayerWidget(),
      completes,
    );
  });

  testWidgets('PrayerHomeScreenWidget has zero overflow under tight constraints and large text scaling', (tester) async {
    final fixedNow = DateTime(2026, 10, 20, 14, 0); // 2:00 PM, before Asr at 3:11 PM
    final prayerDay = PrayerTimesDay(
      city: 'الجزائر العاصمة',
      date: DateTime(2026, 10, 20),
      prayers: {
        AppStrings.prayerFajr: DateTime(2026, 10, 20, 5, 2),
        AppStrings.prayerDhuhr: DateTime(2026, 10, 20, 12, 3),
        AppStrings.prayerAsr: DateTime(2026, 10, 20, 15, 11),
        AppStrings.prayerMaghrib: DateTime(2026, 10, 20, 17, 38),
        AppStrings.prayerIsha: DateTime(2026, 10, 20, 19, 2),
      },
      nextPrayer: AppStrings.prayerAsr,
      nextPrayerTime: DateTime(2026, 10, 20, 15, 11),
    );

    // Test in tight 380x180 box
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 380,
              height: 180,
              child: PrayerHomeScreenWidget(
                prayerDay: prayerDay,
                referenceTime: fixedNow,
                width: 380,
                height: 180,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('صلاة العصر'), findsOneWidget);

    // Test in even tighter 320x150 box with 1.5x text scale
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.5),
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 150,
                child: PrayerHomeScreenWidget(
                  prayerDay: prayerDay,
                  referenceTime: fixedNow,
                  width: 320,
                  height: 150,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('PrayerHomeScreenWidget renders atAdhan, betweenAdhanAndIqama, inSalah, and Friday states', (tester) async {
    final fridayDate = DateTime(2026, 10, 23); // Friday
    final prayers = {
      AppStrings.prayerFajr: DateTime(2026, 10, 23, 5, 0),
      AppStrings.prayerDhuhr: DateTime(2026, 10, 23, 12, 15),
      AppStrings.prayerAsr: DateTime(2026, 10, 23, 15, 30),
      AppStrings.prayerMaghrib: DateTime(2026, 10, 23, 17, 45),
      AppStrings.prayerIsha: DateTime(2026, 10, 23, 19, 15),
    };

    final fridayDay = PrayerTimesDay(
      city: 'الجزائر العاصمة',
      date: fridayDate,
      prayers: prayers,
      nextPrayer: AppStrings.prayerDhuhr,
      nextPrayerTime: prayers[AppStrings.prayerDhuhr]!,
    );

    // 1. Test Friday Dhuhr title
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: PrayerHomeScreenWidget(
            prayerDay: fridayDay,
            referenceTime: DateTime(2026, 10, 23, 11, 30),
          ),
        ),
      ),
    );
    expect(find.text('صلاة الجمعة'), findsOneWidget);
    expect(find.text('بقي على الأذان'), findsOneWidget);

    // 2. Test atAdhan phase (12:15:30)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: PrayerHomeScreenWidget(
            prayerDay: fridayDay,
            referenceTime: DateTime(2026, 10, 23, 12, 15, 30),
          ),
        ),
      ),
    );
    expect(find.text('حان الآن وقت الأذان'), findsOneWidget);
    expect(find.text('الأذان الآن'), findsOneWidget);

    // 3. Test betweenAdhanAndIqama phase (12:25:00 - Friday iqama is 25 min -> 12:40)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PrayerHomeScreenWidget(
            prayerDay: fridayDay,
            referenceTime: DateTime(2026, 10, 23, 12, 25),
          ),
        ),
      ),
    );
    expect(find.text('بقي على الإقامة'), findsOneWidget);
    expect(find.text('الإقامة 12:40 م'), findsOneWidget);

    // 4. Test inSalah phase (12:45:00 - during congregational salah)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: PrayerHomeScreenWidget(
            prayerDay: fridayDay,
            referenceTime: DateTime(2026, 10, 23, 12, 45),
          ),
        ),
      ),
    );
    expect(find.text('تقام الصلاة الآن'), findsOneWidget);
    expect(find.text('أداء الفريضة'), findsOneWidget);

    // 5. Test resized large dimensions (520x220)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 520,
              height: 220,
              child: PrayerHomeScreenWidget(
                prayerDay: fridayDay,
                referenceTime: DateTime(2026, 10, 23, 12, 45),
                width: 520,
                height: 220,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('PrayerHomeScreenWidget renders Compact 2x2, Tall 4x4, and Ribbon 4x1 layouts cleanly', (tester) async {
    final fixedNow = DateTime(2026, 10, 20, 11, 45); // 15 mins before Dhuhr
    final prayerDay = PrayerTimesDay(
      city: 'تونس العاصمة',
      date: DateTime(2026, 10, 20),
      prayers: {
        AppStrings.prayerFajr: DateTime(2026, 10, 20, 5, 2),
        AppStrings.prayerDhuhr: DateTime(2026, 10, 20, 12, 3),
        AppStrings.prayerAsr: DateTime(2026, 10, 20, 15, 11),
        AppStrings.prayerMaghrib: DateTime(2026, 10, 20, 17, 38),
        AppStrings.prayerIsha: DateTime(2026, 10, 20, 19, 2),
      },
      nextPrayer: AppStrings.prayerDhuhr,
      nextPrayerTime: DateTime(2026, 10, 20, 12, 3),
    );

    // A. Compact 2x2 Mode (width: 180, height: 180)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: PrayerHomeScreenWidget(
              prayerDay: prayerDay,
              referenceTime: fixedNow,
              width: 180,
              height: 180,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('صلاة الظهر'), findsOneWidget);
    expect(find.text('بقي على الأذان'), findsOneWidget);
    expect(find.textContaining('التالي:'), findsOneWidget);

    // B. Tall 4x4 Mode (width: 380, height: 350)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: PrayerHomeScreenWidget(
              prayerDay: prayerDay,
              referenceTime: fixedNow,
              width: 380,
              height: 350,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('صلاة الظهر'), findsOneWidget);
    expect(find.text('تونس العاصمة'), findsOneWidget);
    expect(find.text('بقي على الأذان'), findsWidgets);

    // C. Ribbon 4x1 Mode (width: 380, height: 90)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: PrayerHomeScreenWidget(
              prayerDay: prayerDay,
              referenceTime: fixedNow,
              width: 380,
              height: 90,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('صلاة الظهر'), findsOneWidget);
    expect(find.text('بقي على الأذان'), findsOneWidget);
  });

  testWidgets('WidgetRibbon (4x1, 360x80) renders without overflow under text scale 1.0, 1.5, and 2.0', (tester) async {
    final fixedNow = DateTime(2026, 10, 20, 4, 30);
    final prayers = {
      AppStrings.prayerFajr: DateTime(2026, 10, 20, 5, 2),
      AppStrings.prayerDhuhr: DateTime(2026, 10, 20, 12, 3),
      AppStrings.prayerAsr: DateTime(2026, 10, 20, 15, 11),
      AppStrings.prayerMaghrib: DateTime(2026, 10, 20, 17, 38),
      AppStrings.prayerIsha: DateTime(2026, 10, 20, 19, 2),
    };
    final eval = PrayerWidgetStateEvaluator.evaluate(now: fixedNow, all: prayers);

    for (final scale in [1.0, 1.5, 2.0]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Center(
                child: WidgetRibbon(
                  eval: eval,
                  all: prayers,
                  hijriDate: '10 جمادى الأولى 1448 هـ',
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('10 جمادى الأولى 1448 هـ'), findsOneWidget);
      expect(find.text('الفجر'), findsOneWidget);
      expect(find.text('الظهر'), findsOneWidget);
    }
  });

  testWidgets('WidgetStandard (4x2, 360x160) renders without overflow under light and dark themes', (tester) async {
    final fixedNow = DateTime(2026, 10, 20, 11, 45);
    final prayers = {
      AppStrings.prayerFajr: DateTime(2026, 10, 20, 5, 2),
      AppStrings.prayerDhuhr: DateTime(2026, 10, 20, 12, 3),
      AppStrings.prayerAsr: DateTime(2026, 10, 20, 15, 11),
      AppStrings.prayerMaghrib: DateTime(2026, 10, 20, 17, 38),
      AppStrings.prayerIsha: DateTime(2026, 10, 20, 19, 2),
    };
    final eval = PrayerWidgetStateEvaluator.evaluate(now: fixedNow, all: prayers);

    for (final dark in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: WidgetStandard(
                eval: eval,
                all: prayers,
                isDark: dark,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('صلاة الظهر'), findsOneWidget);
      expect(find.text('بقي على الأذان'), findsOneWidget);
    }
  });

  testWidgets('WidgetLarge (4x3, 360x240) renders top bar, hero, and strip without overflow', (tester) async {
    final fixedNow = DateTime(2026, 10, 20, 11, 45);
    final prayers = {
      AppStrings.prayerFajr: DateTime(2026, 10, 20, 5, 2),
      AppStrings.prayerDhuhr: DateTime(2026, 10, 20, 12, 3),
      AppStrings.prayerAsr: DateTime(2026, 10, 20, 15, 11),
      AppStrings.prayerMaghrib: DateTime(2026, 10, 20, 17, 38),
      AppStrings.prayerIsha: DateTime(2026, 10, 20, 19, 2),
    };
    final eval = PrayerWidgetStateEvaluator.evaluate(now: fixedNow, all: prayers);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: WidgetLarge(
              eval: eval,
              all: prayers,
              hijriDate: '10 جمادى الأولى 1448 هـ',
              cityName: 'الجزائر العاصمة',
              isDark: true,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('10 جمادى الأولى'), findsOneWidget);
    expect(find.text('الجزائر العاصمة'), findsOneWidget);
    expect(find.text('الظهر'), findsWidgets);
  });

  testWidgets('WidgetCompact (2x2, 160x160) renders compact prayer card without overflow', (tester) async {
    final fixedNow = DateTime(2026, 10, 20, 11, 45);
    final prayers = {
      AppStrings.prayerFajr: DateTime(2026, 10, 20, 5, 2),
      AppStrings.prayerDhuhr: DateTime(2026, 10, 20, 12, 3),
      AppStrings.prayerAsr: DateTime(2026, 10, 20, 15, 11),
      AppStrings.prayerMaghrib: DateTime(2026, 10, 20, 17, 38),
      AppStrings.prayerIsha: DateTime(2026, 10, 20, 19, 2),
    };
    final eval = PrayerWidgetStateEvaluator.evaluate(now: fixedNow, all: prayers);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: WidgetCompact(
              eval: eval,
              isDark: false,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('صلاة الظهر'), findsOneWidget);
    expect(find.text('بقي على الأذان'), findsOneWidget);
  });

  test('HomeWidgetService fixed widget update methods execute cleanly', () async {
    final fixedNow = DateTime(2026, 10, 20, 11, 45);
    final prayerDay = PrayerTimesDay(
      city: 'الجزائر العاصمة',
      date: DateTime(2026, 10, 20),
      prayers: {
        AppStrings.prayerFajr: DateTime(2026, 10, 20, 5, 2),
        AppStrings.prayerDhuhr: DateTime(2026, 10, 20, 12, 3),
        AppStrings.prayerAsr: DateTime(2026, 10, 20, 15, 11),
        AppStrings.prayerMaghrib: DateTime(2026, 10, 20, 17, 38),
        AppStrings.prayerIsha: DateTime(2026, 10, 20, 19, 2),
      },
      nextPrayer: AppStrings.prayerDhuhr,
      nextPrayerTime: DateTime(2026, 10, 20, 12, 3),
    );

    await expectLater(
      HomeWidgetService.updateRibbon(prayerDay: prayerDay, referenceTime: fixedNow, force: true),
      completes,
    );
    await expectLater(
      HomeWidgetService.updateStandard(prayerDay: prayerDay, referenceTime: fixedNow, force: true),
      completes,
    );
    await expectLater(
      HomeWidgetService.updateLarge(prayerDay: prayerDay, referenceTime: fixedNow, force: true),
      completes,
    );
    await expectLater(
      HomeWidgetService.updateCompact(prayerDay: prayerDay, referenceTime: fixedNow, force: true),
      completes,
    );
    await expectLater(
      HomeWidgetService.updateAllWidgets(prayerDay: prayerDay, referenceTime: fixedNow, force: true),
      completes,
    );
  });

  test('PrayerWidgetStateEvaluator validates canonical per-prayer Iqama durations and header labels', () {
    expect(PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerFajr), 25);
    expect(PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerDhuhr), 20);
    expect(PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerDhuhr, isJumua: true), 25);
    expect(PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerAsr), 20);
    expect(PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerMaghrib), 10);
    expect(PrayerWidgetStateEvaluator.getIqamaMinutes(AppStrings.prayerIsha), 15);

    final prayers = {
      AppStrings.prayerFajr: DateTime(2026, 10, 20, 5, 3),
      AppStrings.prayerDhuhr: DateTime(2026, 10, 20, 12, 3),
      AppStrings.prayerAsr: DateTime(2026, 10, 20, 15, 9),
      AppStrings.prayerMaghrib: DateTime(2026, 10, 20, 17, 35),
      AppStrings.prayerIsha: DateTime(2026, 10, 20, 18, 59),
    };

    // 1. Between Adhan and Iqama (Maghrib 17:35, now 17:39 -> 6 minutes remaining to Iqama 17:45)
    final evalIqama = PrayerWidgetStateEvaluator.evaluate(
      now: DateTime(2026, 10, 20, 17, 39),
      all: prayers,
    );
    expect(evalIqama.phase, PrayerWidgetPhase.betweenAdhanAndIqama);
    expect(evalIqama.statusLabel, 'بقي على الإقامة');
    expect(evalIqama.countdownFormatted, '06:00');
    expect(evalIqama.headerCountdownLabel, 'الإقامة بعد 06:00');
    expect(evalIqama.headerCountdownLabel.contains('أداء الفريضة'), isFalse);

    // 2. In Salah (Maghrib 17:35, now 17:48 -> 3 minutes after Iqama 17:45)
    final evalSalah = PrayerWidgetStateEvaluator.evaluate(
      now: DateTime(2026, 10, 20, 17, 48),
      all: prayers,
    );
    expect(evalSalah.phase, PrayerWidgetPhase.inSalah);
    expect(evalSalah.statusLabel, 'تقام الصلاة الآن');
    expect(evalSalah.countdownFormatted, 'أداء الفريضة');
    expect(evalSalah.headerCountdownLabel, 'تقام الصلاة الآن');
    expect(evalSalah.headerCountdownLabel.contains('بعد أداء الفريضة'), isFalse);

    // 3. Post Salah (Maghrib 17:35, now 18:00 -> 25 minutes after Adhan, beyond 20 min salah duration)
    // Should transition seamlessly to Isha upcoming countdown
    final evalPostSalah = PrayerWidgetStateEvaluator.evaluate(
      now: DateTime(2026, 10, 20, 18, 0),
      all: prayers,
    );
    expect(evalPostSalah.phase, PrayerWidgetPhase.beforeAdhan);
    expect(evalPostSalah.activePrayerName, AppStrings.prayerIsha);
    expect(evalPostSalah.headerCountdownLabel, 'بعد 59:00');
  });
}
