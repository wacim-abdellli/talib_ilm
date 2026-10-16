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
  final bool isDigital;
  final String? description;

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
    this.isDigital = false,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final metaParts = <String>[
      scholar,
      if (totalPages != null && totalPages! > 0) '$totalPages صفحة',
      if (difficulty != null) difficulty!,
    ];
    final subtitleText = metaParts.join(' • ');

    String? progressText;
    if (currentPage != null && currentPage! > 0) {
      if (totalPages != null && totalPages! > 0) {
        progressText = 'وصلت إلى صفحة $currentPage من $totalPages';
      } else {
        progressText = 'وصلت إلى صفحة $currentPage';
      }
    } else if (isLastRead) {
      progressText = 'آخر قراءة';
    }

    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          IconBadge(
            icon: isDigital ? Icons.auto_stories_rounded : Icons.person_outline,
            bg: isDigital ? palette.primarySoft : null,
            fg: isDigital ? palette.primary : null,
          ),
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
                    if (isDigital) ...[
                      const SizedBox(width: AppSpace.xs),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.xs,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primarySoft,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'قراءة رقمية',
                          style: context.text.caption.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    description!,
                    style: context.text.caption.copyWith(
                      color: palette.textSubtle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
            Icons.chevron_right_rounded,
            size: AppIcon.md,
            color: palette.textSubtle,
          ),
        ],
      ),
    );
  }
}
