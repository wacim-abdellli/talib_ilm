import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/services/last_activity_service.dart';
import '../../../../core/services/last_sharh_service.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../shared/widgets/app_popup.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/catalogs/mutun_lessons_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/progress_models.dart';
import '../../data/models/sharh_model.dart';
import '../../data/services/book_progress_service.dart';
import '../../data/services/mutun_audio_service.dart';
import '../services/book_view_navigation_helper.dart';
import '../services/book_view_note_coordinator.dart';
import '../services/book_view_persistence_delegate.dart';
import '../services/book_view_sharh_navigator.dart';
import '../widgets/book_lessons_tab.dart';
import '../widgets/book_mutn_tab.dart';
import '../widgets/book_sharh_tab.dart';
import '../widgets/book_view_bookmarks_sheet.dart';
import '../widgets/book_view_header.dart';

class BookViewPage extends StatefulWidget {
  final IlmBook book;
  final int initialTabIndex;
  final String? autoOpenSharhFile;
  final bool openLessonsOnStart;
  final int? initialPage;

  const BookViewPage({
    super.key,
    required this.book,
    this.initialTabIndex = 0,
    this.autoOpenSharhFile,
    this.openLessonsOnStart = false,
    this.initialPage,
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
  int? _targetParagraph;
  Object? _targetParagraphKey;
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
    final progressService = await _getProgressService();
    final safePage = await BookViewPersistenceDelegate.resolveInitialMutunPage(
      book: widget.book,
      initialPage: widget.initialPage,
      totalPages: _totalPages,
      mutunPdfKey: _mutunPdfKey,
      lastActivityService: _lastActivityService,
      progressService: progressService,
      digitalEntry: digitalEntry,
    );
    _currentPage = safePage;
    return safePage;
  }

  @override
  void initState() {
    super.initState();
    _targetParagraph = widget.initialPage;
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
    final title = await BookViewPersistenceDelegate.resolveBookLevel(widget.book.id);
    _bookLevelLabel = title;
  }

  Future<void> _ensureBookInitialized({int? totalPages}) async {
    final progressService = await _getProgressService();
    await BookViewPersistenceDelegate.ensureBookInitialized(
      book: widget.book,
      bookLevelLabel: _bookLevelLabel,
      totalPages: totalPages ?? _totalPages,
      progressService: progressService,
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

  void _persistLastPositionSync() =>
      BookViewPersistenceDelegate.persistLastPositionSync(
        bookId: widget.book.id,
        mutunPdfKey: _mutunPdfKey,
        currentPage: _currentPage,
        totalPages: _totalPages,
        lastActivityService: _lastActivityService,
      );

  @override
  void dispose() {
    _readingTimer.cancel();
    _persistLastPositionSync();
    _saveProgress();
    _noteController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSharh() async {
    final state = await BookViewSharhNavigator.loadSharhState(
      book: widget.book,
      lastSharhService: _lastSharhService,
      lastActivityService: _lastActivityService,
    );
    if (!mounted) return;
    setState(() {
      _lastSharhFile = state.lastSharhFile;
      _lastSharh = state.lastSharh;
      _lastSharhPage = state.lastSharhPage;
      _shuruhPages
        ..clear()
        ..addAll(state.shuruhPages);
    });
  }

  Future<void> _loadFavorite() async {
    final progressService = await _getProgressService();
    final saved = await BookViewPersistenceDelegate.loadFavorite(
      bookId: widget.book.id,
      favoritesService: _favoritesService,
      progressService: progressService,
    );
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

  Future<void> _toggleFavorite() async {
    final progressService = await _getProgressService();
    final saved = await BookViewPersistenceDelegate.toggleFavorite(
      book: widget.book,
      favoritesService: _favoritesService,
      progressService: progressService,
    );
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

  Future<void> _openSharhPdf(Sharh sharh) =>
      BookViewSharhNavigator.openSharh(
        context: context,
        book: widget.book,
        sharh: sharh,
        lastSharhService: _lastSharhService,
        lastActivityService: _lastActivityService,
        getProgressService: _getProgressService,
        onReload: _loadLastSharh,
      );

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

    final targetPage = _currentPage > 0 ? _currentPage : 1;
    if (progress.bookmarkedPages.contains(targetPage)) {
      await progressService.removeBookmark(widget.book.id, targetPage);
      if (mounted) {
        AppSnackbar.info(context, 'تمت إزالة الإشارة المرجعية (صفحة $targetPage)');
      }
    } else {
      await progressService.addBookmark(widget.book.id, targetPage);
      if (mounted) {
        AppSnackbar.success(context, 'تم حفظ الإشارة المرجعية (صفحة $targetPage)');
      }
    }

    if (!mounted) return;
    await _refreshBookmarkState();
  }

  void _showNoteDialog() => BookViewNoteCoordinator.showNoteDialog(
        context: context,
        bookId: widget.book.id,
        currentPage: _currentPage,
        totalPages: _totalPages,
        noteController: _noteController,
        getProgressService: _getProgressService,
        ensureBookInitialized: _ensureBookInitialized,
        onShowBookmarksAndNotes: _showBookmarksAndNotes,
      );

  void _showBookmarksAndNotes({int initialTab = 0}) async {
    final progressService = await _getProgressService();
    if (!mounted) return;
    await BookViewBookmarksSheet.loadAndShow(
      context: context,
      progressService: progressService,
      currentBookId: widget.book.id,
      initialTab: initialTab,
      onSelectEntry: _navigateToEntry,
    );
  }

  void _navigateToEntry(BookmarkEntry entry) =>
      BookViewNavigationHelper.navigateToEntry(
        context: context,
        entry: entry,
        currentBook: widget.book,
        tabController: _tabController,
        mutnPdfKey: _mutnPdfKey,
        bookmarkedPages: _bookmarkedPages,
        onUpdateMutnState: ({
          required int targetParagraph,
          required int currentPage,
          required int totalPages,
          required bool isBookmarked,
        }) {
          setState(() {
            _targetParagraph = targetParagraph;
            _targetParagraphKey = Object();
            _currentPage = currentPage;
            _totalPages = totalPages;
            _isBookmarked = isBookmarked;
          });
        },
        onOpenSharh: _openSharhPdf,
      );

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
    _persistLastPositionSync();

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
          BookViewHeader(
            showControls: _showControls,
            bookTitle: widget.book.title,
            currentPage: _currentPage,
            totalPages: _totalPages,
            isFavorite: _isFavorite,
            onToggleFavorite: _toggleFavorite,
            onResetProgress: _resetProgress,
            onShowBookmarksAndNotes: () => _showBookmarksAndNotes(),
            tabController: _tabController,
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
              onShowBookmarks: () => _showBookmarksAndNotes(),
              targetParagraph: _targetParagraph,
              targetScrollKey: _targetParagraphKey,
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
