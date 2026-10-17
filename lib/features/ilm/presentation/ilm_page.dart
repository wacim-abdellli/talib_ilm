import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/models/favorite_item.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/catalogs/aqidah_catalog.dart';
import '../data/catalogs/arabic_catalog.dart';
import '../data/catalogs/fiqh_catalog.dart';
import '../data/catalogs/hadith_catalog.dart';
import '../data/catalogs/mutun_digital_catalog.dart';
import '../data/catalogs/raqaeq_adab_catalog.dart';
import '../data/catalogs/seerah_tarikh_catalog.dart';
import '../data/catalogs/tafsir_catalog.dart';
import '../data/catalogs/usul_catalog.dart';
import '../data/models/book_progress_model.dart';
import '../data/models/islamic_quiz_models.dart';
import '../data/models/mutun_models.dart';
import '../data/models/shamela_models.dart';
import '../data/services/book_progress_service.dart';
import '../data/services/daily_reading_service.dart';
import '../data/services/motivation_service.dart';
import '../data/services/quiz_progress_service.dart';
import '../data/services/shamela_service.dart';
import 'pages/book_view_page.dart';
import 'pages/islamic_quiz_hub_page.dart';
import 'pages/shamela_reader_page.dart';
import 'widgets/ilm_category_chips.dart';
import 'widgets/ilm_header.dart';
import 'widgets/ilm_loading_view.dart';
import 'widgets/ilm_mutn_card.dart';
import 'widgets/ilm_partition_header.dart';
import 'widgets/ilm_quiz_banner_card.dart';
import 'widgets/ilm_search_bar.dart';
import 'widgets/maktaba_shamela_view.dart';
import 'widgets/motivation_widgets.dart';
import 'widgets/shamela_book_card.dart';
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
  QuizProgressService? _quizProgressService;
  UserQuizStats? _quizStats;

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
    _quizProgressService = QuizProgressService(prefs);
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
          book.id: MutunDigitalCatalog.getEntry(book.id)?.totalPages ??
              (book.totalPages > 0 ? book.totalPages : 1),
      };
      await _progressService?.auditAndHealCatalogProgress(catalogTotals);

      final allProgress = await _progressService?.getAllProgress() ?? [];
      _progressById = {
        for (final progress in allProgress) progress.bookId: progress,
      };

      _favoriteBookIds =
          await FavoritesService().getIdsByType(FavoriteType.book);

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
            await FavoritesService().add(FavoriteItem(
              id: book.id,
              title: book.title,
              type: FavoriteType.book,
              subtitle: book.author,
            ));
          }
        }
      }

      final currentlyReading = await _progressService?.getCurrentlyReading();
      _continueReadingBook = currentlyReading?.isNotEmpty == true
          ? currentlyReading?.first
          : null;

      if (_dailyReadingService != null) {
        _dailyGoal = _dailyReadingService!.getDailyGoal();
        _pagesReadToday = _dailyReadingService!.getPagesReadToday();
        _currentStreak = _dailyReadingService!.getCurrentStreak();
      }

      _quizStats = _quizProgressService?.getUserStats();

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

    if (!wasCompleted && isGenuinelyFinished && mounted) {
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

  void _openShamelaReader(ShamelaBook book) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      buildFadeRoute(
        page: ShamelaReaderPage(
          book: book,
        ),
      ),
    );
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
        _progressById[bookId] =
            _progressById[bookId]!.copyWith(isFavorite: isFavNow);
      }
    });

    if (mounted) {
      if (isFavNow) {
        AppSnackbar.success(
          context,
          'تمت إضافة "${book.title}" إلى المفضلة (قائمة المحفوظات)',
        );
      } else {
        AppSnackbar.info(
          context,
          'تمت إزالة "${book.title}" من المفضلة',
        );
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
              totalBooksCount: _allBooks.length,
              completedBooksCount: _completedBooksCount,
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
                  : (_selectedCategory == 'quiz'
                      ? const IslamicQuizHubPage(showAppBar: false)
                      : _buildScrollablePartitions(context, palette)),
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
              ),
            ),
          ),

        // Islamic Knowledge Quizzes Banner (competitions, levels & lessons)
        SliverToBoxAdapter(
          child: IlmQuizBannerCard(
            currentCategory: _selectedCategory,
            userStats: _quizStats,
            onReturnFromQuiz: _loadData,
          ),
        ),

        // Section 1: Mutun Taleb Al-Ilm
        if (_selectedCategory == 'all' || _selectedCategory == 'mutun')
          ..._buildMutunSectionSlivers(palette),

        // Section 2: Aqeedah
        if (_selectedCategory == 'all' || _selectedCategory == 'aqidah')
          ..._buildShamelaCatalogSection(
            palette: palette,
            title: 'العقيدة والتوحيد',
            subtitle: 'أصول الإيمان والتوحيد والرد على الشبهات',
            books: AqidahCatalog.books,
            categoryKey: 'aqidah',
          ),

        // Section 3: Hadith
        if (_selectedCategory == 'all' || _selectedCategory == 'hadith')
          ..._buildShamelaCatalogSection(
            palette: palette,
            title: 'الحديث الشريف وعلومه',
            subtitle: 'الأحاديث النبوية وشروحها ومصطلح الحديث',
            books: HadithCatalog.allBooks,
            categoryKey: 'hadith',
          ),

        // Section 4: Fiqh & Usul
        if (_selectedCategory == 'all' || _selectedCategory == 'fiqh')
          ..._buildShamelaCatalogSection(
            palette: palette,
            title: 'الفقه الإسلامي وأصوله',
            subtitle: 'أحكام العبادات والمعاملات وقواعد الاستنباط',
            books: [...FiqhCatalog.allBooks, ...UsulCatalog.books],
            categoryKey: 'fiqh',
          ),

        // Section 5: Adab & Raqaeq
        if (_selectedCategory == 'all' || _selectedCategory == 'adab')
          ..._buildShamelaCatalogSection(
            palette: palette,
            title: 'الآداب والرقائق والأذكار',
            subtitle: 'تزكية النفوس وحفظ الأوقات والأخلاق الإسلامية',
            books: RaqaeqAdabCatalog.books,
            categoryKey: 'adab',
          ),

        // Section 6: Tafsir
        if (_selectedCategory == 'all' || _selectedCategory == 'tafsir')
          ..._buildShamelaCatalogSection(
            palette: palette,
            title: 'التفسير وعلوم القرآن',
            subtitle: 'معاني كلام الله وقواعد التدبر والتجويد',
            books: TafsirCatalog.books,
            categoryKey: 'tafsir',
          ),

        // Section 7: Seerah & Tarikh
        if (_selectedCategory == 'all' || _selectedCategory == 'seerah')
          ..._buildShamelaCatalogSection(
            palette: palette,
            title: 'السيرة النبوية والتاريخ',
            subtitle: 'سيرة النبي ﷺ وتاريخ الخلفاء الراشدين والأمة',
            books: SeerahTarikhCatalog.books,
            categoryKey: 'seerah',
          ),

        // Section 8: Arabic Language
        if (_selectedCategory == 'all' || _selectedCategory == 'arabic')
          ..._buildShamelaCatalogSection(
            palette: palette,
            title: 'اللغة العربية وعلومها',
            subtitle: 'النحو والصرف والبلاغة مفتاح فهم الوحيين',
            books: ArabicCatalog.books,
            categoryKey: 'arabic',
          ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
      ],
    );
  }

  List<Widget> _buildMutunSectionSlivers(AppPalette palette) {
    final isFocused = _selectedCategory == 'mutun';
    final filteredMutun = _selectedMutunLevel == null
        ? _allBooks
        : _allBooks.where((b) => b.level == _selectedMutunLevel).toList();

    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IlmPartitionHeader(
              title: 'متون طالب العلم (المنهاج التأصيلي)',
              subtitle: 'منهج علمي مدرج يبدأ بالتمهيدي حتى المطولات',
              countLabel: '${_allBooks.length} متون',
              onShowAll: !isFocused ? () => setState(() => _selectedCategory = 'mutun') : null,
            ),

            // Horizontal Level Selector Filter
            SizedBox(
              height: AppSize.tap,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildLevelChip(
                    label: 'جميع المستويات',
                    isSelected: _selectedMutunLevel == null,
                    onTap: () => setState(() => _selectedMutunLevel = null),
                    palette: palette,
                  ),
                  for (final lvl in _sortedLevels)
                    _buildLevelChip(
                      label: lvl.label.isNotEmpty ? lvl.label : lvl.title,
                      isSelected: _selectedMutunLevel == lvl.title,
                      onTap: () => setState(() => _selectedMutunLevel = lvl.title),
                      palette: palette,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ),
      ),
      SliverPadding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final book = filteredMutun[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                child: IlmMutnCard(
                  book: book,
                  progress: _progressById[book.id],
                  isFavoriteOverride: _favoriteBookIds.contains(book.id),
                  onOpenReader: () => _navigateToBook(book),
                  onToggleFavorite: () => _toggleFavorite(book.id),
                ),
              );
            },
            childCount: isFocused ? filteredMutun.length : filteredMutun.take(3).length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildShamelaCatalogSection({
    required AppPalette palette,
    required String title,
    required String subtitle,
    required List<ShamelaBook> books,
    required String categoryKey,
  }) {
    final isFocused = _selectedCategory == categoryKey;
    final displayBooks = isFocused ? books : books.take(3).toList();

    return [
      SliverToBoxAdapter(
        child: IlmPartitionHeader(
          title: title,
          subtitle: subtitle,
          countLabel: '${books.length} كتب',
          onShowAll: !isFocused ? () => setState(() => _selectedCategory = categoryKey) : null,
        ),
      ),
      SliverPadding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final book = displayBooks[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                child: ShamelaBookCard(
                  book: book,
                  isDownloaded: true,
                  downloadProgress: null,
                  onOpen: () => _openShamelaReader(book),
                  onDownload: () {},
                  onOpenShuruh: _openShuruhSheet,
                ),
              );
            },
            childCount: displayBooks.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildLevelChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
      child: Material(
        color: isSelected ? palette.primary : palette.surfaceRaised,
        borderRadius: AppRadius.pillRadius,
        child: InkWell(
          borderRadius: AppRadius.pillRadius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: isSelected ? palette.primary : palette.border,
                width: 1.0,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: context.text.caption.copyWith(
                  color: isSelected ? palette.onPrimary : palette.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsView(AppPalette palette) {
    final query = _searchQuery.toLowerCase();

    // 1. Matn matches
    final matchedMutun = _allBooks.where((b) {
      return b.title.toLowerCase().contains(query) ||
          b.author.toLowerCase().contains(query) ||
          b.description.toLowerCase().contains(query);
    }).toList();

    // 2. Classical catalog matches
    final matchedShamela = ShamelaService.searchCatalog(query: query);

    final totalMatches = matchedMutun.length + matchedShamela.length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نتائج البحث: $totalMatches كتب ومتون',
                  style: context.text.titleSmall.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: _onClearSearch,
                  borderRadius: AppRadius.pillRadius,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xs,
                    ),
                    child: Text(
                      'إلغاء البحث',
                      style: context.text.caption.copyWith(color: palette.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (matchedMutun.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: IlmPartitionHeader(
              title: 'المتون العلمية المطابقة',
              countLabel: '${matchedMutun.length} متون',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = matchedMutun[index];
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                    child: IlmMutnCard(
                      book: book,
                      progress: _progressById[book.id],
                      isFavoriteOverride: _favoriteBookIds.contains(book.id),
                      onOpenReader: () => _navigateToBook(book),
                      onToggleFavorite: () => _toggleFavorite(book.id),
                    ),
                  );
                },
                childCount: matchedMutun.length,
              ),
            ),
          ),
        ],
        if (matchedShamela.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: IlmPartitionHeader(
              title: 'كتب المكتبة العلمية المطابقة',
              countLabel: '${matchedShamela.length} كتب',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = matchedShamela[index];
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                    child: ShamelaBookCard(
                      book: book,
                      isDownloaded: true,
                      downloadProgress: null,
                      onOpen: () => _openShamelaReader(book),
                      onDownload: () {},
                      onOpenShuruh: _openShuruhSheet,
                    ),
                  );
                },
                childCount: matchedShamela.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
      ],
    );
  }
}
