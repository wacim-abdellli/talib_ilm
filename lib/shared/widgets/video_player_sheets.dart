import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../features/ilm/data/models/lesson_model.dart';

/// Bottom sheets for playback speed and chapter selection in the video player.
class VideoPlayerSheets {
  VideoPlayerSheets._();

  /// Show playback speed selection sheet
  static void showSpeedSheet(
    BuildContext context, {
    required double currentSpeed,
    required ValueChanged<double> onSpeedChanged,
  }) {
    final palette = context.palette;
    final speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.xl),
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
                const SizedBox(height: AppSpace.lg),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  alignment: WrapAlignment.center,
                  children: speeds.map((speed) {
                    final isSelected = (speed - currentSpeed).abs() < 0.05;
                    return Semantics(
                      button: true,
                      label: '$speed ضعف السرعة',
                      child: InkWell(
                        borderRadius: AppRadius.pillRadius,
                        onTap: () {
                          onSpeedChanged(speed);
                          Navigator.pop(ctx);
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.lg,
                            vertical: AppSpace.sm,
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
                              speed == 1.0 ? 'عادية (1.0x)' : '${speed}x',
                              style: ctx.text.bodySmall.copyWith(
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
                  }).toList(),
                ),
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
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (sheetContext, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xl,
                  vertical: AppSpace.md,
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
                    const SizedBox(height: AppSpace.md),
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
                    const SizedBox(height: AppSpace.md),
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
