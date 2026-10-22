import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../features/ilm/data/models/lesson_model.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'icon_badge.dart';

/// Detailed information, chapters, and playlist navigation below the video player.
class LessonDetailsSection extends StatelessWidget {
  final String title;
  final String? scholar;
  final int? startSeconds;
  final Duration sectionDuration;
  final Duration position;
  final List<LessonChapter>? chapters;
  final List<Lesson>? playlistLessons;
  final int? currentLessonIndex;
  final bool isLessonCompleted;
  final VoidCallback onToggleCompleted;
  final VoidCallback onOpenInYouTube;
  final VoidCallback onShowChaptersSheet;
  final ValueChanged<int> onChapterSelected;
  final ValueChanged<int>? onLessonSelected;

  const LessonDetailsSection({
    super.key,
    required this.title,
    this.scholar,
    this.startSeconds,
    required this.sectionDuration,
    required this.position,
    this.chapters,
    this.playlistLessons,
    this.currentLessonIndex,
    required this.isLessonCompleted,
    required this.onToggleCompleted,
    required this.onOpenInYouTube,
    required this.onShowChaptersSheet,
    required this.onChapterSelected,
    this.onLessonSelected,
  });

  static String _formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final remM = m % 60;
      return '${h.toString().padLeft(2, '0')}:${remM.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isSegmented = startSeconds != null;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title ──
          Text(
            title,
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpace.sm),

          // ── Scholar & Meta Row ──
          Row(
            children: [
              IconBadge(
                icon: Icons.school_rounded,
                bg: palette.primarySoft,
                fg: palette.primary,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            scholar ?? 'شرح المتن العلمي',
                            style: textTheme.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: palette.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Icon(
                          Icons.verified_rounded,
                          size: AppIcon.xs,
                          color: palette.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      isSegmented
                          ? 'مقطع دراسي مركّز (${_formatTime(sectionDuration)})'
                          : 'المدة الإجمالية: ${_formatTime(sectionDuration)}',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.lg),

          // ── Action Buttons Row ──
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: isLessonCompleted
                      ? 'تم إنجاز الدرس ✓'
                      : 'تحديد الدرس كمكتمل',
                  icon: isLessonCompleted
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  size: AppButtonSize.md,
                  variant: isLessonCompleted
                      ? AppButtonVariant.tonal
                      : AppButtonVariant.primary,
                  onPressed: onToggleCompleted,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              IconButton.filledTonal(
                tooltip: 'فتح في تطبيق يوتيوب',
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: AppIcon.md,
                  color: palette.text,
                ),
                onPressed: onOpenInYouTube,
              ),
            ],
          ),

          // ── Interactive Chapters Card ──
          if (chapters != null && chapters!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            AppCard(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.segment_rounded,
                        color: palette.gold,
                        size: AppIcon.sm,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'محاور وموضوعات المقطع',
                        style: textTheme.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onShowChaptersSheet,
                        child: Text(
                          'عرض الكل',
                          style: textTheme.caption.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  ...chapters!.take(4).map((ch) {
                    final isCurrentChapter = position.inSeconds >=
                            ch.startSeconds &&
                        (ch.endSeconds == null ||
                            position.inSeconds < ch.endSeconds!);

                    return Semantics(
                      button: true,
                      label: '${ch.title} عند ${ch.timestampFormatted}',
                      child: InkWell(
                        borderRadius: AppRadius.smRadius,
                        onTap: () => onChapterSelected(ch.startSeconds),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: AppSpace.xs,
                            horizontal: AppSpace.xs,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.xs,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentChapter
                                      ? palette.goldSoft
                                      : palette.surfaceRaised,
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Text(
                                  ch.timestampFormatted,
                                  style: textTheme.caption.copyWith(
                                    color: isCurrentChapter
                                        ? palette.gold
                                        : palette.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: Text(
                                  ch.title,
                                  style: textTheme.bodySmall.copyWith(
                                    color: isCurrentChapter
                                        ? palette.primary
                                        : palette.text,
                                    fontWeight: isCurrentChapter
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrentChapter)
                                Icon(
                                  Icons.play_arrow_rounded,
                                  size: AppIcon.xs,
                                  color: palette.primary,
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
          ],

          // ── Next Lessons in Playlist ──
          if (playlistLessons != null && playlistLessons!.length > 1) ...[
            const SizedBox(height: AppSpace.lg),
            Text(
              'الدروس التالية في هذا المتن',
              style: textTheme.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            ...playlistLessons!
                .where((l) => l.index != currentLessonIndex)
                .take(3)
                .map((nextLesson) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
                child: AppCard(
                  onTap: () {
                    if (onLessonSelected != null) {
                      onLessonSelected!(nextLesson.index);
                    }
                  },
                  padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: palette.surfaceRaised,
                          borderRadius: AppRadius.smRadius,
                        ),
                        child: Center(
                          child: Text(
                            '${nextLesson.index + 1}',
                            style: textTheme.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: palette.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextLesson.title,
                              style: textTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${nextLesson.durationMinutes} دقيقة',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.play_circle_outline_rounded,
                        color: palette.primary,
                        size: AppIcon.md,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Fallback view shown if the video cannot be embedded or has a platform view error.
class VideoPlayerFallbackView extends StatelessWidget {
  final String title;
  final String? scholar;
  final VoidCallback onOpenInYouTube;
  final VoidCallback onComplete;

  const VideoPlayerFallbackView({
    super.key,
    required this.title,
    this.scholar,
    required this.onOpenInYouTube,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: 'رجوع',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.xl),
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: palette.border, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Icon(
                    Icons.play_circle_filled_rounded,
                    color: palette.gold,
                    size: AppIcon.xl,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (scholar != null && scholar!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    scholar!,
                    textAlign: TextAlign.center,
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.md),
                Text(
                  'هذا الدرس متاح للمشاهدة المباشرة عبر تطبيق يوتيوب ضمن السلسلة العلمية المعتمدة.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall.copyWith(
                    color: palette.textMuted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  label: 'فتح ومشاهدة الدرس في يوتيوب',
                  icon: Icons.open_in_new_rounded,
                  size: AppButtonSize.md,
                  onPressed: onOpenInYouTube,
                ),
                const SizedBox(height: AppSpace.sm),
                AppButton(
                  label: 'تحديد الدرس كمكتمل',
                  variant: AppButtonVariant.tonal,
                  icon: Icons.check_circle_outline_rounded,
                  size: AppButtonSize.md,
                  onPressed: onComplete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
