import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../features/ilm/data/models/lesson_model.dart';

/// Minimalistic, YouTube-grade bottom sheets for playback speed and chapter selection.
class VideoPlayerSheets {
  VideoPlayerSheets._();

  /// Show playback speed selection sheet (adaptive to portrait & landscape)
  static void showSpeedSheet(
    BuildContext context, {
    required double currentSpeed,
    required ValueChanged<double> onSpeedChanged,
  }) {
    final palette = context.palette;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) {
        if (isLandscape) {
          // Minimalist horizontal bar in landscape (zero vertical overflow, leaves video visible)
          return SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.lg,
                AppSpace.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: AppSpace.xl,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.border,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        color: palette.gold,
                        size: AppIcon.sm,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'سرعة التشغيل',
                        style: ctx.text.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'إغلاق',
                        icon: Icon(
                          Icons.close_rounded,
                          size: AppIcon.sm,
                          color: palette.textMuted,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: speeds.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSpace.sm),
                      itemBuilder: (itemCtx, idx) {
                        final speed = speeds[idx];
                        final isSelected = (speed - currentSpeed).abs() < 0.05;
                        final label =
                            speed == 1.0 ? 'عادية (1.0x)' : '${speed}x';

                        return Semantics(
                          button: true,
                          label: label,
                          child: InkWell(
                            borderRadius: AppRadius.pillRadius,
                            onTap: () {
                              onSpeedChanged(speed);
                              Navigator.pop(ctx);
                              HapticFeedback.selectionClick();
                            },
                            child: Container(
                              constraints:
                                  const BoxConstraints(minWidth: 72),
                              padding:
                                  const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.md,
                                vertical: AppSpace.xs,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? palette.primary
                                    : palette.surfaceRaised,
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(
                                  color: isSelected
                                      ? palette.primary
                                      : palette.border,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: ctx.text.caption.copyWith(
                                    color: isSelected
                                        ? palette.onPrimary
                                        : palette.text,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Clean, minimalist list in portrait
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpace.xl,
              AppSpace.md,
              AppSpace.xl,
              AppSpace.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: AppSpace.xl,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      color: palette.gold,
                      size: AppIcon.md,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      'سرعة التشغيل',
                      style: ctx.text.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                ...speeds.map((speed) {
                  final isSelected = (speed - currentSpeed).abs() < 0.05;
                  final label = speed == 1.0 ? 'عادية (1.0x)' : '${speed}x';

                  return Semantics(
                    button: true,
                    label: label,
                    child: InkWell(
                      borderRadius: AppRadius.mdRadius,
                      onTap: () {
                        onSpeedChanged(speed);
                        Navigator.pop(ctx);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.primarySoft
                              : Colors.transparent,
                          borderRadius: AppRadius.mdRadius,
                        ),
                        child: Row(
                          children: [
                            Text(
                              label,
                              style: ctx.text.body.copyWith(
                                color: isSelected
                                    ? palette.primary
                                    : palette.text,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: palette.primary,
                                size: AppIcon.sm,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show interactive chapters list sheet
  static void showChaptersSheet(
    BuildContext context, {
    required List<LessonChapter> chapters,
    required int currentSeconds,
    required ValueChanged<int> onChapterSelected,
  }) {
    final palette = context.palette;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: isLandscape ? 0.85 : 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetContext, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: AppSpace.xl,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: AppRadius.pillRadius,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_bulleted_rounded,
                          color: palette.gold,
                          size: AppIcon.md,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Text(
                          'محاور وموضوعات المقطع',
                          style: ctx.text.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${chapters.length} محاور',
                          style: ctx.text.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: chapters.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: AppSpace.xs),
                        itemBuilder: (itemCtx, idx) {
                          final ch = chapters[idx];
                          final isActive = currentSeconds >= ch.startSeconds &&
                              (idx == chapters.length - 1 ||
                                  currentSeconds <
                                      chapters[idx + 1].startSeconds);

                          return Semantics(
                            button: true,
                            label: '${ch.title} عند ${ch.timestampFormatted}',
                            child: InkWell(
                              borderRadius: AppRadius.mdRadius,
                              onTap: () {
                                onChapterSelected(ch.startSeconds);
                                Navigator.pop(ctx);
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                constraints:
                                    const BoxConstraints(minHeight: 48),
                                padding: const EdgeInsetsDirectional.all(
                                  AppSpace.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? palette.primarySoft
                                      : Colors.transparent,
                                  borderRadius: AppRadius.mdRadius,
                                  border: Border.all(
                                    color: isActive
                                        ? palette.primary.withValues(alpha: 0.5)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                        horizontal: AppSpace.sm,
                                        vertical: AppSpace.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? palette.primary
                                            : palette.surfaceRaised,
                                        borderRadius: AppRadius.smRadius,
                                      ),
                                      child: Text(
                                        ch.timestampFormatted,
                                        style: itemCtx.text.caption.copyWith(
                                          color: isActive
                                              ? palette.onPrimary
                                              : palette.gold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpace.md),
                                    Expanded(
                                      child: Text(
                                        ch.title,
                                        style: itemCtx.text.bodySmall.copyWith(
                                          color: isActive
                                              ? palette.primary
                                              : palette.text,
                                          fontWeight: isActive
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isActive)
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        size: AppIcon.sm,
                                        color: palette.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
