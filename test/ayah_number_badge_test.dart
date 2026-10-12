import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/ayah_number_badge.dart';

void main() {
  testWidgets('AyahNumberBadge renders brackets and ayah number in RTL order', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AyahNumberBadge(
            ayahNumber: 61,
            color: Colors.amber,
            fontSize: 22,
          ),
        ),
      ),
    );

    expect(find.text('﴿'), findsOneWidget);
    expect(find.text('61'), findsOneWidget);
    expect(find.text('﴾'), findsOneWidget);

    final rowFinder = find.byType(Row);
    expect(rowFinder, findsOneWidget);
    final row = tester.widget<Row>(rowFinder);
    expect(row.mainAxisSize, MainAxisSize.min);
  });
}
