import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/prayer_models.dart';

/// Clean, prestigious celestial stations card displaying astronomical & Sunnah timings:
/// 1. الشروق (Sunrise)
/// 2. صلاة الضحى (Dhuha / Awabeen)
/// 3. ثلث الليل الآخر (Last Third of Night / Qiyam & Sahoor)
/// 4. منتصف الليل (Midnight / End of Isha)
/// Along with an astronomical Qibla direction indicator.
class PrayerSolarStationsCard extends StatelessWidget {
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? dhuha;
  final DateTime? middleOfTheNight;
  final DateTime? lastThirdOfTheNight;
  final double? qiblaDirection;
  final VoidCallback? onOpenQibla;

  const PrayerSolarStationsCard({
    super.key,
    required this.sunrise,
    this.sunset,
    this.dhuha,
    this.middleOfTheNight,
    this.lastThirdOfTheNight,
    this.qiblaDirection,
    this.onOpenQibla,
  });

  @override
  Widget build(BuildContext context) {
    if (sunrise == null &&
        sunset == null &&
        dhuha == null &&
        middleOfTheNight == null &&
        lastThirdOfTheNight == null) {
      return const SizedBox.shrink();
    }

    final palette = context.palette;
    final textTheme = context.text;
    final now = DateTime.now();

    final sunrisePassed = sunrise != null && now.isAfter(sunrise!);
    final dhuhaPassed = dhuha != null && now.isAfter(dhuha!);
    final midnightPassed =
        middleOfTheNight != null && now.isAfter(middleOfTheNight!);
    final lastThirdPassed =
        lastThirdOfTheNight != null && now.isAfter(lastThirdOfTheNight!);

    final sunriseColor = palette.prayer('sunrise');
    final dhuhaColor = palette.prayer('dhuha');
    final midnightColor = palette.prayer('midnight');
    final qiyamColor = palette.prayer('qiyam');

    return AppCard(
      color: palette.surface,
      border: Border.all(
        color: palette.border,
        width: 1.0,
      ),
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Card Header: Title + Optional Qibla Badge ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'السنن والمحطات الفلكية',
                    style: textTheme.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
              if (qiblaDirection != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onOpenQibla,
                    borderRadius: AppRadius.pillRadius,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xxs,
                      ),
                      constraints: const BoxConstraints(
                        minHeight: AppSize.tap,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: palette.border,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.explore_outlined,
                            size: AppIcon.xs,
                            color: palette.gold,
                          ),
                          const SizedBox(width: AppSpace.xxs),
                          Text(
                            'القبلة ${qiblaDirection!.round()}°',
                            style: textTheme.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xxs),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: AppIcon.xs,
                            color: palette.textSubtle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpace.sm),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpace.sm),

          // ── Row 1: النهار (الشروق + صلاة الضحى) ──
          Row(
            children: [
              Expanded(
                child: _StationItem(
                  label: 'الشروق',
                  subtitle: 'نهاية وقت الفجر',
                  timeText: sunrise != null
                      ? formatPrayerTime12h(sunrise!)
                      : '--:--',
                  icon: Icons.wb_sunny_rounded,
                  iconBgColor: sunriseColor.withValues(alpha: 0.12),
                  iconColor: sunriseColor,
                  isPassed: sunrisePassed,
                ),
              ),
              Container(
                height: 44,
                width: 1,
                color: palette.border,
                margin: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs),
              ),
              Expanded(
                child: _StationItem(
                  label: 'صلاة الضحى',
                  subtitle: 'صلاة الأوابين',
                  timeText:
                      dhuha != null ? formatPrayerTime12h(dhuha!) : '--:--',
                  icon: Icons.light_mode_rounded,
                  iconBgColor: dhuhaColor.withValues(alpha: 0.12),
                  iconColor: dhuhaColor,
                  isPassed: dhuhaPassed,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.xs),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpace.xs),

          // ── Row 2: الليل (ثلث الليل الأخير + منتصف الليل) ──
          Row(
            children: [
              Expanded(
                child: _StationItem(
                  label: 'ثلث الليل الأخير',
                  subtitle: 'قيام الليل والسحر',
                  timeText: lastThirdOfTheNight != null
                      ? formatPrayerTime12h(lastThirdOfTheNight!)
                      : '--:--',
                  icon: Icons.nights_stay_rounded,
                  iconBgColor: qiyamColor.withValues(alpha: 0.12),
                  iconColor: qiyamColor,
                  isPassed: lastThirdPassed,
                ),
              ),
              Container(
                height: 44,
                width: 1,
                color: palette.border,
                margin: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs),
              ),
              Expanded(
                child: _StationItem(
                  label: 'منتصف الليل',
                  subtitle: 'نهاية وقت العشاء',
                  timeText: middleOfTheNight != null
                      ? formatPrayerTime12h(middleOfTheNight!)
                      : '--:--',
                  icon: Icons.bedtime_rounded,
                  iconBgColor: midnightColor.withValues(alpha: 0.12),
                  iconColor: midnightColor,
                  isPassed: midnightPassed,
                ),
              ),
            ],
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
                  Flexible(
                    child: Text(
                      label,
                      style: textTheme.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPassed ? palette.textMuted : palette.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
              Text(
                subtitle,
                style: textTheme.label.copyWith(
                  color: palette.textSubtle,
                  height: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
