import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/services/quran_word_analysis_service.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_word_details_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapWithTheme(Widget child, {TextScaler? textScaler, double width = 360}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: textScaler ?? TextScaler.noScaling,
          ),
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  group('QuranWordDetailsSheet 4-Tier Linguistic Analysis Tests', () {
    testWidgets('renders header, all 4 linguistic tiers, and handles tier switching', (tester) async {
      final mockPageJson = {
        'p': 604,
        'lines': [
          [
            't',
            [
              ['ﮀ', 114, 1, 0, 77413],
              ['ﮁ', 114, 1, 0, 77414],
              ['ﮅ', 114, 1, 1],
            ]
          ]
        ]
      };

      final mockWordsJson = {
        '77413': [
          'قراءة ورش بالنقل وصلاً',
          'فعل أمر مبني على السكون والفاعل ضمير مستتر',
          'تكلم واصدع بالتوحيد',
          '﴿قل﴾: ثلاثي مجرد معتل أجوف واوي على وزن افعل',
        ],
        '77414': [
          'تحقيق الهمزة',
          'فعل مضارع مرفوع بالضمة',
          'ألجأ وأعتصم بحمى الله',
          '﴿أعوذ﴾: ثلاثي مزيد بحرف الهمزة من مادة عوذ',
        ]
      };

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/mushaf/hafs/')) {
          return http.Response(json.encode(mockPageJson), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/words/114')) {
          return http.Response(json.encode(mockWordsJson), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      QuranWordAnalysisService().setHttpClient(mockClient);

      await tester.pumpWidget(
        wrapWithTheme(
          const QuranWordDetailsSheet(
            surahNumber: 114,
            ayahNumber: 1,
            wordIndex: 0,
            tappedWord: 'قُلْ',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Header title and word
      expect(find.text('التحليل اللغوي للمفردة'), findsOneWidget);
      expect(find.textContaining('سورة الناس • الآية 1'), findsOneWidget);

      // All 4 Tier Tabs exist
      expect(find.text('المعنى والبيان'), findsOneWidget);
      expect(find.text('الإعراب المفصل'), findsOneWidget);
      expect(find.text('الصرف والاشتقاق'), findsOneWidget);
      expect(find.text('القراءات الواردة'), findsOneWidget);

      // Default tier is Meaning
      expect(find.textContaining('المعنى في السياق القرآني'), findsOneWidget);

      // Tap Irab tier
      await tester.tap(find.text('الإعراب المفصل'));
      await tester.pumpAndSettle();
      expect(find.textContaining('الإعراب والتركيب النحوي'), findsOneWidget);
      expect(find.textContaining('فعل أمر مبني'), findsOneWidget);

      // Tap Sarf tier
      await tester.tap(find.text('الصرف والاشتقاق'));
      await tester.pumpAndSettle();
      expect(find.textContaining('الوزن الصرفي والاشتقاق والجذر'), findsOneWidget);
      expect(find.textContaining('أجوف واوي'), findsOneWidget);

      // Tap Qira'at tier
      await tester.tap(find.text('القراءات الواردة'));
      await tester.pumpAndSettle();
      expect(find.textContaining('روايات القراء العشر في الموضع'), findsOneWidget);
      expect(find.textContaining('ورش بالنقل'), findsOneWidget);

      // Word stepper to next word
      expect(find.text('الكلمة التالية'), findsOneWidget);
      await tester.tap(find.text('الكلمة التالية'));
      await tester.pumpAndSettle();

      // Switches to second word 'أعوذ'
      expect(find.textContaining('تحقيق الهمزة'), findsOneWidget);
    });

    testWidgets('survives text scales 1.0, 1.5, 2.0 without overflow', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          wrapWithTheme(
            const QuranWordDetailsSheet(
              surahNumber: 1,
              ayahNumber: 1,
              wordIndex: 0,
              tappedWord: 'بِسْمِ',
            ),
            textScaler: TextScaler.linear(scale),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('التحليل اللغوي للمفردة'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}

