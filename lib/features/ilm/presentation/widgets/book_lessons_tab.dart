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
import '../../data/catalogs/mutun_lessons_catalog.dart';
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
  String? _selectedScholar;

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

    final displayLessons = _selectedScholar == null
        ? widget.lessons
        : widget.lessons.where((l) => l.scholar == _selectedScholar).toList();

    final watched = await Navigator.push<bool>(
      context,
      buildFadeRoute(
        page: VideoPlayerPage(
          title: lesson.title,
          videoId: lesson.videoId,
          scholar: lesson.scholar,
          playlistId: lesson.playlistId,
          startSeconds: lesson.startSeconds,
          endSeconds: lesson.endSeconds,
          chapters: lesson.chapters,
          playlistLessons: displayLessons,
          currentLessonIndex: lesson.index,
          onLessonSelected: (newIdx) {
            final nextLesson = displayLessons.firstWhere(
              (l) => l.index == newIdx,
              orElse: () => lesson,
            );
            Navigator.pop(context);
            _openLesson(nextLesson);
          },
        ),
      ),
    );

    if (watched == true && lesson.index >= _completedLessons) {
      await _toggleLessonStatus(lesson.index);
    }
  }

  void _openFullPlaylist(String playlistId, String scholar) {
    Navigator.push(
      context,
      buildFadeRoute(
        page: VideoPlayerPage(
          title: 'قائمة تشغيل: $scholar',
          videoId: playlistId,
          scholar: scholar,
          playlistId: playlistId,
        ),
      ),
    );
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

    final scholars = MutunLessonsCatalog.getScholarsForBook(widget.bookId);
    final displayLessons = _selectedScholar == null
        ? widget.lessons
        : widget.lessons.where((l) => l.scholar == _selectedScholar).toList();

    final totalLessons = widget.lessons.length;
    final progressFraction = totalLessons > 0
        ? (_completedLessons / totalLessons).clamp(0.0, 1.0)
        : 0.0;
    final headerScholar = _selectedScholar ?? (scholars.isNotEmpty ? scholars.first : widget.lessons.first.scholar);
    final activePlaylistId = _selectedScholar != null
        ? MutunLessonsCatalog.getPlaylistForScholar(widget.bookId, _selectedScholar!)
        : (widget.lessons.first.playlistId);

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
                            headerScholar != null && headerScholar.isNotEmpty
                                ? 'شرح $headerScholar'
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

        // ── Scholars Selector Chips (When Multiple Scholars Available) ──
        if (scholars.length > 1) ...[
          const SizedBox(height: AppSpace.sm),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.xl,
            ),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('جميع الشروح'),
                    selected: _selectedScholar == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedScholar = null);
                    },
                    selectedColor: palette.primarySoft,
                    labelStyle: context.text.caption.copyWith(
                      color: _selectedScholar == null
                          ? palette.primary
                          : palette.textMuted,
                      fontWeight: _selectedScholar == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: palette.surfaceRaised,
                    side: BorderSide(
                      color: _selectedScholar == null
                          ? palette.primary
                          : palette.border,
                      width: 1,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  ...scholars.map((scholar) {
                    final isSelected = _selectedScholar == scholar;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                      child: ChoiceChip(
                        label: Text(scholar),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedScholar = selected ? scholar : null);
                        },
                        selectedColor: palette.primarySoft,
                        labelStyle: context.text.caption.copyWith(
                          color: isSelected ? palette.primary : palette.textMuted,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: palette.surfaceRaised,
                        side: BorderSide(
                          color: isSelected ? palette.primary : palette.border,
                          width: 1,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],

        // ── Playlist Shortcut Button ──
        if (activePlaylistId != null && activePlaylistId.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.xl,
            ),
            child: Semantics(
              button: true,
              label: 'مشاهدة قائمة التشغيل الكاملة',
              child: InkWell(
                onTap: () => _openFullPlaylist(
                  activePlaylistId,
                  headerScholar ?? widget.bookTitle,
                ),
                borderRadius: AppRadius.mdRadius,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: palette.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.playlist_play_rounded,
                        color: palette.gold,
                        size: AppIcon.md,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          'تشغيل قائمة السلسلة كاملة على يوتيوب (${headerScholar ?? 'الشرح'})',
                          style: context.text.caption.copyWith(
                            color: palette.gold,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: palette.gold,
                        size: AppIcon.xs,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpace.sm),

        // ── Lessons List ──
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsetsDirectional.all(AppSpace.xl),
            itemCount: displayLessons.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpace.md),
            itemBuilder: (context, index) {
              final lesson = displayLessons[index];
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
                              if (lesson.isSegment &&
                                  lesson.formattedTimeRange != null) ...[
                                const SizedBox(width: AppSpace.xs),
                                Container(
                                  padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: AppSpace.xs,
                                    vertical: AppSpace.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.goldSoft,
                                    borderRadius: AppRadius.smRadius,
                                  ),
                                  child: Text(
                                    lesson.formattedTimeRange!,
                                    style: context.text.caption.copyWith(
                                      color: palette.gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
