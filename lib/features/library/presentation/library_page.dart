import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المكتبة',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'تصفح كتب العلم الشرعي',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search_rounded, size: 26),
                        color: const Color(0xFF64748B),
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
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'ابحث في الكتب والشروحات...',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF94A3B8),
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
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
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
        gradient: AppColors.surfaceGradient,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.stroke,
          width: AppUi.dividerThickness,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppUi.iconBoxSize,
            height: AppUi.iconBoxSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: radius,
              border: Border.all(
                color: AppColors.stroke,
                width: AppUi.dividerThickness,
              ),
            ),
            child: Icon(level.icon, color: AppColors.textMuted),
          ),
          const SizedBox(width: AppUi.gapMD),
          Expanded(child: Text(level.title, style: AppText.sectionTitle)),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
