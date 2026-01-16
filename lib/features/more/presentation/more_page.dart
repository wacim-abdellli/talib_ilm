import 'package:flutter/material.dart';
import 'package:talib_ilm/shared/widgets/app_snackbar.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/pressable_card.dart';

import '../../prayer/presentation/prayer_settings_sheet.dart';
import '../../prayer/presentation/location_settings_sheet.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_MoreSection>[
      _MoreSection(
        title: 'إعدادات الصلاة',
        subtitle: 'تنبيهات الأذان وطرق الحساب',
        icon: Icons.mosque_outlined,
        onTap: () => _openPrayerSettings(context),
      ),
      _MoreSection(
        title: 'الإعدادات العامة',
        subtitle: AppStrings.moreGeneralSubtitle,
        icon: Icons.settings_outlined,
        onTap: () => _openLocationSettings(context),
      ),
      _MoreSection(
        title: AppStrings.moreThemeTitle,
        subtitle: AppStrings.moreThemeSubtitle,
        icon: Icons.color_lens_outlined,
        onTap: () => _showInfo(context, AppStrings.moreThemeInfo),
      ),
      _MoreSection(
        title: AppStrings.moreLanguageTitle,
        subtitle: AppStrings.moreLanguageSubtitle,
        icon: Icons.language_outlined,
        onTap: () => _showInfo(context, AppStrings.moreLanguageInfo),
      ),
      _MoreSection(
        title: AppStrings.moreBackupTitle,
        subtitle: AppStrings.moreBackupSubtitle,
        icon: Icons.backup_outlined,
        onTap: () => _showInfo(context, AppStrings.moreBackupInfo),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF64748B), Color(0xFF94A3B8)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'المزيد',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: ListView(
                padding: AppUi.screenPadding,
                children: [
                  const SizedBox(height: AppUi.gapSM),
                  _MoreSectionCard(section: sections[0]),
                  const SizedBox(height: AppUi.gapMD),
                  _MoreSectionCard(section: sections[1]),
                  const SizedBox(height: AppUi.gapMD),
                  _MoreSectionCard(section: sections[2]),
                  const SizedBox(height: AppUi.gapMD),
                  _MoreSectionCard(section: sections[3]),
                  const SizedBox(height: AppUi.gapMD),
                  _MoreSectionCard(section: sections[4]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    AppSnackbar.info(context, message);
  }

  void _openPrayerSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppUi.radiusMD),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: const PrayerSettingsSheet(),
        ),
      ),
    );
  }

  void _openLocationSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppUi.radiusMD),
        ),
      ),
      builder: (_) => LocationSettingsSheet(
        onSaved: () {
          // No-op for now unless we have a global reload trigger
        },
      ),
    );
  }
}

class _MoreSection {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _MoreSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _MoreSectionCard extends StatelessWidget {
  final _MoreSection section;

  const _MoreSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusMD);

    return PressableCard(
      onTap: section.onTap,
      padding: AppUi.cardPadding,
      borderRadius: radius,
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradient,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.stroke,
          width: AppUi.dividerThickness,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppUi.iconBoxSize,
            height: AppUi.iconBoxSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: radius,
              border: Border.all(
                color: AppColors.stroke,
                width: AppUi.dividerThickness,
              ),
            ),
            child: Icon(section.icon, color: AppColors.textMuted),
          ),
          const SizedBox(width: AppUi.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.title, style: AppText.heading),
                const SizedBox(height: AppUi.gapXS),
                Text(section.subtitle, style: AppText.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
