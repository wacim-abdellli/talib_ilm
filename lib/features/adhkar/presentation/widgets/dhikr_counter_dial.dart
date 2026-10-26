import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

/// Luxury circular counter dial for dhikr recitation sessions.
/// Features smooth spring haptic scaling, fluid arc tweening, and noble gold completion states.
class DhikrCounterDial extends StatefulWidget {
  final int count;
  final int total;
  final bool isComplete;
  final VoidCallback onTap;

  const DhikrCounterDial({
    super.key,
    required this.count,
    required this.total,
    required this.isComplete,
    required this.onTap,
  });

  @override
  State<DhikrCounterDial> createState() => _DhikrCounterDialState();
}

class _DhikrCounterDialState extends State<DhikrCounterDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _springController,
        curve: AppMotion.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _springController.forward().then((_) {
      if (mounted) {
        _springController.reverse();
      }
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final targetProgress = widget.total > 0
        ? (widget.count / widget.total).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      button: true,
      label: 'عداد الذكر، اضغط للعد. ${widget.count} من ${widget.total}',
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            customBorder: const CircleBorder(),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular Progress Dial with Fluid Arc Tweening
                SizedBox(
                  width: 196,
                  height: 196,
                  child: TweenAnimationBuilder<double>(
                    duration: AppMotion.base,
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0.0, end: targetProgress),
                    builder: (context, animatedProgress, _) {
                      return CustomPaint(
                        painter: _DhikrProgressPainter(
                          progress: animatedProgress,
                          trackColor: palette.surfaceMuted,
                          progressColor: widget.isComplete
                              ? palette.gold
                              : palette.primary,
                          isComplete: widget.isComplete,
                        ),
                      );
                    },
                  ),
                ),

                // Inner Numbers & State
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: AppMotion.fast,
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Text(
                        '${widget.count}',
                        key: ValueKey(widget.count),
                        style: context.text.displayHeavy.copyWith(
                          color: widget.isComplete ? palette.gold : palette.text,
                          height: 1,
                        ),
                      ),
                    ),
                    if (widget.total > 0) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        'من ${widget.total}',
                        style: context.text.label.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpace.xs),
                    AnimatedContainer(
                      duration: AppMotion.base,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xs,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isComplete
                            ? palette.goldSoft
                            : palette.surfaceMuted,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: widget.isComplete
                              ? palette.gold.withValues(alpha: 0.5)
                              : palette.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isComplete) ...[
                            Icon(
                              Icons.check_circle_rounded,
                              color: palette.gold,
                              size: AppIcon.sm,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              'اكتمل',
                              style: context.text.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: palette.gold,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.touch_app_rounded,
                              color: palette.textMuted,
                              size: AppIcon.sm,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              'المس للعد',
                              style: context.text.captionBold.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DhikrProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final bool isComplete;

  _DhikrProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.isComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - 18) / 2;

    // Background track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isComplete ? 10 : 8
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        progressPaint,
      );

      // Luminous inner accent ring on completion
      if (isComplete) {
        final innerGlowPaint = Paint()
          ..color = progressColor.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center, radius - 8, innerGlowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DhikrProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        trackColor != oldDelegate.trackColor ||
        progressColor != oldDelegate.progressColor ||
        isComplete != oldDelegate.isComplete;
  }
}
