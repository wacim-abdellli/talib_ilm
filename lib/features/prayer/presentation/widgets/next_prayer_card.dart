import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/models/prayer_models.dart';

class NextPrayerCard extends StatefulWidget {
  final NextPrayer prayer;
  final VoidCallback onTap;
  final String? countdownText;

  const NextPrayerCard({
    super.key,
    required this.prayer,
    required this.onTap,
    this.countdownText,
  });

  @override
  State<NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<NextPrayerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  int? _startMinutes;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1, end: 1.04).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _syncProgressStart();
  }

  @override
  void didUpdateWidget(covariant NextPrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final minutes = widget.prayer.minutesRemaining;
    if (widget.prayer.prayer != oldWidget.prayer.prayer ||
        widget.prayer.time != oldWidget.prayer.time ||
        minutes > oldWidget.prayer.minutesRemaining ||
        _startMinutes == null) {
      _syncProgressStart();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _syncProgressStart() {
    _startMinutes = _safeMinutes(widget.prayer.minutesRemaining);
  }

  int _safeMinutes(int value) => value <= 0 ? 1 : value;

  double _progressValue() {
    final remaining = widget.prayer.minutesRemaining;
    final start = _startMinutes ?? remaining;
    final safeStart = start <= 0 ? 1 : start;
    if (remaining <= 0) return 1;
    final progress = 1 - (remaining / safeStart);
    if (progress <= 0) return 0;
    if (progress >= 1) return 1;
    return progress;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusLG);
    final progress = _progressValue();
    final countdownLabel = widget.countdownText ??
        AppStrings.prayerInMinutes(widget.prayer.minutesRemaining);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress),
      duration: AppUi.animationMedium,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return CustomPaint(
          foregroundPainter: _CardProgressPainter(
            progress: value,
            color: AppColors.secondary,
            trackColor: AppColors.secondary.withOpacity(0.18),
            strokeWidth: 4,
            radius: AppUi.radiusLG,
          ),
          child: child,
        );
      },
      child: Material(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: AppColors.textPrimary.withOpacity(0.12),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: radius,
              border: Border.all(
                color: AppColors.secondary,
                width: 3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppUi.gapXXXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.prayerNext,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppUi.gapSM),
                  Text(
                    widget.prayer.prayer.labelAr,
                    textAlign: TextAlign.center,
                    style: AppText.heading.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppUi.gapSM),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    alignment: Alignment.center,
                    child: Text(
                      countdownLabel,
                      textAlign: TextAlign.center,
                      style: AppText.heading.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppUi.gapSM),
                  Text(
                    _formatTime(widget.prayer.time),
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class NextPrayerCardPlaceholder extends StatelessWidget {
  const NextPrayerCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppUi.gapXXXL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppUi.radiusLG),
        border: Border.all(
          color: AppColors.secondary,
          width: 3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          _SkeletonLine(width: AppUi.skeletonLineMedium),
          SizedBox(height: AppUi.gapMD),
          _SkeletonLine(width: AppUi.skeletonLineLong),
          SizedBox(height: AppUi.gapMD),
          _SkeletonLine(width: AppUi.skeletonLineShort),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;

  const _SkeletonLine({required this.width});

  @override
  Widget build(BuildContext context) {
    final lineColor = AppColors.stroke;

    return Container(
      width: width,
      height: AppUi.gapMD,
      decoration: BoxDecoration(
        color: lineColor,
        borderRadius: BorderRadius.circular(AppUi.radiusXS),
      ),
    );
  }
}

class _CardProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double radius;

  const _CardProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final adjustedRadius = radius > inset ? radius - inset : 0.0;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(adjustedRadius),
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, trackPaint);

    final metrics = (Path()..addRRect(rrect)).computeMetrics();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final safeProgress =
        progress < 0 ? 0.0 : (progress > 1 ? 1.0 : progress);
    final progressPath = metric.extractPath(
      0,
      metric.length * safeProgress,
    );

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CardProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        trackColor != oldDelegate.trackColor ||
        strokeWidth != oldDelegate.strokeWidth ||
        radius != oldDelegate.radius;
  }
}
