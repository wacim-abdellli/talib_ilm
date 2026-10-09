import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';

class SharhCard extends StatelessWidget {
  final String title;
  final String scholar;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int? totalPages;
  final int? currentPage;
  final bool recommended;
  final bool isLastRead;
  final String? difficulty;

  const SharhCard({
    super.key,
    required this.title,
    required this.scholar,
    required this.onTap,
    this.onLongPress,
    this.totalPages,
    this.currentPage,
    this.recommended = false,
    this.isLastRead = false,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    String subtitleText;
    if (totalPages != null && totalPages! > 0) {
      subtitleText = '$totalPages صفحة';
    } else {
      subtitleText = scholar;
      if (difficulty != null) subtitleText += ' • $difficulty';
    }

    String? progressText;
    if (currentPage != null && currentPage! > 0) {
      progressText = 'وصلت إلى صفحة $currentPage';
    } else if (isLastRead) {
      progressText = 'آخر قراءة';
    }

    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          const IconBadge(icon: Icons.person_outline),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: context.text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLastRead) ...[
                      const SizedBox(width: AppSpace.xs),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: palette.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  subtitleText,
                  style: context.text.bodySmall.copyWith(
                    color: palette.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (progressText != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    progressText,
                    style: context.text.caption.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Icon(
            Icons.chevron_left_rounded,
            size: AppIcon.md,
            color: palette.textSubtle,
          ),
        ],
      ),
    );
  }
}
