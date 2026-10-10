import 'package:flutter/material.dart';
import '../../../app/app.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../../prayer/presentation/location_settings_sheet.dart';
import '../../prayer/presentation/prayer_settings_sheet.dart';
import '../../quran/data/services/reading_stats_service.dart';
import 'widgets/more_section_card.dart';
import 'widgets/theme_selector_sheet.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  int _streak = 0;
  int _minutesToday = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await ReadingStatsService().getDailyStats();
    final streak = await ReadingStatsService().getStreak();
    if (mounted) {
      setState(() {
        _minutesToday = stats['minutes'] ?? 0;
        _streak = streak;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        final sections = <MoreSection>[
          MoreSection(
            title: 'إعدادات الصلاة',
            subtitle: 'تنبيهات الأذان وطرق الحساب ومواقيت الصلاة',
            icon: Icons.mosque_rounded,
            color: palette.primary,
            onTap: () => _openPrayerSettings(context),
          ),
          MoreSection(
            title: 'الإعدادات العامة والموقع',
            subtitle: AppStrings.moreGeneralSubtitle,
            icon: Icons.location_on_rounded,
            color: palette.success,
            onTap: () => _openLocationSettings(context),
          ),
          MoreSection(
            title: 'المظهر والسمة',
            subtitle: themeService.themeDisplayName,
            icon: themeService.themeIcon,
            color: palette.gold,
            onTap: () => _showThemeSelector(context),
          ),
          MoreSection(
            title: AppStrings.moreLanguageTitle,
            subtitle: AppStrings.moreLanguageSubtitle,
            icon: Icons.translate_rounded,
            color: palette.primary,
            onTap: () => _showInfo(context, AppStrings.moreLanguageInfo),
          ),
          MoreSection(
            title: AppStrings.moreBackupTitle,
            subtitle: AppStrings.moreBackupSubtitle,
            icon: Icons.cloud_sync_rounded,
            color: palette.gold,
            onTap: () => _showInfo(context, AppStrings.moreBackupInfo),
          ),
        ];

        return Scaffold(
          backgroundColor: palette.bg,
          appBar: const PrimaryAppBar(
            title: 'المزيد',
            showBack: false,
          ),
          body: ListView(
            padding: AppSpace.screenPadding.copyWith(
              top: AppSpace.lg,
              bottom: AppSize.navClearance(context),
            ),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              // Student Journey Summary Card
              AppCard(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.goldSoft,
                        border: Border.all(
                          color: palette.gold.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          palette.logoSymbol,
                          width: 28,
                          height: 28,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.menu_book_rounded,
                            color: palette.gold,
                            size: AppIcon.lg,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'طالب علم',
                                style: textTheme.sacred.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: palette.text,
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.goldSoft,
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Text(
                                  'سائر في الطلب',
                                  style: textTheme.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.onGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: AppIcon.sm,
                                color: palette.gold,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                '$_streak أيام تتابع',
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                              const SizedBox(width: AppSpace.md),
                              Icon(
                                Icons.access_time_rounded,
                                size: AppIcon.sm,
                                color: palette.primary,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                '$_minutesToday دقيقة اليوم',
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpace.lg),

              // Section Cards
              ...sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: MoreSectionCard(section: section),
                ),
              ),

              const SizedBox(height: AppSpace.lg),

              // App Footer Card
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.xl,
                    vertical: AppSpace.lg,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.lgRadius,
                    border: Border.all(
                      color: palette.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            palette.logoSymbol,
                            width: 22,
                            height: 22,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.mosque_rounded,
                              size: AppIcon.sm,
                              color: palette.gold,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Text(
                            'طالب علم • النسخة 1.0.0',
                            style: textTheme.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        '«من سلك طريقاً يلتمس فيه علماً سهل الله له به طريقاً إلى الجنة»',
                        style: textTheme.sacred.copyWith(
                          color: palette.gold,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
    ThemeSelectorSheet.show(context);
  }

  void _openPrayerSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
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
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (_) => LocationSettingsSheet(
        onSaved: () {},
      ),
    );
  }
}
