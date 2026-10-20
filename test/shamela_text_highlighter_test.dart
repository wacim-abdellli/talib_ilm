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

    testWidgets('Recognizes Prophetic Hadiths and citations in guillemets and narrations', (tester) async {
      const sampleText = 'عن النبي صلى الله عليه وسلم قال: «إنما الأعمال بالنيات» رواه البخاري ومسلم.';

      await tester.pumpWidget(buildHighlighterWidget(sampleText));

      expect(find.byType(RichText), findsOneWidget);
      expect(find.textContaining('إنما الأعمال بالنيات'), findsOneWidget);
      expect(find.textContaining('رواه البخاري'), findsOneWidget);
    });

    testWidgets('Highlights Islamic divisions and ordinals (الأصل الأول / ثانياً)', (tester) async {
      const sampleText = 'الأصل الأول: معرفة العبد ربه.\nثانياً: معرفة دين الإسلام بالأدلة.';

      await tester.pumpWidget(buildHighlighterWidget(sampleText));

      expect(find.byType(RichText), findsOneWidget);
      expect(find.textContaining('الأصل الأول:'), findsOneWidget);
      expect(find.textContaining('ثانياً:'), findsOneWidget);
    });

    testWidgets('Survives text scaling up to 2.0 without overflow or crash', (tester) async {
      const sampleText = 'فصل في سنن الوضوء\nوسننه عشرة أشياء: التسمية، وغسل الكفين قبل إدخالهما الإناء.';

      await tester.pumpWidget(buildHighlighterWidget(sampleText, textScale: 2.0));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('فصل في سنن الوضوء'), findsOneWidget);
    });

    testWidgets('Preserves unbroken words containing sub-strings (عقلتا, عـقلـتـا, ثقيل, نقلت)', (tester) async {
      const sampleVerse = 'أَبَا بكرٍ دعوتكَ لَو أجبتا ... إِلَىٰ مَا فِيهِ حظك إِن عقلتا';
      const sampleVerseTatweel = 'إِن عـقلـتـا وثقيل ونقلت وعقلنا';

      final palette = AppPalette.light;
      final textTheme = AppTextTheme.fromPalette(palette);

      final span1 = ShamelaTextHighlighter.buildSpans(
        text: sampleVerse,
        palette: palette,
        textTheme: textTheme,
        fontFamily: 'Amiri',
        fontSizeDelta: 0.0,
      );

      final span2 = ShamelaTextHighlighter.buildSpans(
        text: sampleVerseTatweel,
        palette: palette,
        textTheme: textTheme,
        fontFamily: 'Amiri',
        fontSizeDelta: 0.0,
      );

      // Verify no span erroneously isolated "قلت" from "عقلتا"
      bool hasIsolatedQultu(InlineSpan s) {
        if (s is TextSpan) {
          if (s.text == 'قلت' || s.text == 'قُلْتُ') return true;
          if (s.children != null) {
            return s.children!.any(hasIsolatedQultu);
          }
        }
        return false;
      }

      expect(hasIsolatedQultu(span1), isFalse);
      expect(hasIsolatedQultu(span2), isFalse);

      // Verify the entire word remains intact
      expect(span1.toPlainText(), contains('عقلتا'));
      expect(span2.toPlainText(), contains('عـقلـتـا'));
      expect(span2.toPlainText(), contains('وثقيل'));
      expect(span2.toPlainText(), contains('ونقلت'));
      expect(span2.toPlainText(), contains('وعقلنا'));
    });

    testWidgets('Renders poetic breaks (... or …) with elegant Islamic star marker ✤', (tester) async {
      const sampleVerse = 'أَبَا بكرٍ دعوتكَ لَو أجبتا ... إِلَىٰ مَا فِيهِ حظك إِن عقلتا';

      final palette = AppPalette.light;
      final textTheme = AppTextTheme.fromPalette(palette);

      final span = ShamelaTextHighlighter.buildSpans(
        text: sampleVerse,
        palette: palette,
        textTheme: textTheme,
        fontFamily: 'Amiri',
        fontSizeDelta: 0.0,
      );

      expect(span.toPlainText(), contains(' ✤ '));
    });
  });
}

