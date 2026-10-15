import 'dart:async';
import 'package:flutter/material.dart';

import '../../../app/constants/app_strings.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/last_activity_service.dart';
import '../../../core/services/last_sharh_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../../shared/navigation/fade_page_route.dart';

import 'widgets/home_hero_card.dart';
import 'widgets/continue_learning_card.dart';
import 'widgets/home_header.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_quran_radio_card.dart';

import '../../ilm/data/models/mutun_models.dart';
import '../../ilm/data/models/sharh_model.dart';
import '../../ilm/presentation/ilm_page.dart';
import '../../ilm/presentation/pages/book_view_page.dart';

import '../../prayer/data/models/prayer_models.dart';
import '../../prayer/presentation/qibla_page.dart';
import '../../prayer/presentation/prayer_page.dart';
import '../../prayer/presentation/location_settings_sheet.dart';
import '../../quran/presentation/quran_page.dart';
import '../../adhkar/data/adhkar_models.dart';
import '../../adhkar/data/adhkar_service.dart';
import '../../adhkar/presentation/adhkar_session_page.dart';
import 'widgets/home_daily_dhikr_card.dart';
import 'widgets/home_daily_hadith_card.dart';
import '../../radio/presentation/widgets/quran_radio_sheet.dart';
import '../../../app/theme/app_palette.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/home_state_controller.dart';

class HomePage extends StatefulWidget {
  final bool isActive;
  const HomePage({super.key, this.isActive = true});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final LastActivityService _lastActivityService = LastActivityService();
  final LastSharhService _lastSharhService = LastSharhService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();

  final ProgressService _progressService = ProgressService();
  bool _isLoading = false;
  PrayerTimesDay? _prayerDay;
  ContinueData? _continueData;
  DailyDhikrPayload? _dailyDhikr;

  // Emotional state controller
  final HomeStateController _stateController = HomeStateController();
  Timer? _stateRefreshTimer;
  Key _hadithKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocationService.onLocationChanged.addListener(_onLocationChanged);
    _prayerDay = _prayerTimeService.getCachedOrFallbackPrayerTimesDay();
    _loadAllData();

