import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/models/prayer_models.dart';

class NextPrayerCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusXL);

    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        padding: AppUi.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: radius,
          border: Border.all(
            color: AppColors.stroke,
            width: AppUi.dividerThickness,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.prayerNext,
              style: AppText.headingXL,
            ),
            const SizedBox(height: AppUi.gapXSPlus),
            Text(
              prayer.prayer.labelAr,
              style: AppText.heading,
            ),
            const SizedBox(height: AppUi.gapSM),
            Text(
              _formatTime(prayer.time),
              style: AppText.body,
            ),
            const SizedBox(height: AppUi.gapSM),
            Text(
              countdownText ??
                  AppStrings.prayerInMinutes(prayer.minutesRemaining),
              style: AppText.caption,
            ),
          ],
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
      padding: AppUi.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppUi.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonLine(width: AppUi.skeletonLineMedium),
          SizedBox(height: AppUi.gapSM),
          _SkeletonLine(width: AppUi.skeletonLineLong),
          SizedBox(height: AppUi.gapSM),
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
