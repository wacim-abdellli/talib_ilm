import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../core/models/favorite_item.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../../../shared/widgets/app_tag.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/progress_models.dart';

class BookCard extends StatefulWidget {
  final IlmBook book;
  final BookProgress progress;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.progress,
    required this.onTap,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(
      FavoriteType.book,
      widget.book.id,
    );
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // Calculate progress
    double percent = 0;
    int remainingLessons = 0;
    if (widget.progress.totalLessons > 0) {
      remainingLessons =
          widget.progress.totalLessons - widget.progress.completedLessons;
      percent =
          (widget.progress.completedLessons / widget.progress.totalLessons)
              .clamp(0.0, 1.0);
    } else if (widget.progress.status == BookProgressStatus.completed) {
      percent = 1.0;
    }

    // Estimate time remaining: 15 mins per lesson as an average
    final estimatedMinutes = remainingLessons * 15;
    final timeText = estimatedMinutes > 0
        ? '$estimatedMinutes دقيقة متبقية'
        : 'مكتمل';

    final percentText = '${(percent * 100).round()}%';

    return AppCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with Category Badge & Bookmark
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AppTag(
                  label: widget.book.subject,
                  subject: widget.book.subject,
                ),
              ),
              if (_isFavorite)
                Icon(
                  Icons.bookmark_rounded,
                  color: palette.gold,
                  size: AppIcon.md,
                ),
            ],
          ),

          const SizedBox(height: AppSpace.md),

          // Title
          Text(
            widget.book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall,
          ),

          const SizedBox(height: AppSpace.xs),

          // Subtitle / Author
          Text(
            widget.book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall.copyWith(
              color: palette.textMuted,
            ),
          ),

          if (remainingLessons > 0) ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: AppIcon.sm,
                      color: palette.textSubtle,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      timeText,
                      style: context.text.caption.copyWith(
                        color: palette.textSubtle,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$remainingLessons دروس متبقية',
                  style: context.text.caption.copyWith(
                    color: palette.textSubtle,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpace.md),

          // Progress Section
          Row(
            children: [
              Expanded(
                child: AppProgress(progress: percent),
              ),
              const SizedBox(width: AppSpace.md),
              Text(
                percentText,
                style: context.text.label.copyWith(
                  color: palette.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
