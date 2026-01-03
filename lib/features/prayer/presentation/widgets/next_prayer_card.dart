import 'package:flutter/material.dart';
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
    final colors = Theme.of(context).colorScheme;
    final primary = colors.onSurface;
    final secondary = colors.onSurface.withValues(alpha: 0.7);
    final radius = BorderRadius.circular(22);

    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          boxShadow: AppUi.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الصلاة القادمة',
              style: AppText.body.copyWith(color: secondary),
            ),
            const SizedBox(height: 8),
            Text(
              prayer.prayer.labelAr,
              style: AppText.headingXL.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(prayer.time),
              style: AppText.body.copyWith(color: secondary),
            ),
            const SizedBox(height: 12),
            Text(
              countdownText ?? 'بعد ${prayer.minutesRemaining} دقيقة',
              style: AppText.caption.copyWith(color: secondary),
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonLine(width: 140),
          SizedBox(height: 8),
          _SkeletonLine(width: 180),
          SizedBox(height: 8),
          _SkeletonLine(width: 110),
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
    final colors = Theme.of(context).colorScheme;
    final lineColor = colors.onSurface.withValues(alpha: 0.08);

    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: lineColor,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
