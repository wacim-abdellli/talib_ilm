import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
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
    final textTheme = context.text;

    String? progressText;
    if (currentPage != null && currentPage! > 0) {
      if (totalPages != null && totalPages! > 0) {
        progressText = 'وصلت إلى صفحة $currentPage من $totalPages';
      } else {
        progressText = 'وصلت إلى صفحة $currentPage';
      }
    }

    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                // Full title without ellipsis truncation
                Text(
                  title,
                  style: textTheme.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.xs),

                // Metadata: Scholar, Level, and Reader Badges
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xxs,
                  children: [
                    Text(
                      scholar,
                      style: textTheme.bodySmall.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    if (difficulty != null) ...[
                      Text(
                        '•',
                        style: textTheme.caption.copyWith(
                          color: palette.textSubtle,
                        ),
                      ),
                      Text(
                        difficulty!,
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                    if (totalPages != null && totalPages! > 0) ...[
                      Text(
                        '•',
                        style: textTheme.caption.copyWith(
                          color: palette.textSubtle,
                        ),
                      ),
                      Text(
                        '$totalPages صفحة',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                    if (isDigital) ...[
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.xs,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primarySoft,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: palette.primary.withAlpha(60),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: AppIcon.xs,
                              color: palette.primary,
                            ),
                            const SizedBox(width: AppSpace.xxs),
                            Text(
                              'قراءة رقمية',
                              style: textTheme.captionBold.copyWith(
                                color: palette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isLastRead) ...[
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.xs,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.goldSoft,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: palette.gold.withAlpha(80),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: palette.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpace.xxs),
                            Text(
                              'آخر قراءة',
                              style: textTheme.captionBold.copyWith(
                                color: palette.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    description!,
                    style: textTheme.caption.copyWith(
                      color: palette.textSubtle,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (progressText != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    progressText,
                    style: textTheme.captionBold.copyWith(
                      color: palette.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpace.xs),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: AppIcon.xs,
              color: palette.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
