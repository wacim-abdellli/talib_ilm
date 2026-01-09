import 'package:flutter/material.dart';
import 'package:talib_ilm/features/ilm/presentation/pages/level_books_page.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
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

  void _reload() {
    setState(() {});
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
      drawer: const AppDrawer(),
      appBar: UnifiedAppBar(
        title: AppStrings.ilmTitle,
        showMenu: true,
      ),
      body: FutureBuilder<_IlmOverview>(
        future: _loadOverview(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: AppStrings.ilmLoadErrorTitle,
              message: AppStrings.ilmLoadErrorMessage,
              actionLabel: AppStrings.actionRetry,
              onAction: _reload,
            );
          }

          final overview = snapshot.data!;
          final levels = overview.levels;

          var previousCompleted = true;

          return ListView.builder(
            padding: AppUi.screenPadding,
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
                    buildFadeRoute(page: LevelBooksPage(level: level)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUi.gapXL),
      child: Stack(
        children: [
          PressableCard(
            onTap: locked
                ? null
                : () {
                    onToggle();
                  },
            padding: AppUi.cardPadding,
            borderRadius: BorderRadius.circular(AppUi.radiusMD),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppUi.radiusMD),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ChapterPill(label: AppStrings.levelLabel(level.order)),
                    const SizedBox(width: AppUi.gapSM),
                    if (locked)
                      _StatusPill(
                        label: AppStrings.levelClosed,
                        color: AppColors.textMuted,
                        icon: Icons.lock_outline,
                      ),
                    if (!locked && progress.completed > 0)
                      _StatusPill(
                        label: AppStrings.levelCompleted(progress.completed),
                        color: AppColors.primary,
                        icon: Icons.check,
                      ),
                    if (!locked && progress.inProgress > 0) ...[
                      const SizedBox(width: AppUi.gapSM),
                      _StatusPill(
                        label: AppStrings.levelInProgress(progress.inProgress),
                        color: AppColors.primary,
                        icon: Icons.play_arrow,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppUi.gapMD),
                Text(level.title, style: AppText.heading),
                const SizedBox(height: AppUi.gapSM),
                AnimatedCrossFade(
                  duration: AppUi.animationMedium,
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
                  duration: AppUi.animationMedium,
                  curve: Curves.easeOut,
                  child: expanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppUi.gapLG),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppUi.radiusPill),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(end: completion),
                                duration: AppUi.animationSlow,
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: AppUi.progressBarHeight,
                                    backgroundColor: AppColors.textPrimary
                                        .withValues(alpha: 0.08),
                                    valueColor:
                                        const AlwaysStoppedAnimation(
                                            AppColors.primary),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppUi.gapMD),
                            Text(
                              AppStrings.levelProgress(
                                progress.completed,
                                progress.total,
                              ),
                              style: AppText.caption.copyWith(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: AppUi.gapMD),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: onOpen,
                                icon: const Icon(Icons.menu_book_outlined),
                                label: const Text(AppStrings.viewBooks),
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
                  color: AppColors.background.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppUi.radiusMD),
                ),
              ),
            ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppUi.gapSMPlus,
        vertical: AppUi.gapXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppUi.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppUi.iconSizeXS, color: color),
            const SizedBox(width: AppUi.gapXSPlus),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppUi.gapSMPlus,
        vertical: AppUi.gapXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppUi.radiusPill),
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
