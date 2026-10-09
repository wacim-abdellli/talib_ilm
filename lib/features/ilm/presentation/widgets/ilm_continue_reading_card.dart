import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';

class IlmContinueReadingCard extends StatelessWidget {
  final BookProgress? continueReadingBook;
  final IlmBook? recommendedFirstBook;
  final Map<String, IlmBook> bookCatalog;
  final Animation<double> pulseAnimation;
  final ValueChanged<IlmBook> onNavigateToBook;

  const IlmContinueReadingCard({
    super.key,
    required this.continueReadingBook,
    required this.recommendedFirstBook,
    required this.bookCatalog,
    required this.pulseAnimation,
    required this.onNavigateToBook,
  });

  @override
  Widget build(BuildContext context) {
    if (continueReadingBook != null) {
      return _buildCompactContinueLearningCard(
        context,
        continueReadingBook!,
      );
    }

    if (recommendedFirstBook != null) {
      return _buildCompactStartJourneyCard(
        context,
        recommendedFirstBook!,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCompactContinueLearningCard(
    BuildContext context,
    BookProgress book,
  ) {
    final palette = context.palette;
    final totalPages = book.totalPages;
    final currentPage = book.currentPage;
    final progressValue = totalPages == 0
        ? 0.0
        : (currentPage / totalPages).clamp(0.0, 1.0);

    final bookData = bookCatalog[book.bookId];

    return Padding(
      padding: AppSpace.screenPadding,
      child: AppCard(
        onTap: () {
          if (bookData != null) onNavigateToBook(bookData);
        },
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Book icon badge + info
            Row(
              children: [
                const IconBadge(
                  icon: Icons.menu_book_outlined,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.bookTitle,
                        style: context.text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        'متوقف عند الصفحة $currentPage من $totalPages',
                        style: context.text.bodySmall.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpace.md),

            // Progress bar
            AppProgress(progress: progressValue),

            const SizedBox(height: AppSpace.md),

            // Bottom action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progressValue * 100).round()}% مكتمل',
                  style: context.text.caption.copyWith(
                    color: palette.textSubtle,
                  ),
                ),
                AppButton.tonal(
                  label: 'تابع رحلتك',
                  icon: Icons.arrow_back_rounded,
                  size: AppButtonSize.sm,
                  onPressed: () {
                    if (bookData != null) onNavigateToBook(bookData);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStartJourneyCard(
    BuildContext context,
    IlmBook recommendedBook,
  ) {
    final palette = context.palette;

    return Padding(
      padding: AppSpace.screenPadding,
      child: AppCard(
        onTap: () => onNavigateToBook(recommendedBook),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            const IconBadge(
              icon: Icons.auto_stories_outlined,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ابدأ رحلتك العلمية',
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    recommendedBook.title,
                    style: context.text.bodySmall.copyWith(
                      color: palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            ScaleTransition(
              scale: pulseAnimation,
              child: Icon(
                Icons.arrow_back_rounded,
                size: AppIcon.lg,
                color: palette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
