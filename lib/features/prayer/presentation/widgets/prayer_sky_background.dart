import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Prayer periods for sky gradient
enum PrayerPeriod {
  night, // After Isha to before Fajr
  dawn, // Fajr to Sunrise
  morning, // Sunrise to Dhuhr
  afternoon, // Dhuhr to Asr
  evening, // Asr to Maghrib
  sunset, // Maghrib to Isha
}

/// Dynamic sky background that changes based on prayer time
class PrayerSkyBackground extends StatefulWidget {
  final DateTime? fajrTime;
  final DateTime? sunriseTime;
  final DateTime? dhuhrTime;
  final DateTime? asrTime;
  final DateTime? maghribTime;
  final DateTime? ishaTime;
  final Widget? child;

  const PrayerSkyBackground({
    super.key,
    this.fajrTime,
    this.sunriseTime,
    this.dhuhrTime,
    this.asrTime,
    this.maghribTime,
    this.ishaTime,
    this.child,
  });

  @override
  State<PrayerSkyBackground> createState() => _PrayerSkyBackgroundState();
}

class _PrayerSkyBackgroundState extends State<PrayerSkyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  PrayerPeriod _currentPeriod = PrayerPeriod.night;
  double _celestialPosition = 0.5; // 0 = horizon, 1 = zenith

  // Gradient colors for each period
  static const Map<PrayerPeriod, List<Color>> _gradients = {
    PrayerPeriod.night: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
    PrayerPeriod.dawn: [Color(0xFF3D2C5E), Color(0xFFFF6B35)],
    PrayerPeriod.morning: [Color(0xFF87CEEB), Color(0xFF4FC3F7)],
    PrayerPeriod.afternoon: [Color(0xFF4FC3F7), Color(0xFFFFD54F)],
    PrayerPeriod.evening: [Color(0xFFFFD54F), Color(0xFFFF8A65)],
    PrayerPeriod.sunset: [Color(0xFFFF6B35), Color(0xFF6A1B9A)],
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat(reverse: true);

    _updatePeriod();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePeriod() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Default times if not provided (approximate)
    final fajr = _timeToMinutes(widget.fajrTime) ?? 5 * 60; // 5:00
    final sunrise = _timeToMinutes(widget.sunriseTime) ?? 6 * 60 + 30; // 6:30
    final dhuhr = _timeToMinutes(widget.dhuhrTime) ?? 12 * 60 + 30; // 12:30
    final asr = _timeToMinutes(widget.asrTime) ?? 15 * 60 + 30; // 15:30
    final maghrib = _timeToMinutes(widget.maghribTime) ?? 18 * 60; // 18:00
    final isha = _timeToMinutes(widget.ishaTime) ?? 19 * 60 + 30; // 19:30

    PrayerPeriod newPeriod;
    double position;

    if (currentMinutes < fajr) {
      newPeriod = PrayerPeriod.night;
      position = 0.8; // Moon high
    } else if (currentMinutes < sunrise) {
      newPeriod = PrayerPeriod.dawn;
      position = _calculatePosition(currentMinutes, fajr, sunrise);
    } else if (currentMinutes < dhuhr) {
      newPeriod = PrayerPeriod.morning;
      position = _calculatePosition(currentMinutes, sunrise, dhuhr);
    } else if (currentMinutes < asr) {
      newPeriod = PrayerPeriod.afternoon;
      position = 1.0 - _calculatePosition(currentMinutes, dhuhr, asr) * 0.3;
    } else if (currentMinutes < maghrib) {
      newPeriod = PrayerPeriod.evening;
      position = 0.7 - _calculatePosition(currentMinutes, asr, maghrib) * 0.5;
    } else if (currentMinutes < isha) {
      newPeriod = PrayerPeriod.sunset;
      position = 0.2 - _calculatePosition(currentMinutes, maghrib, isha) * 0.2;
    } else {
      newPeriod = PrayerPeriod.night;
      position = 0.3 + _calculatePosition(currentMinutes, isha, 24 * 60) * 0.5;
    }

    setState(() {
      _currentPeriod = newPeriod;
      _celestialPosition = position.clamp(0.0, 1.0);
    });
  }

  int? _timeToMinutes(DateTime? time) {
    if (time == null) return null;
    return time.hour * 60 + time.minute;
  }

  double _calculatePosition(int current, int start, int end) {
    if (end <= start) return 0;
    return ((current - start) / (end - start)).clamp(0.0, 1.0);
  }

  bool get _isNightTime =>
      _currentPeriod == PrayerPeriod.night ||
      _currentPeriod == PrayerPeriod.dawn ||
      _currentPeriod == PrayerPeriod.sunset;

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[_currentPeriod]!;

    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 30),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Stack(
          children: [
            // Sky gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                  stops: const [0.0, 1.0],
                ),
              ),
            ),

            // Stars (only at night)
            if (_isNightTime)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _StarsPainter(
                      opacity: _currentPeriod == PrayerPeriod.night ? 0.8 : 0.3,
                      twinkle: _controller.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),

            // Celestial body (Sun or Moon)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height * 0.4;

                // Parabolic path for celestial body
                final xPosition = screenWidth * 0.5;
                final yPosition =
                    screenHeight * (1 - _celestialPosition) +
                    math.sin(_controller.value * math.pi) * 10;

                return Positioned(
                  left: xPosition - 30,
                  top: yPosition,
                  child: _isNightTime
                      ? _MoonWidget(glowIntensity: _controller.value)
                      : _SunWidget(glowIntensity: _controller.value),
                );
              },
            ),

            // Child content
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}

/// Sun widget with gradient and glow
class _SunWidget extends StatelessWidget {
  final double glowIntensity;

  const _SunWidget({required this.glowIntensity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFEB3B), Color(0xFFFF9800)],
          stops: [0.3, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFFFEB3B,
            ).withValues(alpha: 0.3 + glowIntensity * 0.3),
            blurRadius: 30 + glowIntensity * 20,
            spreadRadius: 10 + glowIntensity * 10,
          ),
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.2),
            blurRadius: 50,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

/// Moon widget with crescent shape and glow
class _MoonWidget extends StatelessWidget {
  final double glowIntensity;

  const _MoonWidget({required this.glowIntensity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFE3F2FD,
            ).withValues(alpha: 0.3 + glowIntensity * 0.2),
            blurRadius: 20 + glowIntensity * 15,
            spreadRadius: 5 + glowIntensity * 5,
          ),
        ],
      ),
      child: CustomPaint(painter: _CrescentMoonPainter()),
    );
  }
}

/// Custom painter for crescent moon
class _CrescentMoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFDE7)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw full moon
    canvas.drawCircle(center, radius, paint);

    // Cut out shadow to create crescent
    final shadowPaint = Paint()
      ..color = const Color(0xFF1B263B)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx + radius * 0.4, center.dy),
      radius * 0.85,
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for stars
class _StarsPainter extends CustomPainter {
  final double opacity;
  final double twinkle;

  _StarsPainter({required this.opacity, required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.6;
      final starSize = 1 + random.nextDouble() * 2;

      // Twinkle effect
      final starOpacity =
          opacity * (0.5 + 0.5 * math.sin(twinkle * math.pi * 2 + i * 0.5));

      paint.color = Colors.white.withValues(alpha: starOpacity);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) {
    return oldDelegate.twinkle != twinkle || oldDelegate.opacity != opacity;
  }
}
