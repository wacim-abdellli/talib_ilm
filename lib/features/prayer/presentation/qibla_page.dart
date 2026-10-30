import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../core/services/compass_service.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _calibrationController = AnimationController(
      vsync: this,
      duration: AppMotion.twoSeconds,
    )..repeat(reverse: true);

    _checkPermissionsAndStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _calibrationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasPermission) {
      _checkPermissionsAndStart();
    }
  }

  Future<void> _checkPermissionsAndStart() async {
    final status = await Permission.location.status;
    if (status.isGranted || status.isLimited) {
      if (mounted) setState(() => _hasPermission = true);
      _initLocation();
    }
  }

  Future<void> _requestPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      _showEnableLocationServiceDialog();
      return;
    }

    final status = await Permission.location.request();
    if (status.isGranted || status.isLimited) {
      if (mounted) setState(() => _hasPermission = true);
      _initLocation();
    } else if (status.isPermanentlyDenied || status.isDenied || status.isRestricted) {
      if (!mounted) return;
      _showOpenSettingsDialog();
    }
  }

  void _showOpenSettingsDialog() {
    _showPermissionDialog(
      title: 'إذن الموقع مطلوب',
      message: 'لتحديد اتجاه القبلة بدقة، يرجى تفعيل إذن الموقع لتطبيق طالب العلم من إعدادات الهاتف.',
      icon: Icons.location_off_rounded,
      actionLabel: 'فتح الإعدادات',
      onAction: openAppSettings,
    );
  }

  void _showEnableLocationServiceDialog() {
    _showPermissionDialog(
      title: 'خدمة الموقع مغلقة',
      message: 'خدمات تحديد الموقع (GPS) مغلقة على الهاتف. يرجى تفعيلها لحساب اتجاه القبلة بدقة.',
      icon: Icons.location_disabled_rounded,
      actionLabel: 'تفعيل الموقع',
      onAction: Geolocator.openLocationSettings,
    );
  }

  void _showPermissionDialog({
    required String title,
    required String message,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
          side: BorderSide(color: context.palette.border),
        ),
        title: Row(
          children: [
            Icon(icon, color: context.palette.gold),
            const SizedBox(width: AppSpace.sm),
            Text(
              title,
              style: context.text.title.copyWith(color: context.palette.text),
            ),
          ],
        ),
        content: Text(
          message,
          style: context.text.body.copyWith(color: context.palette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'إلغاء',
              style: context.text.label.copyWith(color: context.palette.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.primary,
              foregroundColor: context.palette.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onAction();
            },
            child: Text(
              actionLabel,
              style: context.text.label.copyWith(color: context.palette.onPrimary),
            ),
          ),
        ],
      ),
    );
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
                        width: isFacingQibla && isSensorAvailable ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          !isSensorAvailable
                              ? Icons.info_outline_rounded
                              : isFacingQibla
                                  ? Icons.check_circle_rounded
                                  : Icons.navigation_rounded,
                          color: isFacingQibla && isSensorAvailable ? gold : palette.textMuted,
                          size: AppIcon.sm,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Text(
                          !isSensorAvailable
                              ? 'الهاتف لا يدعم مستشعر البوصلة'
                              : isFacingQibla
                                  ? 'أنت في اتجاه القبلة تماماً'
                                  : 'وجّه هاتفك نحو الكعبة المشرفة',
                          style: textTheme.labelBold.copyWith(
                            color: isFacingQibla && isSensorAvailable ? gold : palette.text,
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
                            style: textTheme.displayHeavy.copyWith(
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
                            style: textTheme.titleHeavy.copyWith(
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
                        _buildAccuracyBadge(context, accuracy, isSensorAvailable),
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
              const SizedBox(height: AppSpace.xxl),
              AppButton(
                label: 'منح إذن الموقع',
                icon: Icons.check_circle_rounded,
                onPressed: _requestPermissions,
              ),
              const SizedBox(height: AppSpace.md),
              AppButton.text(
                label: 'استخدام المدينة المحددة في التطبيق',
                icon: Icons.location_city_rounded,
                onPressed: () {
                  setState(() => _hasPermission = true);
                  _initLocation();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
