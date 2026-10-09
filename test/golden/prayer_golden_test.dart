import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/next_prayer_card.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_header.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_time_card.dart';

import 'golden_test_helper.dart';

void main() {
  group('Prayer Widgets Golden Tests', () {
    testWidgets('NextPrayerCard - light 1.0', (tester) async {
      final widget = NextPrayerCard(
        prayer: NextPrayer(
          prayer: Prayer.asr,
          time: DateTime(2026, 10, 9, 15, 30),
          minutesRemaining: 45,
        ),
        countdownText: '00:45:00',
        progress: 0.65,
        onTap: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/next_prayer_card_light_1_0',
        isDark: false,
        textScale: 1.0,
      );
    });

    testWidgets('NextPrayerCard - dark 1.5', (tester) async {
      final widget = NextPrayerCard(
        prayer: NextPrayer(
          prayer: Prayer.maghrib,
          time: DateTime(2026, 10, 9, 18, 15),
          minutesRemaining: 15,
        ),
        countdownText: '00:15:00',
        progress: 0.9,
        onTap: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/next_prayer_card_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('PrayerTimeCard - light 1.0', (tester) async {
      const currentItem = PrayerTimeEntry(
        name: 'الظهر',
        timeLabel: '12:30',
        isNext: false,
        isCurrent: true,
        isCompleted: false,
      );

      const nextItem = PrayerTimeEntry(
        name: 'العصر',
        timeLabel: '15:45',
        isNext: true,
        isCurrent: false,
        isCompleted: false,
      );

      final widget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrayerTimeCard(
            item: currentItem,
            onAfterAdhkar: () {},
          ),
          const SizedBox(height: 12),
          PrayerTimeCard(
            item: nextItem,
            onBeforeAdhkar: () {},
          ),
        ],
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/prayer_time_card_light_1_0',
        isDark: false,
        textScale: 1.0,
      );
    });

    testWidgets('PrayerTimeCard - dark 1.5', (tester) async {
      const currentItem = PrayerTimeEntry(
        name: 'المغرب',
        timeLabel: '18:15',
        isNext: false,
        isCurrent: true,
        isCompleted: false,
      );

      final widget = PrayerTimeCard(
        item: currentItem,
        onAfterAdhkar: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/prayer_time_card_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('PrayerHeader - light 1.0', (tester) async {
      final widget = PrayerHeader(
        city: 'الجزائر العاصمة',
        gregorianDate: '09/10/2026',
        onOpenLocationSettings: () {},
        onOpenQibla: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/prayer_header_light_1_0',
        isDark: false,
        textScale: 1.0,
      );
    });

    testWidgets('PrayerHeader - dark 1.5', (tester) async {
      final widget = PrayerHeader(
        city: 'مكة المكرمة',
        gregorianDate: '09/10/2026',
        onOpenLocationSettings: () {},
        onOpenQibla: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/prayer_header_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });
  });
}
