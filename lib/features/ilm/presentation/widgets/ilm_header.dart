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
        border: Border(bottom: BorderSide(color: palette.border, width: 1)),
      ),
      child: Row(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          if (onDownloadsTap != null) ...[
            const SizedBox(width: AppSpace.xs),
            _buildDownloadsButton(context, palette),
          ],
          if (totalBooksCount > 0) ...[
            const SizedBox(width: AppSpace.xs),
            _buildStatsButton(context, palette),
          ],
        ],
      ),
    );
  }

  Widget _buildDownloadsButton(BuildContext context, AppPalette palette) {
    return Tooltip(
      message: 'عرض المحتوى المحمّل بدون إنترنت',
      child: Semantics(
        button: true,
        label: 'عرض المحتوى المحمّل بدون إنترنت',
        child: Material(
          color: palette.primarySoft,
          borderRadius: AppRadius.pillRadius,
          child: InkWell(
            borderRadius: AppRadius.pillRadius,
            onTap: () {
              HapticFeedback.lightImpact();
              onDownloadsTap?.call();
            },
            child: Container(
              constraints: const BoxConstraints(
                minWidth: AppSize.tap,
                minHeight: AppSize.tap,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                Icons.offline_pin_rounded,
                size: AppIcon.sm,
                color: palette.onPrimarySoft,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsButton(BuildContext context, AppPalette palette) {
    return Semantics(
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
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: palette.border, width: 1),
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
                  '$completedBooksCount/$totalBooksCount',
                  style: context.text.caption.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
