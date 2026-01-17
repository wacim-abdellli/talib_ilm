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

  Color _getCategoryColor(String category, bool isDark) {
    if (isDark) {
      if (category.contains('عقيدة')) return const Color(0xFFA855F7);
      if (category.contains('فقه')) return const Color(0xFF3B9EFF);
      if (category.contains('حديث')) return const Color(0xFFFF8A3D);
      if (category.contains('لغة')) return const Color(0xFFFF4D9E);
      // Fallbacks matching neon theme
      if (category.contains('قرآن')) return const Color(0xFF00D9C0);
      return const Color(0xFF00D9C0);
    }
    // Light mode defaults
    if (category.contains('عقيدة')) return AppColors.categoryAqidah;
    if (category.contains('فقه')) return AppColors.categoryFiqh;
    if (category.contains('حديث')) return AppColors.categoryHadith;
    if (category.contains('لغة')) return AppColors.categoryArabic;
    if (category.contains('قرآن')) return AppColors.categoryQuran;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(widget.book.subject, isDark);

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
            color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F3F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE8E6E3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : const Color(0xFF3A3A3A).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
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
                        Icon(
                          Icons.bookmark,
                          color: isDark
                              ? const Color(0xFFFFD600)
                              : AppColors.accent,
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
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: isDark ? Colors.white : const Color(0xFF3A3A3A),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    widget.book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFFA1A1A1)
                          : const Color(0xFF6E6E6E),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Smart Progress Labels
                  if (remainingLessons > 0)
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$remainingLessons دروس متبقية',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),

                  const Spacer(),

                  // Progress Section - accent only here
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF141414)
                                : const Color(0xFFE5E4E2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              tween: Tween<double>(begin: 0, end: percent),
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    categoryColor, // Neon in Dark
                                  ),
                                  minHeight: 6,
                                );
                              },
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
                          color: categoryColor, // Neon in Dark
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
