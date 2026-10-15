import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_tag.dart';

class PrayerTimeEntry {
  final String name;
  final String timeLabel;
  final bool isNext;
  final bool isCurrent;
  final bool isCompleted;
  final bool isNotificationEnabled;
  final PrayerNotificationMode notificationMode;
  final VoidCallback? onToggleNotification;
  final ValueChanged<PrayerNotificationMode>? onSelectMode;

  const PrayerTimeEntry({
    required this.name,
    required this.timeLabel,
    required this.isNext,
    required this.isCurrent,
    required this.isCompleted,
    this.isNotificationEnabled = true,
    this.notificationMode = PrayerNotificationMode.adhan,
    this.onToggleNotification,
    this.onSelectMode,
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
                Builder(
                  builder: (context) {
                    final mode = item.notificationMode;
                    final isActive = mode != PrayerNotificationMode.off;
                    final IconData modeIcon;
                    final String shortLabel;
                    switch (mode) {
                      case PrayerNotificationMode.adhan:
                        modeIcon = Icons.volume_up_rounded;
                        shortLabel = 'أذان';
                        break;
                      case PrayerNotificationMode.takbeer:
                        modeIcon = Icons.campaign_rounded;
                        shortLabel = 'تكبيرات';
                        break;
                      case PrayerNotificationMode.announcement:
                        modeIcon = Icons.record_voice_over_rounded;
                        shortLabel = 'نداء';
                        break;
                      case PrayerNotificationMode.tone:
                        modeIcon = Icons.notifications_active_rounded;
                        shortLabel = 'نغمة';
                        break;
                      case PrayerNotificationMode.silent:
                        modeIcon = Icons.notifications_none_rounded;
                        shortLabel = 'صامت';
                        break;
                      case PrayerNotificationMode.off:
                        modeIcon = Icons.notifications_off_outlined;
                        shortLabel = 'معطل';
                        break;
                    }

                    return Theme(
                      data: Theme.of(context).copyWith(
                        cardColor: palette.surfaceRaised,
                        popupMenuTheme: PopupMenuThemeData(
                          color: palette.surfaceRaised,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdRadius,
                            side: BorderSide(color: palette.border),
                          ),
                        ),
                      ),
                      child: PopupMenuButton<PrayerNotificationMode>(
                        tooltip: 'خيارات التنبيه لصلاة ${item.name}',
                        initialValue: mode,
                        onSelected: (selected) {
                          item.onSelectMode?.call(selected);
                        },
                        itemBuilder: (menuContext) => [
                          _buildPopupOption(
                            menuContext,
                            palette: palette,
                            mode: PrayerNotificationMode.adhan,
                            icon: Icons.volume_up_rounded,
                            title: 'أذان كامل',
                            subtitle: 'صوت الأذان كاملاً',
                            isSelected: mode == PrayerNotificationMode.adhan,
                          ),
                          _buildPopupOption(
                            menuContext,
                            palette: palette,
                            mode: PrayerNotificationMode.takbeer,
                            icon: Icons.campaign_rounded,
                            title: 'تكبيرات فقط',
                            subtitle: 'تكبيرات الأذان الأولى',
                            isSelected: mode == PrayerNotificationMode.takbeer,
                          ),
                          _buildPopupOption(
                            menuContext,
                            palette: palette,
                            mode: PrayerNotificationMode.announcement,
                            icon: Icons.record_voice_over_rounded,
                            title: 'نداء وقت الصلاة',
                            subtitle: 'حان الآن وقت صلاة ${item.name}',
                            isSelected: mode == PrayerNotificationMode.announcement,
                          ),
                          _buildPopupOption(
                            menuContext,
                            palette: palette,
                            mode: PrayerNotificationMode.tone,
                            icon: Icons.notifications_active_rounded,
                            title: 'نغمة تنبيه هادئة',
                            subtitle: 'تنبيه نغمي لطيف ومختصر',
                            isSelected: mode == PrayerNotificationMode.tone,
                          ),
                          _buildPopupOption(
                            menuContext,
                            palette: palette,
                            mode: PrayerNotificationMode.silent,
                            icon: Icons.notifications_none_rounded,
                            title: 'إشعار صامت',
                            subtitle: 'تنبيه مرئي بدون صوت',
                            isSelected: mode == PrayerNotificationMode.silent,
                          ),
                          const PopupMenuDivider(),
                          _buildPopupOption(
                            menuContext,
                            palette: palette,
                            mode: PrayerNotificationMode.off,
                            icon: Icons.notifications_off_outlined,
                            title: 'إيقاف التنبيه',
                            subtitle: 'بدون أي إشعار أو صوت',
                            isSelected: mode == PrayerNotificationMode.off,
                            isDestructive: true,
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isCurrent ? palette.goldSoft : palette.surfaceMuted)
                                : palette.bg,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: isActive
                                  ? (isCurrent
                                      ? palette.gold.withValues(alpha: 0.5)
                                      : palette.border)
                                  : palette.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                modeIcon,
                                size: AppIcon.sm,
                                color: isActive
                                    ? (isCurrent ? palette.gold : prayerColor)
                                    : palette.textSubtle,
                              ),
                              const SizedBox(width: AppSpace.xxs),
                              Text(
                                shortLabel,
                                style: context.text.caption.copyWith(
                                  color: isActive
                                      ? (isCurrent ? palette.gold : palette.text)
                                      : palette.textSubtle,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: AppSpace.xxs),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: AppIcon.sm,
                                color: isActive
                                    ? palette.textMuted
                                    : palette.textSubtle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<PrayerNotificationMode> _buildPopupOption(
    BuildContext context, {
    required AppPalette palette,
    required PrayerNotificationMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    bool isDestructive = false,
  }) {
    final activeColor = isDestructive
        ? palette.error
        : (isSelected ? palette.gold : palette.text);

    return PopupMenuItem<PrayerNotificationMode>(
      value: mode,
      height: 48.0,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(
              icon,
              size: AppIcon.sm,
              color: isSelected
                  ? (isDestructive ? palette.error : palette.gold)
                  : palette.textMuted,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.text.caption.copyWith(
                      color: activeColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: context.text.caption.copyWith(
                      color: palette.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpace.xs),
              Icon(
                Icons.check_rounded,
                size: AppIcon.sm,
                color: isDestructive ? palette.error : palette.gold,
              ),
            ],
          ],
        ),
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
