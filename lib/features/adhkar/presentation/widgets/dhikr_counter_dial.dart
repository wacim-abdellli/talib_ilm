import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

/// Luxury circular counter dial for dhikr recitation sessions.
class DhikrCounterDial extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      label: 'عداد الذكر، اضغط للعد. $count من $total',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular Progress Dial
              SizedBox(
                width: 196,
                height: 196,
                child: CustomPaint(
                  painter: _DhikrProgressPainter(
                    count: count,
                    total: total,
                    trackColor: palette.surfaceMuted,
                    progressColor: isComplete ? palette.success : palette.gold,
                  ),
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
                      '$count',
                      key: ValueKey(count),
                      style: context.text.display.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isComplete ? palette.success : palette.text,
                        height: 1,
                      ),
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'من $total',
                      style: context.text.label.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
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
                      color: isComplete ? palette.primarySoft : Colors.transparent,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isComplete) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            color: palette.success,
                            size: AppIcon.sm,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'اكتمل',
                            style: context.text.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: palette.success,
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
                            style: context.text.caption.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w600,
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
    );
  }
}

class _DhikrProgressPainter extends CustomPainter {
  final int count;
  final int total;
  final Color trackColor;
  final Color progressColor;

  _DhikrProgressPainter({
    required this.count,
    required this.total,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - 16) / 2;

    // Background track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0) return;

    // Progress arc
    final progress = (count / total).clamp(0.0, 1.0);
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DhikrProgressPainter oldDelegate) {
    return count != oldDelegate.count ||
        total != oldDelegate.total ||
        trackColor != oldDelegate.trackColor ||
        progressColor != oldDelegate.progressColor;
  }
}
