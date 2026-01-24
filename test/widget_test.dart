import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TalibIlmApp());

    // Verify that the app starts.
    expect(find.byType(TalibIlmApp), findsOneWidget);
  });
}
