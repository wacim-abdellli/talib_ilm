import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/library/presentation/library_page.dart';
import 'golden_test_helper.dart';

void main() {
  group('Library Golden Tests', () {
    testWidgets('LibraryPage - light 1.0 and dark 1.5', (tester) async {
      await testGoldenWidget(
        tester: tester,
        widget: const SizedBox(
          width: 390,
          height: 844,
          child: LibraryPage(),
        ),
        fileName: 'goldens/library_page_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: const SizedBox(
          width: 390,
          height: 844,
          child: LibraryPage(),
        ),
        fileName: 'goldens/library_page_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });
  });
}
