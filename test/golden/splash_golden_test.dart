import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/splash/presentation/splash_page.dart';

import 'golden_test_helper.dart';

void main() {
  group('Splash Golden Tests', () {
    testWidgets('SplashPage - light 1.0', (tester) async {
      await testGoldenWidget(
        tester: tester,
        widget: const SplashPage(autoNavigate: false),
        fileName: 'goldens/splash_page_light_1_0',
        isDark: false,
        textScale: 1.0,
      );
    });

    testWidgets('SplashPage - dark 1.5', (tester) async {
      await testGoldenWidget(
        tester: tester,
        widget: const SplashPage(autoNavigate: false),
        fileName: 'goldens/splash_page_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });
  });
}
