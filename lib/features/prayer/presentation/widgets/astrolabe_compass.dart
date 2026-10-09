import 'dart:math' as math;
import 'package:flutter/material.dart';

class AstrolabeCompass extends StatelessWidget {
  final double heading;
  final double? qiblaDirection;
  final bool isAligned;
  final Color gold;

  const AstrolabeCompass({
    super.key,
    required this.heading,
    required this.qiblaDirection,
    required this.isAligned,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    const dialSize = 310.0;

    return Container(
      width: dialSize,
      height: dialSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isAligned
            ? [
                BoxShadow(
                  color: gold.withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fixed Top Alignment Needle Pointer
          Positioned(
            top: 4,
            child: Icon(
              Icons.arrow_drop_down_rounded,
              size: 28,
              color: isAligned ? gold : Colors.white,
            ),
          ),

          // Rotating Dial with Compass Ring & Kaaba
          Transform.rotate(
            angle: -heading * (math.pi / 180),
            child: SizedBox(
              width: dialSize,
              height: dialSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Astrolabe dial canvas
                  CustomPaint(
                    size: const Size(dialSize, dialSize),
                    painter: AstrolabeDialPainter(gold: gold),
                  ),

                  // Cardinal points in Cairo bold
                  _buildCardinalDirection('ش', 0, gold),
                  _buildCardinalDirection('شر', 90, Colors.white70),
                  _buildCardinalDirection('ج', 180, Colors.white70),
                  _buildCardinalDirection('غر', 270, Colors.white70),

                  // Kaaba Target Icon on outer orbit
                  if (qiblaDirection != null)
                    Transform.rotate(
                      angle: (qiblaDirection!) * (math.pi / 180),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -114),
                            child: Transform.rotate(
                              angle: -(qiblaDirection!) * (math.pi / 180),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isAligned
                                      ? gold
                                      : const Color(0xFF1E282A),
                                  border: Border.all(
                                    color: gold,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gold.withValues(
                                        alpha: isAligned ? 0.6 : 0.25,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.mosque_rounded,
                                  size: 22,
                                  color: isAligned ? Colors.black : gold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Inner Qibla needle
                  if (qiblaDirection != null)
                    Transform.rotate(
                      angle: (qiblaDirection!) * (math.pi / 180),
                      child: CustomPaint(
                        size: const Size(dialSize, dialSize),
                        painter: AstrolabeNeedlePainter(gold: gold),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardinalDirection(String text, double angleDeg, Color color) {
    const radius = 95.0;
    final x = radius * math.sin(angleDeg * (math.pi / 180));
    final y = -radius * math.cos(angleDeg * (math.pi / 180));

    return Transform.translate(
      offset: Offset(x, y),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

/// Ornate Astrolabe dial painter with celestial double rings and tick marks
class AstrolabeDialPainter extends CustomPainter {
  final Color gold;
  AstrolabeDialPainter({required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background disc
    final discPaint = Paint()
      ..color = const Color(0xFF0F1A1B).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, discPaint);

    // Outer double brass rings
    final ringPaint = Paint()
      ..color = gold.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 4, ringPaint);
    canvas.drawCircle(center, radius - 16, ringPaint..color = gold.withValues(alpha: 0.25));

    // Inner subtle ring
    canvas.drawCircle(
      center,
      radius * 0.52,
      ringPaint..color = gold.withValues(alpha: 0.18),
    );

    // Degree Ticks
    for (int i = 0; i < 360; i += 5) {
      final isMajor = i % 30 == 0;
      final isMedium = i % 15 == 0;
      final tickLength = isMajor ? 12.0 : (isMedium ? 8.0 : 4.0);
      final angle = (i - 90) * (math.pi / 180);

      final p1 = Offset(
        center.dx + (radius - 16 - tickLength) * math.cos(angle),
        center.dy + (radius - 16 - tickLength) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 16) * math.cos(angle),
        center.dy + (radius - 16) * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = isMajor
            ? gold.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: isMedium ? 0.4 : 0.2)
        ..strokeWidth = isMajor ? 1.5 : 1;

      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Dynamic Needle Painter towards Qibla
class AstrolabeNeedlePainter extends CustomPainter {
  final Color gold;
  AstrolabeNeedlePainter({required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final path = Path();
    path.moveTo(center.dx, center.dy - 88); // Needle tip
    path.lineTo(center.dx - 10, center.dy);
    path.lineTo(center.dx + 10, center.dy);
    path.close();

    // Shadow
    canvas.drawShadow(path, Colors.black, 4, true);

    // Golden Needle
    final paint = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Center Gold Pivot Cap
    canvas.drawCircle(
      center,
      12,
      Paint()..color = gold,
    );
    canvas.drawCircle(
      center,
      6,
      Paint()..color = const Color(0xFF102224),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
