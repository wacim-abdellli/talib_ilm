import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../models/prayer_time.dart';

class PrayerTimeTile extends StatelessWidget {
  final PrayerTime item;
  final VoidCallback? onBeforeAdhkar;
  final VoidCallback? onAfterAdhkar;

  const PrayerTimeTile({
    super.key,
    required this.item,
    this.onBeforeAdhkar,
    this.onAfterAdhkar,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = item.isCurrent;
    final isPassed = _isPassed(item, isCurrent);
    final iconData = _iconFor(item.name);
    final statusIcon = _statusIcon(isCurrent, isPassed);
    final statusColor = _statusColor(isCurrent, isPassed);
    final titleColor = _titleColor(isCurrent, isPassed);
    final timeColor = _timeColor(isCurrent, isPassed);
    final backgroundColor =
        isCurrent ? AppColors.primaryLight : AppColors.surface;

    final tile = Material(
      color: Colors.transparent,
      elevation: 1,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
          border: isCurrent
              ? Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 4,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppUi.gapLG,
            vertical: AppUi.paddingMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    iconData.icon,
                    size: AppUi.iconSizeLG,
                    color: iconData.color,
                  ),
                  const SizedBox(width: AppUi.gapSM),
                  Expanded(
                    child: Text(
                      item.name,
                      style: AppText.body.copyWith(
                        fontSize: 16,
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppUi.gapSM),
                  Text(
                    item.time,
                    style: AppText.body.copyWith(
                      fontSize: 18,
                      fontWeight:
                          isCurrent ? FontWeight.w800 : FontWeight.w700,
                      color: timeColor,
                    ),
                  ),
                  const SizedBox(width: AppUi.gapSM),
                  Icon(
                    statusIcon,
                    size: AppUi.iconSizeMD,
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: AppUi.gapSM),
              Row(
                children: [
                  _AdhkarLink(
                    label: AppStrings.beforePrayerDhikr,
                    onTap: onBeforeAdhkar,
                  ),
                  const SizedBox(width: AppUi.gapMD),
                  _AdhkarLink(
                    label: AppStrings.afterPrayerDhikr,
                    onTap: onAfterAdhkar,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppUi.gapSM),
      child: Transform.scale(
        scale: isCurrent ? 1.02 : 1,
        alignment: Alignment.center,
        child: tile,
      ),
    );
  }

  _PrayerIconData _iconFor(String name) {
    switch (name) {
      case AppStrings.prayerFajr:
        return const _PrayerIconData(Icons.wb_twilight, Colors.orange);
      case AppStrings.prayerDhuhr:
        return const _PrayerIconData(Icons.wb_sunny, Colors.yellow);
      case AppStrings.prayerAsr:
        return const _PrayerIconData(Icons.wb_sunny_outlined, Colors.amber);
      case AppStrings.prayerMaghrib:
        return const _PrayerIconData(Icons.wb_twilight, Colors.deepOrange);
      case AppStrings.prayerIsha:
        return const _PrayerIconData(Icons.nights_stay, Colors.blue);
    }
    return _PrayerIconData(Icons.access_time, AppColors.textSecondary);
  }

  IconData _statusIcon(bool isCurrent, bool isPassed) {
    if (isCurrent) return Icons.radio_button_checked;
    if (isPassed) return Icons.check_circle;
    return Icons.notifications_active;
  }

  Color _statusColor(bool isCurrent, bool isPassed) {
    if (isCurrent) return AppColors.primary;
    if (isPassed) return AppColors.success;
    return AppColors.textSecondary;
  }

  Color _titleColor(bool isCurrent, bool isPassed) {
    if (isCurrent) return AppColors.primary;
    if (isPassed) return AppColors.textSecondary;
    return AppColors.textPrimary;
  }

  Color _timeColor(bool isCurrent, bool isPassed) {
    if (isCurrent) return AppColors.primary;
    if (isPassed) return AppColors.textSecondary;
    return AppColors.textPrimary;
  }

  bool _isPassed(PrayerTime item, bool isCurrent) {
    if (isCurrent) return false;
    final parsed = _parseTime(item.time);
    if (parsed == null) return false;
    return parsed.isBefore(DateTime.now());
  }

  DateTime? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

class _AdhkarLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AdhkarLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppUi.radiusXS),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppUi.gapXS,
          vertical: AppUi.gapXXS,
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PrayerIconData {
  final IconData icon;
  final Color color;

  const _PrayerIconData(this.icon, this.color);
}
