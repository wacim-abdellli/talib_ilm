import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import 'ilm_book_preview_row.dart';
import 'ilm_mutn_card.dart';
import 'ilm_partition_header.dart';
import 'mutun_rosette_icon.dart';

/// Presentation slivers for Mutun Taleb Al-Ilm section in both overview and focused modes.
class IlmMutunSectionView {
  IlmMutunSectionView._();

  static List<Widget> buildSlivers({
    required BuildContext context,
    required AppPalette palette,
    required List<IlmBook> allBooks,
    required List<IlmLevel> sortedLevels,
    required Map<String, BookProgress> progressById,
    required Set<String> favoriteBookIds,
    required bool isFocused,
    required String? selectedMutunLevel,
    required ValueChanged<String?> onSelectLevel,
    required VoidCallback onViewAll,
    required VoidCallback onBackToAll,
    required ValueChanged<IlmBook> onNavigateToBook,
    required ValueChanged<String> onToggleFavorite,
    required VoidCallback onOpenCurriculumQuiz,
  }) {
    final filteredMutun = selectedMutunLevel == null
        ? allBooks
        : allBooks.where((b) => b.level == selectedMutunLevel).toList();

    if (!isFocused) {
      // ── Clean Partitioned Shelf Section ──────────────────────────
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: AppSpace.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Elegant Two-Tier Mutun Header ──
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tier 1: Mutun Rosette + Full Title + Count Pill <---> View All
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                            decoration: BoxDecoration(
                              color: palette.primarySoft,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: MutunRosetteIcon(
                              size: AppIcon.sm,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'متون طالب العلم',
                                    style: context.text.title.copyWith(
                                      color: palette.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Container(
                                  padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: AppSpace.xs,
                                    vertical: AppSpace.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.primarySoft,
                                    borderRadius: AppRadius.pillRadius,
                                  ),
                                  child: Text(
                                    '5 مستويات • ${allBooks.length}',
                                    style: context.text.caption.copyWith(
                                      color: palette.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),

                          // View All Button with arrow
                          Semantics(
                            button: true,
                            label: 'عرض كل المتون',
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: AppRadius.pillRadius,
                              child: InkWell(
                                borderRadius: AppRadius.pillRadius,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onViewAll();
                                },
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: AppSpace.xs,
                                    vertical: AppSpace.xs,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'عرض الكل',
                                        style: context.text.caption.copyWith(
                                          color: palette.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpace.xxs),
                                      Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: AppIcon.xs,
                                        color: palette.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpace.xxs),

                      // Tier 2: Subtitle Description
                      Text(
                        'المنهاج العلمي التأصيلي المتدرج لحفظ المتون',
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.sm),

                // ── 2. Compact Vertical Mutun Preview List ──
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.lg,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: palette.border, width: 0.8),
                      borderRadius: AppRadius.lgRadius,
                      color: palette.surface,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (int i = 0; i < allBooks.take(4).length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: palette.border,
                              indent: AppSpace.lg,
                              endIndent: 0,
                            ),
                          Builder(
                            builder: (context) {
                              final book = allBooks[i];
                              final progress = progressById[book.id];
                              final digitalEntry = MutunDigitalCatalog.getEntry(book.id);
                              final totalPages = (digitalEntry != null && digitalEntry.totalPages > 0)
                                  ? digitalEntry.totalPages
                                  : (book.totalPages > 0 ? book.totalPages : 1);
                              final currentPage = progress?.currentPage ?? 0;
                              final isCompleted = progress?.isCompleted ?? false;

                              String? badgeText;
                              if (isCompleted) {
                                badgeText = 'مكتمل';
                              } else if (currentPage > 0) {
                                badgeText = 'صفحة $currentPage من $totalPages';
                              }

                              return IlmBookPreviewRow(
                                title: book.title,
                                subtitle: _buildMutnSubtitle(book, progress),
                                author: book.author,
                                progressBadge: badgeText,
                                accentColor: palette
                                    .mutunLevel(book.level)
                                    .fg,
                                isCompleted: isCompleted,
                                onTap: () => onNavigateToBook(book),
                              );
                            },
                          ),
                        ],
                        if (allBooks.length > 4) ...[
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: palette.border,
                          ),
                          IlmViewAllRow(
                            label: 'عرض جميع المتون (${allBooks.length})',
                            onTap: onViewAll,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // ── Focused View for Mutun (Full vertical list with level filters) ──
    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
              ),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'العودة لجميع الأقسام',
                    child: Material(
                      color: palette.surfaceRaised,
                      borderRadius: AppRadius.pillRadius,
                      child: InkWell(
                        borderRadius: AppRadius.pillRadius,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onBackToAll();
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.xs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: AppIcon.xs,
                                color: palette.primary,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                'العودة لجميع الأقسام',
                                style: context.text.caption.copyWith(
                                  color: palette.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.pillRadius,
                    child: InkWell(
                      borderRadius: AppRadius.pillRadius,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onOpenCurriculumQuiz();
                      },
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.xs,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: palette.gold.withAlpha(160),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              size: AppIcon.sm,
                              color: palette.gold,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              'مسابقات المنهاج',
                              style: context.text.caption.copyWith(
                                color: palette.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: AppIcon.xs,
                              color: palette.gold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            IlmPartitionHeader(
              title: 'متون طالب العلم (المنهاج التأصيلي)',
              subtitle: 'منهج علمي مدرج يبدأ بالتمهيدي حتى المطولات',
              countLabel: '${allBooks.length} متون',
            ),

            // Horizontal Level Selector Filter
            SizedBox(
              height: AppSize.tap,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.lg,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildLevelChip(
                    context: context,
                    label: 'جميع المستويات',
                    isSelected: selectedMutunLevel == null,
                    onTap: () => onSelectLevel(null),
                    palette: palette,
                  ),
                  for (final lvl in sortedLevels)
                    _buildLevelChip(
                      context: context,
                      label: lvl.label.isNotEmpty ? lvl.label : lvl.title,
                      isSelected: selectedMutunLevel == lvl.title,
                      onTap: () => onSelectLevel(lvl.title),
                      palette: palette,
                      levelKey: lvl.title,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ),
      ),
      SliverPadding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final book = filteredMutun[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                child: IlmMutnCard(
                  book: book,
                  progress: progressById[book.id],
                  isFavoriteOverride: favoriteBookIds.contains(book.id),
                  onOpenReader: () => onNavigateToBook(book),
                  onToggleFavorite: () => onToggleFavorite(book.id),
                ),
              );
            },
            childCount: filteredMutun.length,
          ),
        ),
      ),
    ];
  }

  static Widget _buildLevelChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
    String? levelKey,
  }) {
    final levelColors = levelKey != null ? palette.mutunLevel(levelKey) : null;
    final Color bgColor = isSelected
        ? (levelColors?.bg ?? palette.primary)
        : palette.surfaceRaised;
    final Color fgColor = isSelected
        ? (levelColors?.fg ?? palette.onPrimary)
        : palette.textMuted;
    final Color borderColor = isSelected
        ? (levelColors?.border ?? palette.primary)
        : palette.border;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
      child: Material(
        color: bgColor,
        borderRadius: AppRadius.pillRadius,
        child: InkWell(
          borderRadius: AppRadius.pillRadius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (levelColors != null && !isSelected) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: levelColors.fg,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                  ],
                  Text(
                    label,
                    style: (isSelected
                            ? context.text.captionHeavy
                            : context.text.captionBold)
                        .copyWith(
                      color: fgColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _buildMutnSubtitle(IlmBook book, BookProgress? progress) {
    final isCompleted = progress?.isCompleted ?? false;
    final currentPage = progress?.currentPage ?? 0;
    final digitalEntry = MutunDigitalCatalog.getEntry(book.id);
    final totalPages = (digitalEntry != null && digitalEntry.totalPages > 0)
        ? digitalEntry.totalPages
        : (book.totalPages > 0 ? book.totalPages : 1);

    if (isCompleted) {
      return '${book.author} • مكتمل';
    } else if (currentPage > 0) {
      return '${book.author} • صفحة $currentPage من $totalPages';
    } else if (book.totalPages > 0) {
      return '${book.author} • $totalPages ص';
    } else {
      return book.author;
    }
  }
}
