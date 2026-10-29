import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';

/// Dignified header for the Ilm scholarly library adhering strictly to the Calm Scholar design system.
class IlmHeader extends StatelessWidget {
  final String dailyMicrocopy;
  final int totalBooksCount;
  final int completedBooksCount;
  final VoidCallback? onStatsTap;
  final VoidCallback? onDownloadsTap;

  const IlmHeader({
    super.key,
    required this.dailyMicrocopy,
    this.totalBooksCount = 0,
    this.completedBooksCount = 0,
    this.onStatsTap,
    this.onDownloadsTap,
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
              if (onDownloadsTap != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                  child: Semantics(
                    button: true,
                    label: 'عرض المحتوى المحمّل بدون إنترنت',
                    child: Material(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.pillRadius,
                      child: InkWell(
                        borderRadius: AppRadius.pillRadius,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onDownloadsTap?.call();
                        },
                        child: Container(
                          padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: palette.gold.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.offline_pin_rounded,
                            size: AppIcon.sm,
                            color: palette.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (totalBooksCount > 0)
                Semantics(
                  button: true,
                  label: 'عرض الكتب المنجزة وقيد المتابعة',
                  child: Material(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.pillRadius,
                    child: InkWell(
                      borderRadius: AppRadius.pillRadius,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onStatsTap?.call();
                      },
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.xs,
                        ),
                        decoration: BoxDecoration(
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
                            const SizedBox(width: AppSpace.xxs),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: AppIcon.sm,
                              color: palette.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
