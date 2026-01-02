import 'package:flutter/material.dart';
import 'package:talib_ilm/features/ilm/presentation/pages/level_books_page.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../../shared/widgets/app_overflow_menu.dart';
import '../data/models/mutun_models.dart';
import '../data/models/progress_models.dart';

class IlmPage extends StatefulWidget {
  const IlmPage({super.key});

  @override
  State<IlmPage> createState() => _IlmPageState();
}

class _IlmPageState extends State<IlmPage> {
  int _expandedIndex = -1;

  Future<_IlmOverview> _loadOverview() async {
    final program = await AssetService.loadMutunProgram();
    final progress = await ProgressService().getAllProgress();
    final progressMap = {for (final item in progress) item.bookId: item};
    final levels = program.levels
      ..sort((a, b) => a.order.compareTo(b.order));
    return _IlmOverview(levels: levels, progressMap: progressMap);
  }

  _LevelProgress _levelProgress(
    IlmLevel level,
    Map<String, BookProgress> progressMap,
  ) {
    var completed = 0;
    var inProgress = 0;

    for (final book in level.books) {
      final progress = progressMap[book.id];
      if (progress == null) continue;
      if (progress.status == BookProgressStatus.completed ||
          progress.isCompleted) {
        completed += 1;
      } else if (progress.status == BookProgressStatus.inProgress ||
          progress.completedLessons > 0) {
        inProgress += 1;
      }
    }

    return _LevelProgress(
      completed: completed,
      inProgress: inProgress,
      total: level.books.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('العلم', style: AppText.headingXL),
        actions: const [AppOverflowMenu()],
      ),
      body: FutureBuilder<_IlmOverview>(
        future: _loadOverview(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('فشل تحميل المنهج', style: AppText.body),
            );
          }

          final overview = snapshot.data!;
          final levels = overview.levels;

          var previousCompleted = true;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              final levelProgress =
                  _levelProgress(level, overview.progressMap);
              final locked = !previousCompleted;
              previousCompleted =
                  previousCompleted && levelProgress.completed == level.books.length;

              final expanded = _expandedIndex == index;

              return _LevelCard(
                level: level,
                progress: levelProgress,
                locked: locked,
                expanded: expanded,
                onToggle: () {
                  setState(() {
                    _expandedIndex = expanded ? -1 : index;
                  });
                },
                onOpen: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LevelBooksPage(level: level),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final IlmLevel level;
  final _LevelProgress progress;
  final bool locked;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  const _LevelCard({
    required this.level,
    required this.progress,
    required this.locked,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final completion = progress.total == 0
        ? 0.0
        : progress.completed / progress.total;
    final gradient = LinearGradient(
      colors: [
        _tint(AppColors.primary, 0.1),
        _tint(AppColors.primaryAlt, 0.06),
      ],
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          PressableCard(
            onTap: locked
                ? null
                : () {
                    onToggle();
                  },
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ChapterPill(label: 'المستوى ${level.order}'),
                    const SizedBox(width: 8),
                    if (locked)
                      _StatusPill(
                        label: 'مغلق',
                        color: AppColors.textSecondary,
                        icon: Icons.lock_outline,
                      ),
                    if (!locked && progress.completed > 0)
                      _StatusPill(
                        label: 'مكتمل ${progress.completed}',
                        color: AppColors.success,
                        icon: Icons.check,
                      ),
                    if (!locked && progress.inProgress > 0) ...[
                      const SizedBox(width: 8),
                      _StatusPill(
                        label: 'قيد التقدم ${progress.inProgress}',
                        color: AppColors.primary,
                        icon: Icons.play_arrow,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(level.title, style: AppText.heading),
                const SizedBox(height: 6),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Text(
                    level.description,
                    style: AppText.bodyMuted,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: expanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(end: completion),
                                duration:
                                    const Duration(milliseconds: 360),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 6,
                                    backgroundColor: AppColors.textPrimary
                                        .withValues(alpha: 0.08),
                                    valueColor:
                                        const AlwaysStoppedAnimation(
                                            AppColors.primary),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${progress.completed} من ${progress.total} كتب',
                              style: AppText.caption.copyWith(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: onOpen,
                                icon: const Icon(Icons.menu_book_outlined),
                                label: const Text('عرض الكتب'),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (locked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _tint(Color color, double amount) {
    return Color.lerp(AppColors.surface, color, amount) ?? color;
  }
}

class _LevelProgress {
  final int completed;
  final int inProgress;
  final int total;

  const _LevelProgress({
    required this.completed,
    required this.inProgress,
    required this.total,
  });
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusPill({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppText.caption.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChapterPill extends StatelessWidget {
  final String label;

  const _ChapterPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.7),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _IlmOverview {
  final List<IlmLevel> levels;
  final Map<String, BookProgress> progressMap;

  const _IlmOverview({
    required this.levels,
    required this.progressMap,
  });
}
