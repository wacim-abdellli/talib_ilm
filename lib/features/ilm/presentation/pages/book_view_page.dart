import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/last_activity_service.dart';
import 'package:talib_ilm/core/services/last_sharh_service.dart';
import 'package:talib_ilm/shared/widgets/app_popup.dart';
import 'package:talib_ilm/shared/widgets/app_snackbar.dart';
import '../../data/models/lesson_model.dart';

import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/theme_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/sharh_model.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/services/progress_service.dart';
import '../../../ilm/data/models/progress_models.dart';
import 'lessons_list_page.dart';
import 'sharh_reader_page.dart';
import '../widgets/book_mutn_tab.dart';
import '../widgets/book_sharh_tab.dart';
import '../widgets/book_view_bookmarks_sheet.dart';
import '../widgets/book_view_controls.dart';
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
        page: SharhReaderPage(
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
    BookNoteDialog.show(
      context,
      controller: _noteController,
      onSave: () async {
        if (!_bookServiceReady) return;
        await _ensureBookInitialized(totalPages: _totalPages);
        await _bookProgressService.saveNote(
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

    final entries = <BookmarkEntry>[];

    for (final progress in allProgress) {
      final bookTitle = progress.bookTitle.isNotEmpty
          ? progress.bookTitle
          : (bookById[progress.bookId]?.title ?? progress.bookId);
      for (final page in progress.bookmarkedPages) {
        final note = progress.notes[page];
        entries.add(
          BookmarkEntry(title: bookTitle, subtitle: 'صفحة $page', note: note),
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
          BookmarkEntry(
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

    BookViewBookmarksSheet.show(context, entries);
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
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isFavorite ? context.palette.gold : context.palette.text,
            ),
          ),
          IconButton(
            tooltip: AppStrings.bookResetProgress,
            onPressed: _resetProgress,
            icon: Icon(Icons.refresh_rounded, color: context.palette.text),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: context.palette.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          labelColor: context.palette.onPrimarySoft,
          unselectedLabelColor: context.palette.textMuted,
          labelStyle: context.text.label,
          unselectedLabelStyle: context.text.label.copyWith(
            fontWeight: FontWeight.w500,
          ),
          indicatorPadding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs,
          ),
          tabs: const [
            Tab(text: AppStrings.bookMutnTab),
            Tab(text: AppStrings.bookSharhTab),
            Tab(text: AppStrings.bookLessonsTab),
          ],
        ),
      ),
      floatingActionButton: _showControls
          ? BookViewControls(
              isBookmarked: _isBookmarked,
              onToggleBookmark: _toggleBookmark,
              onAddNote: _showNoteDialog,
              onShowBookmarks: _showGlobalBookmarksList,
            )
          : null,
      body: Container(
        color: context.backgroundColor,
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            BookMutnTab(
              mutunPdfPath: _mutunPdfPath,
              mutunInitialPage: _mutunInitialPage,
              mutnPdfKey: _mutnPdfKey,
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
                final reachedEnd = page >= safeTotal;

                // hint (only once)
                if (reachedEnd && !_canCompleteBook && !_hasShownReadHint) {
                  _hasShownReadHint = true;

                  AppSnackbar.info(
                    context,
                    'لإتمام الكتاب، يرجى قراءته بتأنٍ وعدم الاكتفاء بالانتقال السريع بين الصفحات 📖',
                  );
                }

                // ✅ completion (one-time)
                if (reachedEnd && _canCompleteBook) {
                  final justCompleted = await _bookProgressService.markCompleted(
                    widget.book.id,
                  );

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
            ),

            BookSharhTab(
              shuruh: widget.book.shuruh,
              lastSharh: _lastSharh,
              lastSharhPage: _lastSharhPage,
              lastSharhFile: _lastSharhFile,
              onGoToMutn: _goToMutn,
              onOpenSharh: _openSharhPdf,
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
}

extension on Iterable<Sharh> {
  Sharh? firstOrNull() => isEmpty ? null : first;
}
