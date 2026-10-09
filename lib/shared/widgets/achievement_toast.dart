import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import 'app_button.dart';

class AchievementToast extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback? onDismiss;
  final Duration duration;

  const AchievementToast({
    super.key,
    required this.title,
    required this.description,
    this.onDismiss,
    this.duration = const Duration(seconds: 4),
  });

  /// Static helper to overlay the toast on top of the screen
  static void show(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.paddingOf(context).top + AppSpace.lg,
        left: AppSpace.lg,
        right: AppSpace.lg,
        child: AchievementToast(
          title: title,
          description: description,
          onDismiss: () {
            entry.remove();
          },
        ),
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<AchievementToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () async {
      if (!_isDisposed && mounted) {
        await _controller.reverse();
        if (!_isDisposed && mounted) {
          widget.onDismiss?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(
                color: palette.gold,
                width: 1.5,
              ),
              boxShadow: palette.shadow,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.lgRadius,
              child: Stack(
                children: [
                  // Sparkles / Confetti
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ConfettiPainter(
                        animation: _controller,
                        particleColor: palette.gold,
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          decoration: BoxDecoration(
                            color: palette.goldSoft,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(AppSpace.sm),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: palette.gold,
                            size: AppIcon.xl,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),

                        // Texts
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: textTheme.titleSmall.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                widget.description,
                                style: textTheme.bodySmall.copyWith(
                                  color: palette.textMuted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: AppSpace.sm),

                        // Close Button
                        AppIconButton(
                          onPressed: _handleDismiss,
                          icon: Icons.close_rounded,
                          tooltip: 'إغلاق',
                          color: palette.textMuted,
                          iconSize: AppIcon.md,
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
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final Color particleColor;
  final Random _random = Random(42);

  _ConfettiPainter({
    required this.animation,
    required this.particleColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value < 0.1) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final dx = _random.nextDouble() * size.width;
      final dy = _random.nextDouble() * size.height;
      final radius = _random.nextDouble() * 3 + 1;
      final opacity = (_random.nextDouble() * 0.4 + 0.1) * animation.value;

      paint.color = particleColor.withValues(alpha: opacity);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
