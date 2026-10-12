import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';
import 'package:talib_ilm/features/quran/data/services/quran_tafsir_service.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/ayah_action_menu_sheet.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/ayah_details_tabs.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: child,
          ),
        ),
      ),
    );
  }

  group('AyahActionMenuSheet Tests', () {
    testWidgets('Renders all actions and verse information correctly', (tester) async {
      final audioService = QuranAudioService();

      await tester.pumpWidget(
        buildTestApp(
          AyahActionMenuSheet(
            surahNumber: 1,
            ayahNumber: 1,
            audioService: audioService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header info
      expect(find.textContaining('سورة الفاتحة • الآية 1'), findsOneWidget);

      // Actions
      expect(find.text('تفسير الآية'), findsOneWidget);
      expect(find.text('معاني الكلمات'), findsOneWidget);
      expect(find.text('استماع للآية'), findsOneWidget);
      expect(find.text('تكرار الآية'), findsOneWidget);
      expect(find.textContaining('الفواصل'), findsOneWidget);
      expect(find.text('تعيين كموضع قراءة'), findsOneWidget);
      expect(find.text('تدبر وملاحظات'), findsOneWidget);
      expect(find.text('نسخ الآية'), findsOneWidget);
      expect(find.text('مشاركة الآية الكريمة'), findsOneWidget);
    });
  });

  group('AyahTafsirTabView Scroll & Zoom Tests', () {
    testWidgets('Renders scroll controller and font size zoom stepper', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AyahTafsirTabView(
            selectedScholar: TafsirScholar.muyassar,
            tafsirText: 'تفسير تجريبي للآية الكريمة\n\nفقرة ثانية للتوضيح والبيان.',
            loadingTafsir: false,
            onScholarChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify scrollbar and scroll view are present
      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

      // Stepper elements: A-, 100%, A+
      expect(find.text('A-'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('A+'), findsOneWidget);

      // Tap A+ to increase zoom
      await tester.tap(find.text('A+'));
      await tester.pumpAndSettle();

      expect(find.text('110%'), findsOneWidget);
    });
  });
}
