import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/section_header.dart';
import 'quick_action_button.dart';

class HomeQuickActions extends StatelessWidget {
  final VoidCallback onOpenQuran;
  final VoidCallback onOpenIlm;
  final VoidCallback onOpenAdhkar;
  final VoidCallback onOpenQibla;

  const HomeQuickActions({
    super.key,
    required this.onOpenQuran,
    required this.onOpenIlm,
    required this.onOpenAdhkar,
    required this.onOpenQibla,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'الأقسام',
          padding: EdgeInsetsDirectional.only(bottom: AppSpace.md),
        ),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Icons.menu_book_rounded,
                label: 'القرآن',
                onTap: onOpenQuran,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: QuickActionButton(
                icon: Icons.auto_stories_rounded,
                label: 'العلم',
                onTap: onOpenIlm,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: QuickActionButton(
                icon: Icons.spa_rounded,
                label: 'الأذكار',
                onTap: onOpenAdhkar,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: QuickActionButton(
                icon: Icons.explore_rounded,
                label: 'القبلة',
                onTap: onOpenQibla,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
