import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/pressable_card.dart';

class SharhCard extends StatelessWidget {
  final String title;
  final String scholar;
  final bool recommended;
  final bool isLastRead;
  final String? difficulty;
  final VoidCallback onTap;

  const SharhCard({
    super.key,
    required this.title,
    required this.scholar,
    required this.onTap,
    this.recommended = false,
    this.isLastRead = false,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _badgeText();
    final radius = BorderRadius.circular(AppUi.radiusMD);

    return PressableCard(
      onTap: onTap,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.heading),
          const SizedBox(height: AppUi.gapSM),
          Text(scholar, style: AppText.bodyMuted),
          if (badge != null || difficulty != null) ...[
            const SizedBox(height: AppUi.gapSM),
            Wrap(
              spacing: AppUi.gapSM,
              runSpacing: AppUi.gapXS,
              children: [
                if (badge != null) _Badge(text: badge),
                if (difficulty != null) _Badge(text: difficulty!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _badgeText() {
    if (isLastRead) return AppStrings.lastReadSharhBadge;
    if (recommended) return AppStrings.recommendedBadge;
    return null;
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppUi.gapSMPlus,
        vertical: AppUi.gapXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppUi.radiusPill),
        border: Border.all(
          color: AppColors.stroke,
          width: AppUi.dividerThickness,
        ),
      ),
      child: Text(
        text,
        style: AppText.caption,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
