import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

/// Juz data model
class JuzInfo {
  final int number;
  final String startingSurah;
  final int startingAyah;
  final double progress; // 0.0 to 1.0

  const JuzInfo({
    required this.number,
    required this.startingSurah,
    required this.startingAyah,
    this.progress = 0.0,
  });
}

/// Juz Grid View with progress circles
class JuzGridView extends StatelessWidget {
  final List<JuzInfo> juzList;
  final void Function(JuzInfo juz)? onJuzTap;

  const JuzGridView({super.key, required this.juzList, this.onJuzTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: juzList.length,
        itemBuilder: (context, index) {
          return JuzCard(
            juz: juzList[index],
            onTap: () => onJuzTap?.call(juzList[index]),
          );
        },
      ),
    );
  }
}

/// Individual Juz card with circular progress
class JuzCard extends StatelessWidget {
  final JuzInfo juz;
  final VoidCallback? onTap;

  const JuzCard({super.key, required this.juz, this.onTap});

  // Get gradient colors based on juz number (rotating through a palette)
  List<Color> _getGradientColors(int juzNumber) {
    final gradients = [
      [const Color(0xFF14B8A6), const Color(0xFF0D9488)], // Teal
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Purple
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // Blue
      [const Color(0xFFEC4899), const Color(0xFFDB2777)], // Pink
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
      [const Color(0xFF10B981), const Color(0xFF059669)], // Emerald
      [const Color(0xFF6366F1), const Color(0xFF4F46E5)], // Indigo
      [const Color(0xFFEF4444), const Color(0xFFDC2626)], // Red
      [const Color(0xFF06B6D4), const Color(0xFF0891B2)], // Cyan
      [const Color(0xFF84CC16), const Color(0xFF65A30D)], // Lime
    ];
    return gradients[(juzNumber - 1) % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final gradientColors = _getGradientColors(juz.number);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? gradientColors[0].withValues(alpha: 0.3)
                : gradientColors[0].withValues(alpha: 0.25),
            blurRadius: isDark ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Circular progress indicator around the edge
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CustomPaint(
                    painter: _CircularProgressPainter(
                      progress: juz.progress,
                      strokeWidth: 3,
                      trackColor: Colors.white.withValues(alpha: 0.2),
                      progressColor: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),

              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // "الجزء" text
                    Text(
                      'الجزء',
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Juz number (large)
                    Text(
                      juz.number.toString(),
                      style: TextStyle(
                        fontSize: responsive.sp(40),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Starting surah
                    Text(
                      juz.startingSurah,
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Progress percentage (if any progress)
                    if (juz.progress > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(juz.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: responsive.sp(11),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for circular progress around card edge
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width.clamp(0, size.height) / 2) - strokeWidth;

    // Draw track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// JUZ DATA WITH STARTING SURAHS
// ═══════════════════════════════════════════════════════════════════════════

final List<JuzInfo> allJuz = [
  JuzInfo(number: 1, startingSurah: 'الفاتحة', startingAyah: 1),
  JuzInfo(number: 2, startingSurah: 'البقرة', startingAyah: 142),
  JuzInfo(number: 3, startingSurah: 'البقرة', startingAyah: 253),
  JuzInfo(number: 4, startingSurah: 'آل عمران', startingAyah: 93),
  JuzInfo(number: 5, startingSurah: 'النساء', startingAyah: 24),
  JuzInfo(number: 6, startingSurah: 'النساء', startingAyah: 148),
  JuzInfo(number: 7, startingSurah: 'المائدة', startingAyah: 83),
  JuzInfo(number: 8, startingSurah: 'الأنعام', startingAyah: 111),
  JuzInfo(number: 9, startingSurah: 'الأعراف', startingAyah: 88),
  JuzInfo(number: 10, startingSurah: 'الأنفال', startingAyah: 41),
  JuzInfo(number: 11, startingSurah: 'التوبة', startingAyah: 93),
  JuzInfo(number: 12, startingSurah: 'هود', startingAyah: 6),
  JuzInfo(number: 13, startingSurah: 'يوسف', startingAyah: 53),
  JuzInfo(number: 14, startingSurah: 'الحجر', startingAyah: 1),
  JuzInfo(number: 15, startingSurah: 'الإسراء', startingAyah: 1),
  JuzInfo(number: 16, startingSurah: 'الكهف', startingAyah: 75),
  JuzInfo(number: 17, startingSurah: 'الأنبياء', startingAyah: 1),
  JuzInfo(number: 18, startingSurah: 'المؤمنون', startingAyah: 1),
  JuzInfo(number: 19, startingSurah: 'الفرقان', startingAyah: 21),
  JuzInfo(number: 20, startingSurah: 'النمل', startingAyah: 56),
  JuzInfo(number: 21, startingSurah: 'العنكبوت', startingAyah: 46),
  JuzInfo(number: 22, startingSurah: 'الأحزاب', startingAyah: 31),
  JuzInfo(number: 23, startingSurah: 'يس', startingAyah: 28),
  JuzInfo(number: 24, startingSurah: 'الزمر', startingAyah: 32),
  JuzInfo(number: 25, startingSurah: 'فصلت', startingAyah: 47),
  JuzInfo(number: 26, startingSurah: 'الأحقاف', startingAyah: 1),
  JuzInfo(number: 27, startingSurah: 'الذاريات', startingAyah: 31),
  JuzInfo(number: 28, startingSurah: 'المجادلة', startingAyah: 1),
  JuzInfo(number: 29, startingSurah: 'الملك', startingAyah: 1),
  JuzInfo(number: 30, startingSurah: 'النبأ', startingAyah: 1),
];
