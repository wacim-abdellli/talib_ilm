import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/more/presentation/more_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget() {
    return MaterialApp(theme: AppTheme.lightTheme, home: const MorePage());
  }

  group('MorePage Streamlined Settings Tests', () {
    testWidgets('renders all essential categories and tiles', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Header checks
      expect(find.text('الإعدادات والمزيد'), findsOneWidget);
      expect(find.text('طالب علم • سائر في الطلب 🌿'), findsOneWidget);

      // Initial visible section: الصلاة والتنبيهات
      expect(find.text('الصلاة والتنبيهات'), findsOneWidget);
      expect(find.text('تنبيهات الصلاة والأذان'), findsOneWidget);
      expect(find.text('موقع الصلاة وطريقة الحساب'), findsOneWidget);

      // Scroll to second section: المحتوى والمحفوظات
      await tester.scrollUntilVisible(find.text('المحتوى والمحفوظات'), 250);
      await tester.pumpAndSettle();
      expect(find.text('المحتوى والمحفوظات'), findsOneWidget);
      expect(find.text('المفضلة والمحفوظات'), findsOneWidget);
      expect(find.text('التنزيلات الصوتية'), findsOneWidget);

      // Scroll to third section: تفضيلات التطبيق
      await tester.scrollUntilVisible(find.text('تفضيلات التطبيق'), 250);
      await tester.pumpAndSettle();
      expect(find.text('تفضيلات التطبيق'), findsOneWidget);
      expect(find.text('المظهر والسمة'), findsOneWidget);

      // Verify purged items are NOT present in the settings list
      expect(find.text('اللغة'), findsNothing);
      expect(find.text('النسخ الاحتياطي والاستعادة'), findsNothing);
      expect(find.textContaining('json'), findsNothing);
      expect(find.textContaining('JSON'), findsNothing);
      expect(find.text('إدارة اللغة ستتوفر قريبًا.'), findsNothing);

      // Footer checks
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('طالب علم • الإصدار 2.0.0'), findsOneWidget);
      expect(
        find.text(
          '«مَن سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا، سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الجَنَّةِ»',
        ),
        findsOneWidget,
      );
      expect(find.text('بيانات الإسناد ومصادر المحتوى'), findsOneWidget);
    });
  });
}
