import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';

import '../../../core/services/asset_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/navigation/fade_page_route.dart';

import '../../../shared/widgets/empty_state.dart';
import '../data/models/book_progress_model.dart';
import '../data/models/mutun_models.dart';
import '../data/services/book_progress_service.dart';
import '../data/services/daily_reading_service.dart';
import '../data/services/motivation_service.dart';
import '../../../shared/widgets/shimmer_loading.dart';

import 'pages/book_view_page.dart';
import 'widgets/motivation_widgets.dart';

class IlmPage extends StatefulWidget {
  const IlmPage({super.key});

  @override
  State<IlmPage> createState() => _IlmPageState();
}

class _IlmPageState extends State<IlmPage> with TickerProviderStateMixin {
  bool _hasLoadError = false;
  int get _completedBooksCount {
    return _progressById.values.where((p) => p.isCompleted).length;
  }

  BookProgressService? _progressService;
  DailyReadingService? _dailyReadingService;
  MotivationService? _motivationService;

  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<BookProgress> _allProgress = [];
  List<IlmBook> _allBooks = [];
  List<IlmBook> _filteredBooks = [];
  String? _selectedLevelTab;
  bool _isLoading = true;
  BookProgress? _continueReadingBook;
  Map<String, IlmBook> _bookCatalog = {};
  Map<String, BookProgress> _progressById = {};
  Map<String, IlmLevel> _levelByTab = {};

  // Daily reading state
  int _dailyGoal = 5;
  int _pagesReadToday = 0;
  int _currentStreak = 0;
  DateTime? _lastReadDate;

  // Motivation state
  Encouragement? _dailyEncouragement;
  bool _showEncouragement = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeService();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeService() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _progressService = BookProgressService(prefs);
    _dailyReadingService = DailyReadingService(prefs);
    _motivationService = MotivationService(prefs);
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final program = await AssetService.loadMutunProgram();

      if (program.levels.isEmpty) {
        throw Exception('Mutun program loaded but has NO levels');
      }

      final levels = program.levels..sort((a, b) => a.order.compareTo(b.order));
      final visibleLevels = levels.where((level) => !level.hidden).toList();
      final levelByTab = <String, IlmLevel>{};
      for (final level in visibleLevels) {
        levelByTab[level.title] = level;
      }

      final catalog = <String, IlmBook>{};
      final allBooks = <IlmBook>[];
      for (final level in visibleLevels) {
        for (final book in level.books) {
          catalog[book.id] = book;
          allBooks.add(book);
        }
      }
      _bookCatalog = catalog;
      _allBooks = allBooks;
      _levelByTab = levelByTab;
      if (_selectedLevelTab == null ||
          !_levelByTab.containsKey(_selectedLevelTab)) {
        _selectedLevelTab = visibleLevels.first.title;
      }

      _allProgress = await _progressService?.getAllProgress() ?? [];
      _progressById = {
        for (final progress in _allProgress) progress.bookId: progress,
      };

      final currentlyReading = await _progressService?.getCurrentlyReading();
      _continueReadingBook = currentlyReading?.isNotEmpty == true
          ? currentlyReading?.first
          : null;
      await _progressService?.getCompletedBooks();
      if (!_levelByTab.containsKey(_selectedLevelTab)) {
        _selectedLevelTab = 'المستوى الأول';
      }

      // Load daily reading stats
      if (_dailyReadingService != null) {
        _dailyGoal = _dailyReadingService!.getDailyGoal();
        _pagesReadToday = _dailyReadingService!.getPagesReadToday();
        _currentStreak = _dailyReadingService!.getCurrentStreak();
        _lastReadDate = _dailyReadingService!.getLastReadDate();
      }

