import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../core/services/location_service.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();

  LocationResult? _currentPosition;
  double? _qiblaDirection;
  double? _distanceToMakkah;
  bool _hasPermission = false;
  bool _wasAligned = false;

  late AnimationController _calibrationController;

  @override
  void initState() {
    super.initState();
    _calibrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _checkPermissionsAndStart();
  }

  @override
  void dispose() {
    _calibrationController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndStart() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      if (mounted) setState(() => _hasPermission = true);
      _initLocation();
    }
  }

  Future<void> _initLocation() async {
    try {
      final position = await _locationService.getLocation();
      final myCoords = Coordinates(position.latitude, position.longitude);
      final qibla = Qibla(myCoords);

      final distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        21.422487,
        39.826206,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _qiblaDirection = qibla.direction;
          _distanceToMakkah = distanceInMeters / 1000;
        });
      }
    } catch (e) {
      debugPrint('Error getting location for Qibla: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return _buildPermissionView();
    }

    final gold = context.goldColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          AppStrings.qiblaTitle,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Amiri',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF102224), // Celestial dark teal
              Color(0xFF0A1315), // Deep night
              Color(0xFF050A0B),
            ],
          ),
        ),
        child: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'خطأ في بوصلة الجهاز: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: gold),
              );
            }

            final event = snapshot.data;
            final heading = event?.heading ?? 0;
            final accuracy = event?.accuracy;

            // Check alignment (within 3 degrees)
            final qibla = _qiblaDirection ?? 0;
            final diff = ((heading - qibla).abs()) % 360;
            final isFacingQibla = diff < 3.5 || diff > 356.5;

            if (isFacingQibla && !_wasAligned) {
              HapticFeedback.mediumImpact();
              _wasAligned = true;
            } else if (!isFacingQibla && _wasAligned) {
              _wasAligned = false;
            }

            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // City & Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFacingQibla
                            ? gold
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: isFacingQibla ? gold : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentPosition?.city ?? 'موقعك الحالي',
                          style: TextStyle(
                            color: isFacingQibla ? gold : Colors.white70,
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Astrolabe Dial
                  _buildAstrolabeCompass(heading, isFacingQibla, gold),

                  const SizedBox(height: 28),

                  // Alignment Banner
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isFacingQibla
                          ? gold.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFacingQibla
                            ? gold
                            : Colors.white.withValues(alpha: 0.12),
                        width: isFacingQibla ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFacingQibla
                              ? Icons.check_circle_rounded
                              : Icons.navigation_rounded,
                          color: isFacingQibla ? gold : Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFacingQibla
                              ? 'أنت في اتجاه القبلة تماماً'
                              : 'وجّه هاتفك نحو الكعبة المشرفة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isFacingQibla ? gold : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Degree & Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${_qiblaDirection?.toStringAsFixed(0) ?? "--"}°',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: gold,
                              fontFamily: 'Cairo',
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'زاوية القبلة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(width: 32),
                      Column(
                        children: [
                          Text(
                            _distanceToMakkah != null
                                ? '${_distanceToMakkah!.toStringAsFixed(0)} كم'
                                : '--',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'المسافة إلى مكة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Accuracy & Calibration
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAccuracyBadge(accuracy),
                        TextButton.icon(
                          onPressed: _checkPermissionsAndStart,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: Colors.white70,
                          ),
                          label: const Text(
                            'إعادة المعايرة',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Cairo',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAstrolabeCompass(
    double heading,
    bool isAligned,
    Color gold,
  ) {
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
                    painter: _AstrolabeDialPainter(gold: gold),
                  ),

                  // Cardinal points in Cairo bold
                  _buildCardinalDirection('ش', 0, gold),
                  _buildCardinalDirection('شر', 90, Colors.white70),
                  _buildCardinalDirection('ج', 180, Colors.white70),
                  _buildCardinalDirection('غر', 270, Colors.white70),

                  // Kaaba Target Icon on outer orbit
                  if (_qiblaDirection != null)
                    Transform.rotate(
                      angle: (_qiblaDirection!) * (math.pi / 180),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -114),
                            child: Transform.rotate(
                              angle: -(_qiblaDirection!) * (math.pi / 180),
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
                  if (_qiblaDirection != null)
                    Transform.rotate(
                      angle: (_qiblaDirection!) * (math.pi / 180),
                      child: CustomPaint(
                        size: const Size(dialSize, dialSize),
                        painter: _AstrolabeNeedlePainter(gold: gold),
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

  Widget _buildAccuracyBadge(double? accuracy) {
    bool isAccurate = true;
    if (accuracy != null && accuracy > 20) {
      isAccurate = false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAccurate ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isAccurate ? 'دقة عالية' : 'دقة منخفضة (حرّك الهاتف)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionView() {
    return Scaffold(
      backgroundColor: const Color(0xFF102224),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.explore_off_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'تحديد اتجاه القبلة',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'نحتاج إذن الوصول إلى الموقع لحساب الاتجاه الدقيق للقبلة والمسافة إلى مكة المكرمة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _checkPermissionsAndStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'منح إذن الموقع',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
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

/// Ornate Astrolabe dial painter with celestial double rings and tick marks
class _AstrolabeDialPainter extends CustomPainter {
  final Color gold;
  _AstrolabeDialPainter({required this.gold});

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
class _AstrolabeNeedlePainter extends CustomPainter {
  final Color gold;
  _AstrolabeNeedlePainter({required this.gold});

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
