import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/prayer_models.dart';

/// Clean, prestigious celestial station card displaying Sunrise (الشروق)
/// and Sunset (الغروب) with solar icons and astronomical timings.
class PrayerSolarStationsCard extends StatelessWidget {
  final DateTime? sunrise;
  final DateTime? sunset;

  const PrayerSolarStationsCard({
    super.key,
    required this.sunrise,
    required this.sunset,
  });

  @override
  Widget build(BuildContext context) {
    if (sunrise == null && sunset == null) {
      return const SizedBox.shrink();
    }

    final palette = context.palette;
    final now = DateTime.now();

    final sunrisePassed = sunrise != null && now.isAfter(sunrise!);
    final sunsetPassed = sunset != null && now.isAfter(sunset!);

    final sunriseColor = palette.prayer('sunrise');
    final sunsetColor = palette.prayer('maghrib');

    return AppCard(
      color: palette.surface,
      border: Border.all(
        color: palette.border,
        width: 1.0,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          // ── Shuruq Station (الشروق) ──
          Expanded(
            child: _StationItem(
              label: 'الشروق',
              subtitle: 'شروق الشمس',
              timeText: sunrise != null ? formatPrayerTime12h(sunrise!) : '--:--',
              icon: Icons.wb_sunny_rounded,
              iconBgColor: sunriseColor.withValues(alpha: 0.12),
              iconColor: sunriseColor,
              isPassed: sunrisePassed,
            ),
          ),

          // ── Subtle Vertical Divider ──
          Container(
            height: 36,
            width: 1,
            color: palette.border,
            margin: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs),
          ),

          // ── Ghurub Station (الغروب) ──
          Expanded(
            child: _StationItem(
              label: 'الغروب',
              subtitle: 'غروب الشمس',
              timeText: sunset != null ? formatPrayerTime12h(sunset!) : '--:--',
              icon: Icons.wb_twilight_rounded,
              iconBgColor: sunsetColor.withValues(alpha: 0.12),
              iconColor: sunsetColor,
              isPassed: sunsetPassed,
            ),
          ),
        ],
      ),
    );
  }
}

class _StationItem extends StatelessWidget {
  final String label;
  final String subtitle;
  final String timeText;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final bool isPassed;

  const _StationItem({
    required this.label,
    required this.subtitle,
    required this.timeText,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Row(
      children: [
        // Station Icon Badge
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBgColor,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: AppIcon.md,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),

        // Titles and Timings
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: textTheme.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPassed ? palette.textMuted : palette.text,
                    ),
                  ),
                  if (isPassed) ...[
                    const SizedBox(width: AppSpace.xxs),
                    Icon(
                      Icons.check_circle_rounded,
                      size: AppIcon.xs,
                      color: palette.textMuted,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                timeText,
                style: textTheme.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPassed ? palette.textMuted : iconColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
