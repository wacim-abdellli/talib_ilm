import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/app.dart';

void main() {
  testWidgets('TalibIlmApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TalibIlmApp());
    expect(find.byType(TalibIlmApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
