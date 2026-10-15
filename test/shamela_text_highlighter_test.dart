import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/app/theme/app_ui.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/shamela_text_highlighter.dart';

void main() {
  Widget buildHighlighterWidget(String text, {double textScale = 1.0}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                final palette = context.palette;
                final textTheme = context.text;
                return SingleChildScrollView(
                  child: Text.rich(
                    ShamelaTextHighlighter.buildSpans(
                      text: text,
                      palette: palette,
                      textTheme: textTheme,
                      fontFamily: 'Amiri',
                      fontSizeDelta: 0.0,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  group('ShamelaTextHighlighter Tests', () {
    testWidgets('Renders simple classical paragraph correctly', (tester) async {
      const sampleText = 'بسم الله الرحمن الرحيم الحمد لله رب العالمين والصلاة والسلام على رسول الله.';

      await tester.pumpWidget(buildHighlighterWidget(sampleText));

      expect(find.byType(RichText), findsOneWidget);
      expect(find.textContaining('الحمد لله رب العالمين'), findsOneWidget);
    });

    testWidgets('Recognizes and renders chapter header banner', (tester) async {
      const sampleText = 'باب معرفة علامات الإعراب\nللرفع أربع علامات: الضمة والواو والألف والنون.';

      await tester.pumpWidget(buildHighlighterWidget(sampleText));

      expect(find.byType(RichText), findsOneWidget);
      expect(find.textContaining('باب معرفة علامات الإعراب'), findsOneWidget);
      expect(find.textContaining('للرفع أربع علامات'), findsOneWidget);
    });

    testWidgets('Parses Quranic verses in curly brackets { ... } and ﴿ ... ﴾', (tester) async {
      const sampleText = 'قال الله تعالى: {يا أيها الذين آمنوا كتب عليكم الصيام} كما قال ﴿قل هو الله أحد﴾.';

      await tester.pumpWidget(buildHighlighterWidget(sampleText));

      expect(find.byType(RichText), findsOneWidget);
      expect(find.textContaining('يا أيها الذين آمنوا'), findsOneWidget);
    });

    testWidgets('Parses classical Matn/Sharh commentary anchors: قوله: ...', (tester) async {
      const sampleText = '(قوله: والواو) تكون علامة للرفع في موضعين: في جمع المذكر السالم وفي الأسماء الخمسة.';

      await tester.pumpWidget(buildHighlighterWidget(sampleText));

      expect(find.byType(RichText), findsOneWidget);
      expect(find.textContaining('قوله: والواو'), findsOneWidget);
    });

    testWidgets('Handles scholarly attribution prefixes (قال المصنف / الشارح)', (tester) async {
      const sampleText = 'قال المصنف رحمه الله: الصلاة عماد الدين.\nقال الشارح: أي قوامها الذي تقوم به.';

      await tester.pumpWidget(buildHighlighterWidget(sampleText));

      expect(find.byType(RichText), findsOneWidget);
      expect(find.textContaining('قال المصنف'), findsOneWidget);
      expect(find.textContaining('قال الشارح'), findsOneWidget);
    });

    testWidgets('Survives text scaling up to 2.0 without overflow or crash', (tester) async {
      const sampleText = 'فصل في سنن الوضوء\nوسننه عشرة أشياء: التسمية، وغسل الكفين قبل إدخالهما الإناء.';

      await tester.pumpWidget(buildHighlighterWidget(sampleText, textScale: 2.0));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('فصل في سنن الوضوء'), findsOneWidget);
    });
  });
}
