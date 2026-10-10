import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';

/// A sleek, space-efficient resume card displayed above the library content.
///
/// Gives immediate access to the currently studied book and daily goal
/// without pushing the library catalog off the first viewport screen.
class StudyResumePill extends StatelessWidget {
  final BookProgress? continueReadingBook;
  final IlmBook? recommendedFirstBook;
  final Map<String, IlmBook> bookCatalog;
  final int dailyGoal;
  final int pagesReadToday;
  final int currentStreak;
  final ValueChanged<IlmBook> onNavigateToBook;

  const StudyResumePill({
    super.key,
    required this.continueReadingBook,
    required this.recommendedFirstBook,
    required this.bookCatalog,
    required this.dailyGoal,
    required this.pagesReadToday,
    required this.currentStreak,
    required this.onNavigateToBook,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (continueReadingBook != null) {
      final book = bookCatalog[continueReadingBook!.bookId];
      if (book != null) {
        return _buildActiveResumeCard(context, palette, book, continueReadingBook!);
      }
    }

    if (recommendedFirstBook != null) {
      return _buildStartJourneyCard(context, palette, recommendedFirstBook!);
    }

    return const SizedBox.shrink();
  }

  Widget _buildActiveResumeCard(
    BuildContext context,
    AppPalette palette,
    IlmBook book,
    BookProgress progress,
  ) {
    final totalPages = progress.totalPages > 0 ? progress.totalPages : book.totalPages;
    final currentPage = progress.currentPage;
    final progressRatio = totalPages > 0
        ? (currentPage / totalPages).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: AppSpace.screenPadding,
      child: AppCard(
        onTap: () => onNavigateToBook(book),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        border: Border.all(
          color: palette.gold.withAlpha(90),
          width: 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Book Icon Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: palette.gold.withAlpha(60),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: palette.primary,
                      size: AppIcon.md,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),

                // Book Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'استئناف المدارسة',
                            style: context.text.caption.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (currentStreak > 0)
                            Text(
                              '🔥 $currentStreak أيام متتالية',
                              style: context.text.caption.copyWith(
                                color: palette.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        book.title,
                        style: context.text.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpace.sm),

                // Forward Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppIcon.sm,
                  color: palette.textMuted,
                ),
              ],
            ),

            const SizedBox(height: AppSpace.sm),

            // Progress Bar and Page Counts
            AppProgress(progress: progressRatio),
            const SizedBox(height: AppSpace.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'متوقف عند الصفحة $currentPage من $totalPages',
                  style: context.text.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                Text(
                  '${(progressRatio * 100).round()}% أُنجز',
                  style: context.text.caption.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartJourneyCard(
    BuildContext context,
    AppPalette palette,
    IlmBook book,
  ) {
    return Padding(
      padding: AppSpace.screenPadding,
      child: AppCard(
        onTap: () => onNavigateToBook(book),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        border: Border.all(
          color: palette.border,
          width: 1,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: AppRadius.mdRadius,
              ),
              child: Center(
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: palette.primary,
                  size: AppIcon.md,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ابدأ رحلتك العلمية المباركة 🌱',
                    style: context.text.caption.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'أول خطوة: ${book.title}',
                    style: context.text.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: AppIcon.sm,
              color: palette.primary,
            ),
          ],
        ),
      ),
    );
  }
}
