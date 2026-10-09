import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isCurrent = item.isCurrent;
    final isCompleted = item.isCompleted;
    final iconData = _iconFor(item.name);
    final iconColor = _colorFor(item.name, isDark);
    final statusIcon = _statusIcon(isCurrent, isCompleted);
    final statusColor = isCurrent
        ? context.goldColor
        : (isCompleted
            ? context.islamicGreenColor
            : context.textSecondaryColor.withValues(alpha: 0.6));

    final titleColor = context.textPrimaryColor;
    final timeColor = isCurrent ? context.goldColor : context.textPrimaryColor;

    final backgroundColor = isCurrent
        ? context.surfaceContainer
        : context.surfaceContainer;

    final borderColor = isCurrent
        ? context.goldColor.withValues(alpha: isDark ? 0.6 : 0.5)
        : context.outlineColor.withValues(alpha: isDark ? 0.12 : 0.08);

    final gradient = isCurrent
        ? LinearGradient(
            colors: isDark
                ? [
                    context.goldColor.withValues(alpha: 0.12),
                    context.surfaceContainer,
                  ]
                : [
                    context.goldColor.withValues(alpha: 0.08),
                    context.surfaceContainer,
                  ],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          )
        : null;

    final subtitle = isCurrent
        ? 'الآن'
        : (item.isNext ? AppStrings.prayerNext : AppStrings.prayerDayLabel);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? context.goldColor.withValues(alpha: isDark ? 0.12 : 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
            blurRadius: isCurrent ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Prayer Icon with Ornate circular container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.16 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: isCurrent ? 0.45 : 0.25),
                width: 1.2,
              ),
            ),
            child: Icon(
              iconData,
              size: 22,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),

          // Prayer Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCurrent || item.isNext)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.goldColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: context.goldColor,
                          ),
                        ),
                      ),
                  ],
                ),
                if (onBeforeAdhkar != null || onAfterAdhkar != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (onBeforeAdhkar != null)
                        AdhkarLink(
                          label: AppStrings.beforePrayerDhikr,
                          onTap: onBeforeAdhkar,
                        ),
                      if (onAfterAdhkar != null)
                        AdhkarLink(
                          label: AppStrings.afterPrayerDhikr,
                          onTap: onAfterAdhkar,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Prayer Time & Status Icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.timeLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: timeColor,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                statusIcon,
                size: 18,
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case AppStrings.prayerFajr:
        return Icons.wb_twilight_rounded;
      case AppStrings.prayerDhuhr:
        return Icons.wb_sunny_rounded;
      case AppStrings.prayerAsr:
        return Icons.wb_sunny_outlined;
      case AppStrings.prayerMaghrib:
        return Icons.nights_stay_rounded;
      case AppStrings.prayerIsha:
        return Icons.dark_mode_rounded;
    }
    return Icons.access_time_rounded;
  }

  Color _colorFor(String name, bool isDark) {
    switch (name) {
      case AppStrings.prayerFajr:
        return AppColors.fajr;
      case AppStrings.prayerDhuhr:
        return AppColors.gold;
      case AppStrings.prayerAsr:
        return AppColors.asr;
      case AppStrings.prayerMaghrib:
        return AppColors.maghrib;
      case AppStrings.prayerIsha:
        return AppColors.isha;
    }
    return isDark ? AppColors.darkGold : AppColors.primary;
  }

  IconData _statusIcon(bool isCurrent, bool isCompleted) {
    if (isCurrent) return Icons.notifications_active_rounded;
    if (isCompleted) return Icons.check_circle_rounded;
    return Icons.notifications_none_rounded;
  }
}

class AdhkarLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AdhkarLink({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gold = context.goldColor;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: gold.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 11,
              color: gold,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
