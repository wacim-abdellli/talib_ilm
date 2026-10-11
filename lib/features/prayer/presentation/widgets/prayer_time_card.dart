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
  final bool isNotificationEnabled;
  final VoidCallback? onToggleNotification;

  const PrayerTimeEntry({
    required this.name,
    required this.timeLabel,
    required this.isNext,
    required this.isCurrent,
    required this.isCompleted,
    this.isNotificationEnabled = true,
    this.onToggleNotification,
  });
}

class PrayerTimeCard extends StatelessWidget {
  final PrayerTimeEntry item;
  final VoidCallback? onBeforeAdhkar;
  final VoidCallback? onAfterAdhkar;
  final VoidCallback? onTap;

  const PrayerTimeCard({
    super.key,
    required this.item,
    this.onBeforeAdhkar,
    this.onAfterAdhkar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isCurrent = item.isCurrent;
    final prayerColor = palette.prayer(item.name);

    return AppCard(
      color: isCurrent ? palette.surfaceRaised : palette.surface,
      border: Border.all(
        color: isCurrent ? palette.gold : palette.border,
        width: isCurrent ? 1.5 : 1.0,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      onTap: onTap,
      child: Row(
        children: [
          // Prayer Jewel Icon Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? palette.goldSoft : palette.surfaceMuted,
              border: Border.all(
                color: isCurrent
                    ? palette.gold.withValues(alpha: 0.4)
                    : palette.border,
              ),
            ),
            child: Center(
              child: Icon(
                _iconFor(item.name),
                size: AppIcon.sm,
                color: isCurrent ? palette.gold : prayerColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),

          // Prayer Details (Name, Tags, Adhkar Link)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: context.text.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight:
                              isCurrent ? FontWeight.w800 : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: AppSpace.sm),
                      AppTag(
                        label: 'الآن',
                        fg: palette.onGold,
                        bg: palette.goldFill,
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
                if (onAfterAdhkar != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  AdhkarLink(
                    label: 'أذكار الصلاة',
                    isCurrent: isCurrent,
                    onTap: onAfterAdhkar,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: AppSpace.md),

          // Prayer Time & Status / Ring Action Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.timeLabel,
                style: context.text.titleSmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              if (item.name == 'الشروق')
                Tooltip(
                  message: 'وقت شروق الشمس',
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      size: AppIcon.sm,
                      color: palette.textSubtle,
                    ),
                  ),
                )
              else
                Semantics(
                  button: true,
                  label: item.isNotificationEnabled
                      ? 'إلغاء تنبيه ${item.name}'
                      : 'تفعيل تنبيه ${item.name}',
                  child: Tooltip(
                    message: item.isNotificationEnabled
                        ? 'التنبيه مفعل (انقر للكتم)'
                        : 'التنبيه مكتوم (انقر للتفعيل)',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: item.onToggleNotification,
                        borderRadius: AppRadius.pillRadius,
                        child: Container(
                          padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                          decoration: BoxDecoration(
                            color: item.isNotificationEnabled
                                ? (isCurrent ? palette.goldSoft : palette.surfaceMuted)
                                : Colors.transparent,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Icon(
                            item.isNotificationEnabled
                                ? (isCurrent
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_active_outlined)
                                : Icons.notifications_off_outlined,
                            size: AppIcon.sm,
                            color: item.isNotificationEnabled
                                ? (isCurrent ? palette.gold : prayerColor)
                                : palette.textSubtle,
                          ),
                        ),
                      ),
                    ),
                  ),
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
      fg: isCurrent ? palette.gold : palette.textMuted,
      bg: isCurrent ? palette.goldSoft : palette.surfaceMuted,
      onTap: onTap,
    );
  }
}
