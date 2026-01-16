import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/last_activity_service.dart';
import 'package:talib_ilm/core/services/last_sharh_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/sharh_card.dart';
import 'package:talib_ilm/shared/widgets/app_popup.dart';
import 'package:talib_ilm/shared/widgets/app_snackbar.dart';
import '../../data/models/lesson_model.dart';

import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/sharh_model.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../../../shared/widgets/pressable_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/services/progress_service.dart';
import '../../../ilm/data/models/progress_models.dart';
import 'lessons_list_page.dart';
import '../../../../shared/widgets/primary_app_bar.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/models/favorite_item.dart';
import '../../../../core/services/asset_service.dart';
import '../../data/services/book_progress_service.dart';

class BookViewPage extends StatefulWidget {
  final IlmBook book;
  final int initialTabIndex;
  final String? autoOpenSharhFile;
  final bool openLessonsOnStart;

  const BookViewPage({
    super.key,
    required this.book,
    this.initialTabIndex = 0,
    this.autoOpenSharhFile,
    this.openLessonsOnStart = false,
  });

  @override
  State<BookViewPage> createState() => _BookViewPageState();
}

class _BookViewPageState extends State<BookViewPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<PdfViewerPageState> _mutnPdfKey =
      GlobalKey<PdfViewerPageState>();

  final ProgressService _lessonProgressService = ProgressService();
  final LastSharhService _lastSharhService = LastSharhService();
  final LastActivityService _lastActivityService = LastActivityService();
  final FavoritesService _favoritesService = FavoritesService();
  late BookProgressService _bookProgressService;
  late Timer _readingTimer;
  int _sessionMinutes = 0;
  final bool _showControls = true;
  final TextEditingController _noteController = TextEditingController();
  final Set<int> _bookmarkedPages = <int>{};
  bool _bookServiceReady = false;
  bool _isBookmarked = false;
  int _currentPage = 1;
  int _totalPages = 0;
  String _bookLevelLabel = 'غير محدد';
  String? _lastSharhFile;
  Sharh? _lastSharh;
  PdfPageInfo? _lastSharhPage;
  static const int _temporaryLessonsCount = 10; // 🔧 TEMP
  late final String _mutunPdfPath;
  late final String _mutunPdfKey;
  late final Future<int> _mutunInitialPage;
  bool _isFavorite = false;
  late final TabController _tabController;
  int _lastTabIndex = 0;
  bool _didAutoOpen = false;
  int _maxPageReached = 1;
  DateTime? _readingStart;
  int _readingSeconds = 0;
  bool _hasShownReadHint = false;
  bool get _canCompleteBook {
    if (_totalPages <= 0) return false;

    final pageRatio = _maxPageReached / _totalPages;
    final enoughPages = pageRatio >= 0.9;
    final enoughTime = _readingSeconds >= 120; // 2 minutes (tweakable)

    return enoughPages && enoughTime;
  }

  void _updateReadingTime() {
    if (_readingStart == null) return;
    final now = DateTime.now();
    _readingSeconds += now.difference(_readingStart!).inSeconds;
    _readingStart = now;
  }

  @override
  void initState() {
    super.initState();
    _mutunPdfPath = widget.book.pdfPath ?? '';
    _mutunPdfKey = _lastActivityService.pdfKeyForMutn(widget.book.id);
    _mutunInitialPage = _lastActivityService.getPdfPage(_mutunPdfKey).then((
      info,
    ) {
      final page = info?.page ?? 1;
      _currentPage = page;
      return page;
    });
    final initialIndex = widget.initialTabIndex.clamp(0, 2).toInt();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _lastTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
    _lastActivityService.setLastBook(widget.book.id);
    _lastActivityService.setLastTab(
      widget.book.id,
      _tabKeyForIndex(_tabController.index),
    );
    _markStartedIfNeeded();
    _loadLastSharh();
    _loadFavorite();
    _initializeService();
    _startReadingTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoOpen());
    _readingStart = DateTime.now();
  }

  Future<void> _initializeService() async {
    final prefs = await SharedPreferences.getInstance();
    _bookProgressService = BookProgressService(prefs);
    _bookServiceReady = true;
    await _resolveBookLevel();
    await _refreshBookmarkState();
  }

  Future<void> _resolveBookLevel() async {
    try {
      final program = await AssetService.loadMutunProgram();
      for (final level in program.levels) {
        if (level.books.any((book) => book.id == widget.book.id)) {
          _bookLevelLabel = level.title;
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _ensureBookInitialized({int? totalPages}) async {
    if (!_bookServiceReady) return;
    final existing = await _bookProgressService.getBookProgress(widget.book.id);
    if (existing != null) return;
    final pages = totalPages ?? _totalPages;
    final safePages = pages <= 0 ? 1 : pages;
    await _bookProgressService.initializeBook(
      bookId: widget.book.id,
      bookTitle: widget.book.title,
      level: _bookLevelLabel,
      totalPages: safePages,
    );
  }

  Future<void> _refreshBookmarkState() async {
    if (!_bookServiceReady) return;
    final progress = await _bookProgressService.getBookProgress(widget.book.id);
    if (!mounted) return;
    final pages = progress?.bookmarkedPages ?? const <int>[];
    setState(() {
      _bookmarkedPages
        ..clear()
        ..addAll(pages);
      _isBookmarked = _bookmarkedPages.contains(_currentPage);
    });
  }

  void _startReadingTimer() {
    _readingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _sessionMinutes++;
      if (_sessionMinutes % 5 == 0) {
        _saveProgress();
      }
    });
  }

  Future<void> _saveProgress() async {
    if (!_bookServiceReady) return;
    await _ensureBookInitialized(totalPages: _totalPages);
    await _bookProgressService.updateCurrentPage(widget.book.id, _currentPage);
    if (_sessionMinutes == 0) return;
    await _bookProgressService.addReadingTime(widget.book.id, _sessionMinutes);
    _sessionMinutes = 0;
  }

  @override
  void dispose() {
    _readingTimer.cancel();
    _saveProgress();
    _noteController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSharh() async {
    final file = await _lastSharhService.get(widget.book.id);
    if (!mounted) return;

    final sharh = widget.book.shuruh.where((s) => s.file == file).firstOrNull();

    PdfPageInfo? info;
    if (file != null) {
      final key = _lastActivityService.pdfKeyForSharh(widget.book.id, file);
      info = await _lastActivityService.getPdfPage(key);
    }

    if (!mounted) return;
    setState(() {
      _lastSharhFile = file;
      _lastSharh = sharh;
      _lastSharhPage = info;
    });
  }

  Future<void> _loadFavorite() async {
    final saved = await _favoritesService.isFavorite(
      FavoriteType.book,
      widget.book.id,
    );
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

  Future<void> _toggleFavorite() async {
    final saved = await _favoritesService.toggle(
      FavoriteItem(
        type: FavoriteType.book,
        id: widget.book.id,
        title: widget.book.title,
        subtitle: widget.book.author,
      ),
    );
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

  Future<void> _markStartedIfNeeded() async {
    final existing = await _lessonProgressService.getProgress(widget.book.id);

    if (existing == null) {
      await _lessonProgressService.saveProgress(
        BookProgress(
          bookId: widget.book.id,
          status: BookProgressStatus.inProgress,
          completedLessons: 0,
          totalLessons: 0,
        ),
      );
    } else {}
  }

  Future<void> _resetProgress() async {
    if (!_bookServiceReady) return;

    await _bookProgressService.resetBook(widget.book.id);

    if (!mounted) return;

    setState(() {
      _currentPage = 1;
      _totalPages = 0;
      _maxPageReached = 1;
      _readingSeconds = 0;
      _hasShownReadHint = false;
      _bookmarkedPages.clear();
      _isBookmarked = false;
    });

    // 🔥 THIS NOW WORKS
    _mutnPdfKey.currentState?.resetToStart();

    HapticFeedback.mediumImpact();
    AppSnackbar.success(context, 'تمت إعادة تعيين تقدم الكتاب');
  }

  void _handleTabChange() {
    if (_tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;
    _lastActivityService.setLastTab(
      widget.book.id,
      _tabKeyForIndex(_tabController.index),
    );
  }

  String _tabKeyForIndex(int index) {
    switch (index) {
      case 0:
        return LastActivityService.tabMutn;
      case 1:
        return LastActivityService.tabSharh;
      case 2:
        return LastActivityService.tabLessons;
      default:
        return LastActivityService.tabMutn;
    }
  }

  Future<void> _maybeAutoOpen() async {
    if (_didAutoOpen) return;
    _didAutoOpen = true;

    if (widget.autoOpenSharhFile != null) {
      final sharh = widget.book.shuruh
          .where((s) => s.file == widget.autoOpenSharhFile)
          .firstOrNull();
      if (sharh == null) return;

      await _openSharhPdf(sharh);
      return;
    }

    if (widget.openLessonsOnStart) {
      await _openLessonsList();
    }
  }

  Future<void> _openSharhPdf(Sharh sharh) async {
    await _lastSharhService.save(widget.book.id, sharh.file);
    await _lastActivityService.setLastSharh(widget.book.id, sharh.file);

    final pdfPath = AppAssets.sharhPdf(widget.book.id, sharh.file);
    final pdfKey = _lastActivityService.pdfKeyForSharh(
      widget.book.id,
      sharh.file,
    );
    final initialPage = await _lastActivityService
        .getPdfPage(pdfKey)
        .then((info) => info?.page ?? 1);

    if (!mounted) return;

    await Navigator.push(
      context,
      buildFadeRoute(
        page: _SharhReaderPage(
          bookId: widget.book.id,
          sharh: sharh,
          pdfPath: pdfPath,
          pdfKey: pdfKey,
          initialPage: initialPage,
          progressService: _bookProgressService,
          lastActivityService: _lastActivityService,
        ),
      ),
    );

    await _loadLastSharh();
  }

  Future<void> _openLessonsList() async {
    if (widget.book.playlistId == null) return;

    await _lastActivityService.setLastTab(
      widget.book.id,
      LastActivityService.tabLessons,
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      buildFadeRoute(
        page: LessonsListPage(
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          lessons: Lesson.generateFromPlaylist(
            widget.book.playlistId!,
            count: _temporaryLessonsCount,
          ),
        ),
      ),
    );
  }

  void _goToMutn() {
    _tabController.animateTo(0);
    _lastActivityService.setLastTab(
      widget.book.id,
      LastActivityService.tabMutn,
    );
  }

  Future<void> _toggleBookmark() async {
    if (!_bookServiceReady) return;
    await _ensureBookInitialized(totalPages: _totalPages);
    final progress = await _bookProgressService.getBookProgress(widget.book.id);
    if (progress == null) return;

    if (progress.bookmarkedPages.contains(_currentPage)) {
      await _bookProgressService.removeBookmark(widget.book.id, _currentPage);
    } else {
      await _bookProgressService.addBookmark(widget.book.id, _currentPage);
    }

    if (!mounted) return;
    await _refreshBookmarkState();
  }

  void _showNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة ملاحظة', style: AppTextStyles.heading3),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            hintText: 'اكتب ملاحظتك هنا...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_bookServiceReady) return;
              await _ensureBookInitialized(totalPages: _totalPages);
              await _bookProgressService.saveNote(
                widget.book.id,
                _currentPage,
                _noteController.text,
              );
              _noteController.clear();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('تم حفظ الملاحظة')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showGlobalBookmarksList() async {
    if (!_bookServiceReady) return;
    final allProgress = await _bookProgressService.getAllProgress();
    final sharhBookmarks = await _bookProgressService.getAllSharhBookmarks();
    final sharhNotes = await _bookProgressService.getAllSharhNotes();
    final program = await AssetService.loadMutunProgram();

    final bookById = <String, IlmBook>{};
    final sharhByKey = <String, Sharh>{};
    for (final level in program.levels) {
      for (final book in level.books) {
        bookById[book.id] = book;
        for (final sharh in book.shuruh) {
          sharhByKey['${book.id}|${sharh.file}'] = sharh;
        }
      }
    }

    final entries = <_BookmarkEntry>[];

    for (final progress in allProgress) {
      final bookTitle = progress.bookTitle.isNotEmpty
          ? progress.bookTitle
          : (bookById[progress.bookId]?.title ?? progress.bookId);
      for (final page in progress.bookmarkedPages) {
        final note = progress.notes[page];
        entries.add(
          _BookmarkEntry(title: bookTitle, subtitle: 'صفحة $page', note: note),
        );
      }
    }

    for (final entry in sharhBookmarks.entries) {
      final sharh = sharhByKey[entry.key];
      final parts = entry.key.split('|');
      final bookId = parts.isNotEmpty ? parts.first : entry.key;
      final bookTitle = bookById[bookId]?.title ?? bookId;
      final sharhTitle = sharh?.title ?? 'شرح';
      final notes = sharhNotes[entry.key] ?? <int, String>{};
      for (final page in entry.value) {
        entries.add(
          _BookmarkEntry(
            title: bookTitle,
            subtitle: '$sharhTitle • صفحة $page',
            note: notes[page],
          ),
        );
      }
    }

    entries.sort((a, b) => a.title.compareTo(b.title));

    if (!mounted) return;
    if (entries.isEmpty) {
      AppSnackbar.info(context, AppStrings.bookProgressSaved);

      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإشارات المرجعية', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = entries[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 4),
                      Text(item.subtitle, style: AppTextStyles.caption),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(item.note!, style: AppTextStyles.bodySmall),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBar(
        title: widget.book.title,
        showBack: true,
        actions: [
          IconButton(
            tooltip: _isFavorite
                ? AppStrings.bookFavoriteRemove
                : AppStrings.bookFavoriteAdd,
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
          ),
          IconButton(
            tooltip: AppStrings.bookResetProgress,
            onPressed: _resetProgress,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
          ),
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textPrimary.withValues(alpha: 0.6),
          labelStyle: AppText.body.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppText.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
          indicatorPadding: const EdgeInsets.symmetric(
            horizontal: AppUi.gapMD,
            vertical: AppUi.gapXSPlus,
          ),
          tabs: const [
            Tab(text: AppStrings.bookMutnTab),
            Tab(text: AppStrings.bookSharhTab),
            Tab(text: AppStrings.bookLessonsTab),
          ],
        ),
      ),
      floatingActionButton: _showControls
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'bookmark_fab',
                  mini: true,
                  backgroundColor: _isBookmarked
                      ? AppColors.primary
                      : AppColors.surface,
                  onPressed: _toggleBookmark,
                  child: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'note_fab',
                  mini: true,
                  backgroundColor: AppColors.surface,
                  onPressed: _showNoteDialog,
                  child: const Icon(Icons.note_add, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'bookmarks_fab',
                  mini: true,
                  backgroundColor: AppColors.surface,
                  onPressed: _showGlobalBookmarksList,
                  child: const Icon(Icons.list, color: AppColors.primary),
                ),
              ],
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _mutunPdfPath.isEmpty
                ? Padding(
                    padding: AppUi.cardPadding,
                    child: EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: AppStrings.bookMutnEmptyTitle,
                      subtitle: AppStrings.bookMutnEmptyMessage,
                      actionLabel: AppStrings.actionBack,
                      onAction: () => Navigator.pop(context),
                    ),
                  )
                : FutureBuilder<int>(
                    future: _mutunInitialPage,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return PdfViewerPage(
                        key: _mutnPdfKey,
                        title: AppStrings.bookMutnTitle,
                        assetPath: _mutunPdfPath,
                        showAppBar: false,
                        initialPage: snapshot.data!,
                        onPageChanged: (page, total) async {
                          if (total <= 0) return;

                          final safeTotal = total < page ? page : total;

                          setState(() {
                            _currentPage = page;
                            _totalPages = safeTotal;
                            _isBookmarked = _bookmarkedPages.contains(page);
                          });

                          _updateReadingTime();

                          if (page > _maxPageReached) {
                            _maxPageReached = page;
                          }

                          _ensureBookInitialized(totalPages: safeTotal);

                          _lastActivityService.savePdfPage(
                            key: _mutunPdfKey,
                            page: page,
                            total: safeTotal,
                          );
                          _lastActivityService.savePdfPage(
                            key: _mutunPdfKey,
                            page: page,
                            total: safeTotal,
                          );
                          final reachedEnd = page >= safeTotal;

                          // hint (only once)
                          if (reachedEnd &&
                              !_canCompleteBook &&
                              !_hasShownReadHint) {
                            _hasShownReadHint = true;

                            AppSnackbar.info(
                              context,
                              'لإتمام الكتاب، يرجى قراءته بتأنٍ وعدم الاكتفاء بالانتقال السريع بين الصفحات 📖',
                            );
                          }

                          // ✅ completion (one-time)
                          if (reachedEnd && _canCompleteBook) {
                            final justCompleted = await _bookProgressService
                                .markCompleted(widget.book.id);

                            if (justCompleted && context.mounted) {
                              HapticFeedback.selectionClick();
                              AppPopup.show(
                                context: context,
                                title: 'اكتمل الكتاب',
                                message: AppStrings.bookProgressSaved,
                                icon: Icons.check_circle_rounded,
                              );
                            }
                          }
                        },
                      );
                    },
                  ),

            widget.book.shuruh.isEmpty
                ? Padding(
                    padding: AppUi.cardPadding,
                    child: EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: AppStrings.bookSharhEmptyTitle,
                      subtitle: AppStrings.bookSharhEmptyMessage,
                      actionLabel: AppStrings.bookSharhEmptyAction,
                      onAction: _goToMutn,
                    ),
                  )
                : Column(
                    children: [
                      if (_lastSharh != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppUi.paddingMD,
                            AppUi.paddingMD,
                            AppUi.paddingMD,
                            0,
                          ),
                          child: _ContinueSharhCard(
                            sharh: _lastSharh!,
                            pageInfo: _lastSharhPage,
                            onTap: () => _openSharhPdf(_lastSharh!),
                          ),
                        ),
                      if (_lastSharh != null)
                        const SizedBox(height: AppUi.gapMD),
                      Expanded(
                        child: ListView.separated(
                          padding: AppUi.cardPadding,
                          itemCount: widget.book.shuruh.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppUi.gapMD),
                          itemBuilder: (context, index) {
                            final sharh = widget.book.shuruh[index];

                            return SharhCard(
                              title: sharh.title,
                              scholar: sharh.scholar,
                              difficulty: _difficultyLabel(index),
                              recommended: index == 0,
                              isLastRead: sharh.file == _lastSharhFile,
                              onTap: () => _openSharhPdf(sharh),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

            widget.book.playlistId == null
                ? Padding(
                    padding: AppUi.cardPadding,
                    child: EmptyState(
                      icon: Icons.ondemand_video_outlined,
                      title: AppStrings.bookLessonsEmptyTitle,
                      subtitle: AppStrings.bookLessonsEmptyMessage,
                      actionLabel: AppStrings.bookLessonsEmptyAction,
                      onAction: _goToMutn,
                    ),
                  )
                : Center(
                    child: FilledButton(
                      onPressed: _openLessonsList,
                      child: Text(
                        AppStrings.bookShowLessons,
                        style: AppText.body,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _difficultyLabel(int index) {
    if (index == 0) return AppStrings.difficultyBeginner;
    if (index == 1) return AppStrings.difficultyIntermediate;
    return AppStrings.difficultyAdvanced;
  }
}

extension on Iterable<Sharh> {
  Sharh? firstOrNull() => isEmpty ? null : first;
}

class _ContinueSharhCard extends StatelessWidget {
  final Sharh sharh;
  final PdfPageInfo? pageInfo;
  final VoidCallback onTap;

  const _ContinueSharhCard({
    required this.sharh,
    required this.pageInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawPage = pageInfo?.page;
    final rawTotal = pageInfo?.total ?? 0;
    final safeTotal = rawPage != null && rawTotal > 0 && rawTotal < rawPage
        ? rawPage
        : (rawTotal > 0 ? rawTotal : null);
    final safePage = rawPage != null && safeTotal != null
        ? rawPage.clamp(1, safeTotal)
        : rawPage;
    final pageLabel = pageInfo == null
        ? AppStrings.continueSharh
        : AppStrings.lastPage(safePage ?? 1, safeTotal);

    return PressableCard(
      onTap: onTap,
      padding: AppUi.cardPadding,
      borderRadius: BorderRadius.circular(AppUi.radiusMD),
      decoration: BoxDecoration(
        gradient: AppColors.surfaceElevatedGradient,
        borderRadius: BorderRadius.circular(AppUi.radiusMD),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: AppColors.primary),
          const SizedBox(width: AppUi.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sharh.title, style: AppText.heading),
                const SizedBox(height: AppUi.gapXSPlus),
                Text(
                  pageLabel,
                  style: AppText.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SharhReaderPage extends StatefulWidget {
  final String bookId;
  final Sharh sharh;
  final String pdfPath;
  final String pdfKey;
  final int initialPage;
  final BookProgressService progressService;
  final LastActivityService lastActivityService;

  const _SharhReaderPage({
    required this.bookId,
    required this.sharh,
    required this.pdfPath,
    required this.pdfKey,
    required this.initialPage,
    required this.progressService,
    required this.lastActivityService,
  });

  @override
  State<_SharhReaderPage> createState() => _SharhReaderPageState();
}

class _SharhReaderPageState extends State<_SharhReaderPage> {
  final TextEditingController _noteController = TextEditingController();
  final Set<int> _bookmarkedPages = <int>{};
  Map<int, String> _notes = <int, String>{};
  int _currentPage = 1;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage < 1 ? 1 : widget.initialPage;
    _loadSharhData();
  }

  Future<void> _loadSharhData() async {
    final pages = await widget.progressService.getSharhBookmarks(
      widget.bookId,
      widget.sharh.file,
    );
    final notes = await widget.progressService.getSharhNotes(
      widget.bookId,
      widget.sharh.file,
    );
    if (!mounted) return;
    setState(() {
      _bookmarkedPages
        ..clear()
        ..addAll(pages);
      _notes = notes;
      _isBookmarked = _bookmarkedPages.contains(_currentPage);
    });
  }

  void _handlePageChanged(int page, int total) {
    if (total <= 0) return;
    final safeTotal = total < page ? page : total;
    setState(() {
      _currentPage = page;
      _isBookmarked = _bookmarkedPages.contains(page);
    });
    widget.lastActivityService.savePdfPage(
      key: widget.pdfKey,
      page: page,
      total: safeTotal,
    );
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkedPages.contains(_currentPage)) {
      await widget.progressService.removeSharhBookmark(
        widget.bookId,
        widget.sharh.file,
        _currentPage,
      );
    } else {
      await widget.progressService.addSharhBookmark(
        widget.bookId,
        widget.sharh.file,
        _currentPage,
      );
    }
    await _loadSharhData();
  }

  void _showNoteDialog() {
    _noteController.text = _notes[_currentPage] ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة ملاحظة', style: AppTextStyles.heading3),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            hintText: 'اكتب ملاحظتك هنا...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.progressService.saveSharhNote(
                widget.bookId,
                widget.sharh.file,
                _currentPage,
                _noteController.text,
              );
              _noteController.clear();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              await _loadSharhData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ الملاحظة')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showBookmarksList() {
    if (_bookmarkedPages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد إشارات مرجعية')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إشارات الشرح', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  final pages = _bookmarkedPages.toList()..sort();
                  return ListView.separated(
                    itemCount: pages.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      final note = _notes[page];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('صفحة $page', style: AppTextStyles.bodyMedium),
                          if (note != null && note.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(note, style: AppTextStyles.bodySmall),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewerPage(
      title: widget.sharh.title,
      assetPath: widget.pdfPath,
      initialPage: widget.initialPage,
      onPageChanged: _handlePageChanged,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'sharh_bookmark_fab',
            mini: true,
            backgroundColor: _isBookmarked
                ? AppColors.primary
                : AppColors.surface,
            onPressed: _toggleBookmark,
            child: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'sharh_note_fab',
            mini: true,
            backgroundColor: AppColors.surface,
            onPressed: _showNoteDialog,
            child: const Icon(Icons.note_add, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'sharh_bookmarks_fab',
            mini: true,
            backgroundColor: AppColors.surface,
            onPressed: _showBookmarksList,
            child: const Icon(Icons.list, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _BookmarkEntry {
  final String title;
  final String subtitle;
  final String? note;

  const _BookmarkEntry({
    required this.title,
    required this.subtitle,
    this.note,
  });
}
