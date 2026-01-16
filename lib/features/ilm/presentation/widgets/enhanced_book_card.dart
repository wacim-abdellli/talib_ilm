import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';

class EnhancedBookCard extends StatelessWidget {
  final IlmBook book;
  final BookProgress? progress;
  final VoidCallback onTap;
  final Responsive responsive;

  const EnhancedBookCard({
    super.key,
    required this.book,
    required this.progress,
    required this.onTap,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    // Computations
    final isStarted = progress != null && progress!.currentPage > 0;
    final isCompleted = progress?.isCompleted ?? false;
    final progressPercent = progress == null
        ? 0.0
        : (progress!.progressPercentage / 100);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                : AppColors.stroke,
            width: isCompleted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Level Badge + Status Icon
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _LevelBadge(level: book.level),
                  _StatusIcon(isCompleted: isCompleted, isStarted: isStarted),
                ],
              ),
            ),

            const Spacer(),

            // 2. Content: Title + Author + Last Accessed
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: responsive.sp(14),
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: responsive.sp(11),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Last Accessed Label
                  if (isStarted && !isCompleted)
                    Row(
                      children: [
                        Icon(Icons.history, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'توقفت عند صـ ${progress!.currentPage}',
                            style: TextStyle(
                              fontSize: responsive.sp(10),
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const Spacer(),

            // 3. Footer: Progress Bar + Action Bar
            if (isStarted && !isCompleted)
              LinearProgressIndicator(
                value: progressPercent,
                minHeight: 4,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              )
            else if (isCompleted)
              Container(
                height: 4,
                color: const Color(0xFF22C55E), // Green success bar
              ),

            // Action Text (instead of button to reduce noise in grid)
            // Or maybe a subtle button if needed, but the card is clickable.
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'المستوى $level',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final bool isCompleted;
  final bool isStarted;

  const _StatusIcon({required this.isCompleted, required this.isStarted});

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20);
    } else if (isStarted) {
      return const Icon(
        Icons.play_circle_outline,
        color: AppColors.primary,
        size: 20,
      );
    } else {
      return Icon(
        Icons.circle_outlined,
        color: AppColors.textSecondary.withValues(alpha: 0.3),
        size: 20,
      );
    }
  }
}
