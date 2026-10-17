import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/reader_theme.dart';

/// Dignified header for the Ilm scholarly library.
class IlmHeader extends StatelessWidget {
  final String dailyMicrocopy;
  final int totalBooksCount;
  final int completedBooksCount;

  const IlmHeader({
    super.key,
    required this.dailyMicrocopy,
    this.totalBooksCount = 0,
    this.completedBooksCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: tokens.headerBrown,
        border: Border(
          bottom: BorderSide(
            color: tokens.headerBrown,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المتون والمكتبة',
                      style: context.text.title.copyWith(
                        color: tokens.headerTitle,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      dailyMicrocopy,
                      style: context.text.bodySmall.copyWith(
                        color: tokens.headerSubtitle,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (totalBooksCount > 0)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.rosetteGold.withValues(alpha: 0.2),
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: tokens.rosetteGold.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.collections_bookmark_rounded,
                        size: AppIcon.sm,
                        color: tokens.rosetteGold,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        '$completedBooksCount/$totalBooksCount مُنجز',
                        style: context.text.caption.copyWith(
                          color: tokens.headerTitle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
