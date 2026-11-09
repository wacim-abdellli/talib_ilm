import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/app.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/dhikr_moment_service.dart';
import '../../../shared/animations/staggered_entrance.dart';
import '../../../shared/animations/theme_switcher.dart';
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
import '../../salaf_gems/presentation/salaf_gems_explorer_page.dart';
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

  Future<void> _openDhikrMomentSettings(BuildContext context) async {
    var settings = await DhikrMomentService.load();
    late StateSetter setModalState;
    if (!context.mounted) return;
    Future<void> pickWindowTime(bool isStart) async {
      final minutes = isStart ? settings.startMinutes : settings.endMinutes;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      );
      if (picked == null) return;
      final value = picked.hour * 60 + picked.minute;
      setModalState(() {
        settings = isStart
            ? settings.copyWith(startMinutes: value)
            : settings.copyWith(endMinutes: value);
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          setModalState = setState;
          final preview = switch (settings.content) {
            DhikrMomentContent.names => ('الرَّحْمَنُ', 'واسع الرحمة بخلقه'),
            DhikrMomentContent.adhkar => (
              'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
              'تنزيهٌ لله وحمدٌ له',
            ),
            DhikrMomentContent.duas => (
              'رَبِّ زِدْنِي عِلْمًا',
              'دعاءٌ قرآني قصير',
            ),
            DhikrMomentContent.quran => (
              'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
              'الشرح • ٦',
            ),
            DhikrMomentContent.hadith => (
              'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
              'صحيح البخاري • ١',
            ),
            DhikrMomentContent.mixed => (
              'تذكيرٌ يتجدد خلال يومك',
              'ذكر • دعاء • آية • حديث',
            ),
          };
          final colors = Theme.of(context).colorScheme;
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .88,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpace.lg,
                  AppSpace.sm,
                  AppSpace.lg,
                  AppSpace.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: AppRadius.mdRadius,
                          ),
                          child: Icon(Icons.spa_rounded, color: colors.primary),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'لحظة ذكر',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'اختر ما تحب أن يذكّرك به يومك',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: settings.enabled,
                          onChanged: (value) async {
                            setModalState(
                              () =>
                                  settings = settings.copyWith(enabled: value),
                            );
                            if (value &&
                                DhikrMomentService.supportsFloatingOverlay &&
                                !await DhikrMomentService.hasOverlayPermission()) {
                              await DhikrMomentService.requestOverlayPermission();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpace.lg),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: AppRadius.lgRadius,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    settings.content == DhikrMomentContent.mixed
                                        ? 'لَحْظَةٌ لِقَلْبِكَ'
                                        : 'مِثَالٌ عَلَى الْبِطَاقَة',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: colors.onPrimary.withValues(
                                            alpha: .78,
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  Text(
                                    preview.$1,
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: colors.onPrimary,
                                          height: 1.5,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpace.xs),
                                  Text(
                                    preview.$2,
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colors.onPrimary.withValues(
                                            alpha: .82,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.lg),
                            Text(
                              'ماذا تريد أن يظهر؟',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpace.sm),
                            Wrap(
                              spacing: AppSpace.sm,
                              runSpacing: AppSpace.xs,
                              children: [
                                for (final option in DhikrMomentContent.values)
                                  ChoiceChip(
                                    avatar: Icon(switch (option) {
                                      DhikrMomentContent.names =>
                                        Icons.auto_awesome_rounded,
                                      DhikrMomentContent.adhkar =>
                                        Icons.favorite_rounded,
                                      DhikrMomentContent.duas =>
                                        Icons.volunteer_activism_rounded,
                                      DhikrMomentContent.quran =>
                                        Icons.menu_book_rounded,
                                      DhikrMomentContent.hadith =>
                                        Icons.format_quote_rounded,
                                      DhikrMomentContent.mixed =>
                                        Icons.shuffle_rounded,
                                    }, size: AppIcon.xs),
                                    label: Text(switch (option) {
                                      DhikrMomentContent.mixed => 'رحلة متنوعة',
                                      DhikrMomentContent.adhkar => 'الأذكار',
                                      DhikrMomentContent.names => 'أسماء الله',
                                      DhikrMomentContent.duas => 'أدعية',
                                      DhikrMomentContent.quran => 'آيات قرآنية',
                                      DhikrMomentContent.hadith => 'من السنة',
                                    }),
                                    selected: settings.content == option,
                                    onSelected: (_) => setModalState(
                                      () => settings = settings.copyWith(
                                        content: option,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.lg),
                            Text(
                              'متى تحب أن تراها؟',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpace.xs),
                            Text(
                              'حتى ${settings.timesPerDay} ${settings.timesPerDay == 1 ? 'مرة' : 'مرات'} خلال الفترة التي تختارها',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Slider(
                                value: settings.timesPerDay.toDouble(),
                                min: 1,
                                max: DhikrMomentService.maxAppearancesPerDay
                                    .toDouble(),
                                divisions:
                                    DhikrMomentService.maxAppearancesPerDay - 1,
                                label: '${settings.timesPerDay}',
                                onChanged: (value) => setModalState(
                                  () => settings = settings.copyWith(
                                    timesPerDay: value.round(),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => pickWindowTime(true),
                                    icon: const Icon(Icons.wb_sunny_outlined),
                                    label: Text(
                                      'من ${_formatMomentTime(settings.startMinutes)}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => pickWindowTime(false),
                                    icon: const Icon(
                                      Icons.nights_stay_outlined,
                                    ),
                                    label: Text(
                                      'إلى ${_formatMomentTime(settings.endMinutes)}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.md),
                            if (DhikrMomentService.supportsFloatingOverlay)
                              TextButton.icon(
                                onPressed:
                                    DhikrMomentService.requestOverlayPermission,
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text(
                                  'فتح إعدادات الظهور فوق التطبيقات',
                                ),
                              )
                            else
                              Text(
                                'على iPhone تظهر كتذكيرات مجدولة، إذ لا يسمح النظام ببطاقة فوق التطبيقات.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    FilledButton.icon(
                      onPressed: () async {
                        if (settings.endMinutes <= settings.startMinutes) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('اختر وقت انتهاء بعد وقت البدء.'),
                            ),
                          );
                          return;
                        }
                        final ready = await DhikrMomentService.save(settings);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (!ready && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'حُفظت الإعدادات، لكن تعذر تفعيل التذكيرات. تحقق من الأذونات.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('حفظ لحظة الذكر'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatMomentTime(int minutes) {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    final period = hour < 12 ? 'ص' : 'م';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

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
                      bottom: BorderSide(color: palette.border, width: 1),
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
                          // Quick Theme Pill Action with Circular Reveal
                          ThemeSwitcher(
                            builder: (switcherContext) {
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    final isDark = themeService.isDark;
                                    final nextMode = isDark
                                        ? ThemeMode.light
                                        : ThemeMode.dark;
                                    final nextTheme = nextMode == ThemeMode.dark
                                        ? AppTheme.darkTheme
                                        : AppTheme.lightTheme;
                                    ThemeSwitcher.of(
                                      switcherContext,
                                    ).changeTheme(
                                      theme: nextTheme,
                                      isReversed: isDark,
                                      onAnimationFinish: () {
                                        themeService.setThemeMode(nextMode);
                                      },
                                    );
                                  },
                                  onLongPress: () =>
                                      _showThemeSelector(context),
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
                              );
                            },
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
                          border: Border.all(color: palette.border, width: 1),
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
                      StaggeredEntrance(
                        index: 0,
                        child: _buildCategoryHeader(
                          context,
                          'الصلاة والتنبيهات',
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
                              onTap: () => _openDhikrMomentSettings(context),
                            ),
                          ),
                        ),
                      ),

                      // Group 2: المحتوى والمحفوظات
                      StaggeredEntrance(
                        index: 4,
                        child: _buildCategoryHeader(
                          context,
                          'المحتوى والمحفوظات',
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

                      // Group 3: التفضيلات والمظهر
                      StaggeredEntrance(
                        index: 9,
                        child: _buildCategoryHeader(
                          context,
                          'تفضيلات التطبيق',
                          'خصّص مظهر التطبيق لراحتك',
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

                      // App Footer Card
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
