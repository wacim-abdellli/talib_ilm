import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
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
    final responsive = Responsive(context);

    if (continueReadingBook != null) {
      return _buildCompactContinueLearningCard(
        context,
        responsive,
        continueReadingBook!,
      );
    }

    if (recommendedFirstBook != null) {
      return _buildCompactStartJourneyCard(
        context,
        responsive,
        recommendedFirstBook!,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCompactContinueLearningCard(
    BuildContext context,
    Responsive responsive,
    BookProgress book,
  ) {
    final totalPages = book.totalPages;
    final currentPage = book.currentPage;
    final progressValue = totalPages == 0
        ? 0.0
        : (currentPage / totalPages).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: GestureDetector(
        onTap: () {
          final bookData = bookCatalog[book.bookId];
          if (bookData != null) onNavigateToBook(bookData);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(responsive.wp(4)),
          decoration: BoxDecoration(
            // Calm teal → mint gradient
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF5A8A8A), Color(0xFF7AB5A8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5A8A8A).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Book icon + info
              Row(
                children: [
                  // Book icon with soft glow
                  Container(
                    width: responsive.wp(12),
                    height: responsive.wp(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      size: responsive.wp(6),
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(width: responsive.wp(3)),

                  // Book info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.bookTitle,
                          style: TextStyle(
                            fontSize: responsive.sp(16),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'متوقف عند الصفحة $currentPage من $totalPages',
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: responsive.hp(1.5)),

              // Animated progress bar (600ms easeOut)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progressValue),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  );
                },
              ),

              SizedBox(height: responsive.hp(1.5)),

              // Pill-style CTA button with elevation on tap
              IlmPressableScale(
                onTap: () {
                  final bookData = bookCatalog[book.bookId];
                  if (bookData != null) onNavigateToBook(bookData);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: responsive.hp(1.4)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'تابع رحلتك',
                        style: TextStyle(
                          fontSize: responsive.sp(14),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5A8A8A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_back,
                        size: responsive.sp(16),
                        color: const Color(0xFF5A8A8A),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStartJourneyCard(
    BuildContext context,
    Responsive responsive,
    IlmBook recommendedBook,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: GestureDetector(
        onTap: () => onNavigateToBook(recommendedBook),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(responsive.wp(4)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF4A7A7A), Color(0xFF386363)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A7A7A).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Book icon
              Container(
                width: responsive.wp(14),
                height: responsive.wp(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: responsive.wp(7),
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),

              SizedBox(width: responsive.wp(3)),

              // Journey info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ابدأ رحلتك العلمية',
                      style: TextStyle(
                        fontSize: responsive.sp(15),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recommendedBook.title,
                      style: TextStyle(
                        fontSize: responsive.sp(12),
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Start arrow with pulse
              ScaleTransition(
                scale: pulseAnimation,
                child: Container(
                  padding: EdgeInsets.all(responsive.wp(2.5)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A853),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: responsive.sp(16),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IlmPressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const IlmPressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<IlmPressableScale> createState() => _IlmPressableScaleState();
}

class _IlmPressableScaleState extends State<IlmPressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
