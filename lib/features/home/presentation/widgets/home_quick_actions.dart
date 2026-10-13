import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/section_header.dart';
import 'quick_action_button.dart';

class HomeQuickActions extends StatelessWidget {
  final VoidCallback onOpenQuran;
  final VoidCallback onOpenIlm;
  final VoidCallback onOpenAdhkar;
  final VoidCallback onOpenQibla;
  final VoidCallback onOpenRadio;

  const HomeQuickActions({
    super.key,
    required this.onOpenQuran,
    required this.onOpenIlm,
    required this.onOpenAdhkar,
    required this.onOpenQibla,
    required this.onOpenRadio,
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
        const SizedBox(height: AppSpace.md),
        // Live Quran Radio Tile
        InkWell(
          onTap: onOpenRadio,
          borderRadius: AppRadius.mdRadius,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSize.buttonH),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Icon(
                    Icons.radio_rounded,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إذاعة القرآن الكريم',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: palette.text,
                          fontFamily: AppTextStyles.cairo,
                        ),
                      ),
                      Text(
                        'بث مباشر 24/7 لكبار القراء والتفاسير',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: palette.textMuted,
                          fontFamily: AppTextStyles.cairo,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: palette.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
