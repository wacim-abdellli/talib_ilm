import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/adhkar/data/adhkar_models.dart';
import 'package:talib_ilm/features/home/presentation/widgets/home_daily_dhikr_card.dart';

void main() {
  const sampleItem = AthkarItem(
    id: 'test_dhikr_home',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    transliteration: '',
    target: 3,
    countDescription: '٣ مرات',
    fadl: 'حُطَّتْ خَطَايَاهُ',
    source: 'صحيح البخاري',
    meaning: '',
    audio: '',
    hadithText: '',
    hadithExplanation: '',
    order: 1,
    type: 1,
  );

  const payload = DailyDhikrPayload(
    item: sampleItem,
    categoryLabel: 'أذكار الصباح',
    category: AdhkarCategory.morning,
    categoryTotal: 25,
    categoryIcon: Icons.wb_sunny_rounded,
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

  group('HomeDailyDhikrCard Tests', () {
    testWidgets('renders category label, dhikr text, and fadl', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          HomeDailyDhikrCard(
            payload: payload,
            onOpenSession: () {},
          ),
        ),
      );

      expect(find.text('ذكر اليوم'), findsOneWidget);
      expect(find.text('أذكار الصباح'), findsOneWidget);
      expect(find.text('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ'), findsOneWidget);
      expect(find.textContaining('حُطَّتْ خَطَايَاهُ'), findsOneWidget);
      expect(find.text('فتح الورد كاملًا'), findsOneWidget);
      expect(find.text('0 من 3'), findsOneWidget);
    });

    testWidgets('increments count on tap and triggers onOpenSession button', (tester) async {
      bool sessionOpened = false;

      await tester.pumpWidget(
        wrapWithTheme(
          HomeDailyDhikrCard(
            payload: payload,
            onOpenSession: () => sessionOpened = true,
          ),
        ),
      );

      await tester.tap(find.text('0 من 3'));
      await tester.pump();
      expect(find.text('1 من 3'), findsOneWidget);

      await tester.tap(find.text('فتح الورد كاملًا'));
      await tester.pump();
      expect(sessionOpened, isTrue);
    });
  });
}
