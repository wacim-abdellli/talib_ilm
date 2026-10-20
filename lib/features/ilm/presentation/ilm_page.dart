import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/models/favorite_item.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/last_activity_service.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/catalogs/mutun_digital_catalog.dart';
import '../data/catalogs/turath_catalog.dart';
import '../data/models/book_progress_model.dart';
import '../data/models/islamic_quiz_models.dart';
import '../data/models/mutun_models.dart';
import '../data/models/shamela_models.dart';
import '../data/services/book_progress_service.dart';
import '../data/services/daily_reading_service.dart';
import '../data/services/motivation_service.dart';
import 'pages/book_view_page.dart';
import 'pages/fan_quiz_levels_page.dart';
import 'pages/islamic_quiz_hub_page.dart';
import 'pages/shamela_reader_page.dart';
import 'widgets/ilm_category_chips.dart';
import 'widgets/ilm_discipline_section.dart';
import 'widgets/ilm_header.dart';
import 'widgets/ilm_loading_view.dart';
import 'widgets/ilm_mutun_section_view.dart';
import 'widgets/ilm_reading_tracker_sheet.dart';
import 'widgets/ilm_search_bar.dart';
import 'widgets/ilm_search_results_view.dart';
import 'widgets/maktaba_shamela_view.dart';
import 'widgets/motivation_widgets.dart';
import 'widgets/shamela_shuruh_sheet.dart';
import 'widgets/study_resume_pill.dart';

/// The unified Ilm screen for Islamic knowledge, partitioned into clear scholarly categories
/// adhering strictly to the Calm Scholar design system and dynamic data.
class IlmPage extends StatefulWidget {
  const IlmPage({super.key});

  @override
  State<IlmPage> createState() => _IlmPageState();
}

