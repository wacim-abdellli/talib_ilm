import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/shared/widgets/app_widgets.dart';
import 'golden_test_helper.dart';

void main() {
  group('Components Golden Tests', () {
    testWidgets('AppButton variants - light 1.0', (tester) async {
      final widget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(label: 'زر رئيسي', onPressed: () {}),
          const SizedBox(height: 12),
          AppButton.tonal(label: 'زر ثانوي نغمي', onPressed: () {}),
          const SizedBox(height: 12),
          AppButton.outline(label: 'زر مخطط', onPressed: () {}),
          const SizedBox(height: 12),
          AppButton.text(label: 'زر نصي', onPressed: () {}),
        ],
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/button_light_1_0',
        isDark: false,
        textScale: 1.0,
      );
    });

    testWidgets('AppButton variants - dark 1.5', (tester) async {
      final widget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(label: 'زر رئيسي', onPressed: () {}),
          const SizedBox(height: 12),
          AppButton.tonal(label: 'زر ثانوي نغمي', onPressed: () {}),
          const SizedBox(height: 12),
          AppButton.outline(label: 'زر مخطط', onPressed: () {}),
          const SizedBox(height: 12),
          AppButton.text(label: 'زر نصي', onPressed: () {}),
        ],
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/button_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('AppCard and IconBadge - light 1.0', (tester) async {
      final widget = AppCard(
        onTap: () {},
        child: Row(
          children: [
            const IconBadge(icon: Icons.book_rounded),
            const SizedBox(width: 16),
            const Expanded(
              child: Text('بطاقة اختبار العلم الشرعي'),
            ),
          ],
        ),
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/card_light_1_0',
        isDark: false,
        textScale: 1.0,
      );
    });

    testWidgets('AppCard and IconBadge - dark 1.5', (tester) async {
      final widget = AppCard(
        onTap: () {},
        child: Row(
          children: [
            const IconBadge(icon: Icons.book_rounded),
            const SizedBox(width: 16),
            const Expanded(
              child: Text('بطاقة اختبار العلم الشرعي'),
            ),
          ],
        ),
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/card_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('AppListTile and AppTag - light', (tester) async {
      final widget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppListTile(
            icon: Icons.bookmark_rounded,
            title: 'كتاب التوحيد',
            subtitle: 'الشيخ محمد بن عبد الوهاب',
            trailing: const AppTag(label: 'عقيدة', subject: 'عقيدة'),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          const AppProgress(progress: 0.65),
          const SizedBox(height: 12),
          const AppProgress(progress: 1.0),
        ],
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/list_tile_progress_light',
        isDark: false,
        textScale: 1.0,
      );
    });

    testWidgets('AppEmptyState - light 1.0', (tester) async {
      final widget = AppEmptyState.books();

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/empty_state_light',
        isDark: false,
        textScale: 1.0,
      );
    });

    testWidgets('NavBar - light 1.0', (tester) async {
      final widget = NavBar(
        currentIndex: 0,
        onTap: (_) {},
        items: const [
          NavBarItem(icon: Icons.home_rounded, label: 'الرئيسية'),
          NavBarItem(icon: Icons.access_time_rounded, label: 'الصلاة'),
          NavBarItem(icon: Icons.auto_stories_rounded, label: 'طلب العلم'),
          NavBarItem(icon: Icons.spa_rounded, label: 'الأذكار'),
          NavBarItem(icon: Icons.settings_rounded, label: 'المزيد'),
        ],
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/nav_bar_light',
        isDark: false,
        textScale: 1.0,
      );
    });
  });
}
