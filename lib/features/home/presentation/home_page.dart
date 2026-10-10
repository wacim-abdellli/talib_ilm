import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/constants/app_strings.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/last_activity_service.dart';
import '../../../core/services/last_sharh_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../../shared/navigation/fade_page_route.dart';

import 'widgets/home_hero_card.dart';
import 'widgets/continue_learning_card.dart';
import 'widgets/home_header.dart';
import 'widgets/home_quick_actions.dart';

import '../../ilm/data/models/mutun_models.dart';
import '../../ilm/data/models/sharh_model.dart';
import '../../ilm/presentation/ilm_page.dart';
import '../../ilm/data/services/motivation_service.dart';
import '../../ilm/presentation/widgets/motivation_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ilm/presentation/pages/book_view_page.dart';

import '../../prayer/data/models/prayer_models.dart';
import '../../prayer/presentation/qibla_page.dart';
import '../../prayer/presentation/prayer_page.dart';
import '../../quran/presentation/quran_page.dart';
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
  bool _isLoading = true;
  PrayerTimesDay? _prayerDay;
  ContinueData? _continueData;
  DailyQuote? _dailyQuote;

  // Emotional state controller
  final HomeStateController _stateController = HomeStateController();
  Timer? _stateRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllData();

    // Refresh state every minute
    _stateRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _stateController.refresh(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo.png'), context);
    precacheImage(const AssetImage('assets/images/symbol_on_dark.png'), context);
  }

  Future<void> _loadAllData() async {
    // Parallel data loading
    final results = await Future.wait([
      _prayerTimeService.getPrayerTimesDay(),
      _loadContinueData(),
      _loadDailyQuoteData(), // Helper method returning data instead of setting state
      _stateController.initialize(),
    ]);

    if (!mounted) return;

    setState(() {
      _prayerDay = results[0] as PrayerTimesDay;
      _continueData = results[1] as ContinueData?;
      _dailyQuote = results[2] as DailyQuote?;
      _isLoading = false;
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _refreshStats();
      _stateController.refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _stateController.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateRefreshTimer?.cancel();
    super.dispose();
  }

  Future<ContinueData?> _loadContinueData() async {
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
    int? safeTotal = lastActivity.total;
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
    return ContinueData(
      book: book,
      tab: tab,
      sharhFile: sharhFile,
      sharh: sharh,
      page: safePage,
      total: safeTotal,
      progressPercent: progressPercent,
    );
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
    await _loadAllData();
  }

  Future<void> _cycleQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final service = MotivationService(prefs);
    final quote = await service.cycleDailyQuote();
    setState(() {
      _dailyQuote = quote;
    });
  }

  Future<DailyQuote?> _loadDailyQuoteData() async {
    final prefs = await SharedPreferences.getInstance();
    final service = MotivationService(prefs);
    return service.getDailyQuote();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final overlay = Theme.of(context).appBarTheme.systemOverlayStyle;
    if (overlay != null) {
      SystemChrome.setSystemUIOverlayStyle(overlay);
    }

    return Scaffold(
      backgroundColor: context.palette.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _stateController,
          builder: (context, child) {
            final weights = _stateController.getHierarchyWeights();

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
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.sm),
                  ),

                  // Hero card (Prayer Time)
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: weights['prayer'] ?? 1.0,
                      duration: AppMotion.slow,
                      child: AnimatedScale(
                        scale: 0.95 + ((weights['prayer'] ?? 1.0) * 0.05),
                        duration: AppMotion.slow,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xl,
                          ),
                          child: _buildHeroGreetingCard(),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.lg),
                  ),

                  // Daily Motivation with temporal framing
                  if (_dailyQuote != null) ...[
                    SliverToBoxAdapter(
                      child: AnimatedOpacity(
                        opacity: weights['quote'] ?? 1.0,
                        duration: AppMotion.slow,
                        child: AnimatedScale(
                          scale: 0.95 + ((weights['quote'] ?? 1.0) * 0.05),
                          duration: AppMotion.slow,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: context.palette.goldSoft,
                                            borderRadius: AppRadius.smRadius,
                                            border: Border.all(
                                              color: context.palette.gold.withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.auto_awesome_rounded,
                                            size: AppIcon.sm,
                                            color: context.palette.gold,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpace.sm),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'قبس من الوحي',
                                              style: context.text.titleSmall.copyWith(
                                                color: context.palette.text,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              'هدايات إيمانية ونفحات ربانية',
                                              style: context.text.caption.copyWith(
                                                color: context.palette.textMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsetsDirectional.symmetric(
                                        horizontal: AppSpace.sm,
                                        vertical: AppSpace.xs / 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.palette.surfaceRaised,
                                        borderRadius: AppRadius.pillRadius,
                                        border: Border.all(
                                          color: context.palette.border,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'آيات وبصائر',
                                        style: context.text.caption.copyWith(
                                          color: context.palette.gold,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpace.sm),
                                DailyMotivationCard(
                                  quote: _dailyQuote!,
                                  onReload: _cycleQuote,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpace.xl),
                    ),
                  ],

                  // Continue Learning
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: weights['learning'] ?? 1.0,
                      duration: AppMotion.slow,
                      child: AnimatedScale(
                        scale: 0.95 + ((weights['learning'] ?? 1.0) * 0.05),
                        duration: AppMotion.slow,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'طريق العلم والتحصيل',
                                padding: EdgeInsetsDirectional.only(bottom: AppSpace.xs),
                              ),
                              _buildPresenceMessage(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.md),
                  ),
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: weights['learning'] ?? 1.0,
                      duration: AppMotion.slow,
                      child: AnimatedScale(
                        scale: 0.95 + ((weights['learning'] ?? 1.0) * 0.05),
                        duration: AppMotion.slow,
                        child: _buildContinueSection(context),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.xl),
                  ),

                  // Quick actions (Other Features)
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: weights['actions'] ?? 1.0,
                      duration: AppMotion.slow,
                      child: AnimatedScale(
                        scale: 0.95 + ((weights['actions'] ?? 1.0) * 0.05),
                        duration: AppMotion.slow,
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
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.xl),
                  ),

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



  void _openPrayerDetails(BuildContext context) {
    final handled = AppShell.switchToTab(context, 1);
    if (!handled) {
      Navigator.push(context, buildFadeRoute(page: const PrayerPage()));
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'أصبحنا وأصبح الملك لله';
    if (hour >= 12 && hour < 17) return 'حيّاك الله وبيّاك يا طالب العلم';
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
      nextPrayerTime = day.prayers[nextPrayerName] ?? DateTime.now();
      isEstimated = false;
    } else {
      // Fallback: estimate next prayer based on current time
      isEstimated = true;
      final now = DateTime.now();
      final hour = now.hour;

      if (hour < 5) {
        nextPrayerName = AppStrings.prayerFajr;
        nextPrayerTime = DateTime(now.year, now.month, now.day, 5, 0);
      } else if (hour < 12) {
        nextPrayerName = AppStrings.prayerDhuhr;
        nextPrayerTime = DateTime(now.year, now.month, now.day, 12, 0);
      } else if (hour < 15) {
        nextPrayerName = AppStrings.prayerAsr;
        nextPrayerTime = DateTime(now.year, now.month, now.day, 15, 0);
      } else if (hour < 18) {
        nextPrayerName = AppStrings.prayerMaghrib;
        nextPrayerTime = DateTime(now.year, now.month, now.day, 18, 0);
      } else if (hour < 20) {
        nextPrayerName = AppStrings.prayerIsha;
        nextPrayerTime = DateTime(now.year, now.month, now.day, 20, 0);
      } else {
        nextPrayerName = AppStrings.prayerFajr;
        nextPrayerTime = DateTime(now.year, now.month, now.day + 1, 5, 0);
      }
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