      // Load motivation data
      if (_motivationService != null) {
        _dailyEncouragement = await _motivationService!.getDailyEncouragement(
          currentStreak: _currentStreak,
          booksCompleted: _completedBooksCount,
          hasReadToday: _pagesReadToday > 0,
        );
        _showEncouragement = _dailyEncouragement != null;

        // Check for milestones
        final milestone = await _motivationService!.checkMilestone(
          booksCompleted: _completedBooksCount,
          currentStreak: _currentStreak,
          totalPagesRead: _pagesReadToday,
          justCompletedBook: false,
          justCompletedLevel: false,
          justAchievedDailyGoal: _pagesReadToday >= _dailyGoal,
        );

        // Show milestone celebration if triggered
        if (milestone != null && mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              MilestoneCelebrationDialog.show(context, milestone);
            }
          });
        }
      }

      _hasLoadError = false;
      _applyFilters(updateState: false);
      setState(() {});
    } catch (e, stack) {
      _hasLoadError = true;
      debugPrint(' Error loading data: $e');
      debugPrint(' Stack trace:\n$stack');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter(String tab, {bool updateState = true}) {
    _applyFilters(levelTab: tab, updateState: updateState);
  }

  void _applyFilters({String? levelTab, bool updateState = true}) {
    if (_allBooks.isEmpty) return;
    final activeTab = levelTab ?? _selectedLevelTab;
    if (activeTab == null) return;
    final activeLevel = activeTab;
    final nextBooks =
        _allBooks.where((book) {
          final matchesLevel = book.level == activeLevel;
          return matchesLevel;
        }).toList()..sort((a, b) {
          final aProgress = _progressById[a.id];
          final bProgress = _progressById[b.id];
          if (aProgress != null && bProgress != null) {
            return bProgress.lastReadDate.compareTo(aProgress.lastReadDate);
          }
          if (aProgress != null) return -1;
          if (bProgress != null) return 1;
          return a.title.compareTo(b.title);
        });

    if (!updateState) {
      _selectedLevelTab = activeTab;
      _filteredBooks = nextBooks;
      return;
    }

    setState(() {
      _selectedLevelTab = activeTab;
      _filteredBooks = nextBooks;
    });
  }

  Future<void> _toggleFavorite(String bookId) async {
    final existing = _progressById[bookId];
    if (existing == null) {
      final book = _bookCatalog[bookId];
      if (book != null) {
        await _progressService?.initializeBook(
          bookId: bookId,
          bookTitle: book.title,
          level: book.level,
          totalPages: book.totalPages > 0 ? book.totalPages : 1,
        );
      }
    }
    await _progressService?.toggleFavorite(bookId);
    if (!mounted) return;
    await _loadData();
  }

  void _navigateToBook(IlmBook book) {
    Navigator.push(
      context,
      buildFadeRoute(page: BookViewPage(book: book)),
    ).then((_) => _loadData());
  }

  IlmBook? get _recommendedFirstBook {
    // Get first book from first level that hasn't been started
    final levels = _levelByTab.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final level in levels) {
      for (final book in level.books) {
        final progress = _progressById[book.id];
        if (progress == null || progress.currentPage <= 1) {
          return book;
        }
      }
    }
    return _allBooks.isNotEmpty ? _allBooks.first : null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        // Drawer removed
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: null, // No menu or back
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.safeHorizontalPadding,
          ),
          child: ListView(
            children: [
              SizedBox(height: responsive.mediumGap),
              // Start Journey Card Shimmer
              const ShimmerBookCard(),
              SizedBox(height: responsive.mediumGap),
              // Progress Card Shimmer
              const ShimmerBookCard(), // Reuse
              SizedBox(height: responsive.largeGap),
              // Level Chips Shimmer
              Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.mediumGap),
              // Books Grid Shimmer
              SizedBox(
                height: 400,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) => const ShimmerBookCard(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasActiveLearning = _continueReadingBook != null;
    final showStartJourney = !hasActiveLearning && _completedBooksCount == 0;

    return Scaffold(
      backgroundColor: AppColors.background,

      // AppBar removed
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'رحلة العلم',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'استكشف الكتب والدروس',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search_rounded, size: 26),
                          color: const Color(0xFF64748B),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Level tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            (_levelByTab.values.toList()
                                  ..sort((a, b) => a.order.compareTo(b.order)))
                                .map((level) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: GestureDetector(
                                      onTap: () => _applyFilter(level.title),
                                      child: _buildLevelChip(
                                        level.title,
                                        level.title == _selectedLevelTab,
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Motivation: Daily Encouragement Banner
              if (_showEncouragement && _dailyEncouragement != null)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.safeHorizontalPadding,
                  ),
                  child: Column(
                    children: [
                      EncouragementBanner(
                        encouragement: _dailyEncouragement!,
                        onDismiss: () {
                          setState(() {
                            _showEncouragement = false;
                          });
                        },
                      ),
                      SizedBox(height: responsive.mediumGap),
                    ],
                  ),
                ),

              // 1. Primary Action: Start Journey OR Continue Learning (Hero)
              if (showStartJourney)
                _buildStartJourneyCard(responsive)
              else if (hasActiveLearning)
                _buildEnhancedContinueLearningCard(
                  responsive,
                  _continueReadingBook!,
                ),

              if (showStartJourney || hasActiveLearning)
                SizedBox(height: responsive.mediumGap),

              // 2. Progress Overview: Daily Progress Ring + Streak
              _buildDailyProgressCard(responsive),
              SizedBox(height: responsive.largeGap),

              // UX Change 3: Level Chips (replaces dropdown)
              // Level chips moved to header
              // _buildLevelChips(responsive),
              SizedBox(height: responsive.mediumGap),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.safeHorizontalPadding,
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      final scale = Tween<double>(
                        begin: 0.98,
                        end: 1.0,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: scale, child: child),
                      );
                    },
                    child: _hasLoadError
                        ? Padding(
                            key: const ValueKey('error'),
                            padding: EdgeInsets.symmetric(
                              vertical: responsive.largeGap,
                            ),
                            child: EmptyState(
                              icon: Icons.error_outline,
                              title: AppStrings.ilmLoadErrorTitle,
                              subtitle: AppStrings.ilmLoadErrorMessage,
                              actionLabel: AppStrings.actionRetry,
                              onAction: _loadData,
                            ),
                          )
                        : _filteredBooks.isEmpty
                        ? _buildEmptyLevelState(responsive)
                        : _buildBooksGrid(
                            responsive,
                            _filteredBooks,
                            key: ValueKey('books-$_selectedLevelTab'),
                          ),
                  ),
                ),
              ),

              // Motivation: Daily Quote Card moved to HomePage
              SizedBox(height: responsive.largeGap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBackCard(Responsive responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: Container(
        padding: EdgeInsets.all(responsive.wp(5)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBF5), Color(0xFFFFF4E0)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.spa_outlined,
              size: responsive.wp(10),
              color: AppColors.accent,
            ),
            SizedBox(height: responsive.mediumGap),
            Text(
              AppStrings.welcomeBackTitle,
              style: TextStyle(
                fontSize: responsive.sp(18),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: responsive.smallGap),
            Text(
              AppStrings.welcomeBackMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.sp(14),
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
            SizedBox(height: responsive.mediumGap),
            ElevatedButton(
              onPressed: () {
                _scrollController.animateTo(
                  responsive.hp(40),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textPrimary,
              ),
              child: Text(AppStrings.startFreshButton),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // UX CHANGE 1: DAILY PROGRESS RING + STREAK
  // ═══════════════════════════════════════════
  Widget _buildDailyProgressCard(Responsive responsive) {
    // 3. Fresh Start Intervention
    if (_lastReadDate != null && _pagesReadToday == 0) {
      final daysLapsed = DateTime.now().difference(_lastReadDate!).inDays;
      if (daysLapsed >= 3) {
        return _buildWelcomeBackCard(responsive);
      }
    }

    final progress = _dailyGoal > 0
        ? (_pagesReadToday / _dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = _pagesReadToday >= _dailyGoal;
    final remaining = _dailyGoal - _pagesReadToday;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: Container(
        padding: EdgeInsets.all(responsive.wp(4)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isCompleted
                ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                : [const Color(0xFFFFFBF5), const Color(0xFFFFF4E0)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isCompleted ? const Color(0xFF22C55E) : AppColors.primary)
                  .withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Progress Ring
            SizedBox(
              width: responsive.wp(18),
              height: responsive.wp(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background ring
                  SizedBox(
                    width: responsive.wp(16),
                    height: responsive.wp(16),
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  // Progress ring
                  SizedBox(
                    width: responsive.wp(16),
                    height: responsive.wp(16),
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        isCompleted
                            ? const Color(0xFF22C55E)
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  // Center text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_pagesReadToday',
                        style: TextStyle(
                          fontSize: responsive.sp(20),
                          fontWeight: FontWeight.w800,
                          color: isCompleted
                              ? const Color(0xFF22C55E)
                              : AppColors.primary,
                        ),
                      ),
                      Text(
                        '/ $_dailyGoal',
                        style: TextStyle(
                          fontSize: responsive.sp(11),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: responsive.mediumGap),

            // Goal info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with streak
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isCompleted
                              ? AppStrings.dailyGoalCompleted
                              : AppStrings.dailyGoalPages(_dailyGoal),
                          style: TextStyle(
                            fontSize: responsive.sp(15),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: responsive.hp(0.5)),

                  // Status message
                  if (!isCompleted && remaining > 0)
                    Text(
                      AppStrings.dailyGoalRemaining(remaining),
                      style: TextStyle(
                        fontSize: responsive.sp(13),
                        color: AppColors.textSecondary,
                      ),
                    ),

                  SizedBox(height: responsive.hp(1)),

                  // Streak badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.wp(3),
                      vertical: responsive.hp(0.6),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF6B35).withValues(alpha: 0.2),
                          const Color(0xFFF7931E).withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🔥',
                          style: TextStyle(fontSize: responsive.sp(12)),
                        ),
                        SizedBox(width: 4),
                        Text(
                          _currentStreak > 0
                              ? AppStrings.streakDays(_currentStreak)
                              : AppStrings.noStreakYet,
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6B35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // UX CHANGE 2A: START JOURNEY CARD (NEW USERS)
  // ═══════════════════════════════════════════
  Widget _buildStartJourneyCard(Responsive responsive) {
    final recommendedBook = _recommendedFirstBook;
    if (recommendedBook == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: GestureDetector(
        onTap: () => _navigateToBook(recommendedBook),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.wp(5)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF1E3A5F), Color(0xFF2D4A6F)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.wp(3),
                  vertical: responsive.hp(0.6),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🌟', style: TextStyle(fontSize: responsive.sp(14))),
                    SizedBox(width: 6),
                    Text(
                      AppStrings.startJourneyTitle,
                      style: TextStyle(
                        fontSize: responsive.sp(13),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: responsive.mediumGap),

              // Book info
              Row(
                children: [
                  // Book icon
                  Container(
                    width: responsive.wp(16),
                    height: responsive.wp(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      size: responsive.wp(8),
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  SizedBox(width: responsive.mediumGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendedBook.title,
                          style: TextStyle(
                            fontSize: responsive.sp(17),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          recommendedBook.author,
                          style: TextStyle(
                            fontSize: responsive.sp(13),
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: responsive.mediumGap),

              // Hadith quote
              Container(
                padding: EdgeInsets.all(responsive.wp(3.5)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppStrings.startJourneyHadith,
                  style: TextStyle(
                    fontSize: responsive.sp(13),
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: responsive.mediumGap),

              // CTA Button with pulse
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: responsive.hp(1.6)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFE8C252)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.startJourneyButton,
                        style: TextStyle(
                          fontSize: responsive.sp(15),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_back,
                        size: responsive.sp(18),
                        color: const Color(0xFF1E3A5F),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // UX CHANGE 2B: ENHANCED CONTINUE LEARNING CARD
  // ═══════════════════════════════════════════
  Widget _buildEnhancedContinueLearningCard(
    Responsive responsive,
    BookProgress book,
  ) {
    final totalPages = book.totalPages;
    final currentPage = book.currentPage;
    final progressValue = totalPages == 0
        ? 0.0
        : (currentPage / totalPages).clamp(0.0, 1.0);
    final percentLabel = '${(progressValue * 100).round()}٪';

    // Estimate time (assuming ~2 min per page to finish chapter)
    final pagesRemaining = totalPages - currentPage;
    final estimatedMinutes = min(pagesRemaining * 2, 15);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: GestureDetector(
        onTap: () {
          final bookData = _bookCatalog[book.bookId];
          if (bookData != null) {
            _navigateToBook(bookData);
          }
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.wp(5)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFFFFBF5), Color(0xFFFFF4E0)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.wp(3),
                  vertical: responsive.hp(0.7),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark,
                      size: responsive.sp(12),
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.continueReading,
                      style: TextStyle(
                        fontSize: responsive.sp(12),
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: responsive.mediumGap),

              // Book info row
              Row(
                children: [
                  // Book cover
                  Container(
                    width: responsive.wp(16),
                    height: responsive.wp(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: AppColors.primary,
                      size: responsive.wp(8),
                    ),
                  ),

                  SizedBox(width: responsive.mediumGap),

                  // Book details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.bookTitle,
                          style: TextStyle(
                            fontSize: responsive.sp(16),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: responsive.hp(0.4)),
                        Text(
                          AppStrings.pageOfTotal(currentPage, totalPages),
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: responsive.hp(0.4)),
                        // Time estimate
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: responsive.sp(12),
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                AppStrings.timeToFinishChapter(
                                  estimatedMinutes,
                                ),
                                style: TextStyle(
                                  fontSize: responsive.sp(11),
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: responsive.mediumGap),

              // Progress bar and button
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progressValue,
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withValues(
                                          alpha: 0.8,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: responsive.hp(0.6)),
                        Text(
                          'تقدم القراءة: $percentLabel',
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: AppColors.primary.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: responsive.mediumGap),
                  // Pulsing continue button
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.wp(4),
                        vertical: responsive.hp(1.2),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            'متابعة',
                            style: TextStyle(
                              fontSize: responsive.sp(13),
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_back,
                            size: responsive.sp(14),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // UX CHANGE 3: LEVEL CHIPS (HORIZONTAL SCROLL)
  // ═══════════════════════════════════════════
  Widget _buildLevelChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8B5CF6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // UX CHANGE 7: EMPTY LEVEL STATE
  // ═══════════════════════════════════════════
  Widget _buildEmptyLevelState(Responsive responsive) {
    final level = _levelByTab[_selectedLevelTab];
    final firstBook = level?.books.isNotEmpty == true
        ? level!.books.first
        : null;

    return Padding(
      key: const ValueKey('empty-level'),
      padding: EdgeInsets.symmetric(vertical: responsive.largeGap),
      child: Container(
        padding: EdgeInsets.all(responsive.wp(6)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.library_books_outlined,
              size: responsive.wp(16),
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            SizedBox(height: responsive.mediumGap),
            Text(
              level?.title ?? 'المستوى',
              style: TextStyle(
                fontSize: responsive.sp(18),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: responsive.hp(0.5)),
            if (firstBook != null)
              Text(
                'ابدأ بـ "${firstBook.title}"',
                style: TextStyle(
                  fontSize: responsive.sp(14),
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: responsive.mediumGap),
            if (firstBook != null)
              ElevatedButton(
                onPressed: () => _navigateToBook(firstBook),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.wp(6),
                    vertical: responsive.hp(1.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.startHereLabel,
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_back, size: 18),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // UX CHANGE 5: ENHANCED BOOK CARDS WITH STATES
  // ═══════════════════════════════════════════
  Widget _buildBooksGrid(
    Responsive responsive,
    List<IlmBook> books, {
    Key? key,
  }) {
    final aspectRatio = responsive.isSmallScreen ? 0.58 : 0.65;

    return GridView.builder(
      key: key,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: responsive.smallGap,
        mainAxisSpacing: responsive.smallGap,
        childAspectRatio: aspectRatio,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final progress = _progressById[book.id];
        final isRecommended =
            index == 0 && (progress == null || progress.currentPage <= 1);

        // 2. High-Contrast Focus Mode
        final isFocused =
            _continueReadingBook == null ||
            _continueReadingBook!.bookId == book.id;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isFocused ? 1.0 : 0.4,
          child: _buildEnhancedBookCard(
            responsive,
            book,
            progress,
            isRecommended: isRecommended,
          ),
        );
      },
    );
  }

  Widget _buildEnhancedBookCard(
    Responsive responsive,
    IlmBook book,
    BookProgress? progress, {
    bool isRecommended = false,
  }) {
    final progressValue = progress == null
        ? 0.0
        : (progress.progressPercentage / 100).clamp(0.0, 1.0).toDouble();
    final isCompleted = progress?.isCompleted ?? false;
    final isNotStarted = progress == null || progress.currentPage <= 1;
    final isInProgress = !isNotStarted && !isCompleted;

    // Determine card state and styling
    Color borderColor;
    Color? glowColor;
    String? badgeText;
    Color? badgeColor;
    IconData? badgeIcon;

    if (isCompleted) {
      borderColor = const Color(0xFF22C55E).withValues(alpha: 0.4);
      badgeText = AppStrings.bookStateCompleted;
      badgeColor = const Color(0xFF22C55E);
      badgeIcon = Icons.check_circle;
    } else if (isInProgress) {
      borderColor = AppColors.primary.withValues(alpha: 0.3);
      glowColor = AppColors.primary.withValues(alpha: 0.15);
    } else if (isRecommended) {
      borderColor = const Color(0xFFD4AF37).withValues(alpha: 0.4);
      badgeText = AppStrings.bookStateRecommended;
      badgeColor = const Color(0xFFD4AF37);
      badgeIcon = Icons.star;
    } else {
      borderColor = AppColors.primary.withValues(alpha: 0.1);
      badgeText = AppStrings.bookStateNotStarted;
      badgeColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: () => _navigateToBook(book),
      onLongPress: () => _toggleFavorite(book.id),
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFFF0FDF4) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            if (glowColor != null)
              BoxShadow(
                color: glowColor,
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: const Color(0xFF8B7355).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Flexible(
              flex: 4,
              child: Stack(
                children: [
                  // Base gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCompleted
                            ? [
                                const Color(0xFF22C55E).withValues(alpha: 0.15),
                                const Color(0xFF22C55E).withValues(alpha: 0.25),
                              ]
                            : [
                                AppColors.primary.withValues(alpha: 0.15),
                                AppColors.primary.withValues(alpha: 0.28),
                              ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(responsive.wp(3)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_circle : Icons.menu_book,
                          size: responsive.wp(13),
                          color: isCompleted
                              ? const Color(0xFF22C55E)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // Subject badge (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        book.subject,
                        style: TextStyle(
                          fontSize: responsive.sp(9),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // State badge (top-left) - for recommended/completed
                  if (isRecommended || isCompleted)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: badgeColor!.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (badgeIcon != null)
                              Icon(badgeIcon, size: 12, color: Colors.white),
                            if (badgeIcon != null) const SizedBox(width: 3),
                            Text(
                              badgeText!,
                              style: TextStyle(
                                fontSize: responsive.sp(9),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Favorite bookmark
                  if (progress?.isFavorite ?? false)
                    Positioned(
                      top: isRecommended || isCompleted ? 40 : 8,
                      left: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bookmark,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Book Info Section
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.all(responsive.wp(3.5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: responsive.hp(0.5)),

                    // Author
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: responsive.sp(12),
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Progress Bar
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: progressValue > 0
                            ? [
                                BoxShadow(
                                  color:
                                      (isCompleted
                                              ? const Color(0xFF22C55E)
                                              : AppColors.primary)
                                          .withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          valueColor: AlwaysStoppedAnimation(
                            isCompleted
                                ? const Color(0xFF22C55E)
                                : AppColors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),

                    SizedBox(height: responsive.hp(0.6)),

                    // Status row
                    Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : isInProgress
                              ? Icons.menu_book
                              : Icons.play_arrow,
                          size: responsive.sp(12),
                          color: isCompleted
                              ? const Color(0xFF22C55E)
                              : isNotStarted && !isRecommended
                              ? AppColors.textSecondary
                              : AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted
                              ? AppStrings.bookStateCompleted
                              : isInProgress
                              ? '${progress.progressPercentage.round()}٪'
                              : AppStrings.bookStateNotStarted,
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            fontWeight: FontWeight.w500,
                            color: isCompleted
                                ? const Color(0xFF22C55E)
                                : isNotStarted && !isRecommended
                                ? AppColors.textSecondary
                                : AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
