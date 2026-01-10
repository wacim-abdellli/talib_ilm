import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../../../shared/widgets/app_drawer.dart';

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
      drawer: const AppDrawer(),
      appBar: const UnifiedAppBar(
        title: AppStrings.libraryTitle,
        showMenu: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: ListView(
          padding: AppUi.screenPadding,
          children: [
            _LibraryHeader(),
            const SizedBox(height: AppUi.gapXXL),
            ...levelCards,
          ],
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusLG);

    return Container(
      padding: AppUi.cardPadding,
      decoration: BoxDecoration(
        gradient: AppColors.surfaceElevatedGradient,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.stroke,
          width: AppUi.dividerThickness,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المكتبة',
            style: AppText.heading,
          ),
          const SizedBox(height: AppUi.gapSM),
          Text(
            'منهج متكامل لطالب العلم\nمرتب حسب المستويات',
            style: AppText.bodyMuted,
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
            child: Icon(
              level.icon,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppUi.gapMD),
          Expanded(
            child: Text(
              level.title,
              style: AppText.sectionTitle,
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
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
