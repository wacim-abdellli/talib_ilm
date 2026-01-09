import 'package:flutter/material.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          city,
          style: AppText.body,
        ),
        const SizedBox(height: AppUi.gapXS),
        Text(
          '$dayLabel • $hijriDate',
          style: AppText.caption,
        ),
      ],
    );
  }
}
