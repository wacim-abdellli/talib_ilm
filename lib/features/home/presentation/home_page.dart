import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shimmer/shimmer.dart';
// import 'package:hijri/hijri.dart';
import '../../../app/constants/app_strings.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/last_activity_service.dart';
import '../../../core/services/last_sharh_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../shared/navigation/fade_page_route.dart';

import 'widgets/home_hero_card.dart';

import 'widgets/quick_action_button.dart';

import '../../ilm/data/models/mutun_models.dart';
import '../../ilm/data/models/sharh_model.dart';
import '../../ilm/presentation/ilm_page.dart';
import '../../ilm/data/services/motivation_service.dart';
import '../../ilm/presentation/widgets/motivation_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ilm/presentation/pages/book_view_page.dart';
import '../../favorites/presentation/favorites_page.dart';

import '../../prayer/data/models/prayer_models.dart';
import '../../prayer/presentation/qibla_page.dart';
import '../../prayer/presentation/prayer_page.dart';
import '../../library/presentation/library_page.dart';
// import '../../adhkar/presentation/adhkar_page.dart'; // Removed
import '../../quran/presentation/quran_page.dart';
import '../../../app/theme/theme_colors.dart';
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
  _ContinueData? _continueData;
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
      _continueData = results[1] as _ContinueData?;
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

  Future<_ContinueData?> _loadContinueData() async {
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
    return _ContinueData(
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
    _ContinueData data,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: context.backgroundColor,
      // Drawer removed as moved to More tab
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
                  // App bar (Cleaner, no border)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, // increased side padding
                        vertical: 16,
                      ),
                      child: Builder(
                        builder: (context) {
                          final city = _prayerDay?.city ?? 'مكة المكرمة';
                          final date = _prayerDay?.date ?? DateTime.now();
                          // DISABLED HIJRI due to build error
                          // HijriCalendar.setLocal('ar');
                          // final hijriDate = HijriCalendar.fromDate(date);

                          return Column(
                            children: [
                              // Row 1: Dates (Gregorian + Hijri)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Gregorian Date
                                  Text(
                                    '${date.day}/${date.month}/${date.year}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: context.textPrimaryColor,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  // Hijri Date - Spiritual Context
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.islamicGreenMutedColor
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: context.islamicGreenLightColor
                                            .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: context.islamicGreenLightColor,
                                        ),
                                        const SizedBox(width: 6),
                                        // Placeholder for Hijri (Disabled)
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Row 2: Logo + Greeting + Location
                              Row(
                                children: [
                                  // App Logo
                                  Image.asset(
                                    'assets/images/logo.png',
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 12),

                                  // Greeting
                                  Text(
                                    _getGreeting(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: context.textPrimaryColor,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),

                                  const Spacer(),

                                  // Location with enhanced icon
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 16,
                                        color: context.islamicGreenLightColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        city,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: context.textSecondaryColor,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Hero card (Prayer Time)
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: weights['prayer'] ?? 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedScale(
                        scale: 0.95 + ((weights['prayer'] ?? 1.0) * 0.05),
                        duration: const Duration(milliseconds: 500),
                        child: _buildHeroGreetingCard(),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Daily Motivation with temporal framing
                  if (_dailyQuote != null) ...[
                    SliverToBoxAdapter(
                      child: AnimatedOpacity(
                        opacity: weights['quote'] ?? 1.0,
                        duration: const Duration(milliseconds: 500),
                        child: AnimatedScale(
                          scale: 0.95 + ((weights['quote'] ?? 1.0) * 0.05),
                          duration: const Duration(milliseconds: 500),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Temporal framing: "Today's reflection"
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_outlined,
                                      size: 16,
                                      color: context.textTertiaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'تأمل اليوم',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: context.textSecondaryColor,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
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
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],

                  // Continue Learning with personal presence
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: weights['learning'] ?? 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedScale(
                        scale: 0.95 + ((weights['learning'] ?? 1.0) * 0.05),
                        duration: const Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: context.textTertiaryColor
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'رحلة التعلم',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Personal presence acknowledgment (subtle, not gamified)
                              _buildPresenceMessage(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: weights['learning'] ?? 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedScale(
                        scale: 0.95 + ((weights['learning'] ?? 1.0) * 0.05),
                        duration: const Duration(milliseconds: 500),
                        child: _buildContinueSection(context),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Quick actions (Other Features)
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: weights['actions'] ?? 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedScale(
                        scale: 0.95 + ((weights['actions'] ?? 1.0) * 0.05),
                        duration: const Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: context.textTertiaryColor
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'الأقسام',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Responsive Grid Layout
                              // Contextual Emphasis Logic (Keep for badges if needed later)
                              // final lastAction = _stateController.lastAction;
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // 1. Holy Quran (Brown/Gold)
                                  Expanded(
                                    child: QuickActionButton(
                                      icon: Icons.menu_book_rounded,
                                      label: 'القرآن',
                                      onTap: () => _openQuran(context),
                                      accentColor: const Color(
                                        0xFFD4AF37,
                                      ), // Metallic Gold
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // 2. Library (Blue)
                                  Expanded(
                                    child: QuickActionButton(
                                      icon: Icons.library_books_rounded,
                                      label: 'المكتبة',
                                      onTap: () => _openLibrary(context),
                                      accentColor: context.celestialBlueColor,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // 3. Favorites (Red/Pink/Gold)
                                  Expanded(
                                    child: QuickActionButton(
                                      icon: Icons.favorite_rounded,
                                      label: 'المفضلة',
                                      onTap: () => _openFavorites(context),
                                      accentColor: const Color(
                                        0xFFE57373,
                                      ), // Soft Red/Rose
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // 4. Qibla (Teal/Primary)
                                  Expanded(
                                    child: QuickActionButton(
                                      icon: Icons.explore_rounded,
                                      label: 'القبلة',
                                      onTap: () => _openQibla(context),
                                      accentColor: context.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Extra padding for nav bar
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
    Navigator.push(context, buildFadeRoute(page: const IlmPage()));
  }

  void _openQuran(BuildContext context) {
    _stateController.recordQuranOpened();
    Navigator.push(context, buildFadeRoute(page: const QuranPage()));
  }

  void _openLibrary(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const LibraryPage()));
  }

  void _openQibla(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const QiblaPage()));
  }

  void _openFavorites(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const FavoritesPage()));
  }

  void _openPrayerDetails(BuildContext context) {
    _stateController.recordAdhkarOpened(); // Or prayer?
    Navigator.push(context, buildFadeRoute(page: const PrayerPage()));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'صباح الخير ☀️';
    if (hour >= 12 && hour < 17) return 'نهارك سعيد';
    if (hour >= 17 && hour < 22) return 'مساء الخير 🌙';
    return 'طاب مساؤك';
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
      // Note: This logic is a fallback and marked as estimated.
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
        // Next day Fajr
        nextPrayerTime = DateTime(now.year, now.month, now.day + 1, 5, 0);
      }
    }

    return HomeHeroCard(
      nextPrayerName: nextPrayerName,
      nextPrayerTime: nextPrayerTime,
      isEstimated: isEstimated,
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
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: context.textTertiaryColor,
        fontFamily: 'Cairo',
      ),
    );
  }

  Widget _buildContinueSection(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _LearningPulseCard(isLoading: true, data: null),
      );
    }

    final data = _continueData;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _LearningPulseCard(
        isLoading: false,
        data: data,
        onTap: data == null
            ? () => _openIlm(context)
            : () => _continueLearning(context, data),
      ),
    );
  }
}

/// Learning Pulse Card - REWARD-DRIVEN
class _LearningPulseCard extends StatefulWidget {
  final VoidCallback? onTap;
  final _ContinueData? data;
  final bool isLoading;

  const _LearningPulseCard({this.onTap, this.data, this.isLoading = false});

  @override
  State<_LearningPulseCard> createState() => _LearningPulseCardState();
}

class _LearningPulseCardState extends State<_LearningPulseCard> {
  // Removed Pulse/Glow Controller - M3 relies on surface elevation not glowing borders

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildShimmerCard(context);
    }
    return _buildContentCard(context);
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Container(
      height: 120, // Compact
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceContainer, // M3 Standard
        borderRadius: BorderRadius.circular(20),
        // No border
      ),
      child: Shimmer.fromColors(
        baseColor: context.shimmerBaseColor,
        highlightColor: context.shimmerHighlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    final hasData = widget.data != null;
    final data = widget.data;

    // Theme resolution
    final containerBg = context.surfaceContainer; // M3 Standard Container

    // Progress
    final progress = hasData
        ? ((data!.progressPercent ?? 0) / 100.0).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(24), // Generous padding
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(24),
          // Subtle elevation via shadow only (no border)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDark ? 0.2 : 0.05,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasData ? Icons.menu_book_rounded : Icons.school_rounded,
                    size: 24,
                    color: context.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasData ? 'متابعة التعلّم' : 'ابدأ رحلة طلب العلم',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasData ? data!.book.title : 'استكشف المتون العلمية',
                        style: TextStyle(
                          fontSize: 16,
                          color: context.textPrimaryColor,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded, // Simple arrow
                  size: 20,
                  color: context.textTertiaryColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress Section
            if (hasData)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${data!.progressPercent}% مكتمل',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (data.page != null)
                        Text(
                          'صفحة ${data.page}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textTertiaryColor,
                            fontFamily: 'Cairo',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          context.surfaceElevatedColor, // Lighter track
                      valueColor: AlwaysStoppedAnimation(context.primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ContinueData {
  final IlmBook book;
  final String tab;
  final String? sharhFile;
  final Sharh? sharh;
  final int? page;
  final int? total;
  final int? progressPercent;
  const _ContinueData({
    required this.book,
    required this.tab,
    this.sharhFile,
    this.sharh,
    this.page,
    this.total,
    this.progressPercent,
  });
}
