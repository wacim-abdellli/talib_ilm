import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:talib_ilm/shared/widgets/shimmer_loading.dart';
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
import '../../library/presentation/library_page.dart';
import '../../adhkar/presentation/adhkar_page.dart';
import '../../quran/presentation/quran_page.dart';
import '../../../app/theme/theme_colors.dart';

class HomePage extends StatefulWidget {
  final bool isActive;
  const HomePage({super.key, this.isActive = true});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LastActivityService _lastActivityService = LastActivityService();
  final LastSharhService _lastSharhService = LastSharhService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();

  final ProgressService _progressService = ProgressService();
  late Future<_ContinueData?> _continueFuture;
  late final Future<PrayerTimesDay> _prayerFuture;

  DailyQuote? _dailyQuote;

  @override
  void initState() {
    super.initState();
    _continueFuture = _loadContinueData();
    _prayerFuture = _prayerTimeService.getPrayerTimesDay();

    _loadDailyQuote();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _refreshStats();
    }
  }

  @override
  void dispose() {
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

  void _refreshStats() {
    setState(() {
      _continueFuture = _loadContinueData();
    });
  }

  Future<void> _handlePullRefresh() async {
    await _loadDailyQuote();
  }

  Future<void> _cycleQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final service = MotivationService(prefs);
    final quote = await service.cycleDailyQuote();
    setState(() {
      _dailyQuote = quote;
    });
  }

  Future<void> _loadDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final service = MotivationService(prefs);
    final quote = await service.getDailyQuote();
    setState(() {
      _dailyQuote = quote;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: RefreshIndicator(
          onRefresh: _handlePullRefresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // App bar with context (Date, Logo, Location)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF000000)
                        : context.surfaceColor,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF1F1F1F)
                            : context.borderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: FutureBuilder<PrayerTimesDay>(
                    future: _prayerFuture,
                    builder: (context, snapshot) {
                      final city = snapshot.data?.city ?? 'مكة المكرمة';
                      final date = snapshot.data?.date ?? DateTime.now();

                      // Calculate Hijri date
                      final hijriDate = _getHijriDate(date);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: Hijri Date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hijriDate['day']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark
                                      ? const Color(0xFFFFFFFF)
                                      : context.textPrimaryColor,
                                ),
                              ),
                              Text(
                                hijriDate['year']!,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFA1A1A1)
                                      : context.textSecondaryColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),

                          // Center: Logo
                          Image.asset(
                            'assets/images/logo.png',
                            height: 44,
                            fit: BoxFit.contain,
                          ),

                          // Right: Location
                          Row(
                            children: [
                              Text(
                                city,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark
                                      ? const Color(0xFFFFFFFF)
                                      : context.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.location_on_outlined,
                                color: isDark
                                    ? const Color(0xFFFFFFFF)
                                    : context.textTertiaryColor,
                                size: 18,
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
              SliverToBoxAdapter(child: _buildHeroGreetingCard()),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Daily Motivation
              if (_dailyQuote != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DailyMotivationCard(
                      quote: _dailyQuote!,
                      onReload: _cycleQuote,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],

              // Continue Learning
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFFC084FC)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'رحلة التعلم',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : context.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildContinueSection(context)),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Quick actions (Other Features)
              SliverToBoxAdapter(
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
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D9C0), Color(0xFF14B8A6)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'الأقسام',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            QuickActionButton(
                              icon: Icons.menu_book_rounded,
                              label: 'القرآن الكريم',
                              color: const Color(
                                0xFF8D6E63,
                              ), // Brown (was Green)
                              onTap: () => _openQuran(context),
                            ),
                            const SizedBox(width: 10),
                            QuickActionButton(
                              icon: Icons.library_books_rounded,
                              label: 'المكتبة',
                              color: const Color(0xFF3B82F6),
                              onTap: () => _openLibrary(context),
                            ),
                            const SizedBox(width: 10),
                            QuickActionButton(
                              icon: Icons.favorite_rounded,
                              label: 'المفضلة',
                              color: const Color(0xFFEC4899),
                              onTap: () => _openFavorites(context),
                            ),
                            const SizedBox(width: 10),
                            QuickActionButton(
                              icon: Icons.explore_rounded,
                              label: 'القبلة',
                              color: const Color(0xFF14B8A6),
                              onTap: () => _openQibla(context),
                            ),
                            const SizedBox(width: 10),
                            QuickActionButton(
                              icon: Icons.auto_awesome_rounded,
                              label: 'الأذكار',
                              color: const Color(0xFF8B5CF6),
                              onTap: () => _openAdhkar(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Extra padding for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  void _openIlm(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const IlmPage()));
  }

  void _openAdhkar(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const AdhkarPage()));
  }

  void _openQuran(BuildContext context) {
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

  Widget _buildHeroGreetingCard() {
    return FutureBuilder<PrayerTimesDay>(
      future: _prayerFuture,
      builder: (context, snapshot) {
        // Show card immediately with estimated/fallback data
        final hasData = snapshot.hasData;
        final day = snapshot.data;

        // Fallback: estimate next prayer based on current time
        String nextPrayerName;
        DateTime nextPrayerTime;

        if (hasData && day != null) {
          nextPrayerName = day.nextPrayer;
          nextPrayerTime = day.prayers[nextPrayerName] ?? DateTime.now();
        } else {
          // Estimate based on typical prayer times
          final now = DateTime.now();
          final hour = now.hour;

          if (hour < 5) {
            nextPrayerName = 'الفجر';
            nextPrayerTime = DateTime(now.year, now.month, now.day, 5, 0);
          } else if (hour < 12) {
            nextPrayerName = 'الظهر';
            nextPrayerTime = DateTime(now.year, now.month, now.day, 12, 30);
          } else if (hour < 15) {
            nextPrayerName = 'العصر';
            nextPrayerTime = DateTime(now.year, now.month, now.day, 15, 30);
          } else if (hour < 18) {
            nextPrayerName = 'المغرب';
            nextPrayerTime = DateTime(now.year, now.month, now.day, 18, 30);
          } else if (hour < 20) {
            nextPrayerName = 'العشاء';
            nextPrayerTime = DateTime(now.year, now.month, now.day, 20, 0);
          } else {
            nextPrayerName = 'الفجر';
            // Next day Fajr
            nextPrayerTime = DateTime(now.year, now.month, now.day + 1, 5, 0);
          }
        }

        return HomeHeroCard(
          nextPrayerName: nextPrayerName,
          nextPrayerTime: nextPrayerTime,
        );
      },
    );
  }

  Widget _buildContinueSection(BuildContext context) {
    return FutureBuilder<_ContinueData?>(
      future: _continueFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: const ShimmerBookCard(),
          );
        }

        final data = snapshot.data;
        final tabLabel = data == null
            ? null
            : switch (data.tab) {
                LastActivityService.tabSharh => AppStrings.continueTabSharh,
                LastActivityService.tabLessons => AppStrings.continueTabLessons,
                _ => AppStrings.continueTabMutn,
              };
        final sectionLabel = tabLabel == null
            ? null
            : AppStrings.sectionValue(tabLabel);
        final page = data?.page;
        final total = data?.total;
        final pageInfo = page == null ? null : AppStrings.lastPage(page, total);
        final progressLabel = data == null
            ? AppStrings.homeStartLearningMessage
            : pageInfo == null
            ? (sectionLabel ?? '')
            : '$sectionLabel • $pageInfo';
        final percentText = data?.progressPercent == null
            ? null
            : '${data!.progressPercent}%';
        final progressValue = data == null
            ? 0.0
            : ((data.progressPercent ?? 0) / 100).clamp(0.0, 1.0);

        // Styling Variables
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final containerBg = isDark
            ? const Color(0xFF0A0A0A)
            : context.goldLightColor;

        final borderColor = isDark
            ? const Color(0xFFA855F7).withValues(alpha: 0.2)
            : context.borderColor;

        final shadowColor = isDark
            ? const Color(0xFFA855F7).withValues(alpha: 0.2)
            : Colors.transparent;

        final shadowBlur = isDark ? 16.0 : 0.0;

        // Icon Gradient (Purple in Dark, Gold in Light)
        final iconDecoration = BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFFA855F7), Color(0xFFC084FC)],
                )
              : null,
          color: isDark ? null : context.goldColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        );

        final iconColor = isDark ? Colors.white : context.goldColor;

        // Text Colors
        final titleColor = isDark
            ? const Color(0xFFFFFFFF)
            : context.textPrimaryColor;
        final subtitleColor = isDark
            ? const Color(0xFFA1A1A1)
            : context.textSecondaryColor;
        final arrowColor = isDark
            ? const Color(0xFFA855F7)
            : context
                  .goldColor; // Added arrow color if needed, or assume icon color

        final progressColor = isDark
            ? const Color(0xFFA855F7)
            : context.goldColor;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: data == null
                  ? () => _openIlm(context)
                  : () => _continueLearning(context, data),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    if (isDark)
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: shadowBlur,
                        offset: const Offset(0, 4), // Assumed nice offset
                      ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: iconDecoration,
                      child: Icon(Icons.menu_book, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data == null ? 'ابدأ رحلة التعلّم' : 'واصل التعلّم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data == null
                                ? 'استكشف الكتب المتاحة'
                                : 'الكتاب: ${data.book.title}',
                            style: TextStyle(
                              fontSize: data == null ? 13 : 14,
                              fontWeight: data == null
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              color: subtitleColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: borderColor,
                              valueColor: AlwaysStoppedAnimation(progressColor),
                              minHeight: 4.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            percentText == null
                                ? progressLabel
                                : '$progressLabel • $percentText',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF666666)
                                  : context.textTertiaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: arrowColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, String> _getHijriDate(DateTime gregorianDate) {
    // Simple Hijri approximation (for display purposes)
    // For production, use a proper Hijri calendar package like 'hijri'
    final hijriYear = ((gregorianDate.year - 622) * 1.030684).round();
    final hijriMonth = gregorianDate.month;
    final hijriDay = gregorianDate.day;

    final monthNames = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الثاني',
      'جمادى الأولى',
      'جمادى الثانية',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];

    final monthIndex = (hijriMonth - 1) % 12;

    return {
      'day': '$hijriDay ${monthNames[monthIndex]}',
      'year': '$hijriYear هـ',
    };
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
