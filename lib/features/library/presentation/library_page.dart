import 'package:flutter/material.dart';

import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../shared/widgets/pressable_card.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = <LibraryLevel>[
      LibraryLevel(
        title: 'طالب العلم',
        icon: Icons.school_outlined,
        onTap: () {},
      ),
      LibraryLevel(
        title: 'المستوى التمهيدي',
        icon: Icons.layers_outlined,
        onTap: () {},
      ),
      LibraryLevel(
        title: 'المستوى الأول',
        icon: Icons.looks_one_outlined,
        onTap: () {},
      ),
      LibraryLevel(
        title: 'المستوى الثاني',
        icon: Icons.looks_two_outlined,
        onTap: () {},
      ),
      LibraryLevel(
        title: 'المستوى الثالث',
        icon: Icons.looks_3_outlined,
        onTap: () {},
      ),
    ];
    final levelCards = <Widget>[];
    for (var i = 0; i < levels.length; i++) {
      levelCards.add(_LibraryLevelCard(levels[i]));
      if (i != levels.length - 1) {
        levelCards.add(const SizedBox(height: AppUi.gapXL));
      }
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(
                bottom: BorderSide(color: context.borderColor, width: 1),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.library_books_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المكتبة',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'تصفح كتب العلم الشرعي',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textSecondaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search_rounded, size: 26),
                        color: context.textSecondaryColor,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceSecondaryColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.borderColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: context.textTertiaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ابحث في الكتب والشروحات...',
                            style: TextStyle(
                              fontSize: 15,
                              color: context.textTertiaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: context.backgroundColor,
              child: ListView(
                padding: AppUi.screenPadding,
                children: [...levelCards],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryLevelCard extends StatelessWidget {
  final LibraryLevel level;

  const _LibraryLevelCard(this.level);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusMD);

    return PressableCard(
      onTap: level.onTap,
      padding: AppUi.cardPadding,
      borderRadius: radius,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: radius,
        border: Border.all(
          color: context.borderColor,
          width: AppUi.dividerThickness,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppUi.iconBoxSize,
            height: AppUi.iconBoxSize,
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: radius,
              border: Border.all(
                color: context.borderColor,
                width: AppUi.dividerThickness,
              ),
            ),
            child: Icon(level.icon, color: context.textSecondaryColor),
          ),
          const SizedBox(width: AppUi.gapMD),
          Expanded(
            child: Text(
              level.title,
              style: AppText.sectionTitle.copyWith(
                color: context.textPrimaryColor,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: context.textSecondaryColor),
        ],
      ),
    );
  }
}

class LibraryLevel {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const LibraryLevel({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
