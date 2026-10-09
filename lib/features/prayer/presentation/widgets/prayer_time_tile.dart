import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_tag.dart';
import '../models/prayer_time.dart';

class PrayerTimeTile extends StatelessWidget {
  final PrayerTime item;
  final VoidCallback? onTap;

  const PrayerTimeTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isCurrent = item.isCurrent;
    final isPassed = _isPassed(item);

    final iconData = _getPrayerIcon(item.name);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.xs,
      ),
      child: Opacity(
        opacity: isPassed && !isCurrent ? 0.72 : 1.0,
        child: AppCard(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          color: isCurrent ? palette.primarySoft : palette.surface,
          border: Border.all(
            color: isCurrent ? palette.primary : palette.border,
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Row(
            children: [
              // Prayer dot + current gold dot
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSpace.sm,
                    height: AppSpace.sm,
                    decoration: BoxDecoration(
                      color: palette.prayer(item.name),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: AppSpace.xs),
                    Container(
                      width: AppSpace.sm,
                      height: AppSpace.sm,
                      decoration: BoxDecoration(
                        color: palette.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: AppSpace.md),

              // Prayer Icon
              Icon(
                isPassed && !isCurrent ? Icons.check_circle_rounded : iconData,
                size: AppIcon.md,
                color: isCurrent
                    ? palette.onPrimarySoft
                    : (isPassed ? palette.textSubtle : palette.textMuted),
              ),
              const SizedBox(width: AppSpace.md),

              // Prayer Name & Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.name,
                          style: context.text.titleSmall.copyWith(
                            color: palette.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (isPassed && !isCurrent) ...[
                          const SizedBox(width: AppSpace.sm),
                          Icon(
                            Icons.done_all_rounded,
                            size: AppIcon.sm,
                            color: palette.textSubtle,
                          ),
                        ],
                      ],
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: AppSpace.xs),
                      AppTag(
                        label: 'الصلاة الحالية',
                        fg: palette.onPrimarySoft,
                        bg: palette.surfaceRaised,
                      ),
                    ],
                  ],
                ),
              ),

              // Time
              Text(
                item.time,
                style: context.text.titleSmall.copyWith(
                  color: palette.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPassed(PrayerTime item) {
    if (item.isCurrent) return false;
    try {
      final now = DateTime.now();
      final parts = item.time.split(':');
      final pTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return pTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  IconData _getPrayerIcon(String name) {
    if (name.contains(AppStrings.prayerFajr) || name == 'الفجر') {
      return Icons.wb_twilight_rounded;
    }
    if (name == 'الشروق') return Icons.wb_sunny_rounded;
    if (name.contains(AppStrings.prayerDhuhr) || name == 'الظهر') {
      return Icons.wb_sunny_rounded;
    }
    if (name.contains(AppStrings.prayerAsr) || name == 'العصر') {
      return Icons.wb_sunny_outlined;
    }
    if (name.contains(AppStrings.prayerMaghrib) || name == 'المغرب') {
      return Icons.nights_stay_rounded;
    }
    if (name.contains(AppStrings.prayerIsha) || name == 'العشاء') {
      return Icons.dark_mode_rounded;
    }
    return Icons.access_time_rounded;
  }
}
