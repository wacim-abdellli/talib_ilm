import 'package:flutter/material.dart';
import '../../../app/app.dart';
import '../../../app/theme/app_palette.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../adhkar/presentation/widgets/adhkar_notification_sheet.dart';
import '../../favorites/presentation/favorites_page.dart';
import '../../prayer/presentation/location_settings_sheet.dart';
import '../../prayer/presentation/prayer_settings_sheet.dart';
import '../../quran/data/services/reading_stats_service.dart';
import '../../quran/presentation/quran_audio_downloads_page.dart';
import 'credits_and_licenses_page.dart';
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

  Widget _buildCategoryHeader(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    final palette = context.palette;
    final textTheme = context.text;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpace.xs,
        top: AppSpace.md,
        bottom: AppSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.caption.copyWith(
              color: palette.gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            subtitle,
            style: textTheme.caption.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: palette.bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Integrated Luxury Settings Header ───────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.xl,
                    vertical: AppSpace.md,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: palette.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tier 1: Title, Sacred Emblem, and Quick Theme Switcher
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.surfaceRaised,
                              borderRadius: AppRadius.mdRadius,
                              border: Border.all(
                                color: palette.gold.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: palette.shadow,
                            ),
                            padding: const EdgeInsets.all(AppSpace.xs),
                            child: ClipRRect(
                              borderRadius: AppRadius.smRadius,
                              child: Image.asset(
                                palette.logoSymbol,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.settings_suggest_rounded,
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
                                Text(
                                  'الإعدادات والمزيد',
                                  style: textTheme.title.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: AppSpace.xs / 2),
                                Text(
                                  'طالب علم • سائر في الطلب 🌿',
                                  style: textTheme.caption.copyWith(
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          // Quick Theme Pill Action
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showThemeSelector(context),
                              borderRadius: AppRadius.pillRadius,
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.md,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceMuted,
                                  borderRadius: AppRadius.pillRadius,
                                  border: Border.all(
                                    color: palette.border,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      themeService.themeIcon,
                                      size: AppIcon.sm,
                                      color: palette.gold,
                                    ),
                                    const SizedBox(width: AppSpace.xs),
                                    Text(
                                      themeService.themeDisplayName,
                                      style: textTheme.caption.copyWith(
                                        color: palette.text,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpace.md),

                      // Tier 2: Study Activity & Streak Status Strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.sm,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(
                            color: palette.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                                    color: palette.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: 1,
                              height: 14,
                              color: palette.border,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: AppIcon.sm,
                                  color: palette.primary,
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  '$_minutesToday دقيقة تعلّم اليوم',
                                  style: textTheme.caption.copyWith(
                                    color: palette.text,
                                    fontWeight: FontWeight.bold,
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

                // ── Scrollable Settings Sections ────────────────────────
                Expanded(
                  child: ListView(
                    padding: AppSpace.screenPadding.copyWith(
                      top: AppSpace.xs,
                      bottom: AppSize.navClearance(context),
                    ),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: [
                      // Group 1: الصلاة والتنبيهات
                      _buildCategoryHeader(
                        context,
                        'الصلاة والتنبيهات',
                        'إعداد موقعك ومواقيت الصلاة والأذان وتنبيهات الأذكار',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: MoreSectionCard(
                          section: MoreSection(
                            title: 'تنبيهات الصلاة والأذان',
                            subtitle:
                                'اعرض حالة الإشعارات واضبط الأذان والإقامة',
                            icon: Icons.notifications_active_rounded,
                            color: palette.gold,
                            onTap: () => _openPrayerSettings(
                              context,
                              initialTabIndex: 1,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: MoreSectionCard(
                          section: MoreSection(
                            title: 'موقع الصلاة وطريقة الحساب',
                            subtitle:
                                'حدّد مدينتك وطريقة حساب مواقيت الصلاة',
                            icon: Icons.explore_rounded,
                            color: palette.success,
                            onTap: () => _openLocationSettings(context),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: MoreSectionCard(
                          section: MoreSection(
                            title: 'تنبيهات الأذكار اليومية',
                            subtitle:
                                'تذكير بأذكار الصباح، المساء، والنوم في أوقاتها المسنونة',
                            icon: Icons.notifications_active_rounded,
                            color: palette.gold,
                            onTap: () => AdhkarNotificationSheet.show(context),
                          ),
                        ),
                      ),

                      // Group 2: المحتوى والمحفوظات
                      _buildCategoryHeader(
                        context,
                        'المحتوى والمحفوظات',
                        'العناصر التي حفظتها والتلاوات التي نزّلتها',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: MoreSectionCard(
                          section: MoreSection(
                            title: 'المفضلة والمحفوظات',
                            subtitle:
                                'إشارات القراءة، الأذكار، المتون، والفوائد المحفوظة',
                            icon: Icons.bookmark_rounded,
                            color: palette.gold,
                            onTap: () => Navigator.push(
                              context,
                              buildFadeRoute(page: const FavoritesPage()),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: MoreSectionCard(
                          section: MoreSection(
                            title: 'التنزيلات الصوتية',
                            subtitle:
                                'إدارة التلاوات المحملة للاستماع دون اتصال بالإنترنت',
                            icon: Icons.download_for_offline_rounded,
                            color: palette.primary,
                            onTap: () => Navigator.push(
                              context,
                              buildFadeRoute(
                                page: const QuranAudioDownloadsPage(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Group 3: التفضيلات والمظهر
                      _buildCategoryHeader(
                        context,
                        'تفضيلات التطبيق',
                        'خصّص مظهر التطبيق لراحتك',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: MoreSectionCard(
                          section: MoreSection(
                            title: 'المظهر والسمة',
                            subtitle:
                                'تخصيص وضع الرؤية وألوان الواجهة للقراءة المريحة',
                            icon: themeService.themeIcon,
                            color: palette.gold,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: palette.surfaceMuted,
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(
                                  color: palette.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                themeService.themeDisplayName,
                                style: textTheme.captionBold.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ),
                            onTap: () => _showThemeSelector(context),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpace.lg),

                      // App Footer Card
                      Center(
                        child: Container(
                          width: double.infinity,
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
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                      Icons.mosque_rounded,
                                      size: AppIcon.sm,
                                      color: palette.gold,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Text(
                                    'طالب علم • الإصدار 2.0.0',
                                    style: textTheme.captionHeavy.copyWith(
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                '«مَن سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا، سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الجَنَّةِ»',
                                style: textTheme.sacred.copyWith(
                                  color: palette.gold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpace.md),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    buildFadeRoute(
                                      page: const CreditsAndLicensesPage(),
                                    ),
                                  ),
                                  borderRadius: AppRadius.pillRadius,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.md,
                                      vertical: AppSpace.xs,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.shield_outlined,
                                          size: AppIcon.xs,
                                          color: palette.textMuted,
                                        ),
                                        const SizedBox(width: AppSpace.xs),
                                        Text(
                                          'بيانات الإسناد ومصادر المحتوى',
                                          style: textTheme.caption.copyWith(
                                            color: palette.textMuted,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: palette.border,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeSelector(BuildContext context) {
    ThemeSelectorSheet.show(context);
  }

  void _openPrayerSettings(BuildContext context, {int initialTabIndex = 0}) {
    PrayerSettingsSheet.show(context, initialTabIndex: initialTabIndex);
  }

  void _openLocationSettings(BuildContext context) {
    LocationSettingsSheet.show(context);
  }
}
