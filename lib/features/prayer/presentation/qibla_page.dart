import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/primary_app_bar.dart';
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
    final palette = context.palette;
    final textTheme = context.text;

    if (!_hasPermission) {
      return _buildPermissionView(palette, textTheme);
    }

    final gold = palette.gold;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const PrimaryAppBar(
        title: AppStrings.qiblaTitle,
        showBack: true,
      ),
      body: Container(
        color: palette.bg,
        child: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'خطأ في بوصلة الجهاز: ${snapshot.error}',
                  style: textTheme.body.copyWith(color: palette.text),
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

            // Check alignment (within 3.5 degrees)
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
                  const SizedBox(height: AppSpace.lg),

                  // City & Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isFacingQibla ? palette.goldSoft : palette.surfaceMuted,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: isFacingQibla
                            ? gold
                            : palette.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: AppIcon.sm,
                          color: isFacingQibla ? gold : palette.textMuted,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          _currentPosition?.city ?? 'موقعك الحالي',
                          style: textTheme.caption.copyWith(
                            color: isFacingQibla ? gold : palette.textMuted,
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
                  ),

                  const SizedBox(height: AppSpace.xxl),

                  // Alignment Banner
                  AnimatedContainer(
                    duration: AppMotion.base,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.xl,
                      vertical: AppSpace.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isFacingQibla
                          ? palette.goldSoft
                          : palette.surfaceMuted,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: isFacingQibla
                            ? gold
                            : palette.border,
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
                          color: isFacingQibla ? gold : palette.textMuted,
                          size: AppIcon.sm,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Text(
                          isFacingQibla
                              ? 'أنت في اتجاه القبلة تماماً'
                              : 'وجّه هاتفك نحو الكعبة المشرفة',
                          style: textTheme.label.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isFacingQibla ? gold : palette.text,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.lg),

                  // Degree & Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${_qiblaDirection?.toStringAsFixed(0) ?? "--"}°',
                            style: textTheme.display.copyWith(
                              fontWeight: FontWeight.w800,
                              color: gold,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            'زاوية القبلة',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpace.xxxl),
                      Container(
                        width: 1,
                        height: 40,
                        color: palette.border,
                      ),
                      const SizedBox(width: AppSpace.xxxl),
                      Column(
                        children: [
                          Text(
                            _distanceToMakkah != null
                                ? '${_distanceToMakkah!.toStringAsFixed(0)} كم'
                                : '--',
                            style: textTheme.title.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.text,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            'المسافة إلى مكة',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Accuracy & Calibration
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.xxl,
                      vertical: AppSpace.lg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAccuracyBadge(context, accuracy),
                        TextButton.icon(
                          onPressed: _checkPermissionsAndStart,
                          icon: Icon(
                            Icons.refresh_rounded,
                            size: AppIcon.sm,
                            color: palette.textMuted,
                          ),
                          label: Text(
                            'إعادة المعايرة',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
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

  Widget _buildAccuracyBadge(BuildContext context, double? accuracy) {
    final palette = context.palette;
    final textTheme = context.text;

    bool isAccurate = true;
    if (accuracy != null && accuracy > 20) {
      isAccurate = false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAccurate ? palette.success : palette.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            isAccurate ? 'دقة عالية' : 'دقة منخفضة (حرّك الهاتف)',
            style: textTheme.caption.copyWith(
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionView(AppPalette palette, AppTextTheme textTheme) {
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const PrimaryAppBar(
        title: AppStrings.qiblaTitle,
        showBack: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.primarySoft,
                ),
                child: Icon(
                  Icons.explore_off_rounded,
                  size: AppIcon.hero,
                  color: palette.onPrimarySoft,
                ),
              ),
              const SizedBox(height: AppSpace.xxl),
              Text(
                'تحديد اتجاه القبلة',
                style: textTheme.title.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'نحتاج إذن الوصول إلى الموقع لحساب الاتجاه الدقيق للقبلة والمسافة إلى مكة المكرمة.',
                textAlign: TextAlign.center,
                style: textTheme.body.copyWith(
                  color: palette.textMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpace.xxxl),
              AppButton(
                label: 'منح إذن الموقع',
                onPressed: _checkPermissionsAndStart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
