import 'package:flutter/material.dart';
import 'package:talib_ilm/shared/widgets/app_snackbar.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_ui.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../app/app.dart';
import '../../../shared/widgets/pressable_card.dart';

import '../../prayer/presentation/prayer_settings_sheet.dart';
import '../../prayer/presentation/location_settings_sheet.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
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
            title: 'المظهر',
            subtitle: themeService.themeDisplayName,
            icon: themeService.themeIcon,
            onTap: () => _showThemeSelector(context),
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
          backgroundColor: context.backgroundColor,
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  border: Border(
                    bottom: BorderSide(color: context.borderColor, width: 1),
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
                      Expanded(
                        child: Text(
                          'المزيد',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
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
                  color: context.backgroundColor,
                  child: ListView(
                    padding: AppUi.screenPadding,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
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
                      const SizedBox(height: 100), // Extra padding for nav bar
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfo(BuildContext context, String message) {
    AppSnackbar.info(context, message);
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'اختر المظهر',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _ThemeOption(
                icon: Icons.brightness_auto,
                title: 'تلقائي',
                subtitle: 'حسب إعدادات الجهاز',
                isSelected: themeService.isSystem,
                onTap: () {
                  themeService.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _ThemeOption(
                icon: Icons.light_mode,
                title: 'الوضع الفاتح',
                subtitle: 'مظهر فاتح دائماً',
                isSelected: themeService.isLight,
                onTap: () {
                  themeService.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _ThemeOption(
                icon: Icons.dark_mode,
                title: 'الوضع الداكن',
                subtitle: 'مظهر داكن دائماً',
                isSelected: themeService.isDark,
                onTap: () {
                  themeService.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _openPrayerSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppUi.radiusMD),
        ),
      ),
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: const PrayerSettingsSheet(),
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

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryColor.withValues(alpha: 0.1)
              : context.surfaceSecondaryColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? context.primaryColor : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.primaryColor.withValues(alpha: 0.15)
                    : context.borderColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? context.primaryColor
                    : context.textSecondaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: context.primaryColor, size: 24),
          ],
        ),
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
        color: context.surfaceColor,
        borderRadius: radius,
        border: Border.all(
          color: context.borderColor,
          width: AppUi.dividerThickness,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppUi.iconBoxSize,
            height: AppUi.iconBoxSize,
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: radius,
              border: Border.all(
                color: context.borderColor,
                width: AppUi.dividerThickness,
              ),
            ),
            child: Icon(section.icon, color: context.textTertiaryColor),
          ),
          const SizedBox(width: AppUi.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppUi.gapXS),
                Text(
                  section.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
