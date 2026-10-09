import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_tag.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import 'ilm_enhanced_book_card.dart';

class IlmLevelSection extends StatelessWidget {
  final IlmLevel level;
  final List<IlmBook> allBooks;
  final Map<String, BookProgress> progressById;
  final Map<String, IlmBook> bookCatalog;
  final ValueChanged<IlmBook> onNavigateToBook;
  final ValueChanged<String> onToggleFavorite;

  const IlmLevelSection({
    super.key,
    required this.level,
    required this.allBooks,
    required this.progressById,
    required this.bookCatalog,
    required this.onNavigateToBook,
    required this.onToggleFavorite,
  });

  double _getLevelCompletion(String levelTitle) {
    final books = bookCatalog.values
        .where((b) => b.level.trim() == levelTitle.trim())
        .toList();
    if (books.isEmpty) return 0.0;

    int completed = 0;
    for (var book in books) {
      if (progressById[book.id]?.isCompleted ?? false) {
        completed++;
      }
    }
    return completed / books.length;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final completion = _getLevelCompletion(level.title);
    final levelBooks = allBooks.where((b) => b.level == level.title).toList();

    if (levelBooks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Header Section
          Padding(
            padding: AppSpace.screenPadding,
            child: Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: palette.border,
                ),
              ),
              child: Row(
                children: [
                  const IconBadge(
                    icon: Icons.auto_stories_rounded,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      level.title,
                      style: context.text.titleSmall,
                    ),
                  ),
                  if (completion > 0)
                    AppTag(
                      label: '${(completion * 100).round()}%',
                      fg: completion >= 1.0
                          ? palette.success
                          : palette.onPrimarySoft,
                      bg: palette.primarySoft,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpace.md),

          // Books Grid
          Padding(
            padding: AppSpace.screenPadding,
            child: _buildBooksGrid(
              context,
              levelBooks,
              key: ValueKey('level-${level.title}'),
            ),
          ),

          const SizedBox(height: AppSpace.lg),

          // Divider between levels
          Padding(
            padding: AppSpace.screenPadding,
            child: Divider(
              color: palette.border,
              height: AppSpace.xl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksGrid(
    BuildContext context,
    List<IlmBook> books, {
    Key? key,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 360;
        final aspectRatio = isSmall ? 0.60 : 0.68;

        return GridView.builder(
          key: key,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpace.md,
            mainAxisSpacing: AppSpace.md,
            childAspectRatio: aspectRatio,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            final progress = progressById[book.id];
            final isRecommended =
                index == 0 && (progress == null || progress.currentPage <= 1);

            return IlmEnhancedBookCard(
              book: book,
              progress: progress,
              isRecommended: isRecommended,
              onNavigateToBook: onNavigateToBook,
              onToggleFavorite: onToggleFavorite,
            );
          },
        );
      },
    );
  }
}
