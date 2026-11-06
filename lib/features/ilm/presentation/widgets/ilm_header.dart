import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';

/// Dignified header for the Ilm scholarly library adhering strictly to the Calm Scholar design system.
///
/// Features a two-tier layout:
/// - Tier 1: Library title alongside compact offline downloads and reading progress pills.
/// - Tier 2: Dedicated full-width scholarly microcopy banner to avoid horizontal cramming on narrow phones.
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
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isVeryCompact = constraints.maxWidth < 420;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Tier 1: Library Title & Action Pills ──
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'المكتبة العلمية',
                        style: context.text.title.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  if (onDownloadsTap != null) ...[
                    const SizedBox(width: AppSpace.xs),
                    _buildDownloadsButton(
                      context,
                      palette,
                      compact: isVeryCompact,
                    ),
                  ],
                  if (totalBooksCount > 0) ...[
                    const SizedBox(width: AppSpace.xs),
                    _buildStatsButton(
                      context,
                      palette,
                      compact: isVeryCompact,
                    ),
                  ],
                ],
              ),

              // ── Tier 2: Scholarly Wisdom Microcopy (Full Width) ──
              if (dailyMicrocopy.isNotEmpty) ...[
                const SizedBox(height: AppSpace.xs),
                Text(
                  dailyMicrocopy,
                  style: context.text.caption.copyWith(
                    color: palette.textMuted,
                    height: 1.3,
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDownloadsButton(
    BuildContext context,
    AppPalette palette, {
    bool compact = false,
  }) {
    return Tooltip(
      message: 'الكتب والمتون المحفوظة بدون إنترنت',
      child: Semantics(
        button: true,
        label: 'الكتب والمتون المحفوظة بدون إنترنت',
        child: Material(
          color: palette.surfaceMuted,
          borderRadius: AppRadius.pillRadius,
          child: InkWell(
            borderRadius: AppRadius.pillRadius,
            onTap: () {
              HapticFeedback.lightImpact();
              onDownloadsTap?.call();
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSize.tap),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.sm,
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
                    Icons.download_done_rounded,
                    size: AppIcon.xs,
                    color: palette.primary,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'المحمّلات',
                      style: context.text.caption.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsButton(
    BuildContext context,
    AppPalette palette, {
    bool compact = false,
  }) {
    final statsLabel = completedBooksCount > 0
        ? '$completedBooksCount/$totalBooksCount'
        : '$totalBooksCount';

    return Semantics(
      button: true,
      label: 'عرض الكتب المنجزة وقيد المتابعة ($statsLabel)',
      child: Tooltip(
        message: 'الكتب المنجزة: $completedBooksCount من إجمالي $totalBooksCount',
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
                horizontal: AppSpace.sm,
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
                    size: AppIcon.xs,
                    color: palette.primary,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    statsLabel,
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
      ),
    );
  }
}
