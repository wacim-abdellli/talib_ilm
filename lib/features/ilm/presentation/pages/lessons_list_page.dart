import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talib_ilm/core/services/progress_service.dart';
import 'package:talib_ilm/core/services/last_activity_service.dart';
import 'package:talib_ilm/features/ilm/data/models/progress_models.dart';
import 'package:talib_ilm/features/ilm/data/models/lesson_model.dart';
import 'package:talib_ilm/shared/widgets/app_popup.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/video_player_page.dart';
import '../../../../shared/widgets/primary_app_bar.dart';

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
    final target = (currentIndex * AppUi.lessonScrollExtent).toDouble();
    _scrollController.animateTo(
      target,
      duration: AppUi.animationScroll,
      curve: Curves.easeOut,
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
    return Scaffold(
      appBar: UnifiedAppBar(
        title: widget.bookTitle,
        showBack: true,
      ),
      body: ListView.separated(
        controller: _scrollController,
        padding: AppUi.screenPaddingCompact,
        itemCount: widget.lessons.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppUi.gapMD),
        itemBuilder: (context, index) {
          final lesson = widget.lessons[index];
          final done = index < _completedLessons;
          final isCurrent =
              !done && _completedLessons < widget.lessons.length &&
                  index == _completedLessons;

          return AnimatedContainer(
            duration: AppUi.animationMedium,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppUi.gapSMPlus,
              vertical: AppUi.gapMD,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.surfaceElevatedGradient,
              borderRadius: BorderRadius.circular(AppUi.radiusMD),
              boxShadow: AppUi.cardShadow,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppUi.radiusMD),
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
              child: Row(
                children: [
                  _LessonIcon(
                    done: done,
                    isCurrent: isCurrent,
                  ),
                  const SizedBox(width: AppUi.gapMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.lessonTitle(index),
                          style: AppText.caption.copyWith(
                            color: AppColors.textPrimary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: AppUi.gapXXS),
                        Text(lesson.title, style: AppText.heading),
                        const SizedBox(height: AppUi.gapXS),
                        Text(
                          AppStrings.lessonDuration(lesson.durationMinutes),
                          style: AppText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppUi.gapSMPlus,
                        vertical: AppUi.gapXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppUi.radiusPill),
                      ),
                      child: Text(
                        AppStrings.lessonNext,
                        style: AppText.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LessonIcon extends StatelessWidget {
  final bool done;
  final bool isCurrent;

  const _LessonIcon({
    required this.done,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Icon(
        Icons.check_circle,
        color: AppColors.primary,
        size: AppUi.iconSizeLG,
      );
    }

    if (isCurrent) {
      return Icon(
        Icons.play_circle_fill,
        color: AppColors.primary,
        size: AppUi.iconSizeXL,
      );
    }

    return Icon(
      Icons.play_circle_outline,
      color: AppColors.textMuted,
      size: AppUi.iconSizeLG,
    );
  }
}
