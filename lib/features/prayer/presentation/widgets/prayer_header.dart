import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';

class PrayerHeader extends StatelessWidget {
  final String city;
  final String dayLabel;
  final String hijriDate;

  const PrayerHeader({
    super.key,
    required this.city,
    required this.dayLabel,
    required this.hijriDate,
  });

  @override
  Widget build(BuildContext context) {
    const secondary = AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          city,
          style: AppText.heading.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          '$dayLabel • $hijriDate',
          style: AppText.body.copyWith(color: secondary),
        ),
      ],
    );
  }
}
