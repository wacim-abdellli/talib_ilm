import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_tag.dart';

class PrayerTimeEntry {
  final String name;
  final String timeLabel;
  final bool isNext;
  final bool isCurrent;
  final bool isCompleted;

  const PrayerTimeEntry({
    required this.name,
    required this.timeLabel,
    required this.isNext,
    required this.isCurrent,
    required this.isCompleted,
  });
}

class PrayerTimeCard extends StatelessWidget {
  final PrayerTimeEntry item;
  final VoidCallback? onBeforeAdhkar;
  final VoidCallback? onAfterAdhkar;

  const PrayerTimeCard({
    super.key,
    required this.item,
    this.onBeforeAdhkar,
    this.onAfterAdhkar,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isCurrent = item.isCurrent;
    final isCompleted = item.isCompleted;

    final statusIcon = isCurrent
        ? Icons.notifications_active_rounded
        : (isCompleted
            ? Icons.check_circle_rounded
            : Icons.notifications_none_rounded);

    final statusColor = isCurrent
        ? palette.primary
        : palette.textSubtle;

    return AppCard(
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
          // Prayer color 8px dot + current prayer gold 8px dot
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
            _iconFor(item.name),
            size: AppIcon.md,
            color: isCurrent ? palette.onPrimarySoft : palette.textMuted,
          ),
          const SizedBox(width: AppSpace.md),

          // Prayer Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: context.text.titleSmall.copyWith(
                          color: palette.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: AppSpace.sm),
                      AppTag(
                        label: 'الآن',
                        fg: palette.onPrimarySoft,
                        bg: palette.surfaceRaised,
                      ),
                    ] else if (item.isNext) ...[
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        child: AppTag(
                          label: AppStrings.prayerNext,
                          fg: palette.textMuted,
                          bg: palette.surfaceMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (onBeforeAdhkar != null || onAfterAdhkar != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xs,
                    children: [
                      if (onBeforeAdhkar != null)
                        AdhkarLink(
                          label: AppStrings.beforePrayerDhikr,
                          isCurrent: isCurrent,
                          onTap: onBeforeAdhkar,
                        ),
                      if (onAfterAdhkar != null)
                        AdhkarLink(
                          label: AppStrings.afterPrayerDhikr,
                          isCurrent: isCurrent,
                          onTap: onAfterAdhkar,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: AppSpace.md),

          // Prayer Time & Status Icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.timeLabel,
                style: context.text.titleSmall.copyWith(
                  color: palette.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Icon(
                statusIcon,
                size: AppIcon.md,
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    if (name.contains(AppStrings.prayerFajr) || name == 'الفجر') {
      return Icons.wb_twilight_rounded;
    }
    if (name == 'الشروق') {
      return Icons.wb_sunny_rounded;
    }
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

class AdhkarLink extends StatelessWidget {
  final String label;
  final bool isCurrent;
  final VoidCallback? onTap;

  const AdhkarLink({
    super.key,
    required this.label,
    this.isCurrent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppTag(
      label: label,
      fg: isCurrent ? palette.onPrimarySoft : palette.primary,
      bg: isCurrent ? palette.surfaceRaised : palette.primarySoft,
      onTap: onTap,
    );
  }
}
