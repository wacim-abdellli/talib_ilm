import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/adhkar/data/adhkar_models.dart';
import 'package:talib_ilm/features/adhkar/presentation/widgets/adhkar_session_card.dart';
import 'package:talib_ilm/features/adhkar/presentation/widgets/dhikr_counter_dial.dart';

void main() {
  const sampleItem = AthkarItem(
    id: 'test_dhikr_1',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    transliteration: 'Subhan Allahi wa bihamdihi',
    target: 33,
    countDescription: '٣٣ مرة',
    fadl: 'حُطَّتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ',
    source: 'صحيح مسلم',
    meaning: 'سبحان الله وبحمده، تنزيهاً له عن كل نقص',
    audio: '',
    hadithText: '',
    hadithExplanation: '',
    order: 1,
    type: 0,
  );

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ),
    );
  }

  group('AdhkarSessionCard & Navigation Tests', () {
    testWidgets('AdhkarSessionCard renders Arabic text, badge, and virtue', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const AdhkarSessionCard(
            item: sampleItem,
            repeat: 33,
            isDone: false,
          ),
        ),
      );

      expect(find.text('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ'), findsOneWidget);
      expect(find.text('٣٣ مرة'), findsOneWidget);
      expect(find.textContaining('حُطَّتْ خَطَايَاهُ'), findsOneWidget);
      expect(find.text('صحيح مسلم'), findsOneWidget);
    });

    testWidgets('FloatingChevronButton triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          FloatingChevronButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'الذكر التالي',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      await tester.tap(find.byType(FloatingChevronButton));
      expect(tapped, isTrue);
    });

    testWidgets('NavigationPillButton renders label and respects isEnabled', (tester) async {
      bool nextTapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          Row(
            children: [
              NavigationPillButton(
                icon: Icons.chevron_right_rounded,
                label: 'السابق',
                isLeadingIcon: true,
                isEnabled: false,
                onTap: () {},
              ),
              NavigationPillButton(
                icon: Icons.chevron_left_rounded,
                label: 'التالي',
                isLeadingIcon: false,
                isEnabled: true,
                onTap: () => nextTapped = true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('السابق'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);

      await tester.tap(find.text('التالي'));
      expect(nextTapped, isTrue);
    });

    testWidgets('DhikrCounterDial displays count and triggers onTap', (tester) async {
      int count = 5;
      await tester.pumpWidget(
        wrapWithTheme(
          DhikrCounterDial(
            count: count,
            total: 33,
            isComplete: false,
            onTap: () => count++,
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('من 33'), findsOneWidget);
      expect(find.text('المس للعد'), findsOneWidget);

      await tester.tap(find.byType(DhikrCounterDial));
      expect(count, 6);
    });
  });
}
