import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../data/models/book_progress_model.dart';
import '../data/models/mutun_models.dart';
import '../data/services/book_progress_service.dart';
import '../data/services/daily_reading_service.dart';
import '../data/services/motivation_service.dart';
import 'pages/book_view_page.dart';
import 'widgets/ilm_continue_reading_card.dart';
import 'widgets/ilm_daily_progress_card.dart';
import 'widgets/ilm_header.dart';
import 'widgets/ilm_level_section.dart';
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
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.backgroundColor,
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

    // Get sorted levels for section display
    final sortedLevels = _levelByTab.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IlmHeader(dailyMicrocopy: _dailyMicrocopy),

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

                    // 1. PRIMARY ACTION: CONTINUE LEARNING
                    IlmContinueReadingCard(
                      continueReadingBook: _continueReadingBook,
                      recommendedFirstBook: _recommendedFirstBook,
                      bookCatalog: _bookCatalog,
                      pulseAnimation: _pulseAnimation,
                      onNavigateToBook: _navigateToBook,
                    ),

                    SizedBox(height: responsive.mediumGap),

                    // 2. DAILY GOAL CARD
                    IlmDailyProgressCard(
                      dailyGoal: _dailyGoal,
                      pagesReadToday: _pagesReadToday,
                      lastReadDate: _lastReadDate,
                      onGoalChanged: (newGoal) async {
                        await _dailyReadingService?.setDailyGoal(newGoal);
                        _loadData();
                      },
                      onStartFresh: () {
                        _scrollController.animateTo(
                          responsive.hp(40),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),

                    SizedBox(height: responsive.mediumGap),

                    // 3. BOOKS BY LEVEL SECTIONS (Main Focus)
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
                        return IlmLevelSection(
                          level: level,
                          allBooks: _allBooks,
                          progressById: _progressById,
                          bookCatalog: _bookCatalog,
                          onNavigateToBook: _navigateToBook,
                          onToggleFavorite: _toggleFavorite,
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

                    SizedBox(height: AppSize.navClearance(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
