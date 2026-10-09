import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/theme_colors.dart';

class RosaryDial extends StatefulWidget {
  final String label;
  final int count;
  final int? target;
  final VoidCallback onTap;
  final VoidCallback onReset;
  final VoidCallback onChangeDhikr;
  final VoidCallback onSetTarget;

  const RosaryDial({
    super.key,
    required this.label,
    required this.count,
    required this.target,
    required this.onTap,
    required this.onReset,
    required this.onChangeDhikr,
    required this.onSetTarget,
  });

  @override
  State<RosaryDial> createState() => _RosaryDialState();
}

class _RosaryDialState extends State<RosaryDial> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pulseController.forward().then((_) {
      if (mounted) _pulseController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = widget.target != null && widget.target! > 0
        ? (widget.count / widget.target!).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = widget.target != null && widget.count >= widget.target!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Top Dhikr Display Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: context.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.goldColor.withValues(alpha: isDark ? 0.3 : 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: widget.onChangeDhikr,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: context.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.goldColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 16, color: context.goldColor),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.changeDhikr,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.goldColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Interactive Astrolabe Rosary Medallion
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer decorative halo
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (isCompleted ? context.goldColor : context.primaryColor)
                                .withValues(alpha: isDark ? 0.18 : 0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),

                    // Custom Painter Dial Rings & Progress
                    CustomPaint(
                      size: const Size(220, 220),
                      painter: _RosaryPainter(
                        progress: progress,
                        baseColor: context.outlineVariantColor.withValues(alpha: 0.4),
                        activeColor: isCompleted ? context.goldColor : context.primaryColor,
                        accentGold: context.goldColor,
                        isCompleted: isCompleted,
                      ),
                    ),

                    // Center Glassmorphic Dial Core
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.surfaceColor,
                        border: Border.all(
                          color: (isCompleted ? context.goldColor : context.primaryColor)
                              .withValues(alpha: isDark ? 0.4 : 0.25),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.count.toString(),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 54,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: isCompleted ? context.goldColor : context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.target != null
                                ? 'الهدف: ${widget.target}'
                                : 'عدّ حر',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? context.goldColor
                                  : context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'المس الشاشة للتسبيح',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: context.textTertiaryColor,
              ),
            ),

            const Spacer(),

            // Bottom Action Control Island
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Set Target Button
                  InkWell(
                    onTap: widget.onSetTarget,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 20, color: context.goldColor),
                          const SizedBox(width: 8),
                          Text(
                            widget.target != null ? '${widget.target} مرة' : 'تحديد هدف',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 24,
                    color: context.outlineVariantColor,
                  ),

                  // Reset Button
                  InkWell(
                    onTap: widget.onReset,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 20, color: context.textSecondaryColor),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.reset,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _RosaryPainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  final Color activeColor;
  final Color accentGold;
  final bool isCompleted;

  _RosaryPainter({
    required this.progress,
    required this.baseColor,
    required this.activeColor,
    required this.accentGold,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track
    final trackPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 6, trackPaint);

    // Decorative Astrolabe Ticks (33 ticks)
    final tickPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;

    const tickCount = 33;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i * 2 * math.pi / tickCount) - (math.pi / 2);
      final outerX = center.dx + (radius + 2) * math.cos(angle);
      final outerY = center.dy + (radius + 2) * math.sin(angle);
      final innerX = center.dx + (radius - 1) * math.cos(angle);
      final innerY = center.dy + (radius - 1) * math.sin(angle);
      canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);
    }

    // Active progress arc
    if (progress > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        -math.pi / 2,
        sweepAngle,
        false,
        activePaint,
      );

      // Gold bead at the tip of progress
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipX = center.dx + (radius - 6) * math.cos(tipAngle);
      final tipY = center.dy + (radius - 6) * math.sin(tipAngle);

      final beadGlowPaint = Paint()
        ..color = accentGold.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), 10, beadGlowPaint);

      final beadPaint = Paint()
        ..color = accentGold
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), 6, beadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RosaryPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isCompleted != isCompleted;
  }
}
