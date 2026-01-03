import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talib_ilm/core/services/progress_service.dart';
import 'package:talib_ilm/core/services/last_activity_service.dart';
import 'package:talib_ilm/features/ilm/data/models/progress_models.dart';
import 'package:talib_ilm/features/ilm/data/models/lesson_model.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/video_player_page.dart';
import '../../../../shared/widgets/primary_app_bar.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/models/favorite_item.dart';

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

class _LessonsListPageState extends State<LessonsListPage>
    with SingleTickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  final LastActivityService _lastActivityService = LastActivityService();
  final FavoritesService _favoritesService = FavoritesService();
  final ScrollController _scrollController = ScrollController();
  int _completedLessons = 0;
  Set<String> _favoriteLessonIds = {};
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _loadProgress();
    _loadFavorites();
    _lastActivityService.setLastTab(
      widget.bookId,
      LastActivityService.tabLessons,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    final target = (currentIndex * 96).toDouble();
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, color: AppColors.textPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'تم حفظ التقدم',
                style: AppText.body.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _loadFavorites() async {
    final ids = await _favoritesService.getIdsByType(FavoriteType.lesson);
    if (!mounted) return;
    setState(() => _favoriteLessonIds = ids);
  }

  String _favoriteId(Lesson lesson) {
    return '${widget.bookId}:${lesson.index}';
  }

  Future<void> _toggleFavorite(Lesson lesson) async {
    final id = _favoriteId(lesson);
    final saved = await _favoritesService.toggle(
      FavoriteItem(
        type: FavoriteType.lesson,
        id: id,
        title: lesson.title,
        subtitle: widget.bookTitle,
      ),
    );
    if (!mounted) return;
    setState(() {
      if (saved) {
        _favoriteLessonIds.add(id);
      } else {
        _favoriteLessonIds.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: widget.bookTitle,
        showBack: true,
      ),
      body: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: widget.lessons.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lesson = widget.lessons[index];
          final done = index < _completedLessons;
          final isCurrent =
              !done && _completedLessons < widget.lessons.length &&
                  index == _completedLessons;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppUi.cardShadow,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
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
                    pulse: _pulseController,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الدرس ${index + 1}',
                          style: AppText.caption.copyWith(
                            color: AppColors.textPrimary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(lesson.title, style: AppText.heading),
                        const SizedBox(height: 4),
                        Text(
                          '⏱ ${lesson.durationMinutes} دقيقة',
                          style: AppText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'المفضلة',
                    onPressed: () => _toggleFavorite(lesson),
                    icon: Icon(
                      _favoriteLessonIds.contains(_favoriteId(lesson))
                          ? Icons.star
                          : Icons.star_border,
                      color: _favoriteLessonIds.contains(_favoriteId(lesson))
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'التالي',
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
  final Animation<double> pulse;

  const _LessonIcon({
    required this.done,
    required this.isCurrent,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Icon(
        Icons.check_circle,
        color: AppColors.primary,
        size: 24,
      );
    }

    if (isCurrent) {
      return AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final scale = 0.95 + (pulse.value * 0.1);
          return Transform.scale(scale: scale, child: child);
        },
        child: Icon(
          Icons.play_circle_fill,
          color: AppColors.primary,
          size: 28,
        ),
      );
    }

    return Icon(
      Icons.play_circle_outline,
      color: AppColors.textMuted,
      size: 24,
    );
  }
}
