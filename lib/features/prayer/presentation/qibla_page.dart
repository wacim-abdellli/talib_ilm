import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../core/services/compass_service.dart';
import '../../../core/services/location_service.dart';
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
  bool _wasAligned = false;

  late AnimationController _calibrationController;

  @override
  void initState() {
    super.initState();
    _calibrationController = AnimationController(
      vsync: this,
      duration: AppMotion.twoSeconds,
    )..repeat(reverse: true);

    _initLocation();
  }

  @override
  void dispose() {
    _calibrationController.dispose();
    super.dispose();
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
    final gold = palette.gold;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const PrimaryAppBar(
        title: AppStrings.qiblaTitle,
        showBack: true,
      ),
      body: _currentPosition == null
          ? Center(
              child: CircularProgressIndicator(color: gold),
            )
          : Container(
              color: palette.bg,
              child: StreamBuilder<CompassReading>(
                stream: CompassService().stream,
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

                  final reading = snapshot.data;
                  final heading = reading?.heading ?? 0;
                  final accuracy = reading?.accuracy;
                  final isSensorAvailable = reading?.isSensorAvailable ?? true;

                  // Check alignment (within 3.5 degrees)
                  final qibla = _qiblaDirection ?? 0;
                  final diff = ((heading - qibla).abs()) % 360;
                  final isFacingQibla = diff < 3.5 || diff > 356.5;

                  if (isFacingQibla && !_wasAligned && isSensorAvailable) {
                    HapticFeedback.mediumImpact();
                    _wasAligned = true;
                  } else if ((!isFacingQibla || !isSensorAvailable) && _wasAligned) {
                    _wasAligned = false;
                  }

                  return SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpace.lg),

                        // City & Status Pill (directly displays the chosen city/capital)
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
                                Icons.location_city_rounded,
                                size: AppIcon.sm,
                                color: isFacingQibla ? gold : palette.textMuted,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                _currentPosition?.city ?? 'مكة المكرمة',
                                style: textTheme.captionBold.copyWith(
                                  color: isFacingQibla ? gold : palette.textMuted,
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
                            color: isFacingQibla && isSensorAvailable
                                ? palette.goldSoft
                                : palette.surfaceMuted,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: isFacingQibla && isSensorAvailable
                                  ? gold
                                  : palette.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isFacingQibla && isSensorAvailable
                                    ? Icons.check_circle_rounded
                                    : Icons.explore_rounded,
                                size: AppIcon.md,
                                color: isFacingQibla && isSensorAvailable
                                    ? gold
                                    : palette.textMuted,
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Text(
                                isFacingQibla && isSensorAvailable
                                    ? 'أنت تواجه القبلة المشرفة مباشرة'
                                    : 'أدر الهاتف حتى يتطابق السهم الذهبي مع القبلة',
                                style: textTheme.body.copyWith(
                                  color: isFacingQibla && isSensorAvailable
                                      ? gold
                                      : palette.textMuted,
                                  fontWeight: isFacingQibla && isSensorAvailable
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpace.md),

                        // Accuracy & Guidance
                        _buildAccuracyBadge(context, accuracy, isSensorAvailable),

                        const Spacer(),

                        // Bottom Info Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                          padding: const EdgeInsets.all(AppSpace.lg),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: AppRadius.lgRadius,
                            border: Border.all(color: palette.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'زاوية القبلة',
                                    style: textTheme.caption.copyWith(
                                      color: palette.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.xs),
                                  Text(
                                    _qiblaDirection != null
                                        ? '${_qiblaDirection!.toStringAsFixed(1)}°'
                                        : '--',
                                    style: textTheme.title.copyWith(
                                      color: palette.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: palette.border,
                              ),
                              Column(
                                children: [
                                  Text(
                                    'المسافة إلى مكة',
                                    style: textTheme.caption.copyWith(
                                      color: palette.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.xs),
                                  Text(
                                    _distanceToMakkah != null
                                        ? '${_distanceToMakkah!.toStringAsFixed(0)} كم'
                                        : '--',
                                    style: textTheme.title.copyWith(
                                      color: palette.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpace.lg),

                        // Calibration Hint
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.lg),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FadeTransition(
                                opacity: _calibrationController,
                                child: Icon(
                                  Icons.screen_rotation_rounded,
                                  size: AppIcon.sm,
                                  color: palette.textMuted,
                                ),
                              ),
                              const SizedBox(width: AppSpace.xs),
                              TextButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _initLocation();
                                },
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: AppIcon.sm,
                                  color: palette.textMuted,
                                ),
                                label: Text(
                                  'إعادة التحديث',
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

  Widget _buildAccuracyBadge(
    BuildContext context,
    double? accuracy,
    bool isSensorAvailable,
  ) {
    final palette = context.palette;
    final textTheme = context.text;

    if (!isSensorAvailable) {
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
                color: palette.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              'استدل بالزاوية أعلاه بالنسبة للشمال',
              style: textTheme.caption.copyWith(
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      );
    }

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
            isAccurate ? 'دقة عالية' : 'دقة منخفضة (حرّك الهاتف 8)',
            style: textTheme.caption.copyWith(
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}