    // Refresh state and prayer times every minute
    _stateRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshPeriodicData(),
    );
  }

  void _onLocationChanged() {
    if (!mounted) return;
    PrayerTimeService.clearCache();
    _loadAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final palette = context.palette;
    precacheImage(AssetImage(palette.logoSymbol), context);
    precacheImage(AssetImage(palette.logoLockup), context);
  }

  Future<void> _loadAllData() async {
    try {
      final prayerFuture = _prayerTimeService.getPrayerTimesDay();
      final continueFuture = _loadContinueData();
      final dhikrFuture = AthkarService().getDailyDhikr();

      final prayerDay = await prayerFuture.catchError((_) {
        return _prayerTimeService.getCachedOrFallbackPrayerTimesDay();
      });

      if (!mounted) return;
      setState(() {
        _prayerDay = prayerDay;
      });

      final stateFuture = _stateController.initialize(preloadedPrayerDay: prayerDay);

      final results = await Future.wait([
        continueFuture.catchError((_) => null),
        stateFuture.catchError((_) {}),
        dhikrFuture.catchError((_) => null),
      ]);

      if (!mounted) return;
      setState(() {
        _continueData = results[0] as ContinueData?;
        _dailyDhikr = results[2] as DailyDhikrPayload?;
      });
    } catch (_) {
      // Graceful fallback: never leave UI in a broken state
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPeriodicData() async {
    _stateController.refresh();
    try {
      final day = await _prayerTimeService.getPrayerTimesDay();
      if (mounted) {
        setState(() => _prayerDay = day);
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _refreshStats();
      _refreshPeriodicData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPeriodicData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocationService.onLocationChanged.removeListener(_onLocationChanged);
    _stateRefreshTimer?.cancel();
    super.dispose();
  }

  Future<ContinueData?> _loadContinueData() async {
    try {
      final lastActivity = await _lastActivityService.getLastActivity();
      if (lastActivity == null) return null;
      final program = await AssetService.loadMutunProgram();
      final book = _findBook(program, lastActivity.bookId);
      if (book == null) return null;
      var tab = lastActivity.tab;
      if (tab == LastActivityService.tabLessons && book.playlistId == null) {
        tab = LastActivityService.tabMutn;
      }
      if (tab == LastActivityService.tabSharh && book.shuruh.isEmpty) {
        tab = LastActivityService.tabMutn;
      }
      String? sharhFile = lastActivity.sharhFile;
      if (tab == LastActivityService.tabSharh && sharhFile == null) {
        sharhFile = await _lastSharhService.get(book.id);
      }
      Sharh? sharh;
      if (tab == LastActivityService.tabSharh && sharhFile != null) {
        sharh = _findSharhByFile(book, sharhFile);
      }
      int? progressPercent;
      int? safePage = lastActivity.page;
      int? safeTotal = book.totalPages > 0 ? book.totalPages : lastActivity.total;
      if (safePage != null && safeTotal != null && safeTotal > 0) {
        final normalizedTotal = safeTotal < safePage ? safePage : safeTotal;
        final normalizedPage = safePage.clamp(1, normalizedTotal);
        safePage = normalizedPage;
        safeTotal = normalizedTotal;
        final value = (normalizedPage / normalizedTotal) * 100;
        progressPercent = value.clamp(0, 100).round();
      } else {
        final progress = await _progressService.getProgress(book.id);
        if (progress != null && progress.totalLessons > 0) {
          progressPercent = progress.percent.clamp(0, 100).round();
        }
      }
      progressPercent ??= (safePage != null && safeTotal != null && safeTotal > 0)
          ? ((safePage / safeTotal) * 100).round().clamp(0, 100)
          : 0;
      return ContinueData(
        book: book,
        tab: tab,
        sharhFile: sharhFile,
        sharh: sharh,
        page: safePage,
        total: safeTotal,
        progressPercent: progressPercent,
      );
    } catch (_) {
      return null;
    }
  }

  IlmBook? _findBook(MutunProgram program, String bookId) {
    for (final level in program.levels) {
      for (final book in level.books) {
        if (book.id == bookId) return book;
      }
    }
    return null;
  }

  Sharh? _findSharhByFile(IlmBook book, String file) {
    for (final sharh in book.shuruh) {
      if (sharh.file == file) return sharh;
    }
    return null;
  }

  Future<void> _continueLearning(
    BuildContext context,
    ContinueData data,
  ) async {
    final tabIndex = switch (data.tab) {
      LastActivityService.tabSharh => 1,
      LastActivityService.tabLessons => 2,
      _ => 0,
    };

    await _lastActivityService.setLastBook(data.book.id);
    await _lastActivityService.setLastTab(data.book.id, data.tab);

    if (!context.mounted) return;

    await Navigator.push(
      context,
      buildFadeRoute(
        page: BookViewPage(
          book: data.book,
          initialTabIndex: tabIndex,
          autoOpenSharhFile: data.tab == LastActivityService.tabSharh
              ? data.sharhFile
              : null,
          openLessonsOnStart: data.tab == LastActivityService.tabLessons,
        ),
      ),
    );
    if (!mounted) return;
    _refreshStats();
  }

  void _refreshStats() async {
    final data = await _loadContinueData();
    if (mounted) {
      setState(() {
        _continueData = data;
      });
    }
  }

  Future<void> _handlePullRefresh() async {
    setState(() {
      _hadithKey = UniqueKey();
    });
    await _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _stateController,
          builder: (context, child) {
            return RefreshIndicator(
              onRefresh: _handlePullRefresh,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // App bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xl,
                        vertical: AppSpace.lg,
                      ),
                      child: HomeHeader(
                        city: _prayerDay?.city ?? 'مكة المكرمة',
                        greeting: _getGreeting(),
                        greetingSubtitle: _getGreetingSubtitle(),
                        onLocationTap: () => _openLocationSettings(context),
                        onSearchTap: () => _openIlm(context),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.sm),
                  ),

                  // Hero card (Prayer Time)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xl,
                      ),
                      child: _buildHeroGreetingCard(),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.lg),
                  ),

                  // Daily Graded Hadith & Prophetic Remembrances
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xl,
                      ),
                      child: HomeDailyHadithCard(key: _hadithKey),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.xl),
                  ),

                  // Daily Dhikr
                  if (_dailyDhikr != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.xl,
                        ),
                        child: HomeDailyDhikrCard(
                          payload: _dailyDhikr!,
                          onOpenSession: () => _openAdhkarSession(_dailyDhikr!.category),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpace.xl),
                    ),
                  ],

                  // Continue Learning
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'زاد طالب العلم',
                            padding: EdgeInsetsDirectional.only(bottom: AppSpace.xs),
                          ),
                          _buildPresenceMessage(context),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.md),
                  ),
                  SliverToBoxAdapter(
                    child: _buildContinueSection(context),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.xl),
                  ),

                  // Quick actions (أبواب الخير)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xl,
                      ),
                      child: HomeQuickActions(
                        onOpenQuran: () => _openQuran(context),
                        onOpenIlm: () => _openIlm(context),
                        onOpenAdhkar: () => _openAdhkar(context),
                        onOpenQibla: () => _openQibla(context),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.md),
                  ),

                  // Live Quran Radio Card (إذاعة القرآن الكريم)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xl,
                      ),
                      child: HomeQuranRadioCard(
                        onTap: () => QuranRadioSheet.show(context),
                      ),
                    ),
                  ),

                  // Bottom clearance ensuring the radio card scrolls cleanly above the floating nav bar
                  SliverToBoxAdapter(
                    child: SizedBox(height: AppSize.navClearance(context)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openIlm(BuildContext context) {
    _stateController.recordLearningContinued();
    final handled = AppShell.switchToTab(context, 2);
    if (!handled) {
      Navigator.push(context, buildFadeRoute(page: const IlmPage()));
    }
  }

  void _openQuran(BuildContext context) {
    _stateController.recordQuranOpened();
    Navigator.push(context, buildFadeRoute(page: const QuranPage()));
  }


  void _openQibla(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const QiblaPage()));
  }

  void _openAdhkar(BuildContext context) {
    AppShell.switchToTab(context, 3);
  }

  void _openAdhkarSession(AdhkarCategory category) {
    _stateController.recordAdhkarOpened();
    Navigator.push(
      context,
      buildFadeRoute(page: AdhkarSessionPage(category: category)),
    );
  }

  void _openLocationSettings(BuildContext context) {
    LocationSettingsSheet.show(
      context,
      onSaved: () {
        LocationService.clearCache();
        PrayerTimeService.clearCache();
        _loadAllData();
      },
    );
  }

  void _openPrayerDetails(BuildContext context) {
    final handled = AppShell.switchToTab(context, 1);
    if (!handled) {
      Navigator.push(context, buildFadeRoute(page: const PrayerPage()));
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'أصبحنا وأصبح الملك لله';
    if (hour >= 12 && hour < 17) return 'حيّاك الله يا طالب العلم';
    if (hour >= 17 && hour < 22) return 'أمسينا وأمسى الملك لله';
    return 'طابت ليلتك بذكر الله';
  }

  String _getGreetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'طاب مسعاك في طلب العلم والخير';
    if (hour >= 12 && hour < 17) return 'بارك الله في وقتك وثبّت خطاك';
    if (hour >= 17 && hour < 22) return 'أنار الله دربك بنور العلم والهدى';
    return 'ألا بذكر الله تطمئن القلوب';
  }

  Widget _buildHeroGreetingCard() {
    final day = _prayerDay;
    bool isEstimated = false;

    String nextPrayerName;
    DateTime nextPrayerTime;

    if (day != null) {
      nextPrayerName = day.nextPrayer;
      nextPrayerTime = day.nextPrayerTime ?? day.prayers[nextPrayerName] ?? DateTime.now();
      if (nextPrayerTime.isBefore(DateTime.now())) {
        if (nextPrayerName == AppStrings.prayerFajr) {
          nextPrayerTime = nextPrayerTime.add(const Duration(days: 1));
        }
      }
      isEstimated = false;
    } else {
      isEstimated = true;
      final now = DateTime.now();
      final (pName, pHour, dayOffset) = switch (now.hour) {
        < 5 => (AppStrings.prayerFajr, 5, 0),
        < 12 => (AppStrings.prayerDhuhr, 12, 0),
        < 15 => (AppStrings.prayerAsr, 15, 0),
        < 18 => (AppStrings.prayerMaghrib, 18, 0),
        < 20 => (AppStrings.prayerIsha, 20, 0),
        _ => (AppStrings.prayerFajr, 5, 1),
      };
      nextPrayerName = pName;
      nextPrayerTime = DateTime(now.year, now.month, now.day + dayOffset, pHour, 0);
    }

    return HomeHeroCard(
      nextPrayerName: nextPrayerName,
      nextPrayerTime: nextPrayerTime,
      isEstimated: isEstimated,
      allPrayers: day?.prayers,
      onTap: () => _openPrayerDetails(context),
    );
  }

  /// Personal presence acknowledgment using emotional state
  Widget _buildPresenceMessage(BuildContext context) {
    final message = _stateController.getPresenceMessage();

    // Silent presence for userAbsent state (no guilt)
    if (message == null) {
      return const SizedBox.shrink();
    }

    return Text(
      message,
      style: context.text.caption.copyWith(
        color: context.palette.textSubtle,
      ),
    );
  }

  Widget _buildContinueSection(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
        child: LearningPulseCard(isLoading: true, data: null),
      );
    }

    final data = _continueData;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
      child: LearningPulseCard(
        isLoading: false,
        data: data,
        onTap: data == null
            ? () => _openIlm(context)
            : () => _continueLearning(context, data),
      ),
    );
  }
}
