import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HadithOfTheDayCard extends StatefulWidget {
  final String arabicText;
  final String source;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const HadithOfTheDayCard({
    super.key,
    required this.arabicText,
    required this.source,
    this.isFavorite = false,
    required this.onFavoriteToggle,
  });

  @override
  State<HadithOfTheDayCard> createState() => _HadithOfTheDayCardState();
}

class _HadithOfTheDayCardState extends State<HadithOfTheDayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Tap scale animation
  double _tapScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Slide up animation
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // Gentle bounce/scale animation
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark Mode Styling Colors (User Request: Ultra Dark)
    final containerBg = isDark ? const Color(0xFF0A0A0A) : Colors.white;

    final borderColor = isDark
        ? const Color(0xFF3B9EFF).withValues(alpha: 0.2)
        : const Color(0xFFE2E8F0);

    final shadowColor = isDark
        ? const Color(0xFF3B9EFF).withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.04);

    final shadowBlur = isDark ? 20.0 : 12.0;
    final shadowOffset = isDark ? const Offset(0, 8) : const Offset(0, 4);

    // Gradients
    const gradientColors = [Color(0xFF3B9EFF), Color(0xFF60A5FA)];
    const leftAccentGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: gradientColors,
    );

    // Icon Container
    final iconDecoration = BoxDecoration(
      gradient: isDark ? const LinearGradient(colors: gradientColors) : null,
      color: isDark ? null : const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(10),
    );

    final iconColor = isDark ? Colors.white : const Color(0xFF3B82F6);

    // Text Colors
    final titleColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF0F172A);
    final arabicColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1E293B);

    // Source Badge
    final sourceBadgeBg = isDark
        ? const Color(0xFF141414)
        : const Color(0xFFF8FAFC);
    final sourceTextColor = isDark
        ? const Color(0xFF3B9EFF)
        : const Color(0xFF64748B);
    final checkIconColor = isDark
        ? const Color(0xFF00E676)
        : const Color(0xFF22C55E); // Neon green in dark

    // Action Icons
    final actionIconColor = isDark
        ? const Color(0xFFA1A1A1)
        : const Color(0xFF64748B);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _tapScale = 0.98),
            onTapUp: (_) => setState(() => _tapScale = 1.0),
            onTapCancel: () => setState(() => _tapScale = 1.0),
            child: AnimatedScale(
              scale: _tapScale,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
                        )
                      : null,
                  color: isDark ? null : containerBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                        : borderColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                          : shadowColor,
                      blurRadius: isDark ? 24 : shadowBlur,
                      offset: isDark ? const Offset(0, 8) : shadowOffset,
                      spreadRadius: isDark ? -4 : 0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Left accent stripe with shimmer animation
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Container(
                            width: 4,
                            decoration: BoxDecoration(
                              gradient: leftAccentGradient,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                bottomLeft: Radius.circular(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors[0].withValues(
                                    alpha: 0.4 * _fadeAnimation.value,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: iconDecoration,
                                child: Icon(
                                  Icons.auto_stories_rounded,
                                  color: iconColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'حديث نبوي',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  widget.onFavoriteToggle();
                                },
                                icon: Icon(
                                  widget.isFavorite
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: actionIconColor,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Arabic text
                          Text(
                            widget.arabicText,
                            style: TextStyle(
                              fontSize: 19,
                              height: 2.2,
                              color: arabicColor,
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            overflow: TextOverflow.fade,
                            maxLines: 8,
                          ),

                          const SizedBox(height: 16),

                          // Source and actions
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: sourceBadgeBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: checkIconColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        widget.source,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: sourceTextColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: widget.arabicText),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                color: actionIconColor,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.share_rounded, size: 20),
                                color: actionIconColor,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
