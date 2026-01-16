import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/mutun_models.dart';
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
  bool _isHovered = false;

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

  Color _getCategoryColor(String category) {
    if (category.contains('عقيدة')) return AppColors.categoryAqidah;
    if (category.contains('فقه')) return AppColors.categoryFiqh;
    if (category.contains('حديث')) return AppColors.categoryHadith;
    if (category.contains('لغة')) return AppColors.categoryArabic;
    if (category.contains('قرآن')) return AppColors.categoryQuran;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.book.subject);

    // Calculate progress
    double percent = 0;
    if (widget.progress.totalLessons > 0) {
      percent =
          (widget.progress.completedLessons / widget.progress.totalLessons)
              .clamp(0.0, 1.0);
    } else if (widget.progress.status == BookProgressStatus.completed) {
      percent = 1.0;
    }

    final percentText = '${(percent * 100).round()}% مكتمل';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: PressableCard(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(top: BorderSide(color: categoryColor, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: 180,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Category Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.book.subject,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (_isFavorite)
                        const Icon(
                          Icons.bookmark,
                          color: AppColors.accent,
                          size: 20,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    widget.book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const Spacer(),

                  // Progress Section
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                categoryColor,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        percentText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
