import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Parchment texture background for Quran reading
class ParchmentBackground extends StatelessWidget {
  final Widget? child;
  final bool isDark;
  final bool showBorders;
  final bool showVignette;

  const ParchmentBackground({
    super.key,
    this.child,
    this.isDark = false,
    this.showBorders = true,
    this.showVignette = true,
  });

  @override
  Widget build(BuildContext context) {
    // Colors based on theme
    final baseColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFFF9E6);

    final borderColor = isDark
        ? const Color(0xFF14B8A6)
        : const Color(0xFFD4AF37); // Gold

    return Stack(
      children: [
        // Base paper color
        Container(color: baseColor),

        // Paper grain texture
        CustomPaint(
          painter: _PaperTexturePainter(isDark: isDark),
          size: Size.infinite,
        ),

        // Light from above gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? Colors.white : Colors.white).withValues(
                  alpha: isDark ? 0.02 : 0.15,
                ),
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
        ),

        // Vignette effect
        if (showVignette)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  (isDark ? Colors.black : const Color(0xFF8B7355)).withValues(
                    alpha: isDark ? 0.4 : 0.08,
                  ),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),

        // Top decorative border
        if (showBorders)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: CustomPaint(
              painter: _ArabesqueBorderPainter(
                color: borderColor,
                isTop: true,
                isDark: isDark,
              ),
            ),
          ),

        // Bottom decorative border
        if (showBorders)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: CustomPaint(
              painter: _ArabesqueBorderPainter(
                color: borderColor,
                isTop: false,
                isDark: isDark,
              ),
            ),
          ),

        // Child content
        if (child != null) child!,
      ],
    );
  }
}

/// Paper texture painter with grain effect
class _PaperTexturePainter extends CustomPainter {
  final bool isDark;

  _PaperTexturePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistency
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw noise/grain
    final grainCount = (size.width * size.height / 200).toInt().clamp(
      500,
      3000,
    );

    for (int i = 0; i < grainCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final dotSize = 0.5 + random.nextDouble() * 1.5;

      // Brown/beige grain colors
      final grainColors = isDark
          ? [const Color(0xFFFFFFFF), const Color(0xFF14B8A6)]
          : [
              const Color(0xFF8B7355),
              const Color(0xFFD4B896),
              const Color(0xFFA0826D),
            ];

      paint.color = grainColors[random.nextInt(grainColors.length)].withValues(
        alpha: isDark ? 0.015 : 0.025,
      );

      canvas.drawCircle(Offset(x, y), dotSize, paint);
    }

    // Add some larger, more visible spots for aged effect
    if (!isDark) {
      for (int i = 0; i < 30; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final spotSize = 2 + random.nextDouble() * 4;

        paint.color = const Color(0xFF8B7355).withValues(alpha: 0.02);
        canvas.drawCircle(Offset(x, y), spotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Arabesque border painter
class _ArabesqueBorderPainter extends CustomPainter {
  final Color color;
  final bool isTop;
  final bool isDark;

  _ArabesqueBorderPainter({
    required this.color,
    required this.isTop,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw decorative pattern
    final path = Path();
    const patternWidth = 40.0;
    final patternCount = (size.width / patternWidth).ceil() + 1;

    for (int i = 0; i < patternCount; i++) {
      final x = i * patternWidth;
      final baseY = isTop ? size.height : 0.0;
      final direction = isTop ? -1.0 : 1.0;

      // Draw arabesque curves
      path.moveTo(x, baseY);
      path.quadraticBezierTo(
        x + patternWidth / 4,
        baseY + direction * 20,
        x + patternWidth / 2,
        baseY,
      );
      path.quadraticBezierTo(
        x + patternWidth * 3 / 4,
        baseY - direction * 15,
        x + patternWidth,
        baseY,
      );
    }

    canvas.drawPath(path, paint);

    // Draw horizontal line
    final lineY = isTop ? size.height - 2.0 : 2.0;
    paint.strokeWidth = 0.5;
    canvas.drawLine(Offset(0, lineY), Offset(size.width, lineY), paint);

    // Draw decorative dots
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < patternCount; i++) {
      final x = i * patternWidth + patternWidth / 2.0;
      final y = isTop ? size.height - 8.0 : 8.0;
      canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
    }

    // Draw corner flourishes
    _drawCornerFlourish(
      canvas,
      paint,
      0.0,
      isTop ? size.height : 0.0,
      false,
      isTop,
    );
    _drawCornerFlourish(
      canvas,
      paint,
      size.width,
      isTop ? size.height : 0.0,
      true,
      isTop,
    );
  }

  void _drawCornerFlourish(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    bool mirror,
    bool isTop,
  ) {
    final path = Path();
    final m = mirror ? -1.0 : 1.0;
    final d = isTop ? -1.0 : 1.0;

    path.moveTo(x, y);
    path.cubicTo(
      x + m * 30,
      y + d * 10,
      x + m * 20,
      y + d * 25,
      x + m * 40,
      y + d * 30,
    );

    paint.strokeWidth = 1.0;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
