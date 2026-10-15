import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/presentation/quran_page.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    );
  }

  testWidgets('QuranPage loads without crash and displays all 114 surahs',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget(const QuranPage()));
    await tester.pumpAndSettle();

    // Verify app bar
    expect(find.text('القرآن الكريم'), findsOneWidget);

    // Verify category tabs are visible
    expect(find.text('السور (114)'), findsOneWidget);
    expect(find.text('الأجزاء (30)'), findsOneWidget);
    expect(find.text('الأحزاب (60)'), findsOneWidget);

    // Verify Surah cards are present
    expect(find.text('سورة الفاتحة'), findsWidgets);
    expect(find.text('سورة البقرة'), findsOneWidget);

    // Verify search field is present
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('QuranPage tab switching works without blank screen',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget(const QuranPage()));
    await tester.pumpAndSettle();

    // Switch to Juzs tab
    await tester.tap(find.text('الأجزاء (30)'));
    await tester.pumpAndSettle();

    expect(find.text('الجزء الأول'), findsOneWidget);

    // Switch to Hizbs tab
    await tester.tap(find.text('الأحزاب (60)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('الحزب'), findsWidgets);
  });
}
