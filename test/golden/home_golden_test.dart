import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/home/presentation/widgets/home_hero_card.dart';
import 'package:talib_ilm/features/home/presentation/widgets/home_header.dart';
import 'package:talib_ilm/features/home/presentation/widgets/quick_action_button.dart';
import 'package:talib_ilm/features/home/presentation/widgets/continue_learning_card.dart';
import 'package:talib_ilm/features/ilm/data/models/mutun_models.dart';
import 'golden_test_helper.dart';

void main() {
  group('Home Widgets Golden Tests', () {
    testWidgets('HomeHeroCard - light 1.0', (tester) async {
      final widget = HomeHeroCard(
        nextPrayerName: 'الظهر',
        nextPrayerTime: DateTime.now().add(const Duration(hours: 1, minutes: 25)),
        allPrayers: {
          'الفجر': DateTime.now().subtract(const Duration(hours: 6)),
          'الظهر': DateTime.now().add(const Duration(hours: 1, minutes: 25)),
          'العصر': DateTime.now().add(const Duration(hours: 4)),
          'المغرب': DateTime.now().add(const Duration(hours: 7)),
          'العشاء': DateTime.now().add(const Duration(hours: 8, minutes: 30)),
        },
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/home_hero_light_1_0',
        isDark: false,
        textScale: 1.0,
      );
    });

    testWidgets('HomeHeroCard - dark 1.5', (tester) async {
      final widget = HomeHeroCard(
        nextPrayerName: 'العصر',
        nextPrayerTime: DateTime.now().add(const Duration(minutes: 12)),
        allPrayers: {
          'الفجر': DateTime.now().subtract(const Duration(hours: 9)),
          'الظهر': DateTime.now().subtract(const Duration(hours: 3)),
          'العصر': DateTime.now().add(const Duration(minutes: 12)),
          'المغرب': DateTime.now().add(const Duration(hours: 3)),
          'العشاء': DateTime.now().add(const Duration(hours: 4, minutes: 30)),
        },
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/home_hero_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('QuickActionButton - light 1.0 and dark 1.5', (tester) async {
      final widget = Row(
        children: [
          Expanded(
            child: QuickActionButton(
              icon: Icons.menu_book_rounded,
              label: 'القرآن',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: QuickActionButton(
              icon: Icons.auto_stories_rounded,
              label: 'العلم',
              onTap: () {},
            ),
          ),
        ],
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/home_quick_actions_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/home_quick_actions_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('LearningPulseCard - light 1.0', (tester) async {
      final book = IlmBook(
        id: '1',
        title: 'الأصول الثلاثة وأدلتها',
        author: 'محمد بن عبد الوهاب',
        subject: 'العقيدة',
        level: '1',
        description: 'متن في بيان الأصول الثلاثة',
        totalPages: 42,
        shuruh: const [],
      );

      final data = ContinueData(
        book: book,
        tab: 'mutn',
        page: 14,
        total: 42,
        progressPercent: 33,
      );

      final widget = LearningPulseCard(
        data: data,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/home_continue_light_1_0',
        isDark: false,
        textScale: 1.0,
      );
    });

    testWidgets('HomeHeader - light 1.0 and dark 1.5', (tester) async {
      const widget = HomeHeader(
        city: 'مكة المكرمة',
        greeting: 'أصبحنا وأصبح الملك لله',
        greetingSubtitle: 'طاب مسعاك يا طالب العلم',
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/home_header_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/home_header_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });
  });
}
