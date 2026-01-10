import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';

class PrayerHeader extends StatelessWidget {
  final String city;
  final String dayLabel;
  final String hijriDate;
  final String? gregorianDate;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onQiblaTap;

  const PrayerHeader({
    super.key,
    required this.city,
    required this.dayLabel,
    required this.hijriDate,
    this.gregorianDate,
    this.onSettingsTap,
    this.onLocationTap,
    this.onQiblaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppUi.gapXL),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppUi.radiusXXL),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: onLocationTap ?? () => _showLocationSheet(context),
                  borderRadius: BorderRadius.circular(AppUi.radiusPill),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: AppUi.iconSizeSM,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppUi.gapXS),
                      Flexible(
                        child: Text(
                          city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.heading.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppUi.gapSM),
              _HeaderIconButton(
                icon: Icons.settings_outlined,
                onTap: onSettingsTap,
              ),
            ],
          ),
          const SizedBox(height: AppUi.gapXS),
          Text(
            _dateLabel(),
            style: AppText.body.copyWith(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          Center(
            child: InkWell(
              onTap: onQiblaTap,
              borderRadius: BorderRadius.circular(AppUi.radiusPill),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppUi.gapXS),
                  Text(
                    'Tap to open Qibla compass',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel() {
    final gregorian = gregorianDate?.trim();
    if (gregorian != null && gregorian.isNotEmpty) {
      return '$gregorian • $hijriDate';
    }
    return '$dayLabel • $hijriDate';
  }

  void _showLocationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppUi.radiusLG),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppUi.paddingMD,
            AppUi.gapMD,
            AppUi.paddingMD,
            AppUi.paddingLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppUi.handleWidth,
                height: AppUi.handleHeight,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppUi.radiusPill),
                ),
              ),
              const SizedBox(height: AppUi.gapLG),
              Text(
                AppStrings.locationCurrent,
                style: AppText.heading.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppUi.gapSM),
              Text(
                city,
                style: AppText.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppUi.gapXS),
              Text(
                _dateLabel(),
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppUi.gapLG),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppStrings.actionClose),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: AppUi.iconBoxSize / 2,
      highlightShape: BoxShape.circle,
      child: Padding(
        padding: const EdgeInsets.all(AppUi.gapXS),
        child: Icon(
          icon,
          size: AppUi.iconSizeMD,
          color: Colors.white,
        ),
      ),
    );
  }
}
