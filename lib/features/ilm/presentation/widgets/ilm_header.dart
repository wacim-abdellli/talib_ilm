import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

/// Dignified header for the Ilm scholarly library adhering strictly to the Calm Scholar design system.
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          bottom: BorderSide(
            color: palette.border,
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
                      'المكتبة العلمية',
                      style: context.text.title.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      dailyMicrocopy,
                      style: context.text.bodySmall.copyWith(
                        color: palette.textMuted,
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
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: palette.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.collections_bookmark_rounded,
                        size: AppIcon.sm,
                        color: palette.primary,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        '$completedBooksCount/$totalBooksCount مُنجز',
                        style: context.text.caption.copyWith(
                          color: palette.primary,
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
