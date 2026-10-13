import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/more/presentation/credits_and_licenses_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CreditsAndLicensesPage(),
    );
  }

  group('CreditsAndLicensesPage Tests', () {
    testWidgets('renders all official sources, sacred note, licenses button, and privacy policy',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Check App Bar
      expect(find.text('المصادر والتراخيص'), findsOneWidget);

      // Check Sacred Veneration notice
      expect(find.text('ضبط النص القرآني الشريف'), findsOneWidget);
      expect(find.textContaining('مجمع الملك فهد'), findsWidgets);

      // Check EveryAyah and reciters
      expect(find.text('التلاوات الصوتية (EveryAyah.com)'), findsOneWidget);
      expect(find.textContaining('مشاري بن راشد العفاسي'), findsOneWidget);
      expect(find.textContaining('محمود خليل الحصري'), findsOneWidget);

      // Check Quran.com API
      expect(find.text('التفاسير ومعاني الكلمات (Quran.com API)'), findsOneWidget);

      // Scroll down to reveal tafsirs, licenses button, and privacy policy
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('تفاسير أهل السنة المعتمدة'), findsOneWidget);

      // Scroll further down
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Check Open source licenses button
      expect(find.text('الحزم مفتوحة المصدر (Third-party)'), findsOneWidget);
      expect(find.text('عرض قائمة التراخيص القانونية الكاملة'), findsOneWidget);

      // Check Privacy Policy
      expect(find.text('سياسة الخصوصية وحماية البيانات'), findsOneWidget);
      expect(find.textContaining('لا جمع للبيانات الشخصية'), findsOneWidget);
      expect(find.textContaining('خلو تام من الإعلانات'), findsOneWidget);
    });
  });
}
