import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/last_activity_service.dart';
import 'package:talib_ilm/core/services/last_sharh_service.dart';
import 'package:talib_ilm/shared/widgets/app_popup.dart';
import 'package:talib_ilm/shared/widgets/app_snackbar.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../app/theme/theme_colors.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/sharh_model.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../../../core/services/progress_service.dart';
import '../../../ilm/data/models/progress_models.dart';
import '../../data/catalogs/mutun_lessons_catalog.dart';
import '../../data/catalogs/turath_catalog.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';
import 'shamela_reader_page.dart';
import 'sharh_reader_page.dart';
import '../widgets/book_lessons_tab.dart';
import '../widgets/book_mutn_tab.dart';
import '../widgets/book_sharh_tab.dart';
import '../widgets/book_view_bookmarks_sheet.dart';
import '../widgets/book_view_app_bar.dart';
import '../widgets/book_view_controls.dart' show BookNoteDialog;
import '../../../../core/services/favorites_service.dart';
import '../../../../core/models/favorite_item.dart';
import '../../../../core/services/asset_service.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/services/book_progress_service.dart';
import '../../data/services/mutun_audio_service.dart';

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
  BookProgressService? _bookProgressService;
  late Timer _readingTimer;
  int _sessionMinutes = 0;
  bool _showControls = true;
  final TextEditingController _noteController = TextEditingController();
  final Set<int> _bookmarkedPages = <int>{};
  bool _isBookmarked = false;
  int _currentPage = 1;
  int _totalPages = 0;
  String _bookLevelLabel = 'غير محدد';
  String? _lastSharhFile;
  Sharh? _lastSharh;
  PdfPageInfo? _lastSharhPage;
  final Map<String, int> _shuruhPages = <String, int>{};
  late final String _mutunPdfKey;
  late final Future<int> _mutunInitialPage;
  bool _isFavorite = false;
  late final TabController _tabController;
  int _lastTabIndex = 0;
  bool _didAutoOpen = false;
  int _maxPageReached = 1;
  DateTime? _readingStart;
  int _readingSeconds = 0;
  bool get _canCompleteBook {
    if (_totalPages <= 1) return false;
    return (_maxPageReached / _totalPages) >= 0.95 && _readingSeconds >= 120;
  }

  void _updateReadingTime() {
    if (_readingStart == null) return;
    final now = DateTime.now();
    _readingSeconds += now.difference(_readingStart!).inSeconds;
    _readingStart = now;
  }

  Future<BookProgressService> _getProgressService() async {
    if (_bookProgressService != null) return _bookProgressService!;
    final prefs = await SharedPreferences.getInstance();
    _bookProgressService = BookProgressService(prefs);
    return _bookProgressService!;
  }

  Future<int> _resolveInitialMutunPage(MutunDigitalEntry? digitalEntry) async {
    int resolvedPage = 1;

    try {
      final info = await _lastActivityService.getPdfPage(_mutunPdfKey);
      if (info != null && info.page > resolvedPage) {
        resolvedPage = info.page;
      }
    } catch (_) {}

    try {
      final progressService = await _getProgressService();
      final progress = await progressService.getBookProgress(widget.book.id);
      if (progress != null && progress.currentPage > resolvedPage) {
        resolvedPage = progress.currentPage;
      }
    } catch (_) {}

    if (digitalEntry != null) {
      try {
        final shamelaPage =
            await ShamelaService.getLastReadPage(digitalEntry.shamelaId);
        if (shamelaPage > resolvedPage) {
          resolvedPage = shamelaPage;
        }
      } catch (_) {}
    }

    final maxPage = _totalPages > 0
        ? _totalPages
        : (digitalEntry?.totalPages ??
            (widget.book.totalPages > 0 ? widget.book.totalPages : 1));
    final safePage = resolvedPage.clamp(1, maxPage);
    _currentPage = safePage;
    return safePage;
  }

  @override
  void initState() {
    super.initState();
    final digitalEntry = MutunDigitalCatalog.getEntry(widget.book.id);
    final fallbackTotal = (digitalEntry != null && digitalEntry.totalPages > 0)
        ? digitalEntry.totalPages
        : (widget.book.totalPages > 0 ? widget.book.totalPages : 0);
    _totalPages = fallbackTotal;

    _mutunPdfKey = _lastActivityService.pdfKeyForMutn(widget.book.id);
    _mutunInitialPage = _resolveInitialMutunPage(digitalEntry);
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
    await _getProgressService();
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
    final progressService = await _getProgressService();
    final digitalEntry = MutunDigitalCatalog.getEntry(widget.book.id);
    final canonicalTotal = (digitalEntry != null && digitalEntry.totalPages > 0)
        ? digitalEntry.totalPages
        : (widget.book.totalPages > 0 ? widget.book.totalPages : 0);
    final pages = totalPages ?? _totalPages;
    final safePages = pages > canonicalTotal
        ? pages
        : (canonicalTotal > 0 ? canonicalTotal : (pages <= 0 ? 1 : pages));

    await progressService.initializeBook(
      bookId: widget.book.id,
      bookTitle: widget.book.title,
      level: _bookLevelLabel,
      totalPages: safePages,
    );
  }

  Future<void> _refreshBookmarkState() async {
    final progressService = await _getProgressService();
    final progress = await progressService.getBookProgress(widget.book.id);
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
    final progressService = await _getProgressService();
    await _ensureBookInitialized(totalPages: _totalPages);
    await progressService.updateCurrentPage(
      widget.book.id,
      _currentPage,
      totalPages: _totalPages > 0 ? _totalPages : null,
    );
    if (_sessionMinutes == 0) return;
    await progressService.addReadingTime(widget.book.id, _sessionMinutes);
    _sessionMinutes = 0;
  }

  void _persistLastPositionSync() {
    _lastActivityService.savePdfPage(
      key: _mutunPdfKey,
      page: _currentPage,
      total: _totalPages > 0 ? _totalPages : 1,
    );
    final digitalEntry = MutunDigitalCatalog.getEntry(widget.book.id);
    if (digitalEntry != null) {
      ShamelaService.saveLastReadPage(digitalEntry.shamelaId, _currentPage);
    }
  }

  @override
  void dispose() {
    MutunAudioService().pause();
    _readingTimer.cancel();
    _persistLastPositionSync();
    _saveProgress();
    _noteController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSharh() async {
    final file = await _lastSharhService.get(widget.book.id);
    if (!mounted) return;

    final sharh = widget.book.shuruh.where((s) => s.file == file).firstOrNull;

    final Map<String, int> pages = {};
    for (final s in widget.book.shuruh) {
      if (s.shamelaId != null) {
        final page = await ShamelaService.getLastReadPage(s.shamelaId!);
        if (page > 1) {
          pages[s.file] = page;
        }
      } else {
        final key = _lastActivityService.pdfKeyForSharh(widget.book.id, s.file);
        final pageInfo = await _lastActivityService.getPdfPage(key);
        if (pageInfo != null && pageInfo.page > 1) {
          pages[s.file] = pageInfo.page;
        }
      }
    }

    PdfPageInfo? info;
    if (file != null) {
      if (sharh != null && sharh.shamelaId != null) {
        final page =
            pages[file] ?? await ShamelaService.getLastReadPage(sharh.shamelaId!);
        final total = sharh.totalPages ?? 50;
        info = PdfPageInfo(page: page, total: total);
      } else {
        final key = _lastActivityService.pdfKeyForSharh(widget.book.id, file);
        info = await _lastActivityService.getPdfPage(key);
      }
    }

    if (!mounted) return;
    setState(() {
      _lastSharhFile = file;
      _lastSharh = sharh;
      _lastSharhPage = info;
      _shuruhPages
        ..clear()
        ..addAll(pages);
    });
  }

  Future<void> _loadFavorite() async {
    final saved = await _favoritesService.isFavorite(
      FavoriteType.book,
      widget.book.id,
    );
    final progressService = await _getProgressService();
    await progressService.setFavorite(widget.book.id, saved);
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
    final progressService = await _getProgressService();
    await progressService.setFavorite(widget.book.id, saved);
    if (!mounted) return;
    setState(() => _isFavorite = saved);

    if (saved) {
      AppSnackbar.success(context, 'تمت إضافة الكتاب إلى المفضلة (قائمة المحفوظات)');
    } else {
      AppSnackbar.info(context, 'تمت إزالة الكتاب من المفضلة');
    }
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
    final progressService = await _getProgressService();
    await progressService.resetBook(widget.book.id);

    if (!mounted) return;

    setState(() {
      _currentPage = 1;
      _totalPages = 0;
      _maxPageReached = 1;
      _readingSeconds = 0;
      _bookmarkedPages.clear();
      _isBookmarked = false;
    });

    _mutnPdfKey.currentState?.resetToStart();

    HapticFeedback.mediumImpact();
    AppSnackbar.success(context, 'تمت إعادة تعيين تقدم الكتاب');
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _handleTabChange() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    if (_tabController.index != 0) {
      MutunAudioService().pause();
    }
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
          .firstOrNull;
      if (sharh == null) return;

      await _openSharhPdf(sharh);
      return;
    }

    if (widget.openLessonsOnStart) {
      _tabController.animateTo(2);
    }
  }

  Future<void> _openSharhPdf(Sharh sharh) async {
    await _lastSharhService.save(widget.book.id, sharh.file);
    await _lastActivityService.setLastSharh(widget.book.id, sharh.file);

    if (sharh.shamelaId != null) {
      final match = TurathCatalog.books
          .where((b) => b.id == sharh.shamelaId)
          .firstOrNull;
      final totalPages = sharh.totalPages ?? match?.totalPages ?? 50;
      final shamelaBook = match?.copyWith(totalPages: totalPages) ??
          ShamelaBook(
            id: sharh.shamelaId!,
            title: sharh.title,
            author: sharh.scholar,
            category: 'شروح المتون',
            categoryId: 1,
            totalPages: totalPages,
            description: sharh.description ?? sharh.title,
          );

      final initialPage =
          await ShamelaService.getLastReadPage(sharh.shamelaId!);

      if (!mounted) return;

      await Navigator.push(
        context,
        buildFadeRoute(
          page: ShamelaReaderPage(
            book: shamelaBook,
            initialPage: initialPage,
          ),
        ),
      );

      await _loadLastSharh();
      return;
    }

    final pdfPath = AppAssets.sharhPdf(widget.book.id, sharh.file);
    final pdfKey = _lastActivityService.pdfKeyForSharh(
      widget.book.id,
      sharh.file,
    );
    final initialPage = await _lastActivityService
        .getPdfPage(pdfKey)
        .then((info) => info?.page ?? 1);

    final progressService = await _getProgressService();
    if (!mounted) return;

    await Navigator.push(
      context,
      buildFadeRoute(
        page: SharhReaderPage(
          bookId: widget.book.id,
          sharh: sharh,
          pdfPath: pdfPath,
          pdfKey: pdfKey,
          initialPage: initialPage,
          progressService: progressService,
          lastActivityService: _lastActivityService,
        ),
      ),
    );

    await _loadLastSharh();
  }

  void _goToMutn() {
    _tabController.animateTo(0);
    _lastActivityService.setLastTab(
      widget.book.id,
      LastActivityService.tabMutn,
    );
  }

  Future<void> _toggleBookmark() async {
    final progressService = await _getProgressService();
    await _ensureBookInitialized(totalPages: _totalPages);
    final progress = await progressService.getBookProgress(widget.book.id);
    if (progress == null) return;

    if (progress.bookmarkedPages.contains(_currentPage)) {
      await progressService.removeBookmark(widget.book.id, _currentPage);
    } else {
      await progressService.addBookmark(widget.book.id, _currentPage);
    }

    if (!mounted) return;
    await _refreshBookmarkState();
  }

  void _showNoteDialog() {
    BookNoteDialog.show(
      context,
      controller: _noteController,
      onSave: () async {
        final progressService = await _getProgressService();
        await _ensureBookInitialized(totalPages: _totalPages);
        await progressService.saveNote(
          widget.book.id,
          _currentPage,
          _noteController.text,
        );
        _noteController.clear();
        if (!mounted) return;
        Navigator.of(context).pop();
        AppSnackbar.success(context, 'تم حفظ الملاحظة');
      },
    );
  }

  void _showGlobalBookmarksList() async {
    final progressService = await _getProgressService();
    if (!mounted) return;
    await BookViewBookmarksSheet.loadAndShow(
      context: context,
      progressService: progressService,
    );
  }

  Future<void> _onMutnPageChanged(int page, int total) async {
    if (total <= 0) return;

    final digitalEntry = MutunDigitalCatalog.getEntry(widget.book.id);
    final canonicalTotal = (digitalEntry != null && digitalEntry.totalPages > 0)
        ? digitalEntry.totalPages
        : (widget.book.totalPages > 0 ? widget.book.totalPages : total);
    final safeTotal = canonicalTotal > 0 ? canonicalTotal : total;

    setState(() {
      _currentPage = page;
      _totalPages = safeTotal;
      _isBookmarked = _bookmarkedPages.contains(page);
    });

    _updateReadingTime();

    if (page > _maxPageReached) {
      _maxPageReached = page;
    }

    // Persist immediately across both storage systems
    _lastActivityService.savePdfPage(
      key: _mutunPdfKey,
      page: page,
      total: safeTotal,
    );
    if (digitalEntry != null) {
      ShamelaService.saveLastReadPage(digitalEntry.shamelaId, page);
    }

    final progressService = await _getProgressService();
    await _ensureBookInitialized(totalPages: safeTotal);
    await progressService.updateCurrentPage(
      widget.book.id,
      page,
      totalPages: safeTotal,
    );

    final reachedEnd = safeTotal > 1 && page >= safeTotal;
    if (!mounted) return;

    // completion (one-time when actually completed)
    if (reachedEnd && _canCompleteBook) {
      final justCompleted = await progressService.markCompleted(
        widget.book.id,
      );

      if (justCompleted && mounted) {
        HapticFeedback.selectionClick();
        AppPopup.show(
          context: context,
          title: 'اكتمل الكتاب',
          message: AppStrings.bookProgressSaved,
          icon: Icons.check_circle_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final topBarHeight = topPadding + kToolbarHeight + 48.0;
    final minimalBarHeight = topPadding + 42.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveProgress();
        _persistLastPositionSync();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: context.palette.bg,
        floatingActionButton: null,
      body: Column(
        children: [
          AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.easeOut,
            height: _showControls ? topBarHeight : minimalBarHeight,
            decoration: BoxDecoration(
              color: _showControls ? context.palette.surfaceRaised : context.palette.bg,
              border: Border(
                bottom: BorderSide(
                  color: _showControls
                      ? context.palette.border
                      : context.palette.border.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
            ),
            child: ClipRect(
              child: Stack(
                children: [
                  // Minimal header when controls hidden
                  Positioned(
                    top: topPadding,
                    left: AppSpace.md,
                    right: AppSpace.md,
                    height: 42.0,
                    child: AnimatedOpacity(
                      duration: AppMotion.fast,
                      curve: AppMotion.easeOut,
                      opacity: _showControls ? 0.0 : 1.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              widget.book.title,
                              style: context.text.titleSmall.copyWith(
                                color: context.palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: context.palette.goldSoft,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: context.palette.gold.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'صفحة $_currentPage من $_totalPages',
                              style: context.text.caption.copyWith(
                                color: context.palette.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Full App Bar when controls visible
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topBarHeight,
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: AnimatedOpacity(
                        duration: AppMotion.fast,
                        curve: AppMotion.easeOut,
                        opacity: _showControls ? 1.0 : 0.0,
                        child: BookViewAppBar(
                          title: widget.book.title,
                          isFavorite: _isFavorite,
                          onToggleFavorite: _toggleFavorite,
                          onResetProgress: _resetProgress,
                          tabController: _tabController,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
            BookMutnTab(
              book: widget.book,
              mutunInitialPage: _mutunInitialPage,
              onPageChanged: _onMutnPageChanged,
              showControls: _showControls,
              onToggleControls: _toggleControls,
              isBookmarked: _isBookmarked,
              onToggleBookmark: _toggleBookmark,
              onAddNote: _showNoteDialog,
              onShowBookmarks: _showGlobalBookmarksList,
            ),

            BookSharhTab(
              shuruh: widget.book.shuruh,
              lastSharh: _lastSharh,
              lastSharhPage: _lastSharhPage,
              lastSharhFile: _lastSharhFile,
              shuruhPages: _shuruhPages,
              onGoToMutn: _goToMutn,
              onOpenSharh: _openSharhPdf,
            ),

            BookLessonsTab(
              bookId: widget.book.id,
              bookTitle: widget.book.title,
              lessons: MutunLessonsCatalog.getLessonsForBook(
                widget.book.id,
                fallbackPlaylist: widget.book.playlistId,
              ),
              onGoToMutn: _goToMutn,
            ),
          ],
        ),
      ),
    ],
  ),
),
);
}

}
