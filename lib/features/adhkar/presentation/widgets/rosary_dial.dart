import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';

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

class _RosaryDialState extends State<RosaryDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
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
    HapticFeedback.lightImpact();
    _pulseController.forward().then((_) {
      if (mounted) _pulseController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final progress = widget.target != null && widget.target! > 0
        ? (widget.count / widget.target!).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = widget.target != null && widget.count >= widget.target!;

    return Semantics(
      button: true,
      label: 'عداد التسبيح، اضغط للعد',
      child: InkWell(
        onTap: _handleTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 0
                      ? constraints.maxHeight
                      : 0,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.xl,
                      vertical: AppSpace.md,
                    ),
                    child: Column(
                      children: [
                        // Top Dhikr Display Card
                        AppCard(
                          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                          child: Column(
                            children: [
                              Text(
                                widget.label,
                                textAlign: TextAlign.center,
                                style: context.text.sacredLarge.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              InkWell(
                                onTap: widget.onChangeDhikr,
                                borderRadius: AppRadius.mdRadius,
                                child: Container(
                                  padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: AppSpace.md,
                                    vertical: AppSpace.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.primarySoft,
                                    borderRadius: AppRadius.mdRadius,
                                    border: Border.all(
                                      color: palette.primary,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swap_horiz_rounded,
                                        size: AppIcon.sm,
                                        color: palette.onPrimarySoft,
                                      ),
                                      const SizedBox(width: AppSpace.xs),
                                      Text(
                                        AppStrings.changeDhikr,
                                        style: context.text.caption.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: palette.onPrimarySoft,
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
                        const SizedBox(height: AppSpace.md),

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
                                    color: (isCompleted
                                            ? palette.gold
                                            : palette.primary)
                                        .withValues(alpha: 0.1),
                                  ),
                                ),

                                // Custom Painter Dial Rings & Progress
                                CustomPaint(
                                  size: const Size(220, 220),
                                  painter: _RosaryPainter(
                                    progress: progress,
                                    baseColor: palette.border,
                                    activeColor: isCompleted
                                        ? palette.gold
                                        : palette.primary,
                                    accentGold: palette.gold,
                                    isCompleted: isCompleted,
                                  ),
                                ),

                                // Center Dial Core
                                Container(
                                  width: 170,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: palette.surface,
                                    border: Border.all(
                                      color: isCompleted
                                          ? palette.gold
                                          : palette.primary,
                                      width: 2,
                                    ),
                                    boxShadow: palette.shadow,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.count.toString(),
                                        textScaler: const TextScaler.linear(2.0),
                                        style: context.text.display.copyWith(
                                          fontWeight: FontWeight.w800,
                                          height: 1.1,
                                          color: isCompleted
                                              ? palette.gold
                                              : palette.text,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.target != null
                                            ? 'الهدف: ${widget.target}'
                                            : 'عدّ حر',
                                        style: context.text.caption.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isCompleted
                                              ? palette.gold
                                              : palette.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpace.lg),
                        Text(
                          'المس الشاشة للتسبيح',
                          style: context.text.caption.copyWith(
                            color: palette.textSubtle,
                          ),
                        ),

                        const SizedBox(height: AppSpace.md),
                        const Spacer(),

                        // Bottom Action Control Island
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.xs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: AppRadius.lgRadius,
                            border: Border.all(
                              color: palette.border,
                              width: 1,
                            ),
                            boxShadow: palette.shadow,
                          ),
                          child: Row(
                            children: [
                              // Set Target Button
                              Expanded(
                                child: InkWell(
                                  onTap: widget.onSetTarget,
                                  borderRadius: AppRadius.mdRadius,
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.symmetric(
                                      horizontal: AppSpace.sm,
                                      vertical: AppSpace.sm,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.flag_outlined,
                                          size: AppIcon.sm,
                                          color: palette.gold,
                                        ),
                                        const SizedBox(width: AppSpace.xs),
                                        Flexible(
                                          child: Text(
                                            widget.target != null
                                                ? '${widget.target} مرة'
                                                : 'تحديد هدف',
                                            style: context.text.label.copyWith(
                                              color: palette.text,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              Container(
                                width: 1,
                                height: 24,
                                color: palette.border,
                              ),

                              // Reset Button
                              Expanded(
                                child: InkWell(
                                  onTap: widget.onReset,
                                  borderRadius: AppRadius.mdRadius,
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.symmetric(
                                      horizontal: AppSpace.sm,
                                      vertical: AppSpace.sm,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          size: AppIcon.sm,
                                          color: palette.textMuted,
                                        ),
                                        const SizedBox(width: AppSpace.xs),
                                        Flexible(
                                          child: Text(
                                            AppStrings.reset,
                                            style: context.text.label.copyWith(
                                              color: palette.textMuted,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        tickPaint,
      );
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