class _IlmPageState extends State<IlmPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  BookProgressService? _progressService;
  DailyReadingService? _dailyReadingService;
  MotivationService? _motivationService;

  bool _isLoading = true;
  String _selectedCategory = 'all';
  String? _selectedMutunLevel; // null means all levels in mutun section
  String _searchQuery = '';

  List<IlmBook> _allBooks = [];
  Map<String, IlmBook> _bookCatalog = {};
  Map<String, BookProgress> _progressById = {};
  Set<String> _favoriteBookIds = {};
  List<IlmLevel> _sortedLevels = [];
  BookProgress? _continueReadingBook;

  int _dailyGoal = 5;
  int _pagesReadToday = 0;
  int _currentStreak = 0;
  late String _dailyMicrocopy;

  static const List<String> _scholarlyQuotes = [
    'العلم يؤتى ولا يأتي',
    'من أدمن الطرق ولج',
    'قليل دائم خير من كثير منقطع',
    'العلم صيد والكتابة قيد',
    'زكاة العلم تعليمه',
    'إنما العلم بالتعلم',
    'بداية الغيث قطرة',
    'العلماء ورثة الأنبياء',
  ];

  int get _completedBooksCount {
    return _progressById.values.where((p) => p.isCompleted).length;
  }

  int get _totalLibraryBooksCount {
    return _allBooks.length + TurathCatalog.books.length;
  }

  IlmBook? get _recommendedFirstBook {
    if (_allBooks.isEmpty) return null;
    return _allBooks.first;
  }

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
      final levels = program.levels..sort((a, b) => a.order.compareTo(b.order));
      final visibleLevels = levels.where((level) => !level.hidden).toList();

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
      _sortedLevels = visibleLevels;

      final catalogTotals = {
        for (final book in _allBooks)
          book.id:
              MutunDigitalCatalog.getEntry(book.id)?.totalPages ??
              (book.totalPages > 0 ? book.totalPages : 1),
      };
      await _progressService?.auditAndHealCatalogProgress(catalogTotals);

      final allProgress = await _progressService?.getAllProgress() ?? [];
      _progressById = {
        for (final progress in allProgress) progress.bookId: progress,
      };

      _favoriteBookIds = await FavoritesService().getIdsByType(
        FavoriteType.book,
      );

      // Automatically reconcile and sync favorites bidirectionally
      for (final bookId in _favoriteBookIds) {
        if (_progressById.containsKey(bookId)) {
          final p = _progressById[bookId]!;
          if (!p.isFavorite) {
            _progressById[bookId] = p.copyWith(isFavorite: true);
            await _progressService?.setFavorite(bookId, true);
          }
        }
      }
      for (final p in _progressById.values) {
        if (p.isFavorite && !_favoriteBookIds.contains(p.bookId)) {
          final book = _bookCatalog[p.bookId];
          if (book != null) {
            _favoriteBookIds.add(p.bookId);
            await FavoritesService().add(
              FavoriteItem(
                id: book.id,
                title: book.title,
                type: FavoriteType.book,
                subtitle: book.author,
              ),
            );
          }
        }
      }

      final lastActivity = await LastActivityService().getLastActivity();
      if (lastActivity != null && _bookCatalog.containsKey(lastActivity.bookId)) {
        final existingProgress = _progressById[lastActivity.bookId];
        if (existingProgress != null) {
          _continueReadingBook = existingProgress;
        } else {
          final book = _bookCatalog[lastActivity.bookId]!;
          _continueReadingBook = BookProgress(
            bookId: book.id,
            bookTitle: book.title,
            level: book.level,
            totalPages: lastActivity.total ?? (book.totalPages > 0 ? book.totalPages : 1),
            currentPage: lastActivity.page ?? 1,
            lastReadDate: DateTime.now(),
            startedDate: DateTime.now(),
          );
        }
      } else {
        _continueReadingBook = await _progressService?.getLastReadBook();
      }

      if (_dailyReadingService != null) {
        _dailyGoal = _dailyReadingService!.getDailyGoal();
        _pagesReadToday = _dailyReadingService!.getPagesReadToday();
        _currentStreak = _dailyReadingService!.getCurrentStreak();
      }

      if (_motivationService != null) {
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
    } catch (e) {
      debugPrint('Error loading mutun program: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query.trim());
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _navigateToBook(IlmBook book) async {
    final wasCompleted = _progressById[book.id]?.isCompleted ?? false;
    final lastTab = await LastActivityService().getLastTab(book.id);
    if (!mounted) return;
    final initialTabIndex = switch (lastTab) {
      LastActivityService.tabSharh => 1,
      LastActivityService.tabLessons => 2,
      _ => 0,
    };

    await Navigator.push(
      context,
      buildFadeRoute(
        page: BookViewPage(
          book: book,
          initialTabIndex: initialTabIndex,
        ),
      ),
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
    final isGenuinelyFinished =
        isCompletedNow &&
        expectedTotal > 1 &&
        (progressNow?.currentPage ?? 0) >= expectedTotal;

    if (!wasCompleted && isGenuinelyFinished && mounted) {
      MilestoneCelebrationDialog.show(
        context,
        MilestoneTrigger(
          type: MilestoneType.booksCount,
          title: 'أحسنت!',
          message: 'أتممت كتاب "${book.title}" بفضل الله.',
          icon: '🌿',
          verse: 'وَقُل رَّبِّ زِدْنِي عِلْمًا',
          verseRef: 'سورة طه: 114',
        ),
      );
    }
  }

  void _openShamelaReader(ShamelaBook book) async {
    HapticFeedback.selectionClick();
    await Navigator.of(
      context,
    ).push(buildFadeRoute(page: ShamelaReaderPage(book: book)));
    await _loadData();
  }

  void _openDisciplineQuiz(FanQuiz fan) async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      buildFadeRoute(page: FanQuizLevelsPage(fan: fan)),
    );
    await _loadData();
  }

  void _openCurriculumQuiz() async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      buildFadeRoute(page: const IslamicQuizHubPage(showAppBar: true)),
    );
    await _loadData();
  }

  void _openShuruhSheet(ShamelaBook parentBook, List<ShamelaBook> shuruh) {
    HapticFeedback.selectionClick();
    ShamelaShuruhSheet.show(
      context: context,
      parentBook: parentBook,
      shuruh: shuruh,
      downloadedMap: const {},
      downloadProgress: const {},
      onOpenSharh: _openShamelaReader,
      onDownloadSharh: (_) {},
    );
  }

  void _showReadingProgressSheet() async {
    final inProgress = _progressById.values
        .where((p) =>
            (!p.isCompleted || p.currentPage < p.totalPages) &&
            p.currentPage > 1)
        .toList()
      ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));

    final completed = _progressById.values
        .where((p) => p.isCompleted)
        .toList()
      ..sort((a, b) => (b.completedDate ?? b.lastReadDate)
          .compareTo(a.completedDate ?? a.lastReadDate));

    await IlmReadingTrackerSheet.show(
      context: context,
      inProgressBooks: inProgress,
      completedBooks: completed,
      totalLibraryBooks: _totalLibraryBooksCount,
      bookCatalog: _bookCatalog,
      onOpenBook: _openBookFromTracker,
    );
  }

  void _openBookFromTracker(String bookId) {
    if (bookId.startsWith('shamela_')) {
      final shamelaId = int.tryParse(bookId.replaceFirst('shamela_', ''));
      if (shamelaId != null) {
        final match = TurathCatalog.books.cast<ShamelaBook?>().firstWhere(
              (b) => b?.id == shamelaId,
              orElse: () => null,
            );
        if (match != null) {
          _openShamelaReader(match);
          return;
        }
        final p = _progressById[bookId];
        if (p != null) {
          _openShamelaReader(
            ShamelaBook(
              id: shamelaId,
              title: p.bookTitle,
              author: 'علم شرعي',
              category: p.level,
              categoryId: 0,
              totalPages: p.totalPages,
            ),
          );
          return;
        }
      }
    }

    final book = _bookCatalog[bookId];
    if (book != null) {
      _navigateToBook(book);
    }
  }

  void _toggleFavorite(String bookId) async {
    final book = _bookCatalog[bookId];
    if (book == null) return;

    final favItem = FavoriteItem(
      id: book.id,
      title: book.title,
      type: FavoriteType.book,
      subtitle: book.author,
    );

    final isFavNow = await FavoritesService().toggle(favItem);
    await _progressService?.setFavorite(bookId, isFavNow);

    setState(() {
      if (isFavNow) {
        _favoriteBookIds.add(bookId);
      } else {
        _favoriteBookIds.remove(bookId);
      }
      if (_progressById.containsKey(bookId)) {
        _progressById[bookId] = _progressById[bookId]!.copyWith(
          isFavorite: isFavNow,
        );
      }
    });

    if (mounted) {
      if (isFavNow) {
        AppSnackbar.success(
          context,
          'تمت إضافة "${book.title}" إلى المفضلة (قائمة المحفوظات)',
        );
      } else {
        AppSnackbar.info(context, 'تمت إزالة "${book.title}" من المفضلة');
      }
    }
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

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── 1. Native Calm Scholar Header ───────────────────────
            IlmHeader(
              dailyMicrocopy: _dailyMicrocopy,
              totalBooksCount: _totalLibraryBooksCount,
              completedBooksCount: _completedBooksCount,
              onStatsTap: _showReadingProgressSheet,
            ),

            const SizedBox(height: AppSpace.sm),

            // ── 2. Unified Minimalist Search Bar ────────────────────
            IlmSearchBar(
              controller: _searchController,
              onSearchChanged: _onSearchChanged,
              onClear: _onClearSearch,
            ),

            const SizedBox(height: AppSpace.sm),

            // ── 3. Categorized Partition Chips ──────────────────────
            IlmCategoryChips(
              selectedCategoryId: _selectedCategory,
              onCategorySelected: (catId) {
                setState(() {
                  _selectedCategory = catId;
                  if (catId != 'mutun') {
                    _selectedMutunLevel = null;
                  }
                });
              },
            ),

            const SizedBox(height: AppSpace.sm),

            // ── 4. Partitioned Content Body ─────────────────────────
            Expanded(
              child: _selectedCategory == 'shamela'
                  ? const MaktabaShamelaView(key: ValueKey('maktaba_section'))
                  : _buildScrollablePartitions(context, palette),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollablePartitions(BuildContext context, AppPalette palette) {
    final isSearching = _searchQuery.isNotEmpty;

    if (isSearching) {
      return _buildSearchResultsView(palette);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Continue Reading Resume Hero
        if (_continueReadingBook != null && _selectedCategory == 'all')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpace.lg,
                end: AppSpace.lg,
                bottom: AppSpace.md,
              ),
              child: StudyResumePill(
                continueReadingBook: _continueReadingBook,
                recommendedFirstBook: _recommendedFirstBook,
                bookCatalog: _bookCatalog,
                dailyGoal: _dailyGoal,
                pagesReadToday: _pagesReadToday,
                currentStreak: _currentStreak,
                onNavigateToBook: _navigateToBook,
                onOpenBookId: _openBookFromTracker,
              ),
            ),
          ),

        // Section 1: Mutun Taleb Al-Ilm
        if (_selectedCategory == 'all' || _selectedCategory == 'mutun')
          ...IlmMutunSectionView.buildSlivers(
            context: context,
            palette: palette,
            allBooks: _allBooks,
            sortedLevels: _sortedLevels,
            progressById: _progressById,
            favoriteBookIds: _favoriteBookIds,
            isFocused: _selectedCategory == 'mutun',
            selectedMutunLevel: _selectedMutunLevel,
            onSelectLevel: (lvl) => setState(() => _selectedMutunLevel = lvl),
            onViewAll: () => setState(() => _selectedCategory = 'mutun'),
            onBackToAll: () => setState(() {
              _selectedCategory = 'all';
              _selectedMutunLevel = null;
            }),
            onNavigateToBook: _navigateToBook,
            onToggleFavorite: _toggleFavorite,
            onOpenCurriculumQuiz: _openCurriculumQuiz,
          ),

        // Disciplines (Aqidah, Hadith, Fiqh, Adab, Tafsir, Seerah, Arabic)
        for (final d in IlmDisciplineSection.disciplines)
          if (_selectedCategory == 'all' || _selectedCategory == d.key)
            ...IlmDisciplineSection.buildSlivers(
              context: context,
              palette: palette,
              title: d.title,
              subtitle: d.subtitle,
              books: d.books,
              categoryKey: d.key,
              isFocused: _selectedCategory == d.key,
              fan: d.fan,
              onOpenBook: _openShamelaReader,
              onOpenShuruh: _openShuruhSheet,
              onViewAll: () => setState(() => _selectedCategory = d.key),
              onBackToAll: () => setState(() => _selectedCategory = 'all'),
              onOpenQuiz: _openDisciplineQuiz,
            ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: AppSize.navClearance(context) + AppSpace.xxxl,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsView(AppPalette palette) {
    return IlmSearchResultsView(
      searchQuery: _searchQuery,
      allBooks: _allBooks,
      progressById: _progressById,
      favoriteBookIds: _favoriteBookIds,
      onClearSearch: _onClearSearch,
      onNavigateToBook: _navigateToBook,
      onToggleFavorite: _toggleFavorite,
      onOpenShamelaReader: _openShamelaReader,
      onOpenShuruhSheet: _openShuruhSheet,
    );
  }
}