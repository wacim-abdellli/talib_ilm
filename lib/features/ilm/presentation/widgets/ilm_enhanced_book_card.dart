import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../../../shared/widgets/app_tag.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';

class IlmEnhancedBookCard extends StatelessWidget {
  final IlmBook book;
  final BookProgress? progress;
  final bool isRecommended;
  final ValueChanged<IlmBook> onNavigateToBook;
  final ValueChanged<String> onToggleFavorite;

  const IlmEnhancedBookCard({
    super.key,
    required this.book,
    required this.progress,
    this.isRecommended = false,
    required this.onNavigateToBook,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final progressValue = progress == null
        ? 0.0
        : (progress!.progressPercentage / 100).clamp(0.0, 1.0).toDouble();
    final isCompleted = progress?.isCompleted ?? false;
    final isNotStarted = progress == null || progress!.currentPage <= 1;
    final isInProgress = !isNotStarted && !isCompleted;

    final cardContent = AppCard(
      onTap: () => onNavigateToBook(book),
      onLongPress: () => onToggleFavorite(book.id),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Icon Badge + Category / Completed Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconBadge(
                icon: isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.menu_book_outlined,
              ),
              if (isCompleted)
                AppTag(
                  label: 'مكتمل',
                  fg: palette.success,
                  bg: palette.primarySoft,
                )
              else
                Flexible(
                  child: AppTag(
                    label: book.subject,
                    subject: book.subject,
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpace.md),

          // Title
          Text(
            book.title,
            style: context.text.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpace.xs),

          // Author
          Text(
            book.author,
            style: context.text.bodySmall.copyWith(
              color: palette.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Progress bar (only for in-progress or completed)
          if (isInProgress) ...[
            AppProgress(progress: progressValue),
            const SizedBox(height: AppSpace.xs),
            Text(
              '${(progressValue * 100).round()}% مكتمل',
              style: context.text.caption.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (isCompleted) ...[
            AppProgress(progress: 1.0),
            const SizedBox(height: AppSpace.xs),
            Text(
              '١٠٠٪ مكتمل',
              style: context.text.caption.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Text(
              'ابدأ القراءة',
              style: context.text.caption.copyWith(
                color: palette.textSubtle,
              ),
            ),
          ],
        ],
      ),
    );

    if (isNotStarted) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.0),
        duration: AppMotion.base,
        curve: AppMotion.easeIn,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: cardContent,
      );
    }

    return cardContent;
  }
}
