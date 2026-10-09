import 'package:flutter/material.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../app/app.dart';
import '../../quran/data/services/reading_stats_service.dart';
import '../../prayer/presentation/prayer_settings_sheet.dart';
import '../../prayer/presentation/location_settings_sheet.dart';
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
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        final sections = <MoreSection>[
          MoreSection(
            title: 'إعدادات الصلاة',
            subtitle: 'تنبيهات الأذان وطرق الحساب ومواقيت الصلاة',
            icon: Icons.mosque_rounded,
            color: context.primaryColor,
            onTap: () => _openPrayerSettings(context),
          ),
          MoreSection(
            title: 'الإعدادات العامة والموقع',
            subtitle: AppStrings.moreGeneralSubtitle,
            icon: Icons.location_on_rounded,
            color: context.islamicGreenColor,
            onTap: () => _openLocationSettings(context),
          ),
          MoreSection(
            title: 'المظهر والسمة',
            subtitle: themeService.themeDisplayName,
            icon: themeService.themeIcon,
            color: context.goldColor,
            onTap: () => _showThemeSelector(context),
          ),
          MoreSection(
            title: AppStrings.moreLanguageTitle,
            subtitle: AppStrings.moreLanguageSubtitle,
            icon: Icons.translate_rounded,
            color: context.celestialBlueLightColor,
            onTap: () => _showInfo(context, AppStrings.moreLanguageInfo),
          ),
          MoreSection(
            title: AppStrings.moreBackupTitle,
            subtitle: AppStrings.moreBackupSubtitle,
            icon: Icons.cloud_sync_rounded,
            color: context.goldLightColor,
            onTap: () => _showInfo(context, AppStrings.moreBackupInfo),
          ),
        ];

        final isDark = context.isDark;
        final gold = context.goldColor;
        return Scaffold(
          backgroundColor: context.backgroundColor,
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  border: Border(
                    bottom: BorderSide(
                      color: context.outlineColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.primaryColor,
                              gold,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: gold.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المزيد',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimaryColor,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              'الإعدادات والتفضيلات العامة',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.textSecondaryColor,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  children: [
                    // Student Journey Summary Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  context.surfaceContainerHigh,
                                  context.surfaceContainer,
                                ]
                              : [
                                  Colors.white,
                                  context.surfaceContainerLow,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: gold.withValues(alpha: isDark ? 0.35 : 0.28),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.04,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: gold.withValues(alpha: 0.15),
                              border: Border.all(
                                color: gold.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 30,
                                height: 30,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.menu_book_rounded,
                                  color: gold,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'طالب علم',
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: gold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'سائر في الطلب',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: gold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 14,
                                      color: AppColors.categorySeerah,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_streak أيام تتابع',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        color: context.textSecondaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: context.islamicGreenColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_minutesToday دقيقة اليوم',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        color: context.textSecondaryColor,
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

                    const SizedBox(height: 16),

                    // Section Cards
                    ...sections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MoreSectionCard(section: section),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // App Footer Card
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: context.surfaceContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: context.outlineColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  width: 22,
                                  height: 22,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.mosque_rounded,
                                    size: 18,
                                    color: gold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'طالب علم • النسخة 1.0.0',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '«من سلك طريقاً يلتمس فيه علماً سهل الله له به طريقاً إلى الجنة»',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 14,
                                color: gold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSize.navClearance(context)),
                  ],
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
          top: Radius.circular(24),
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
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => LocationSettingsSheet(
        onSaved: () {},
      ),
    );
  }
}
