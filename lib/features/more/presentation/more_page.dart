import 'package:flutter/material.dart';
import '../../../app/app.dart';
import '../../../app/theme/app_palette.dart';
import '../../../shared/animations/staggered_entrance.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../adhkar/presentation/widgets/adhkar_notification_sheet.dart';
import '../../favorites/presentation/favorites_page.dart';
import '../../prayer/presentation/location_settings_sheet.dart';
import '../../prayer/presentation/prayer_settings_sheet.dart';
import '../../ilm/presentation/pages/book_view_page.dart';
import '../../ilm/presentation/pages/shamela_reader_page.dart';
import '../../ilm/presentation/widgets/offline_downloads_hub_sheet.dart';
import '../../quran/data/services/reading_stats_service.dart';
import '../../quran/presentation/quran_audio_downloads_page.dart';
import 'credits_and_licenses_page.dart';
import 'dhikr_moment_settings_sheet.dart';
import '../../salaf_gems/presentation/salaf_gems_explorer_page.dart';
import 'widgets/more_page_header.dart';
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
    ReadingStatsService.statsUpdateNotifier.addListener(_loadStats);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  @override
  void dispose() {
    ReadingStatsService.statsUpdateNotifier.removeListener(_loadStats);
    super.dispose();
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
        return Scaffold(
          backgroundColor: palette.bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                MorePageHeader(
                  streak: _streak,
                  minutesToday: _minutesToday,
                  onThemeLongPress: () => _showThemeSelector(context),
                ),

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
                      StaggeredEntrance(
                        index: 0,
                        child: MoreSectionHeader(
                          'الصلاة والتنبيهات',
                          subtitle:
                              'إعداد موقعك ومواقيت الصلاة والأذان وتنبيهات الأذكار',
                        ),
                      ),
                      StaggeredEntrance(
                        index: 1,
                        child: Padding(
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
                      ),
                      StaggeredEntrance(
                        index: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: MoreSectionCard(
                            section: MoreSection(
                              title: 'موقع الصلاة وطريقة الحساب',
                              subtitle: 'حدّد مدينتك وطريقة حساب مواقيت الصلاة',
                              icon: Icons.explore_rounded,
                              color: palette.success,
                              onTap: () => _openLocationSettings(context),
                            ),
                          ),
                        ),
                      ),
                      StaggeredEntrance(
                        index: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: MoreSectionCard(
                            section: MoreSection(
                              title: 'تنبيهات الأذكار اليومية',
                              subtitle:
                                  'تذكير بأذكار الصباح، المساء، والنوم في أوقاتها المسنونة',
                              icon: Icons.notifications_active_rounded,
                              color: palette.gold,
                              onTap: () =>
                                  AdhkarNotificationSheet.show(context),
                            ),
                          ),
                        ),
                      ),
                      StaggeredEntrance(
                        index: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: MoreSectionCard(
                            section: MoreSection(
                              title: 'لحظة ذكر',
                              subtitle: 'بطاقة ذكر متجددة وتذكيرات حسب اختيارك',
                              icon: Icons.spa_rounded,
                              color: palette.success,
                              onTap: () =>
                                  DhikrMomentSettingsSheet.show(context),
                            ),
                          ),
                        ),
                      ),

                      StaggeredEntrance(
                        index: 4,
                        child: MoreSectionHeader(
                          'المحتوى والمحفوظات',
                          subtitle:
                              'العناصر التي حفظتها والتلاوات التي نزّلتها',
                        ),
                      ),
                      StaggeredEntrance(
                        index: 5,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: MoreSectionCard(
                            section: MoreSection(
                              title: 'موسوعة درر السلف والآثار',
                              subtitle:
                                  'أقوال الصحابة، حكم السلف، وفوائد المحققين (8,650+ أثر)',
                              icon: Icons.auto_awesome_rounded,
                              color: palette.gold,
                              onTap: () => Navigator.push(
                                context,
                                buildFadeRoute(
                                  page: const SalafGemsExplorerPage(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      StaggeredEntrance(
                        index: 6,
                        child: Padding(
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
                      ),
                      StaggeredEntrance(
                        index: 7,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: MoreSectionCard(
                            section: MoreSection(
                              title: 'حقيبة المحتوى بدون إنترنت',
                              subtitle:
                                  'تصفح الكتب التراثية المحملة ومتون طالب العلم دون اتصال',
                              icon: Icons.download_done_rounded,
                              color: palette.primary,
                              onTap: () => OfflineDownloadsHubSheet.show(
                                context: context,
                                onOpenShamelaBook: (book) => Navigator.push(
                                  context,
                                  buildFadeRoute(
                                    page: ShamelaReaderPage(book: book),
                                  ),
                                ),
                                onOpenMutunBook: (book) => Navigator.push(
                                  context,
                                  buildFadeRoute(
                                    page: BookViewPage(book: book),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      StaggeredEntrance(
                        index: 8,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: MoreSectionCard(
                            section: MoreSection(
                              title: 'تنزيل تلاوات القرآن',
                              subtitle:
                                  'إدارة تحميل تلاوات القرآن الكريم والاستماع دون اتصال',
                              icon: Icons.download_for_offline_rounded,
                              color: palette.gold,
                              onTap: () => Navigator.push(
                                context,
                                buildFadeRoute(
                                  page: const QuranAudioDownloadsPage(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      StaggeredEntrance(
                        index: 9,
                        child: MoreSectionHeader(
                          'تفضيلات التطبيق',
                          subtitle: 'خصّص مظهر التطبيق لراحتك',
                        ),
                      ),
                      StaggeredEntrance(
                        index: 10,
                        child: Padding(
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
                      ),

                      const SizedBox(height: AppSpace.lg),

                      StaggeredEntrance(
                        index: 11,
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.xl,
                              vertical: AppSpace.lg,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceMuted,
                              borderRadius: AppRadius.lgRadius,
                              border: Border.all(color: palette.border),
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
