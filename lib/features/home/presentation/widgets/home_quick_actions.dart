import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';
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
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    context.primaryColor,
                    context.goldColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'الأقسام',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Responsive Grid Layout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Holy Quran (Gold)
            Expanded(
              child: QuickActionButton(
                icon: Icons.menu_book_rounded,
                label: 'القرآن',
                onTap: onOpenQuran,
                accentColor: AppColors.jewelQuran,
              ),
            ),

            const SizedBox(width: 10),

            // 2. Ilm / Mutun (Teal)
            Expanded(
              child: QuickActionButton(
                icon: Icons.auto_stories_rounded,
                label: 'العلم',
                onTap: onOpenIlm,
                accentColor: AppColors.jewelIlm,
              ),
            ),

            const SizedBox(width: 10),

            // 3. Adhkar (Emerald)
            Expanded(
              child: QuickActionButton(
                icon: Icons.spa_rounded,
                label: 'الأذكار',
                onTap: onOpenAdhkar,
                accentColor: AppColors.jewelAdhkar,
              ),
            ),

            const SizedBox(width: 10),

            // 4. Qibla (Azure)
            Expanded(
              child: QuickActionButton(
                icon: Icons.explore_rounded,
                label: 'القبلة',
                onTap: onOpenQibla,
                accentColor: AppColors.jewelQibla,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
