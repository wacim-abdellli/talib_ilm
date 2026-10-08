import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/app.dart';

void main() {
  testWidgets('TalibIlmApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TalibIlmApp());
    expect(find.byType(TalibIlmApp), findsOneWidget);
  });
}
