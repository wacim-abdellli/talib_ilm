import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talib_ilm/core/services/progress_service.dart';
import 'package:talib_ilm/core/services/last_activity_service.dart';
import 'package:talib_ilm/features/ilm/data/models/progress_models.dart';
import 'package:talib_ilm/features/ilm/data/models/lesson_model.dart';
import 'package:talib_ilm/shared/widgets/app_popup.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/theme_colors.dart';
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
          final isDark = context.isDark;

          return Container(
            decoration: BoxDecoration(
              color: context.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrent
                    ? context.goldColor.withValues(alpha: 0.5)
                    : context.outlineColor.withValues(
                        alpha: isDark ? 0.12 : 0.08,
                      ),
                width: isCurrent ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCurrent
                      ? context.goldColor.withValues(alpha: isDark ? 0.12 : 0.06)
                      : Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                  blurRadius: isCurrent ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _LessonIcon(
                        done: done,
                        isCurrent: isCurrent,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.lessonTitle(index),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              lesson.title,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: context.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppStrings.lessonDuration(lesson.durationMinutes),
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.goldColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.goldColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            AppStrings.lessonNext,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.goldColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.islamicGreenColor.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle_rounded,
          color: context.islamicGreenColor,
          size: 24,
        ),
      );
    }

    if (isCurrent) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.goldColor.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(
            color: context.goldColor.withValues(alpha: 0.4),
          ),
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          color: context.goldColor,
          size: 26,
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: context.outlineColor.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.play_arrow_outlined,
        color: context.textSecondaryColor,
        size: 22,
      ),
    );
  }
}
