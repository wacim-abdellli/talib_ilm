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
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'أبواب الخير',
          padding: EdgeInsetsDirectional.only(bottom: AppSpace.md),
        ),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Icons.menu_book_rounded,
                label: 'القرآن',
                accentColor: palette.gold,
                onTap: onOpenQuran,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: QuickActionButton(
                icon: Icons.auto_stories_rounded,
                label: 'العلم',
                accentColor: palette.primary,
                onTap: onOpenIlm,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: QuickActionButton(
                icon: Icons.spa_rounded,
                label: 'الأذكار',
                accentColor: palette.prayer('الفجر'),
                onTap: onOpenAdhkar,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: QuickActionButton(
                icon: Icons.explore_rounded,
                label: 'القبلة',
                accentColor: palette.prayer('المغرب'),
                onTap: onOpenQibla,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
