import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talib_ilm/core/services/last_activity_service.dart';
import 'package:talib_ilm/core/services/progress_service.dart';
import 'package:talib_ilm/features/ilm/data/models/lesson_model.dart';
import 'package:talib_ilm/features/ilm/data/models/progress_models.dart';
import 'package:talib_ilm/shared/widgets/app_popup.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/primary_app_bar.dart';
import '../../../../shared/widgets/video_player_page.dart';

class LessonsListPage extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final List<Lesson> lessons;

  const LessonsListPage({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.lessons,
  });

  @override
  State<LessonsListPage> createState() => _LessonsListPageState();
}

class _LessonsListPageState extends State<LessonsListPage> {
  final ProgressService _progressService = ProgressService();
  final LastActivityService _lastActivityService = LastActivityService();
  final ScrollController _scrollController = ScrollController();
  int _completedLessons = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _lastActivityService.setLastTab(
      widget.bookId,
      LastActivityService.tabLessons,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final progress = await _progressService.getProgress(widget.bookId);

    if (!mounted) return;
    setState(() => _completedLessons = progress?.completedLessons ?? 0);
    _scrollToCurrent();
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) return;
    final currentIndex = _currentIndex();
    if (currentIndex == null) return;
    const itemExtent = 84.0;
    final target = (currentIndex * itemExtent).toDouble();
    _scrollController.animateTo(
      target,
      duration: AppMotion.base,
      curve: AppMotion.easeIn,
    );
  }

  int? _currentIndex() {
    if (_completedLessons >= widget.lessons.length) return null;
    return _completedLessons;
  }

  Future<void> _completeLesson(int index) async {
    if (index < _completedLessons) return;

    final completed = index + 1;
    final total = widget.lessons.length;

    await _progressService.saveProgress(
      BookProgress(
        bookId: widget.bookId,
        status: completed == total
            ? BookProgressStatus.completed
            : BookProgressStatus.inProgress,
        completedLessons: completed,
        totalLessons: total,
      ),
    );

    if (!mounted) return;

    setState(() => _completedLessons = completed);

    if (completed == total) {
      HapticFeedback.selectionClick();

      AppPopup.show(
        context: context,
        title: 'اكتملت الدروس',
        message: AppStrings.lessonProgressSaved,
        icon: Icons.check_circle_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      appBar: UnifiedAppBar(
        title: widget.bookTitle,
        showBack: true,
      ),
      body: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpace.xl),
        itemCount: widget.lessons.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpace.md),
        itemBuilder: (context, index) {
          final lesson = widget.lessons[index];
          final done = index < _completedLessons;
          final isCurrent = !done &&
              _completedLessons < widget.lessons.length &&
              index == _completedLessons;

          return AppCard(
            onTap: () async {
              await _lastActivityService.setLastTab(
                widget.bookId,
                LastActivityService.tabLessons,
              );
              if (!context.mounted) return;
              final watched = await Navigator.push<bool>(
                context,
                buildFadeRoute(
                  page: VideoPlayerPage(
                    title: lesson.title,
                    videoId: lesson.videoId,
                  ),
                ),
              );

              if (watched == true) {
                await _completeLesson(index);
              }
            },
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                _LessonBadge(done: done, isCurrent: isCurrent),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.lessonTitle(index),
                        style: context.text.caption.copyWith(
                          color: palette.textSubtle,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        lesson.title,
                        style: context.text.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: AppIcon.sm,
                            color: palette.textMuted,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            AppStrings.lessonDuration(lesson.durationMinutes),
                            style: context.text.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: AppSpace.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      AppStrings.lessonNext,
                      style: context.text.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.gold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LessonBadge extends StatelessWidget {
  final bool done;
  final bool isCurrent;

  const _LessonBadge({
    required this.done,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (done) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: palette.primarySoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle_rounded,
          color: palette.primary,
          size: AppIcon.md,
        ),
      );
    }

    if (isCurrent) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: palette.goldSoft,
          shape: BoxShape.circle,
          border: Border.all(
            color: palette.gold,
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          color: palette.gold,
          size: AppIcon.lg,
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.play_arrow_outlined,
        color: palette.textMuted,
        size: AppIcon.md,
      ),
    );
  }
}
