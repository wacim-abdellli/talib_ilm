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
import 'package:intl/intl.dart' as intl;

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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      // Drawer removed as moved to More tab
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handlePullRefresh,
          child: CustomScrollView(
            slivers: [
              // App bar with logo
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Hero card (Prayer Time)
              SliverToBoxAdapter(child: _buildHeroGreetingCard()),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

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
                  child: Text(
                    'رحلة التعلم',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
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
                      const Text(
                        'الأقسام',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            QuickActionButton(
                              icon: Icons.menu_book_rounded,
                              label: 'القرآن الكريم',
                              color: const Color(0xFF10B981),
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

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('القرآن الكريم: قريباً إن شاء الله')),
    );
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
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final day = snapshot.data!;
        final nextPrayerName = day.nextPrayer;
        final nextPrayerTime = day.prayers[nextPrayerName] ?? DateTime.now();
        final timeDisplay = intl.DateFormat.jm('ar').format(nextPrayerTime);

        return StatefulBuilder(
          builder: (context, setState) {
            // Calculate time remaining
            final now = DateTime.now();
            final difference = nextPrayerTime.difference(now);
            final hours = difference.inHours.toString().padLeft(2, '0');
            final minutes = (difference.inMinutes % 60).toString().padLeft(
              2,
              '0',
            );
            final seconds = (difference.inSeconds % 60).toString().padLeft(
              2,
              '0',
            );
            final timeRemaining = '$hours:$minutes:$seconds';

            // Update every second
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) {
                setState(() {});
              }
            });

            return HomeHeroCard(
              nextPrayer: nextPrayerName,
              timeRemaining: timeRemaining,
              nextPrayerTime: timeDisplay,
            );
          },
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

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
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
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F1E8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8DCC8), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.menu_book,
                        color: const Color(0xFFB8860B),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data == null ? 'ابدأ رحلة التعلّم' : 'واصل التعلّم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2C1810),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            data == null
                                ? 'استكشف الكتب المتاحة'
                                : 'الكتاب: ${data.book.title}',
                            style: TextStyle(
                              fontSize: data == null ? 13 : 14,
                              fontWeight: data == null
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              color: data == null
                                  ? const Color(0xFF5D4E37)
                                  : const Color(0xFF2C1810),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: const Color(0xFFE8DCC8),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFB8860B),
                              ),
                              minHeight: 4.0,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            percentText == null
                                ? progressLabel
                                : '$progressLabel • $percentText',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF8B7355),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
