import 'package:flutter/material.dart';
import 'package:talib_ilm/shared/widgets/app_snackbar.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../../shared/widgets/primary_app_bar.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_MoreSection>[
      _MoreSection(
        title: AppStrings.moreGeneralTitle,
        subtitle: AppStrings.moreGeneralSubtitle,
        icon: Icons.settings_outlined,
        onTap: () => _showInfo(context, AppStrings.moreGeneralInfo),
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
      appBar: UnifiedAppBar(title: AppStrings.moreSectionTitle, showBack: true),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    AppSnackbar.info(context, message);
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
