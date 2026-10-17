import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../core/models/favorite_item.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_states.dart';
import 'widgets/ilm_loading_view.dart';
import '../data/catalogs/mutun_digital_catalog.dart';
import '../data/models/book_progress_model.dart';
import '../data/models/mutun_models.dart';
import '../data/services/book_progress_service.dart';
import '../data/services/daily_reading_service.dart';
import '../data/services/motivation_service.dart';
import 'pages/book_view_page.dart';
import 'widgets/ilm_books_grid.dart';
import 'widgets/ilm_header.dart';
import 'widgets/ilm_level_header_card.dart';
import 'widgets/ilm_search_bar.dart';
import 'widgets/ilm_search_filter_bar.dart';
import 'package:flutter/services.dart';
import 'widgets/ilm_section_switcher.dart';
import 'widgets/maktaba_shamela_view.dart';
import 'widgets/motivation_widgets.dart';
import 'widgets/mutun_categories_view.dart';
import 'widgets/study_resume_pill.dart';
import 'logic/ilm_search_engine.dart';

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
  final TextEditingController _searchController = TextEditingController();

  List<BookProgress> _allProgress = [];
  List<IlmBook> _allBooks = [];
  bool _isLoading = true;
  BookProgress? _continueReadingBook;
  Map<String, IlmBook> _bookCatalog = {};
  Map<String, BookProgress> _progressById = {};
  Map<String, IlmLevel> _levelByTab = {};
  List<IlmLevel> _sortedLevels = [];
  List<IlmBook> _searchResults = [];

  // Navigation & Search State
  IlmSection _selectedSection = IlmSection.mutun;
  bool _showMutunCategories = true;
  String? _selectedLevelId;
  String _searchQuery = '';

  // Daily reading state
  int _dailyGoal = 5;
  int _pagesReadToday = 0;
  int _currentStreak = 0;

  // Motivation state
  Encouragement? _dailyEncouragement;
  bool _showEncouragement = false;
  late String _dailyMicrocopy;

  static const List<String> _scholarlyQuotes = [
    'العلم يؤتى ولا يأتي', 'من أدمن الطرق ولج', 'قليل دائم خير من كثير منقطع',
    'العلم صيد والكتابة قيد', 'زكاة العلم تعليمه', 'إنما العلم بالتعلم',
    'بداية الغيث قطرة', 'العلماء ورثة الأنبياء',
  ];

  @override
  void initState() {
    super.initState();
    _initDailyMicrocopy();
    _initializeService();
  }

  void _initDailyMicrocopy() {
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
        levelByTab[level.id] = level;
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
      _sortedLevels = visibleLevels;

      if (_selectedLevelId == null ||
          !_levelByTab.containsKey(_selectedLevelId)) {
        _selectedLevelId = visibleLevels.first.id;
      }

      final catalogTotals = {
        for (final book in _allBooks)
          book.id: MutunDigitalCatalog.getEntry(book.id)?.totalPages ??
              (book.totalPages > 0 ? book.totalPages : 1),
      };
      await _progressService?.auditAndHealCatalogProgress(catalogTotals);

      _allProgress = await _progressService?.getAllProgress() ?? [];
      _progressById = {
        for (final progress in _allProgress) progress.bookId: progress,
      };

      final currentlyReading = await _progressService?.getCurrentlyReading();
      _continueReadingBook = currentlyReading?.isNotEmpty == true
          ? currentlyReading?.first
          : null;

      // Load daily reading stats
      if (_dailyReadingService != null) {
        _dailyGoal = _dailyReadingService!.getDailyGoal();
        _pagesReadToday = _dailyReadingService!.getPagesReadToday();
        _currentStreak = _dailyReadingService!.getCurrentStreak();
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

        if (milestone != null && mounted) {
          Future.delayed(AppMotion.base, () {
            if (mounted) {
              MilestoneCelebrationDialog.show(context, milestone);
            }
          });
        }
      }

      _hasLoadError = false;
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

  Map<String, double> get _levelCompletions {
    final map = <String, double>{};
    for (final level in _sortedLevels) {
      if (level.books.isEmpty) {
        map[level.id] = 0.0;
        continue;
      }
      int count = 0;
      for (final book in level.books) {
        if (_progressById[book.id]?.isCompleted ?? false) {
          count++;
        }
      }
      map[level.id] = count / level.books.length;
    }
    return map;
  }

  void _onSearchChanged(String query) {
    if (_searchQuery != query) {
      setState(() {
        _searchQuery = query;
        if (query.trim().isNotEmpty) {
          _searchResults = IlmSearchEngine.search(
            books: _allBooks,
            query: query.trim(),
          );
        } else {
          _searchResults = [];
        }
      });
    }
  }

  void _onClearSearch() {
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
      });
    }
  }

  List<IlmBook> get _filteredBooks {
    if (_searchQuery.isNotEmpty) {
      return _searchResults;
    }
    final currentLevel = _levelByTab[_selectedLevelId];
    return currentLevel?.books ?? [];
  }

  IlmBook? get _recommendedFirstBook {
    for (final level in _sortedLevels) {
      for (final book in level.books) {
        final progress = _progressById[book.id];
        if (progress == null || progress.currentPage <= 1) {
          return book;
        }
      }
    }
    return _allBooks.isNotEmpty ? _allBooks.first : null;
  }

  Future<void> _toggleFavorite(String bookId) async {
    final existing = _progressById[bookId];
    final book = _bookCatalog[bookId];
    if (existing == null) {
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
    if (book != null) {
      final favService = FavoritesService();
      await favService.toggle(
        FavoriteItem(
          type: FavoriteType.book,
          id: book.id,
          title: book.title,
          subtitle: book.author,
        ),
      );
    }
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

    final progressNow = _progressById[book.id];
    final isCompletedNow = progressNow?.isCompleted ?? false;
    final digitalEntry = MutunDigitalCatalog.getEntry(book.id);
    final expectedTotal = digitalEntry != null && digitalEntry.totalPages > 0
        ? digitalEntry.totalPages
        : (book.totalPages > 0
            ? book.totalPages
            : (progressNow?.totalPages ?? 0));
    final isGenuinelyFinished = isCompletedNow &&
        expectedTotal > 1 &&
        (progressNow?.currentPage ?? 0) >= expectedTotal;

    if (!wasCompleted && isGenuinelyFinished) {
      _showCompletionReward(book);
    }
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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (_isLoading) return const IlmLoadingView();

    final activeLevel = _levelByTab[_selectedLevelId] ?? _sortedLevels.first;
    final levelBooks = activeLevel.books;
    final completedInLevel = levelBooks.where((b) => _progressById[b.id]?.isCompleted ?? false).length;
    final levelCompletionRatio = levelBooks.isNotEmpty ? completedInLevel / levelBooks.length : 0.0;
    final displayedBooks = _filteredBooks;
    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── 1. Prestigious Library Header ─────────────────────
            IlmHeader(
              dailyMicrocopy: _dailyMicrocopy,
              totalBooksCount: _allBooks.length,
              completedBooksCount: _completedBooksCount,
            ),

            // ── 2. Library Section Switcher ───────────────────────
            IlmSectionSwitcher(
              selectedSection: _selectedSection,
              onSectionChanged: (sec) => setState(() => _selectedSection = sec),
            ),

            if (_selectedSection == IlmSection.mutun)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.xxs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSubSwitcherItem(
                        title: 'جميع المتون والأقسام',
                        icon: Icons.grid_view_rounded,
                        isSelected: _showMutunCategories,
                        onTap: () => setState(() => _showMutunCategories = true),
                        palette: palette,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: _buildSubSwitcherItem(
                        title: 'خطة المستويات والمنهج',
                        icon: Icons.timeline_rounded,
                        isSelected: !_showMutunCategories,
                        onTap: () => setState(() => _showMutunCategories = false),
                        palette: palette,
                      ),
                    ),
                  ],
                ),
              ),

            // ── 3. Scrollable Library Content ─────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.base,
                switchInCurve: AppMotion.easeOut,
                switchOutCurve: AppMotion.easeIn,
                child: _selectedSection == IlmSection.shamela
                    ? const MaktabaShamelaView(key: ValueKey('maktaba_section'))
                    : _showMutunCategories
                        ? const MutunCategoriesView(
                            key: ValueKey('mutun_categories_view'),
                          )
                        : CustomScrollView(
                            key: const ValueKey('mutun_levels_section'),
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const SizedBox(height: AppSpace.md),

                              // ── Dedicated Minimalist Search Bar ───────────
                              IlmSearchBar(
                                controller: _searchController,
                                onSearchChanged: _onSearchChanged,
                                onClear: _onClearSearch,
                              ),

                              const SizedBox(height: AppSpace.md),

                              if (isSearching) ...[
                                // ── Search Results Badge & Clear ────────────
                                Padding(
                                  padding: AppSpace.screenPadding,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'نتائج البحث: ${displayedBooks.length} متون',
                                        style: context.text.titleSmall.copyWith(
                                          color: palette.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          _searchController.clear();
                                          _onClearSearch();
                                        },
                                        borderRadius: AppRadius.pillRadius,
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional.symmetric(
                                            horizontal: AppSpace.sm,
                                            vertical: AppSpace.xs,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.close_rounded,
                                                size: AppIcon.sm,
                                                color: palette.textMuted,
                                              ),
                                              const SizedBox(width: AppSpace.xs),
                                              Text(
                                                'إلغاء البحث',
                                                style: context.text.caption.copyWith(
                                                  color: palette.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpace.sm),
                              ] else ...[
                                // ── Hero Study Resume Pill ──────────────────
                                StudyResumePill(
                                  continueReadingBook: _continueReadingBook,
                                  recommendedFirstBook: _recommendedFirstBook,
                                  bookCatalog: _bookCatalog,
                                  dailyGoal: _dailyGoal,
                                  pagesReadToday: _pagesReadToday,
                                  currentStreak: _currentStreak,
                                  onNavigateToBook: _navigateToBook,
                                ),
                                const SizedBox(height: AppSpace.md),

                                // ── Level Selector Chips ────────────────────
                                IlmFilterBar(
                                  levels: _sortedLevels,
                                  selectedLevelId: _selectedLevelId ?? activeLevel.id,
                                  onSelectLevel: (lvlId) {
                                    setState(() => _selectedLevelId = lvlId);
                                  },
                                  levelCompletion: _levelCompletions,
                                ),
                                const SizedBox(height: AppSpace.md),

                                // ── Active Level Header Card ────────────────
                                IlmLevelHeaderCard(
                                  level: activeLevel,
                                  completion: levelCompletionRatio,
                                  totalBooks: levelBooks.length,
                                  completedBooks: completedInLevel,
                                ),
                                const SizedBox(height: AppSpace.md),
                              ],
                            ],
                          ),
                        ),

                        // ── Books Section (Virtualized Sliver Grid) ───
                        if (_hasLoadError)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: AppSpace.screenPadding,
                              child: AppEmptyState(
                                icon: Icons.error_outline,
                                title: AppStrings.ilmLoadErrorTitle,
                                subtitle: AppStrings.ilmLoadErrorMessage,
                                action: AppButton(
                                  label: AppStrings.actionRetry,
                                  onPressed: _loadData,
                                ),
                              ),
                            ),
                          )
                        else if (displayedBooks.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: AppSpace.screenPadding,
                              child: AppEmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'لم يتم العثور على نتائج',
                                subtitle: isSearching
                                    ? 'لا يوجد متن أو كتاب يطابق عبارة البحث "$_searchQuery"'
                                    : 'لا توجد كتب مسجلة في هذا القسم حالياً',
                              ),
                            ),
                          )
                        else
                          SliverIlmBooksGrid(
                            books: displayedBooks,
                            progressById: _progressById,
                            recommendedBookId: _recommendedFirstBook?.id,
                            onNavigateToBook: _navigateToBook,
                            onToggleFavorite: _toggleFavorite,
                          ),

                        // ── Motivation & Nav Clearance ─────────────────
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const SizedBox(height: AppSpace.lg),
                              if (_showEncouragement && _dailyEncouragement != null) ...[
                                Padding(
                                  padding: AppSpace.screenPadding,
                                  child: EncouragementBanner(
                                    encouragement: _dailyEncouragement!,
                                    onDismiss: () {
                                      setState(() {
                                        _showEncouragement = false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: AppSpace.md),
                              ],
                              SizedBox(height: AppSize.navClearance(context)),
                            ],
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
  }

  Widget _buildSubSwitcherItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: AppRadius.pillRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? palette.surfaceRaised : palette.surfaceMuted,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: isSelected ? palette.primary : palette.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppIcon.xs,
                color: isSelected ? palette.primary : palette.textMuted,
              ),
              const SizedBox(width: AppSpace.xs),
              Flexible(
                child: Text(
                  title,
                  style: context.text.caption.copyWith(
                    color: isSelected ? palette.text : palette.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

