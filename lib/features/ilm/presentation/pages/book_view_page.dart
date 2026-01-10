import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talib_ilm/core/services/last_sharh_service.dart';
import 'package:talib_ilm/core/services/last_activity_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/sharh_card.dart';
import '../../data/models/lesson_model.dart';

import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
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
  final ProgressService _progressService = ProgressService();
  final LastSharhService _lastSharhService = LastSharhService();
  final LastActivityService _lastActivityService = LastActivityService();
  final FavoritesService _favoritesService = FavoritesService();
  String? _lastSharhFile;
  Sharh? _lastSharh;
  PdfPageInfo? _lastSharhPage;
  static const int _temporaryLessonsCount = 10; // 🔧 TEMP
  late final String _mutunPdfPath;
  late final String _mutunPdfKey;
  late final Future<int> _mutunInitialPage;
  bool _mutunActivityMarked = false;
  bool _isBookCompleted = false;
  bool _isFavorite = false;
  late final TabController _tabController;
  int _lastTabIndex = 0;
  bool _didAutoOpen = false;

  @override
  void initState() {
    super.initState();
    _mutunPdfPath = AppAssets.mutunPdf(widget.book.id);
    _mutunPdfKey = _lastActivityService.pdfKeyForMutn(widget.book.id);
    _mutunInitialPage = _lastActivityService
        .getPdfPage(_mutunPdfKey)
        .then((info) => info?.page ?? 1);
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoOpen());
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSharh() async {
    final file = await _lastSharhService.get(widget.book.id);
    if (!mounted) return;

    final sharh = widget.book.shuruh
        .where((s) => s.file == file)
        .firstOrNull();

    PdfPageInfo? info;
    if (file != null) {
      final key = _lastActivityService.pdfKeyForSharh(
        widget.book.id,
        file,
      );
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
    final existing = await _progressService.getProgress(widget.book.id);

    if (existing == null) {
      await _progressService.saveProgress(
        BookProgress(
          bookId: widget.book.id,
          status: BookProgressStatus.inProgress,
          completedLessons: 0,
          totalLessons: 0,
        ),
      );
    } else {
      _isBookCompleted = existing.status == BookProgressStatus.completed;
    }
  }

  Future<void> _resetProgress() async {
    await _progressService.saveProgress(
      BookProgress(
        bookId: widget.book.id,
        status: BookProgressStatus.notStarted,
        completedLessons: 0,
        totalLessons: 0,
      ),
    );
    if (!mounted) return;
    setState(() {
      _isBookCompleted = false;
    });
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
    final pdfKey =
        _lastActivityService.pdfKeyForSharh(widget.book.id, sharh.file);
    final initialPage = await _lastActivityService
        .getPdfPage(pdfKey)
        .then((info) => info?.page ?? 1);

    if (!mounted) return;

    await Navigator.push(
      context,
      buildFadeRoute(
        page: PdfViewerPage(
          title: sharh.title,
          assetPath: pdfPath,
          initialPage: initialPage,
          onPageChanged: (page, total) {
            if (total <= 0) return;
            final safeTotal = total < page ? page : total;
            _lastActivityService.savePdfPage(
              key: pdfKey,
              page: page,
              total: safeTotal,
            );
          },
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

  Future<void> _updateProgressFromPdf(int page, int totalPages) async {
    if (_isBookCompleted || totalPages <= 0) return;

    final isCompleted = page >= totalPages;
    if (!isCompleted) return;

    final existing = await _progressService.getProgress(widget.book.id);
    final completedLessons = existing?.completedLessons ?? 0;
    final totalLessons = existing?.totalLessons ?? 0;

    await _progressService.saveProgress(
      BookProgress(
        bookId: widget.book.id,
        status: BookProgressStatus.completed,
        completedLessons: completedLessons,
        totalLessons: totalLessons,
      ),
    );

    _isBookCompleted = true;
    if (!mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: AppUi.snackDuration,
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check,
              color: AppColors.textPrimary,
              size: AppUi.iconSizeSM,
            ),
            const SizedBox(width: AppUi.gapSM),
            Text(
              AppStrings.bookProgressSaved,
              style: AppText.body.copyWith(color: AppColors.textPrimary),
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
          unselectedLabelColor:
              AppColors.textPrimary.withValues(alpha: 0.6),
          labelStyle: AppText.body.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              AppText.body.copyWith(fontWeight: FontWeight.w500),
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

      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
          FutureBuilder<int>(
            future: _mutunInitialPage,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return PdfViewerPage(
                title: AppStrings.bookMutnTitle,
                assetPath: _mutunPdfPath,
                showAppBar: false,
                initialPage: snapshot.data!,
                onPageChanged: (page, total) {
                  if (total <= 0) return;
                  final safeTotal = total < page ? page : total;
                  _lastActivityService.savePdfPage(
                    key: _mutunPdfKey,
                    page: page,
                    total: safeTotal,
                  );
                  if (!_mutunActivityMarked) {
                    _mutunActivityMarked = true;
                    _lastActivityService.setLastTab(
                      widget.book.id,
                      LastActivityService.tabMutn,
                    );
                  }
                  _updateProgressFromPdf(page, safeTotal);
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
                      message: AppStrings.bookSharhEmptyMessage,
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
                      message: AppStrings.bookLessonsEmptyMessage,
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
    final safeTotal =
        rawPage != null && rawTotal > 0 && rawTotal < rawPage
            ? rawPage
            : (rawTotal > 0 ? rawTotal : null);
    final safePage = rawPage != null && safeTotal != null
        ? rawPage.clamp(1, safeTotal)
        : rawPage;
    final pageLabel = pageInfo == null
        ? AppStrings.continueSharh
        : AppStrings.lastPage(
            safePage ?? 1,
            safeTotal,
          );

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
                Text(
                  sharh.title,
                  style: AppText.heading,
                ),
                const SizedBox(height: AppUi.gapXSPlus),
                Text(
                  pageLabel,
                  style: AppText.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
