import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import 'scholarly_book_card.dart';

/// Luxury 2-column grid for Ilm library books.
class IlmBooksGrid extends StatelessWidget {
  final List<IlmBook> books;
  final Map<String, BookProgress> progressById;
  final String? recommendedBookId;
  final ValueChanged<IlmBook> onNavigateToBook;
  final ValueChanged<String> onToggleFavorite;

  const IlmBooksGrid({
    super.key,
    required this.books,
    required this.progressById,
    required this.recommendedBookId,
    required this.onNavigateToBook,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 360;
        final baseRatio = isSmall ? 0.62 : 0.68;
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final aspectRatio = textScale > 1.25 ? (baseRatio * 0.8) : baseRatio;

        return GridView.builder(
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
            final isRecommended = book.id == recommendedBookId;

            return ScholarlyBookCard(
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
