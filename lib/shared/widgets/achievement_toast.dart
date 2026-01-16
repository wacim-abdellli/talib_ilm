import 'dart:math';

import 'package:flutter/material.dart';

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
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
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
      duration: const Duration(milliseconds: 500),
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
    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            children: [
              // 1. Confetti Background (Simulated with simple shapes or external package?
              // Prompt asks for "Confetti background".
              // Without an external package like `confetti`, we can render static decoration
              // or simple animated particles. For built-in simplicity,
              // let's use a subtle pattern in the gradient container or custom painter.
              // We'll use a CustomPainter for simple sparkles behind the content.)

              // The main container
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFD4AF37),
                      Color(0xFFE8C85E),
                    ], // Gold to Light Gold
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Confetti / Sparkles
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ConfettiPainter(animation: _controller),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.emoji_events_rounded, // Trophy
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Texts
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo', // Assuming app font
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.description,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 14,
                                      fontFamily: 'Cairo',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Close Button
                            IconButton(
                              onPressed: _handleDismiss,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
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
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final Random _random = Random(42); // Fixed seed for consistent sparkly look

  _ConfettiPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value < 0.1) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final dx = _random.nextDouble() * size.width;
      final dy = _random.nextDouble() * size.height;
      final radius = _random.nextDouble() * 3 + 1;
      final opacity = (_random.nextDouble() * 0.5 + 0.1) * animation.value;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
