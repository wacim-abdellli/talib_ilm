import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/models/book_progress_model.dart';
import '../data/models/mutun_models.dart';
import '../data/services/book_progress_service.dart';
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

  final ScrollController _scrollController = ScrollController();

  List<BookProgress> _allProgress = [];
  List<IlmBook> _allBooks = [];
  List<IlmBook> _filteredBooks = [];
  String? _selectedLevelTab;
  bool _isLoading = true;
  BookProgress? _continueReadingBook;
  Map<String, IlmBook> _bookCatalog = {};
  Map<String, BookProgress> _progressById = {};
  Map<String, IlmLevel> _levelByTab = {};

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _progressService = BookProgressService(prefs);
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final hasActiveLearning = _continueReadingBook != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'متون طالب العلم',
          style: AppTextStyles.appBarTitle.copyWith(
            fontSize: responsive.sp(18),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: AppStrings.tooltipMenu,
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: () {},
          ),
          SizedBox(width: responsive.wp(2)),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: responsive.mediumGap),
            _buildSimpleStats(responsive),
            SizedBox(height: responsive.mediumGap),
            if (hasActiveLearning)
              _buildContinueLearningCard(responsive, _continueReadingBook!),
            if (hasActiveLearning) SizedBox(height: responsive.largeGap),
            SizedBox(height: responsive.mediumGap),
            _buildLevelSelector(responsive),
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
                            message: AppStrings.ilmLoadErrorMessage,
                            actionLabel: AppStrings.actionRetry,
                            onAction: _loadData,
                          ),
                        )
                      : _filteredBooks.isEmpty
                      ? Padding(
                          key: const ValueKey('empty-filter'),
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.largeGap,
                          ),
                          child: EmptyState(
                            icon: Icons.filter_alt_off,
                            title: 'لا توجد كتب',
                            message: 'لا توجد كتب لهذا التصنيف في هذا المستوى',
                            actionLabel: '',
                            onAction: () {},
                          ),
                        )
                      : _buildBooksGrid(
                          responsive,
                          _filteredBooks,
                          key: ValueKey('books-$_selectedLevelTab'),
                        ),
                ),
              ),
            ),
            SizedBox(height: responsive.largeGap),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearningCard(Responsive responsive, BookProgress book) {
    final totalPages = book.totalPages;
    final currentPage = book.currentPage;
    final progressValue = totalPages == 0
        ? 0.0
        : (currentPage / totalPages).clamp(0.0, 1.0);
    final percentLabel = '${(progressValue * 100).round()}٪';
    final detailLabel = totalPages == 0
        ? 'عدد الصفحات غير متاح'
        : 'صفحة $currentPage من $totalPages';

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
          width: responsive.wp(92),
          padding: EdgeInsets.all(responsive.wp(5)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
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
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge with pulse animation effect
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
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories,
                      size: responsive.sp(12),
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'واصل التعلّم',
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
                  // Elevated book icon
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
                          offset: Offset(0, 4),
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
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            book.level,
                            style: TextStyle(
                              fontSize: responsive.sp(11),
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.hp(0.6)),
                        Row(
                          children: [
                            Icon(
                              Icons.bookmark_outline,
                              size: responsive.sp(12),
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              detailLabel,
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
                ],
              ),

              SizedBox(height: responsive.mediumGap),

              // Progress section with percentage
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
                  // Continue button
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.wp(4),
                      vertical: responsive.hp(1.2),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
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
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_back,
                          size: responsive.sp(14),
                          color: Colors.white,
                        ),
                      ],
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

  Widget _buildSimpleStats(Responsive responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.wp(3.5),
          vertical: responsive.hp(1.6),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _statItem(
                icon: Icons.layers_outlined,
                label: 'المستويات',
                value: _levelByTab.length.toString(),
                responsive: responsive,
              ),
            ),
            _verticalDivider(responsive),
            Expanded(
              child: _statItem(
                icon: Icons.menu_book_outlined,
                label: 'الكتب',
                value: _allBooks.length.toString(),
                responsive: responsive,
              ),
            ),
            _verticalDivider(responsive),
            Expanded(
              child: _statItem(
                icon: Icons.check_circle_outline,
                label: 'مكتملة',
                value: _completedBooksCount.toString(),
                responsive: responsive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider(Responsive responsive) {
    return Container(
      width: 1,
      height: responsive.hp(4.5),
      margin: EdgeInsets.symmetric(horizontal: responsive.wp(2)),
      color: AppColors.primary.withValues(alpha: 0.15),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
    required Responsive responsive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: responsive.sp(18), color: AppColors.primary),
        SizedBox(height: responsive.hp(0.6)),

        /// VALUE (auto-scales, never overflows)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontSize: responsive.sp(18),
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
          ),
        ),

        SizedBox(height: responsive.hp(0.3)),

        /// LABEL (safe text)
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: responsive.sp(10),
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLevelSelector(Responsive responsive) {
    final levels = _levelByTab.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.wp(4),
          vertical: responsive.hp(1.2),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            borderRadius: BorderRadius.circular(12),
            value: _selectedLevelTab,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
            items: levels.map((level) {
              return DropdownMenuItem(
                value: level.title,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: responsive.hp(0.3)),
                    Text(
                      '${level.books.length} كتب • ${level.duration}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _applyFilter(value);
              }
            },
          ),
        ),
      ),
    );
  }

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
        return _buildBookCard(responsive, book, progress);
      },
    );
  }

  Widget _buildBookCard(
    Responsive responsive,
    IlmBook book,
    BookProgress? progress,
  ) {
    final progressValue = progress == null
        ? 0.0
        : (progress.progressPercentage / 100).clamp(0.0, 1.0).toDouble();
    final percentLabel = progress == null
        ? 'لم يبدأ'
        : progress.isCompleted
        ? 'مكتمل'
        : '${progress.progressPercentage.round()}٪';

    // Icon based on progress
    final IconData progressIcon = progress == null
        ? Icons.play_arrow
        : progress.isCompleted
        ? Icons.check_circle
        : Icons.menu_book;

    return GestureDetector(
      onTap: () => _navigateToBook(book),
      onLongPress: () => _toggleFavorite(book.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8B7355).withValues(alpha: 0.12),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Book Cover
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
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.28),
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(
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
                          Icons.menu_book,
                          size: responsive.wp(13),
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  // Subject badge (top-right overlay)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
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

                  // Favorite bookmark (top-left overlay)
                  if (progress?.isFavorite ?? false)
                    Positioned(
                      top: 8,
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
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
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

                    Spacer(),

                    // Enhanced Progress Bar
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: progressValue > 0
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
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
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                    ),

                    SizedBox(height: responsive.hp(0.6)),

                    // Progress text with icon
                    Row(
                      children: [
                        Icon(
                          progressIcon,
                          size: responsive.sp(12),
                          color: progress?.isCompleted ?? false
                              ? Color(0xFF7D9B76)
                              : AppColors.accent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          percentLabel,
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            fontWeight: FontWeight.w500,
                            color: progress?.isCompleted ?? false
                                ? Color(0xFF7D9B76)
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
