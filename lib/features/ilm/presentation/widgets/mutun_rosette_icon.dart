import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';

/// Authentic Islamic 8-pointed geometric rosette icon as seen in the Mutun reference app.
class MutunRosetteIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const MutunRosetteIcon({
    super.key,
    this.color,
    this.size = AppIcon.lg,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? MutunThemeColors.getTokens(isDark: context.palette.isDark).rosetteGold;

    return CustomPaint(
      size: Size(size, size),
      painter: _RosettePainter(color: effectiveColor),
    );
  }
}

class _RosettePainter extends CustomPainter {
  final Color color;

  _RosettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;

    final paintFill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw 8-point geometric star (two overlapping squares rotated 45 degrees)
    final path = Path();
    const int points = 8;
    const double step = math.pi / points;
    final double innerRadius = radius * 0.58;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius * 0.9 : innerRadius;
      final angle = i * step - (math.pi / 2);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill star softly
    canvas.drawPath(path, paintFill);
    // Draw star outline
    canvas.drawPath(path, paintStroke);

    // Draw central decorative circle ring
    canvas.drawCircle(center, radius * 0.28, paintStroke);
    // Draw center point dot
    canvas.drawCircle(
      center,
      radius * 0.1,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RosettePainter oldDelegate) =>
      oldDelegate.color != color;
}
