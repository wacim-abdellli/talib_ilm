import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/home_widget_service.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_home_screen_widget.dart';

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
}
