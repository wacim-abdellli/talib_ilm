
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
import 'widgets/astrolabe_compass.dart';

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
                  AstrolabeCompass(
                    heading: heading,
                    qiblaDirection: _qiblaDirection,
                    isAligned: isFacingQibla,
                    gold: gold,
                  ),

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


