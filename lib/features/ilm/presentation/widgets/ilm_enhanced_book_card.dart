import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import 'ilm_continue_reading_card.dart';

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
    final responsive = Responsive(context);
    final progressValue = progress == null
        ? 0.0
        : (progress!.progressPercentage / 100).clamp(0.0, 1.0).toDouble();
    final isCompleted = progress?.isCompleted ?? false;
    final isNotStarted = progress == null || progress!.currentPage <= 1;
    final isInProgress = !isNotStarted && !isCompleted;

    // Category color based on subject
    Color categoryColor = _getCategoryColor(book.subject);

    // Card styling based on state
    Color cardBg;
    Color borderColor;
    double borderWidth;
    List<BoxShadow> cardShadow;

    // Completed color - nice emerald green
    const completedColor = Color(0xFF059669);
    const completedBg = Color(0xFFECFDF5);

    if (isCompleted) {
      // Completed: Soft sage background
      cardBg = context.isDark ? AppColors.darkSuccessLight : completedBg;
      borderColor = completedColor.withValues(alpha: 0.3);
      borderWidth = 1.5;
      cardShadow = [
        BoxShadow(
          color: completedColor.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isInProgress) {
      // In Progress: Teal border highlight
      cardBg = context.surfaceColor;
      borderColor = const Color(0xFF5A8A8A);
      borderWidth = 2;
      cardShadow = [
        BoxShadow(
          color: const Color(0xFF5A8A8A).withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      // New: Clean white with subtle shadow
      cardBg = context.surfaceColor;
      borderColor = context.borderColor;
      borderWidth = 1;
      cardShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }

    Widget cardContent = IlmPressableScale(
      onTap: () => onNavigateToBook(book),
      onLongPress: () => onToggleFavorite(book.id),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover Area with Category-Colored Icon
            Flexible(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFEDF5F5)
                      : categoryColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Icon with breathing animation for in-progress
                    if (isInProgress)
                      BreathingIcon(
                        icon: Icons.menu_book_outlined,
                        size: responsive.wp(10),
                        color: categoryColor,
                      )
                    else if (isCompleted)
                      Container(
                        width: responsive.wp(12),
                        height: responsive.wp(12),
                        decoration: BoxDecoration(
                          color: completedColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: responsive.wp(8),
                          color: completedColor,
                        ),
                      )
                    else
                      Container(
                        width: responsive.wp(12),
                        height: responsive.wp(12),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_stories_outlined,
                          size: responsive.wp(6),
                          color: categoryColor,
                        ),
                      ),

                    // Completed badge
                    if (isCompleted)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: completedColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                size: responsive.sp(12),
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'مكتمل',
                                style: TextStyle(
                                  fontSize: responsive.sp(10),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Book Info
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.all(responsive.wp(3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (bold)
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: responsive.hp(0.3)),

                    // Author (muted)
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: responsive.sp(11),
                        color: context.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Progress bar (only for in-progress)
                    if (isInProgress) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: progressValue),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 5,
                              backgroundColor: context.borderColor,
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF5A8A8A),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: responsive.hp(0.5)),
                      Text(
                        '${(progressValue * 100).round()}% مكتمل',
                        style: TextStyle(
                          fontSize: responsive.sp(10),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A8A8A),
                        ),
                      ),
                    ],

                    // Subject tag for new books
                    if (isNotStarted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book.subject,
                          style: TextStyle(
                            fontSize: responsive.sp(10),
                            fontWeight: FontWeight.w600,
                            color: categoryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with scale animation for new books
    if (isNotStarted) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: cardContent,
      );
    }

    return cardContent;
  }

  Color _getCategoryColor(String subject) {
    final subjectLower = subject.toLowerCase();

    if (subjectLower.contains('عقيدة') || subjectLower.contains('توحيد')) {
      return const Color(0xFF0891B2); // Cyan - عقيدة
    } else if (subjectLower.contains('حديث') ||
        subjectLower.contains('مصطلح')) {
      return const Color(0xFF7C3AED); // Violet - حديث
    } else if (subjectLower.contains('فقه') || subjectLower.contains('أصول')) {
      return const Color(0xFF059669); // Emerald - فقه
    } else if (subjectLower.contains('قرآن') ||
        subjectLower.contains('تجويد') ||
        subjectLower.contains('تفسير')) {
      return const Color(0xFFCA8A04); // Amber - قرآن
    } else if (subjectLower.contains('لغة') ||
        subjectLower.contains('نحو') ||
        subjectLower.contains('صرف')) {
      return const Color(0xFFDC2626); // Red - لغة
    } else if (subjectLower.contains('سيرة') ||
        subjectLower.contains('تاريخ')) {
      return const Color(0xFFDB2777); // Pink - سيرة
    } else {
      return const Color(0xFF5A8A8A); // Default teal
    }
  }
}

class BreathingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;

  const BreathingIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  State<BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<BreathingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size * 1.3,
        height: widget.size * 1.3,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(widget.icon, size: widget.size * 0.6, color: widget.color),
      ),
    );
  }
}
