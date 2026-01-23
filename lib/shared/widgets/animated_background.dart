import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A star element with its properties
class _StarElement {
  final Offset position;
  final double size;
  final double rotationSpeed;
  final double initialRotation;

  _StarElement({
    required this.position,
    required this.size,
    required this.rotationSpeed,
    required this.initialRotation,
  });
}

/// Animated geometric background with Islamic 8-point stars
class AnimatedGeometricBackground extends StatefulWidget {
  final Color starColor;
  final int starCount;

  const AnimatedGeometricBackground({
    super.key,
    this.starColor = const Color(0xFF14B8A6), // Teal
    this.starCount = 12,
  });

  @override
  State<AnimatedGeometricBackground> createState() =>
      _AnimatedGeometricBackgroundState();
}

class _AnimatedGeometricBackgroundState
    extends State<AnimatedGeometricBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_StarElement> _stars = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _generateStars();
      _initialized = true;
    }
  }

  void _generateStars() {
    final random = math.Random(42); // Fixed seed for consistency
    final size = MediaQuery.of(context).size;

    _stars = List.generate(widget.starCount, (index) {
      return _StarElement(
        position: Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        size: 50 + random.nextDouble() * 150, // 50-200
        rotationSpeed: 0.5 + random.nextDouble() * 1.5, // Different speeds
        initialRotation: random.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: GeometricPatternPainter(
            stars: _stars,
            animationValue: _controller.value,
            starColor: widget.starColor.withValues(alpha: 0.03), // 3% opacity
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Custom painter for Islamic geometric patterns
class GeometricPatternPainter extends CustomPainter {
  final List<_StarElement> stars;
  final double animationValue;
  final Color starColor;

  GeometricPatternPainter({
    required this.stars,
    required this.animationValue,
    required this.starColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = starColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..blendMode = BlendMode.screen;

    for (final star in stars) {
      final rotation =
          star.initialRotation +
          (animationValue * math.pi * 2 * star.rotationSpeed);

      canvas.save();
      canvas.translate(star.position.dx, star.position.dy);
      canvas.rotate(rotation);

      _draw8PointStar(canvas, paint, star.size);

      canvas.restore();
    }
  }

  /// Draw an 8-point Islamic star
  void _draw8PointStar(Canvas canvas, Paint paint, double size) {
    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.4;
    final path = Path();

    const points = 8;
    const twoPi = math.pi * 2;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * twoPi) / (points * 2) - math.pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // Draw inner decorative square (rotated 45°)
    final innerSquareSize = innerRadius * 0.8;
    canvas.save();
    canvas.rotate(math.pi / 4);

    final squarePaint = Paint()
      ..color = starColor.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..blendMode = BlendMode.screen;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: innerSquareSize * 2,
        height: innerSquareSize * 2,
      ),
      squarePaint,
    );
    canvas.restore();

    // Draw outer circle (decorative)
    final circlePaint = Paint()
      ..color = starColor.withValues(alpha: 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(Offset.zero, outerRadius * 1.1, circlePaint);
  }

  @override
  bool shouldRepaint(GeometricPatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
