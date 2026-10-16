import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/adhkar/data/adhkar_models.dart';
import 'package:talib_ilm/features/adhkar/presentation/widgets/adhkar_font_size_sheet.dart';
import 'package:talib_ilm/features/adhkar/presentation/widgets/adhkar_session_card.dart';

void main() {
  const testItem = AthkarItem(
    id: 'test_dhikr_1',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    transliteration: 'Subhan Allahi wa bihamdihi',
    meaning: 'Glory be to Allah and His is the praise',
    target: 33,
    countDescription: '٣٣ مرة',
    fadl: 'تُحط خطاياه وإن كانت مثل زبد البحر',
    source: 'صحيح مسلم',
    audio: '',
    hadithText: '',
    hadithExplanation: '',
    order: 1,
    type: 1,
  );

  Widget buildWrapper({required Widget child}) {
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

  group('AdhkarSessionCard font resize controls', () {
    testWidgets('renders font minimize, maximize, and percentage indicator', (tester) async {
      await tester.pumpWidget(
        buildWrapper(
          child: AdhkarSessionCard(
            item: testItem,
            repeat: 33,
            isDone: false,
            fontScale: 1.0,
            onIncreaseFontSize: () {},
            onDecreaseFontSize: () {},
            onResetFontSize: () {},
          ),
        ),
      );

      // Verify stepper buttons exist
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('tapping maximize triggers onIncreaseFontSize', (tester) async {
      bool increased = false;
      await tester.pumpWidget(
        buildWrapper(
          child: AdhkarSessionCard(
            item: testItem,
            repeat: 33,
            isDone: false,
            fontScale: 1.0,
            onIncreaseFontSize: () => increased = true,
            onDecreaseFontSize: () {},
            onResetFontSize: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(increased, isTrue);
    });

    testWidgets('tapping minimize triggers onDecreaseFontSize', (tester) async {
      bool decreased = false;
      await tester.pumpWidget(
        buildWrapper(
          child: AdhkarSessionCard(
            item: testItem,
            repeat: 33,
            isDone: false,
            fontScale: 1.15,
            onIncreaseFontSize: () {},
            onDecreaseFontSize: () => decreased = true,
            onResetFontSize: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(decreased, isTrue);
    });

    testWidgets('tapping percentage label triggers onResetFontSize', (tester) async {
      bool reset = false;
      await tester.pumpWidget(
        buildWrapper(
          child: AdhkarSessionCard(
            item: testItem,
            repeat: 33,
            isDone: false,
            fontScale: 1.30,
            onIncreaseFontSize: () {},
            onDecreaseFontSize: () {},
            onResetFontSize: () => reset = true,
          ),
        ),
      );

      await tester.tap(find.text('130%'));
      await tester.pump();
      expect(reset, isTrue);
    });

    testWidgets('scales all card texts (Arabic, virtue, and source) with fontScale', (tester) async {
      await tester.pumpWidget(
        buildWrapper(
          child: AdhkarSessionCard(
            item: testItem,
            repeat: 33,
            isDone: false,
            fontScale: 1.30,
            onIncreaseFontSize: () {},
            onDecreaseFontSize: () {},
            onResetFontSize: () {},
          ),
        ),
      );

      // Verify sacred Arabic text scaler
      final arabicFinder = find.text(testItem.arabic);
      expect(arabicFinder, findsOneWidget);
      final Text arabicTextWidget = tester.widget(arabicFinder);
      expect(arabicTextWidget.textScaler, equals(const TextScaler.linear(1.30)));

      // Verify virtue text scaler
      final fadlFinder = find.text(testItem.fadl);
      expect(fadlFinder, findsOneWidget);
      final Text fadlTextWidget = tester.widget(fadlFinder);
      expect(fadlTextWidget.textScaler, equals(const TextScaler.linear(1.30)));

      // Verify source text scaler
      final sourceFinder = find.text(testItem.source);
      expect(sourceFinder, findsOneWidget);
      final Text sourceTextWidget = tester.widget(sourceFinder);
      expect(sourceTextWidget.textScaler, equals(const TextScaler.linear(1.30)));
    });
  });

  group('AdhkarFontSizeSheet modal', () {
    testWidgets('renders stepper, presets, tashkeel toggle and live preview', (tester) async {
      double currentScale = 1.0;
      bool currentTashkeel = true;

      await tester.pumpWidget(
        buildWrapper(
          child: AdhkarFontSizeSheet(
            currentScale: currentScale,
            showTashkeel: currentTashkeel,
            onFontScaleChanged: (scale) => currentScale = scale,
            onToggleTashkeel: (tashkeel) => currentTashkeel = tashkeel,
            onReset: () => currentScale = 1.0,
          ),
        ),
      );

      expect(find.text('حجم الخط وتنسيق النص'), findsOneWidget);
      expect(find.text('100%'), findsWidgets);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('115%'), findsOneWidget);
      expect(find.text('130%'), findsOneWidget);
      expect(find.text('145%'), findsOneWidget);
      expect(find.text('160%'), findsOneWidget);
      expect(find.text('عرض التشكيل والحركات'), findsOneWidget);
      expect(find.text('معاينة حية لبطاقة الذكر:'), findsOneWidget);

      // Tap preset 130%
      await tester.tap(find.text('130%'));
      await tester.pump();
      expect(currentScale, equals(1.30));

      // Tap minimize (-) in sheet
      await tester.tap(find.byTooltip('تصغير الخط (-)'));
      await tester.pump();
      expect(currentScale, equals(1.15));

      // Tap maximize (+) in sheet
      await tester.tap(find.byTooltip('تكبير الخط (+)'));
      await tester.pump();
      expect(currentScale, equals(1.30));
    });
  });
}
