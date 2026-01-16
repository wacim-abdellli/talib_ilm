import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/app_drawer.dart';

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(selectedIndex: 1),
      appBar: AppBar(
        title: const Text(
          AppStrings.qiblaTitle,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) {
            final canPop = Navigator.of(context).canPop();
            return IconButton(
              icon: Icon(canPop ? Icons.arrow_back : Icons.menu),
              onPressed: () {
                if (canPop) {
                  Navigator.pop(context);
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
          ),
        ),
        child: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final event = snapshot.data;
            final heading = event?.heading ?? 0;
            final accuracy = event?.accuracy;

            return SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  _buildCompass(heading),

                  const SizedBox(height: 48),

                  Text(
                    '${_qiblaDirection?.toStringAsFixed(0) ?? "--"}°',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _distanceToMakkah != null
                        ? '${_distanceToMakkah!.toStringAsFixed(0)} كم إلى مكة'
                        : 'جاري حساب المسافة...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAccuracyBadge(accuracy),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        if (accuracy != null && accuracy > 15) ...[
                          // Heuristic for low accuracy on iOS, ignored if not applicable
                          _buildCalibrationHint(),
                          const SizedBox(height: 24),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currentPosition?.city ?? "-",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            _checkPermissionsAndStart();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text('إعادة المعايرة'),
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

  Widget _buildCompass(double heading) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(20, 20),
              painter: _TrianglePainter(color: Colors.white),
            ),
          ),

          Transform.rotate(
            angle: -heading * (math.pi / 180),
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(300, 300),
                    painter: _CompassDialPainter(),
                  ),

                  _buildCardinalDirection('ش', 0),
                  _buildCardinalDirection('شر', 90),
                  _buildCardinalDirection('ج', 180),
                  _buildCardinalDirection('غر', 270),

                  if (_qiblaDirection != null)
                    Transform.rotate(
                      angle: (_qiblaDirection!) * (math.pi / 180),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -110),
                            child: Transform.rotate(
                              angle: -(_qiblaDirection!) * (math.pi / 180),
                              child: Image.asset(
                                'assets/icons/kaaba.png',
                                width: 40,
                                height: 40,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.mosque,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_qiblaDirection != null)
                    Transform.rotate(
                      angle: (_qiblaDirection!) * (math.pi / 180),
                      child: CustomPaint(
                        size: const Size(300, 300),
                        painter: _NeedlePainter(),
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

  Widget _buildCardinalDirection(String text, double angleDeg) {
    const radius = 90.0;

    final x = radius * math.sin(angleDeg * (math.pi / 180));
    final y = -radius * math.cos(angleDeg * (math.pi / 180));

    return Transform.translate(
      offset: Offset(x, y),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildAccuracyBadge(double? accuracy) {
    bool isAccurate = true;
    if (accuracy != null) {
      if (accuracy > 20) isAccurate = false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
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
            isAccurate ? 'دقة عالية' : 'دقة منخفضة',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationHint() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _calibrationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _calibrationController.value * math.pi * 0.1,
              child: const Icon(
                Icons.all_inclusive,
                size: 48,
                color: Colors.white70,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'حرّك هاتفك بحركة 8',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPermissionView() {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_disabled, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'نحتاج إذن الموقع لتحديد القبلة',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkPermissionsAndStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('منح الصلاحية'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Outer Ring
    canvas.drawCircle(center, radius, paint);

    // Degree MArkers
    for (int i = 0; i < 360; i += 5) {
      final isMajor = i % 30 == 0;
      final markerLength = isMajor ? 15.0 : 8.0;
      final angle = (i - 90) * (math.pi / 180);

      final p1 = Offset(
        center.dx + (radius - markerLength) * math.cos(angle),
        center.dy + (radius - markerLength) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      paint.strokeWidth = isMajor ? 2 : 1;
      paint.color = Colors.white.withValues(alpha: isMajor ? 0.8 : 0.4);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final path = Path();
    path.moveTo(center.dx, center.dy - 100); // Tip
    path.lineTo(center.dx - 15, center.dy);
    path.lineTo(center.dx + 15, center.dy);
    path.close();

    // Top Shadow
    canvas.drawShadow(path, Colors.black, 4, true);

    final paint = Paint()
      ..color =
          const Color(0xFFD4AF37) // Gold
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width / 2, size.height); // Bottom center
    path.lineTo(0, 0); // Top Left
    path.lineTo(size.width, 0); // Top Right
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
