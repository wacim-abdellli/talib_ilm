import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../data/models/mutun_models.dart';
import '../../../../shared/widgets/progress_pill.dart';
import '../../data/models/progress_models.dart';
import '../../../../shared/widgets/pressable_card.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/models/favorite_item.dart';

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
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final saved = await _favoritesService.isFavorite(
      FavoriteType.book,
      widget.book.id,
    );
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

  Future<void> _toggleFavorite() async {
    final saved = await _favoritesService.toggle(
      FavoriteItem(
        type: FavoriteType.book,
        id: widget.book.id,
        title: widget.book.title,
        subtitle: widget.book.author,
      ),
    );
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.progress.status;
    final percent = _progressValue(widget.progress);
    final statusLabel = switch (status) {
      BookProgressStatus.completed => 'مكتمل',
      BookProgressStatus.inProgress => 'قيد التقدم',
      _ => 'جديد',
    };
    final color = switch (status) {
      BookProgressStatus.completed => AppColors.primary,
      BookProgressStatus.inProgress => AppColors.primary,
      _ => AppColors.textMuted,
    };

    return PressableCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressRing(value: percent, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.book.title,
                            style: AppText.heading
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'المفضلة',
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite ? Icons.star : Icons.star_border,
                            color: _isFavorite
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.book.author, style: AppText.bodyMuted),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ProgressPill(progress: widget.progress),
                        const Spacer(),
                        Text(
                          statusLabel,
                          style: AppText.caption.copyWith(color: color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _progressValue(BookProgress progress) {
    if (progress.totalLessons > 0) {
      return (progress.completedLessons / progress.totalLessons)
          .clamp(0, 1);
    }
    switch (progress.status) {
      case BookProgressStatus.completed:
        return 1;
      case BookProgressStatus.inProgress:
        return 0.45;
      case BookProgressStatus.notStarted:
        return 0.05;
    }
  }
}

class _ProgressRing extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressRing({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: 5,
              backgroundColor: AppColors.textMuted.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: AppText.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
