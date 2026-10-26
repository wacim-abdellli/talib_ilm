import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/onboarding/presentation/onboarding_page.dart';

import 'golden_test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Onboarding Golden Tests', () {
    testWidgets('OnboardingPage - light 1.0', (tester) async {
      await testGoldenWidget(
        tester: tester,
        widget: const OnboardingPage(),
        fileName: 'goldens/onboarding_page_light_1_0',
        isDark: false,
        textScale: 1.0,
        fullScreen: true,
      );
    });

    testWidgets('OnboardingPage - dark 1.5', (tester) async {
      await testGoldenWidget(
        tester: tester,
        widget: const OnboardingPage(),
        fileName: 'goldens/onboarding_page_dark_1_5',
        isDark: true,
        textScale: 1.5,
        fullScreen: true,
      );
    });
  });
}
