import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_time_card.dart';

void main() {
  group('PrayerTimeCard Athan Options Tests', () {
    Widget buildCard({
      required PrayerNotificationMode mode,
      ValueChanged<PrayerNotificationMode>? onSelectMode,
    }) {
      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: PrayerTimeCard(
              item: PrayerTimeEntry(
                name: 'الفجر',
                timeLabel: '05:15 ص',
                isNext: false,
                isCurrent: false,
                isCompleted: false,
                notificationMode: mode,
                onSelectMode: onSelectMode,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('displays current athan mode pill label beside prayer', (tester) async {
      await tester.pumpWidget(buildCard(mode: PrayerNotificationMode.adhan));

      expect(find.text('الفجر'), findsOneWidget);
      expect(find.text('05:15 ص'), findsOneWidget);
      expect(find.text('أذان'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('tapping options pill opens popup menu with all notification choices', (tester) async {
      PrayerNotificationMode? chosen;

      await tester.pumpWidget(
        buildCard(
          mode: PrayerNotificationMode.adhan,
          onSelectMode: (m) => chosen = m,
        ),
      );

      // Tap on the options pill
      await tester.tap(find.text('أذان'));
      await tester.pumpAndSettle();

      // Verify all options are visible in the popup menu
      expect(find.text('أذان كامل'), findsOneWidget);
      expect(find.text('تكبيرات فقط'), findsOneWidget);
      expect(find.text('نداء وقت الصلاة'), findsOneWidget);
      expect(find.text('نغمة تنبيه هادئة'), findsOneWidget);
      expect(find.text('إشعار صامت'), findsOneWidget);
      expect(find.text('إيقاف التنبيه'), findsOneWidget);

      // Select 'تكبيرات فقط'
      await tester.tap(find.text('تكبيرات فقط'));
      await tester.pumpAndSettle();

      expect(chosen, PrayerNotificationMode.takbeer);
    });
  });
}
