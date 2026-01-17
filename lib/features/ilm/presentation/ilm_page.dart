import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_colors.dart';

import '../../../core/services/asset_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/empty_state.dart';
import 'widgets/motivation_widgets.dart';
import '../data/models/book_progress_model.dart';
import '../data/models/mutun_models.dart';
import '../data/services/book_progress_service.dart';
import '../data/services/daily_reading_service.dart';
import '../data/services/motivation_service.dart';
import '../../../shared/widgets/shimmer_loading.dart';

import 'pages/book_view_page.dart';

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
  late String _dailyMicrocopy;

  // Simple scholarly quotes rotation
  final List<String> _scholarlyQuotes = [
    'العلم يؤتى ولا يأتي',
    'من أدمن الطرق ولج',
    'قليل دائم خير من كثير منقطع',
    'العلم صيد والكتابة قيد',
    'زكاة العلم تعليمه',
    'إنما العلم بالتعلم',
    'بداية الغيث قطرة',
    'العلماء ورثة الأنبياء',
  ];

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

    // DETERMINISTIC DAILY QUOTE
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    _dailyMicrocopy = _scholarlyQuotes[dayOfYear % _scholarlyQuotes.length];
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

  void _applyFilters({String? levelTab, bool updateState = true}) {
    if (_allBooks.isEmpty) return;
    final activeTab = levelTab ?? _selectedLevelTab;
    if (activeTab == null) return;

    if (!updateState) {
      _selectedLevelTab = activeTab;
      return;
    }

    setState(() {
      _selectedLevelTab = activeTab;
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

  void _navigateToBook(IlmBook book) async {
    final wasCompleted = _progressById[book.id]?.isCompleted ?? false;

    await Navigator.push(
      context,
      buildFadeRoute(page: BookViewPage(book: book)),
    );

    await _loadData();

    final isCompletedNow = _progressById[book.id]?.isCompleted ?? false;
    if (!wasCompleted && isCompletedNow) {
      _showCompletionReward(book);
    }
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
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: null,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.safeHorizontalPadding,
          ),
          child: ListView(
            children: [
              SizedBox(height: responsive.mediumGap),
              // Continue Learning Shimmer
              const ShimmerBookCard(),
              SizedBox(height: responsive.largeGap),
              // Books Grid Shimmer
              SizedBox(
                height: 500,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: 6,
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

    // Get sorted levels for section display
    final sortedLevels = _levelByTab.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.safeHorizontalPadding,
                vertical: responsive.hp(2),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF000000)
                    : context.backgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1F1F1F)
                        : const Color(0xFFE8E6E3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رحلتك العلمية',
                    style: TextStyle(
                      fontSize: responsive.sp(26),
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFFFFFFF)
                          : context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dailyMicrocopy,
                    style: TextStyle(
                      fontSize: responsive.sp(14),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFA1A1A1)
                          : context.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // ════════════════════════════════════════════════════════════
            // SCROLLABLE CONTENT
            // ════════════════════════════════════════════════════════════
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: responsive.mediumGap),

                    // ════════════════════════════════════════════════════════════
                    // 2. PRIMARY ACTION: CONTINUE LEARNING (Compact Hero Card)
                    // ════════════════════════════════════════════════════════════
                    if (showStartJourney)
                      _buildCompactStartJourneyCard(responsive)
                    else if (hasActiveLearning)
                      _buildCompactContinueLearningCard(
                        responsive,
                        _continueReadingBook!,
                      ),

                    SizedBox(height: responsive.mediumGap),

                    // ════════════════════════════════════════════════════════════
                    // 2. DAILY GOAL CARD (Now at the top)
                    // ════════════════════════════════════════════════════════════
                    _buildDailyProgressCard(responsive),

                    SizedBox(height: responsive.mediumGap),

                    // ════════════════════════════════════════════════════════════
                    // 3. BOOKS BY LEVEL SECTIONS (Main Focus)
                    // ════════════════════════════════════════════════════════════
                    if (_hasLoadError)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.safeHorizontalPadding,
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
                    else
                      ...sortedLevels.map((level) {
                        return _buildLevelSection(
                          responsive,
                          level,
                          sortedLevels,
                        );
                      }),

                    SizedBox(height: responsive.largeGap),

                    // Motivation Banner (contextual, at bottom)
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

                    SizedBox(height: 80), // Bottom padding for Nav Bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // COMPACT CONTINUE LEARNING CARD (Hero Style)
  // ═══════════════════════════════════════════
  Widget _buildCompactContinueLearningCard(
    Responsive responsive,
    BookProgress book,
  ) {
    final totalPages = book.totalPages;
    final currentPage = book.currentPage;
    final progressValue = totalPages == 0
        ? 0.0
        : (currentPage / totalPages).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: GestureDetector(
        onTap: () {
          final bookData = _bookCatalog[book.bookId];
          if (bookData != null) _navigateToBook(bookData);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(responsive.wp(4)),
          decoration: BoxDecoration(
            // Calm teal → mint gradient
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF5A8A8A), Color(0xFF7AB5A8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5A8A8A).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Book icon + info
              Row(
                children: [
                  // Book icon with soft glow
                  Container(
                    width: responsive.wp(12),
                    height: responsive.wp(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      size: responsive.wp(6),
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(width: responsive.wp(3)),

                  // Book info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.bookTitle,
                          style: TextStyle(
                            fontSize: responsive.sp(16),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'متوقف عند الصفحة $currentPage من $totalPages',
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: responsive.hp(1.5)),

              // Animated progress bar (600ms easeOut)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progressValue),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  );
                },
              ),

              SizedBox(height: responsive.hp(1.5)),

              // Pill-style CTA button with elevation on tap
              _PressableScale(
                onTap: () {
                  final bookData = _bookCatalog[book.bookId];
                  if (bookData != null) _navigateToBook(bookData);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: responsive.hp(1.4)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'تابع رحلتك',
                        style: TextStyle(
                          fontSize: responsive.sp(14),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5A8A8A),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_back,
                        size: responsive.sp(16),
                        color: const Color(0xFF5A8A8A),
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
  // COMPACT START JOURNEY CARD (Hero Style)
  // ═══════════════════════════════════════════
  Widget _buildCompactStartJourneyCard(Responsive responsive) {
    final recommendedBook = _recommendedFirstBook;
    if (recommendedBook == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: GestureDetector(
        onTap: () => _navigateToBook(recommendedBook),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(responsive.wp(4)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF1E3A5F), Color(0xFF2D4A6F)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A5F).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Book icon
              Container(
                width: responsive.wp(14),
                height: responsive.wp(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: responsive.wp(7),
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),

              SizedBox(width: responsive.wp(3)),

              // Journey info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ابدأ رحلتك العلمية',
                      style: TextStyle(
                        fontSize: responsive.sp(15),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      recommendedBook.title,
                      style: TextStyle(
                        fontSize: responsive.sp(12),
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Start arrow with pulse
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: EdgeInsets.all(responsive.wp(2.5)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: responsive.sp(18),
                    color: const Color(0xFF1E3A5F),
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
  // LEVEL SECTION WITH BOOKS
  // ═══════════════════════════════════════════
  Widget _buildLevelSection(
    Responsive responsive,
    IlmLevel level,
    List<IlmLevel> allLevels,
  ) {
    final completion = _getLevelCompletion(level.title);
    final levelBooks = _allBooks.where((b) => b.level == level.title).toList();

    if (levelBooks.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: responsive.largeGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level Header Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.safeHorizontalPadding,
              ),
              child: Container(
                padding: EdgeInsets.all(responsive.hp(1.5)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: isDark
                        ? [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)]
                        : [const Color(0xFFF5F3F0), const Color(0xFFFBFAF8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1F1F1F)
                        : const Color(0xFFE8E6E3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Level icon
                    Container(
                      width: responsive.sp(36),
                      height: responsive.sp(36),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6A9A9A), Color(0xFF7AB5A8)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: responsive.sp(18),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: responsive.wp(3)),
                    // Level title
                    Expanded(
                      child: Text(
                        level.title,
                        style: TextStyle(
                          fontSize: responsive.sp(16),
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFFFFFFF)
                              : context.textPrimaryColor,
                        ),
                      ),
                    ),
                    // Completion badge
                    if (completion > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: completion >= 1.0
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                )
                              : null,
                          color: completion >= 1.0
                              ? null
                              : const Color(0xFF5A8A8A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (completion >= 1.0)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            Text(
                              '${(completion * 100).round()}%',
                              style: TextStyle(
                                fontSize: responsive.sp(12),
                                fontWeight: FontWeight.w700,
                                color: completion >= 1.0
                                    ? Colors.white
                                    : const Color(0xFF5A8A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: responsive.mediumGap),

            // Books Grid
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.safeHorizontalPadding,
              ),
              child: _buildBooksGrid(
                responsive,
                levelBooks,
                key: ValueKey('level-${level.title}'),
              ),
            ),

            SizedBox(height: responsive.mediumGap),

            // Decorative separator
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.safeHorizontalPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            isDark
                                ? const Color(0xFF1F1F1F)
                                : const Color(0xFFE8E6E3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F1F1F)
                            : const Color(0xFFE8E6E3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            isDark
                                ? const Color(0xFF1F1F1F)
                                : const Color(0xFFE8E6E3),
                            Colors.transparent,
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
  }

  // ═══════════════════════════════════════════
  // INPUT 8: COMPLETION REWARD FLOW
  // ═══════════════════════════════════════════
  void _showCompletionReward(IlmBook book) {
    MilestoneCelebrationDialog.show(
      context,
      MilestoneTrigger(
        type: MilestoneType.booksCount,
        title: 'أحسنت!',
        message: 'أتممت كتاب "${book.title}" بفضل الله.',
        icon: '🌿',
        verse: 'وَقُل رَّبِّ زِدْنِي عِلْمًا',
        verseRef: 'سورة طه: ١١٤',
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
          gradient: LinearGradient(
            colors: context.isDark
                ? [AppColors.darkSurface, AppColors.darkSurfaceSecondary]
                : [const Color(0xFFFFFBF5), const Color(0xFFFFF4E0)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.goldColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: context.goldColor.withValues(alpha: 0.1),
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
              color: context.goldColor,
            ),
            SizedBox(height: responsive.mediumGap),
            Text(
              AppStrings.welcomeBackTitle,
              style: TextStyle(
                fontSize: responsive.sp(18),
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
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
                color: context.textSecondaryColor,
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
                backgroundColor: context.goldColor,
                foregroundColor: Colors.white,
              ),
              child: Text(AppStrings.startFreshButton),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // DAILY GOAL CARD (MOTIVATIONAL REDESIGN)
  // ═══════════════════════════════════════════
  Widget _buildDailyProgressCard(Responsive responsive) {
    // Fresh Start Intervention
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
    final hasStarted = _pagesReadToday > 0;

    // Dynamic subtitle based on progress
    String dynamicSubtitle;
    if (isCompleted) {
      dynamicSubtitle = 'أنجزت اليوم ✨';
    } else if (hasStarted) {
      dynamicSubtitle = 'قاربنا الهدف 🔥';
    } else {
      dynamicSubtitle = 'بداية جميلة 🌱';
    }

    // Warm gold/amber accent colors
    const goldAccent = Color(0xFFD4A853);
    const goldLight = Color(0xFFFFF8E7);
    const goldGlow = Color(0xFFE8C252);
    const completedColor = Color(0xFF6A9A9A);
    const completedLight = Color(0xFFF5FAFA);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(responsive.wp(4)),
        decoration: BoxDecoration(
          color: isCompleted
              ? (context.isDark ? AppColors.darkSuccessLight : completedLight)
              : (context.isDark ? AppColors.darkGoldLight : goldLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? completedColor.withValues(alpha: 0.3)
                : goldAccent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? completedColor.withValues(alpha: 0.1)
                  : goldAccent.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Animated Circular Progress with warm glow
                SizedBox(
                  width: responsive.wp(16),
                  height: responsive.wp(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft glow behind
                      Container(
                        width: responsive.wp(14),
                        height: responsive.wp(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isCompleted
                                  ? completedColor.withValues(alpha: 0.2)
                                  : goldGlow.withValues(alpha: 0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Animated progress ring
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return SizedBox(
                            width: responsive.wp(14),
                            height: responsive.wp(14),
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 6,
                              strokeCap: StrokeCap.round,
                              backgroundColor: isCompleted
                                  ? completedColor.withValues(alpha: 0.2)
                                  : goldAccent.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation(
                                isCompleted ? completedColor : goldAccent,
                              ),
                            ),
                          );
                        },
                      ),
                      // Center icon/number
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_pagesReadToday',
                            style: TextStyle(
                              fontSize: responsive.sp(18),
                              fontWeight: FontWeight.w800,
                              color: isCompleted ? completedColor : goldAccent,
                            ),
                          ),
                          Text(
                            '/ $_dailyGoal',
                            style: TextStyle(
                              fontSize: responsive.sp(10),
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: responsive.wp(3)),

                // Goal Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الورد اليومي',
                        style: TextStyle(
                          fontSize: responsive.sp(16),
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        dynamicSubtitle,
                        style: TextStyle(
                          fontSize: responsive.sp(13),
                          fontWeight: FontWeight.w500,
                          color: isCompleted ? completedColor : goldAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings icon
                IconButton(
                  onPressed: () => _showGoalSetter(context),
                  icon: Icon(
                    Icons.tune_rounded,
                    size: responsive.sp(20),
                    color: const Color(0xFF9A9A9A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalSetter(BuildContext context) {
    int localGoal = _dailyGoal;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFFBFAF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تعديل الهدف اليومي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A3A3A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'كم صفحة تخطط لقراءتها يومياً؟',
                style: TextStyle(color: Color(0xFF6E6E6E)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (localGoal > 1) {
                        setModalState(() => localGoal--);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '$localGoal',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A3A3A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setModalState(() => localGoal++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _dailyReadingService?.setDailyGoal(localGoal);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadData(); // Refresh page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'حفظ التغييرات',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  double _getLevelCompletion(String levelTitle) {
    final books = _bookCatalog.values
        .where((b) => b.level.trim() == levelTitle.trim())
        .toList();
    if (books.isEmpty) return 0.0;

    int completed = 0;
    for (var book in books) {
      if (_progressById[book.id]?.isCompleted ?? false) {
        completed++;
      }
    }
    return completed / books.length;
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

        return TweenAnimationBuilder<double>(
          key: ValueKey(book.id),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 8 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
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

  // ═══════════════════════════════════════════
  // BOOK CARD (REDESIGNED WITH VISUAL STATES)
  // ═══════════════════════════════════════════
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

    // Category color based on subject
    Color categoryColor = _getCategoryColor(book.subject);

    // Card styling based on state
    Color cardBg;
    Color borderColor;
    double borderWidth;
    List<BoxShadow> cardShadow;

    // Completed color - nice emerald green
    const completedColor = Color(0xFF059669);
    const completedBg = Color(0xFFECFDF5);

    if (isCompleted) {
      // Completed: Soft sage background
      cardBg = context.isDark ? AppColors.darkSuccessLight : completedBg;
      borderColor = completedColor.withValues(alpha: 0.3);
      borderWidth = 1.5;
      cardShadow = [
        BoxShadow(
          color: completedColor.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isInProgress) {
      // In Progress: Teal border highlight
      cardBg = context.surfaceColor;
      borderColor = const Color(0xFF5A8A8A);
      borderWidth = 2;
      cardShadow = [
        BoxShadow(
          color: const Color(0xFF5A8A8A).withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      // New: Clean white with subtle shadow
      cardBg = context.surfaceColor;
      borderColor = context.borderColor;
      borderWidth = 1;
      cardShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }

    // Build card with appropriate animation wrapper
    Widget cardContent = _PressableScale(
      onTap: () => _navigateToBook(book),
      onLongPress: () => _toggleFavorite(book.id),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover Area with Category-Colored Icon
            Flexible(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFEDF5F5)
                      : categoryColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Icon with breathing animation for in-progress
                    if (isInProgress)
                      _BreathingIcon(
                        icon: Icons.menu_book_outlined,
                        size: responsive.wp(10),
                        color: categoryColor,
                      )
                    else if (isCompleted)
                      Container(
                        width: responsive.wp(12),
                        height: responsive.wp(12),
                        decoration: BoxDecoration(
                          color: completedColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: responsive.wp(8),
                          color: completedColor,
                        ),
                      )
                    else
                      Container(
                        width: responsive.wp(12),
                        height: responsive.wp(12),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_stories_outlined,
                          size: responsive.wp(6),
                          color: categoryColor,
                        ),
                      ),

                    // Completed badge
                    if (isCompleted)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: completedColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                size: responsive.sp(12),
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'مكتمل',
                                style: TextStyle(
                                  fontSize: responsive.sp(10),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Book Info
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.all(responsive.wp(3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (bold)
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: responsive.hp(0.3)),

                    // Author (muted)
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: responsive.sp(11),
                        color: context.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Progress bar (only for in-progress)
                    if (isInProgress) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: progressValue),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 5,
                              backgroundColor: context.borderColor,
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF5A8A8A),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: responsive.hp(0.5)),
                      Text(
                        '${(progressValue * 100).round()}% مكتمل',
                        style: TextStyle(
                          fontSize: responsive.sp(10),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A8A8A),
                        ),
                      ),
                    ],

                    // Subject tag for new books
                    if (isNotStarted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book.subject,
                          style: TextStyle(
                            fontSize: responsive.sp(10),
                            fontWeight: FontWeight.w600,
                            color: categoryColor,
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
    );

    // Wrap with scale animation for new books
    if (isNotStarted) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: cardContent,
      );
    }

    return cardContent;
  }

  // Helper to get category color based on subject
  // Colors are vibrant and distinct for easy identification
  Color _getCategoryColor(String subject) {
    final subjectLower = subject.toLowerCase();

    if (subjectLower.contains('عقيدة') || subjectLower.contains('توحيد')) {
      return const Color(0xFF0891B2); // Cyan - عقيدة
    } else if (subjectLower.contains('حديث') ||
        subjectLower.contains('مصطلح')) {
      return const Color(0xFF7C3AED); // Violet - حديث
    } else if (subjectLower.contains('فقه') || subjectLower.contains('أصول')) {
      return const Color(0xFF059669); // Emerald - فقه
    } else if (subjectLower.contains('قرآن') ||
        subjectLower.contains('تجويد') ||
        subjectLower.contains('تفسير')) {
      return const Color(0xFFCA8A04); // Amber - قرآن
    } else if (subjectLower.contains('لغة') ||
        subjectLower.contains('نحو') ||
        subjectLower.contains('صرف')) {
      return const Color(0xFFDC2626); // Red - لغة
    } else if (subjectLower.contains('سيرة') ||
        subjectLower.contains('تاريخ')) {
      return const Color(0xFFDB2777); // Pink - سيرة
    } else {
      return const Color(0xFF5A8A8A); // Default teal
    }
  }
}

// ═══════════════════════════════════════════
// BREATHING ICON ANIMATION (for in-progress books)
// ═══════════════════════════════════════════
class _BreathingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;

  const _BreathingIcon({
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  State<_BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<_BreathingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size * 1.3,
        height: widget.size * 1.3,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(widget.icon, size: widget.size * 0.6, color: widget.color),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PressableScale({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
