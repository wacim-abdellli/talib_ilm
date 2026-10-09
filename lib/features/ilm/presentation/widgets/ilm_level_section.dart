import 'package:flutter/material.dart';

import '../../../../app/theme/theme_colors.dart';
import '../../../../core/utils/responsive.dart';
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
    final responsive = Responsive(context);
    final completion = _getLevelCompletion(level.title);
    final levelBooks = allBooks.where((b) => b.level == level.title).toList();

    if (levelBooks.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: responsive.largeGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level Header Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.safeHorizontalPadding,
              ),
              child: Container(
                padding: EdgeInsets.all(responsive.hp(1.5)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: isDark
                        ? [context.surfaceContainer, context.surfaceLowest]
                        : [const Color(0xFFF5F3F0), const Color(0xFFFBFAF8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? context.outlineColor.withValues(alpha: 0.15)
                        : const Color(0xFFE8E6E3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Level icon
                    Container(
                      width: responsive.sp(36),
                      height: responsive.sp(36),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6A9A9A), Color(0xFF7AB5A8)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: responsive.sp(18),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: responsive.wp(3)),
                    // Level title
                    Expanded(
                      child: Text(
                        level.title,
                        style: TextStyle(
                          fontSize: responsive.sp(16),
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFFFFFFF)
                              : context.textPrimaryColor,
                        ),
                      ),
                    ),
                    // Completion badge
                    if (completion > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: completion >= 1.0
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                )
                              : null,
                          color: completion >= 1.0
                              ? null
                              : const Color(0xFF5A8A8A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (completion >= 1.0)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            Text(
                              '${(completion * 100).round()}%',
                              style: TextStyle(
                                fontSize: responsive.sp(12),
                                fontWeight: FontWeight.w700,
                                color: completion >= 1.0
                                    ? Colors.white
                                    : const Color(0xFF5A8A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: responsive.mediumGap),

            // Books Grid
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.safeHorizontalPadding,
              ),
              child: _buildBooksGrid(
                context,
                responsive,
                levelBooks,
                key: ValueKey('level-${level.title}'),
              ),
            ),

            SizedBox(height: responsive.mediumGap),

            // Decorative separator
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.safeHorizontalPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            isDark
                                ? const Color(0xFF1F1F1F)
                                : const Color(0xFFE8E6E3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F1F1F)
                            : const Color(0xFFE8E6E3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            isDark
                                ? const Color(0xFF1F1F1F)
                                : const Color(0xFFE8E6E3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksGrid(
    BuildContext context,
    Responsive responsive,
    List<IlmBook> books, {
    Key? key,
  }) {
    final aspectRatio = responsive.isSmallScreen ? 0.58 : 0.65;

    return GridView.builder(
      key: key,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: responsive.smallGap,
        mainAxisSpacing: responsive.smallGap,
        childAspectRatio: aspectRatio,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final progress = progressById[book.id];
        final isRecommended =
            index == 0 && (progress == null || progress.currentPage <= 1);

        return TweenAnimationBuilder<double>(
          key: ValueKey(book.id),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 8 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: IlmEnhancedBookCard(
            book: book,
            progress: progress,
            isRecommended: isRecommended,
            onNavigateToBook: onNavigateToBook,
            onToggleFavorite: onToggleFavorite,
          ),
        );
      },
    );
  }
}
