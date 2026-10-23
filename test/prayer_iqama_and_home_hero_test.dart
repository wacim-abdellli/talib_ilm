import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/utils/prayer_countdown.dart';
import 'package:talib_ilm/features/home/presentation/widgets/home_hero_card.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';

void main() {
  group('Prayer Iqama & Dynamic Transition Tests', () {
    final baseDate = DateTime(2026, 10, 14, 12, 0);

    final testPrayers = <String, DateTime>{
      AppStrings.prayerFajr: DateTime(2026, 10, 14, 5, 0),
      AppStrings.prayerDhuhr: DateTime(2026, 10, 14, 12, 4),
      AppStrings.prayerAsr: DateTime(2026, 10, 14, 15, 15),
      AppStrings.prayerMaghrib: DateTime(2026, 10, 14, 17, 44),
      AppStrings.prayerIsha: DateTime(2026, 10, 14, 19, 3),
    };

    final testDay = PrayerTimesDay(
      city: 'صفاقس',
      date: baseDate,
      prayers: testPrayers,
      nextPrayer: AppStrings.prayerAsr,
      nextPrayerTime: testPrayers[AppStrings.prayerAsr],
    );

    test(
      'PrayerCountdownController detects active Iqama period within 15 minutes of Adhan',
      () async {
        // Current time is 3:20 PM (5 minutes after Asr at 3:15 PM)
        final testNow = DateTime(2026, 10, 14, 15, 20);

        final controller = PrayerCountdownController(
          day: testDay,
          now: () => testNow,
        );

        controller.start();
        addTearDown(controller.dispose);

        final state = controller.state.value;
        expect(state.nextPrayerName, equals(AppStrings.prayerAsr));
        expect(state.isInPrayerTime, isTrue);
        expect(state.elapsed.inMinutes, equals(5));
        expect(state.remaining, equals(Duration.zero));
      },
    );

    test(
      'PrayerCountdownController automatically advances to next prayer after 15 minutes',
      () async {
        // Current time is 3:31 PM (16 minutes after Asr at 3:15 PM)
        final testNow = DateTime(2026, 10, 14, 15, 31);

        final controller = PrayerCountdownController(
          day: testDay,
          now: () => testNow,
        );

        controller.start();
        addTearDown(controller.dispose);

        final state = controller.state.value;
        expect(state.nextPrayerName, equals(AppStrings.prayerMaghrib));
        expect(state.isInPrayerTime, isFalse);
        expect(
          state.remaining.inMinutes,
          equals(
            testPrayers[AppStrings.prayerMaghrib]!
                .difference(testNow)
                .inMinutes,
          ),
        );
      },
    );

    testWidgets(
      'HomeHeroCard displays Iqama countdown before the congregation',
      (tester) async {
        final asrTime = DateTime.now().subtract(
          const Duration(minutes: 7, seconds: 30),
        );
        final prayers = {
          AppStrings.prayerFajr: DateTime.now().subtract(
            const Duration(hours: 10),
          ),
          AppStrings.prayerDhuhr: DateTime.now().subtract(
            const Duration(hours: 3),
          ),
          AppStrings.prayerAsr: asrTime,
          AppStrings.prayerMaghrib: DateTime.now().add(
            const Duration(hours: 2),
          ),
          AppStrings.prayerIsha: DateTime.now().add(const Duration(hours: 4)),
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeHeroCard(
                nextPrayerName: AppStrings.prayerAsr,
                nextPrayerTime: asrTime,
                allPrayers: prayers,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('بقي على الإقامة'), findsOneWidget);
        expect(find.text('تقام الصلاة الآن'), findsNothing);
        expect(find.text(AppStrings.prayerAsr), findsWidgets);
      },
    );

    testWidgets('HomeHeroCard displays countdown mode when before Adhan', (
      tester,
    ) async {
      final maghribTime = DateTime.now().add(
        const Duration(hours: 1, minutes: 45),
      );
      final prayers = {
        AppStrings.prayerFajr: DateTime.now().subtract(
          const Duration(hours: 12),
        ),
        AppStrings.prayerDhuhr: DateTime.now().subtract(
          const Duration(hours: 5),
        ),
        AppStrings.prayerAsr: DateTime.now().subtract(const Duration(hours: 2)),
        AppStrings.prayerMaghrib: maghribTime,
        AppStrings.prayerIsha: DateTime.now().add(const Duration(hours: 3)),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeroCard(
              nextPrayerName: AppStrings.prayerMaghrib,
              nextPrayerTime: maghribTime,
              allPrayers: prayers,
            ),
          ),
        ),
      );

      await tester.pump();

      // Expect to see countdown mode
      expect(find.text('بقي على الأذان'), findsOneWidget);
      expect(find.text('وقت الصلاة الآن (الإقامة)'), findsNothing);
    });
  });
}
