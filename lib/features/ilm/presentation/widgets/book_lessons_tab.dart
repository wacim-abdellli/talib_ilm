import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/last_activity_service.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_popup.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../../../shared/widgets/video_player_page.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/progress_models.dart';

class BookLessonsTab extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final List<Lesson> lessons;
  final VoidCallback onGoToMutn;

  const BookLessonsTab({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.lessons,
    required this.onGoToMutn,
  });

  @override
  State<BookLessonsTab> createState() => _BookLessonsTabState();
}

class _BookLessonsTabState extends State<BookLessonsTab> {
  final ProgressService _progressService = ProgressService();
  final LastActivityService _lastActivityService = LastActivityService();
  final ScrollController _scrollController = ScrollController();
  int _completedLessons = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final progress = await _progressService.getProgress(widget.bookId);
    if (!mounted) return;
    setState(() {
      _completedLessons = progress?.completedLessons ?? 0;
    });
  }

  Future<void> _toggleLessonStatus(int index) async {
    final isDone = index < _completedLessons;
    final int newCompleted;
    if (isDone) {
      newCompleted = index;
    } else {
      newCompleted = index + 1;
    }

    final total = widget.lessons.length;
    await _progressService.saveProgress(
      BookProgress(
        bookId: widget.bookId,
        status: newCompleted == total
            ? BookProgressStatus.completed
            : BookProgressStatus.inProgress,
        completedLessons: newCompleted,
        totalLessons: total,
      ),
    );

    if (!mounted) return;
    setState(() => _completedLessons = newCompleted);
    HapticFeedback.lightImpact();

    if (newCompleted == total && !isDone) {
      HapticFeedback.selectionClick();
      AppPopup.show(
        context: context,
        title: 'اكتملت جميع الدروس',
        message: AppStrings.lessonProgressSaved,
        icon: Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _openLesson(Lesson lesson) async {
    await _lastActivityService.setLastTab(
      widget.bookId,
      LastActivityService.tabLessons,
    );

    if (!mounted) return;

    final watched = await Navigator.push<bool>(
      context,
      buildFadeRoute(
        page: VideoPlayerPage(
          title: lesson.title,
          videoId: lesson.videoId,
          scholar: lesson.scholar,
        ),
      ),
    );

    if (watched == true && lesson.index >= _completedLessons) {
      await _toggleLessonStatus(lesson.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (widget.lessons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: AppEmptyState(
            icon: Icons.ondemand_video_outlined,
            title: AppStrings.bookLessonsEmptyTitle,
            subtitle: AppStrings.bookLessonsEmptyMessage,
            action: AppButton(
              label: AppStrings.bookLessonsEmptyAction,
              onPressed: widget.onGoToMutn,
            ),
          ),
        ),
      );
    }

    final totalLessons = widget.lessons.length;
    final progressFraction = totalLessons > 0
        ? (_completedLessons / totalLessons).clamp(0.0, 1.0)
        : 0.0;
    final scholarName = widget.lessons.first.scholar;

    return Column(
      children: [
        // ── Scholarly Curriculum Header ──
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpace.xl,
            AppSpace.lg,
            AppSpace.xl,
            0,
          ),
          child: AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          Text(
                            scholarName != null && scholarName.isNotEmpty
                                ? 'شرح $scholarName'
                                : 'الدروس العلمية المصورة',
                            style: context.text.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpace.xxs),
                          Text(
                            _completedLessons == 0
                                ? '$totalLessons درساً منهجياً معتمداً'
                                : 'أتممت $_completedLessons من أصل $totalLessons درساً',
                            style: context.text.bodySmall.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: _completedLessons == totalLessons
                            ? palette.success.withValues(alpha: 0.15)
                            : palette.goldSoft,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        '${(progressFraction * 100).toInt()}%',
                        style: context.text.caption.copyWith(
                          color: _completedLessons == totalLessons
                              ? palette.success
                              : palette.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                ClipRRect(
                  borderRadius: AppRadius.pillRadius,
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 6,
                    backgroundColor: palette.surfaceRaised,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _completedLessons == totalLessons
                          ? palette.success
                          : palette.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpace.sm),

        // ── Lessons List ──
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsetsDirectional.all(AppSpace.xl),
            itemCount: widget.lessons.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpace.md),
            itemBuilder: (context, index) {
              final lesson = widget.lessons[index];
              final isDone = index < _completedLessons;
              final isCurrent = !isDone && index == _completedLessons;

              return AppCard(
                onTap: () => _openLesson(lesson),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.md,
                ),
                child: Row(
                  children: [
                    // Lesson Number / Done Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDone
                            ? palette.success.withValues(alpha: 0.15)
                            : (isCurrent
                                ? palette.primarySoft
                                : palette.surfaceRaised),
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(
                          color: isCurrent
                              ? palette.primary.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(
                                Icons.check_rounded,
                                size: AppIcon.md,
                                color: palette.success,
                              )
                            : Text(
                                '${index + 1}',
                                style: context.text.titleSmall.copyWith(
                                  color: isCurrent
                                      ? palette.primary
                                      : palette.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: AppSpace.md),

                    // Lesson Title & Meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: context.text.body.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isDone ? palette.textMuted : palette.text,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: AppIcon.sm,
                                color: palette.textSubtle,
                              ),
                              const SizedBox(width: AppSpace.xxs),
                              Text(
                                '${lesson.durationMinutes} دقيقة',
                                style: context.text.caption.copyWith(
                                  color: palette.textSubtle,
                                ),
                              ),
                              if (lesson.scholar != null &&
                                  lesson.scholar!.isNotEmpty) ...[
                                const SizedBox(width: AppSpace.sm),
                                Flexible(
                                  child: Text(
                                    '•  ${lesson.scholar}',
                                    style: context.text.caption.copyWith(
                                      color: palette.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpace.xs),

                    // Completion Toggle Button
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color: isDone ? palette.success : palette.textSubtle,
                        size: AppIcon.md,
                      ),
                      tooltip: isDone ? 'إلغاء التحديد' : 'تحديد كمكتمل',
                      onPressed: () => _toggleLessonStatus(index),
                    ),

                    // Play Video Action
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.play_circle_fill_rounded,
                        color: palette.primary,
                        size: AppIcon.md,
                      ),
                      tooltip: 'مشاهدة الدرس',
                      onPressed: () => _openLesson(lesson),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
