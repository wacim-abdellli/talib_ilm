import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/more/presentation/widgets/more_section_card.dart';
import 'package:talib_ilm/features/more/presentation/widgets/theme_selector_sheet.dart';
import 'golden_test_helper.dart';

void main() {
  group('More Widgets Golden Tests', () {
    testWidgets('MoreSectionCard - light 1.0 and dark 1.5', (tester) async {
      final widget = MoreSectionCard(
        section: MoreSection(
          title: 'إعدادات الصلاة',
          subtitle: 'تنبيهات الأذان وطرق الحساب ومواقيت الصلاة',
          icon: Icons.mosque_rounded,
          color: const Color(0xFF0F766E),
          onTap: () {},
        ),
      );

      await testGoldenWidget(
        tester: tester,
        widget: SizedBox(
          width: 360,
          child: widget,
        ),
        fileName: 'goldens/more_section_card_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: SizedBox(
          width: 360,
          child: widget,
        ),
        fileName: 'goldens/more_section_card_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('ThemeOption - selected light 1.0 and unselected dark 1.5', (tester) async {
      const selectedWidget = ThemeOption(
        icon: Icons.light_mode_rounded,
        title: 'الوضع الفاتح',
        subtitle: 'مظهر فاتح وناصع',
        isSelected: true,
        onTap: _noop,
      );

      await testGoldenWidget(
        tester: tester,
        widget: const SizedBox(
          width: 360,
          child: selectedWidget,
        ),
        fileName: 'goldens/more_theme_option_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      const unselectedWidget = ThemeOption(
        icon: Icons.dark_mode_rounded,
        title: 'الوضع الداكن',
        subtitle: 'مظهر ليلي مريح للعين',
        isSelected: false,
        onTap: _noop,
      );

      await testGoldenWidget(
        tester: tester,
        widget: const SizedBox(
          width: 360,
          child: unselectedWidget,
        ),
        fileName: 'goldens/more_theme_option_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });
  });
}

void _noop() {}
