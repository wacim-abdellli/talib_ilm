import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:quran/quran.dart' as quran;

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/utils/arabic_search_utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/models/hizb_catalog.dart';
import '../data/models/quran_models.dart';
import '../data/database/quran_pack_database.dart';
import '../data/services/bookmark_service.dart';
import '../data/services/edition_service.dart';
import '../data/services/quran_pack_install_service.dart';
import '../data/services/reading_history_service.dart';
import '../data/services/reading_stats_service.dart';
import 'bookmarks_page.dart';
import 'quran_pack_reader_page.dart';
import 'quran_riwayah_downloads_page.dart';
import 'widgets/mushaf_page_viewer.dart';
import 'widgets/quick_jump_sheet.dart';
import 'widgets/quran_ayah_search_card.dart';
import 'widgets/quran_bookmarks_tab_view.dart';
import 'widgets/quran_index_slivers.dart';
import 'widgets/quran_search_results_view.dart';
import 'widgets/quran_sliver_header.dart';
import 'widgets/quran_stats_banner.dart';
import 'widgets/reading_history_sheet.dart';

List<Map<String, dynamic>> _performAyahSearch(String query) {
  final searchResult = searchWords(query, limit: 100);
  final rawList = searchResult['result'] as List? ?? const [];
  final results = <Map<String, dynamic>>[];
  for (final raw in rawList) {
    if (raw is Map) {
      results.add({
        'sora': (raw['sora'] as num).toInt(),
        'aya_no': (raw['aya_no'] as num).toInt(),
        'text': raw['text']?.toString(),
      });
    }
  }
  return results;
}

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ReadingStatsService _statsService = ReadingStatsService();

  List<int> _filteredSurahs = List.generate(114, (i) => i + 1);
  List<int> _filteredJuzs = List.generate(30, (i) => i + 1);
  List<int> _filteredHizbs = List.generate(60, (i) => i + 1);
  List<QuranAyahMatch> _filteredAyahs = const [];
  Map<int, QuranPackSurah> _editionSurahs = const {};
  int _searchFilterIndex = 0; // 0: All, 1: Surahs, 2: Ayahs
  int _selectedTabIndex = 0; // 0: Surahs, 1: Juzs, 2: Hizbs, 3: Bookmarks
  bool _isLoading = true;
  String _currentEditionId = 'hafs';

  // Stats
  int _minutesToday = 0;
  int _streak = 0;
  final int _dailyGoal = 20; // minutes

  LastRead? _lastRead;
  List<Bookmark> _bookmarks = [];
  Timer? _searchDebounce;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppMotion.searchDebounce, _filterIndex);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Fire all independent I/O concurrently — total wait = slowest, not sum.
      final dailyFuture = _statsService.getDailyStats();
      final streakFuture = _statsService.getStreak();
      final lastReadFuture = BookmarkService.getLastRead();
      final bookmarksFuture = BookmarkService.getBookmarks();
      final editionFuture = EditionService.getCurrentEdition();

      final daily = await dailyFuture;
      final streak = await streakFuture;
      final lastRead = await lastReadFuture;
      final bookmarks = await bookmarksFuture;
      final editionId = await editionFuture;
      final editionSurahs = editionId == null || editionId == 'hafs'
          ? const <int, QuranPackSurah>{}
          : await _loadEditionSurahs(editionId);

      if (mounted) {
        setState(() {
          _minutesToday = daily['minutes'] ?? 0;
          _streak = streak;
          _lastRead = lastRead;
          _bookmarks = bookmarks;
          _currentEditionId = editionId ?? '';
          _editionSurahs = editionSurahs;
          _isLoading = false;
        });
        if (_currentEditionId == 'hafs') {
          QcfFontLoader.preloadPages(lastRead.page, radius: 2);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<int, QuranPackSurah>> _loadEditionSurahs(String editionId) async {
    final QuranRiwayahId edition;
    try {
      edition = QuranRiwayahId.parse(editionId);
    } on FormatException {
      return const {};
    }
    final database = await QuranPackInstallService.openInstalled(edition);
    if (database == null) return const {};
    try {
      return {
        for (final surah in await database.getSurahList()) surah.number: surah,
      };
    } catch (_) {
      return const {};
    } finally {
      await database.close();
    }
  }

  static final Map<int, String> _surahSearchIndex = {
    for (int i = 1; i <= 114; i++)
      i: ArabicSearchUtils.normalize(
        '${quran.getSurahNameArabic(i)} ${quran.getSurahName(i)} $i',
      ),
  };

  static final Map<int, String> _juzSearchIndex = {
    for (int i = 1; i <= 30; i++)
      i: () {
        final map = quran.getSurahAndVersesFromJuz(i);
        final firstSurah = map.keys.first;
        final firstVerse = map[firstSurah]!.first;
        final surahName = quran.getSurahNameArabic(firstSurah);
        final snippet = quran.getVerse(
          firstSurah,
          firstVerse,
          verseEndSymbol: false,
        );
        return ArabicSearchUtils.normalize('الجزء $i $surahName $snippet $i');
      }(),
  };

  static final Map<int, String> _hizbSearchIndex = {
    for (int i = 1; i <= 60; i++)
      i: () {
        final hizb = HizbCatalog.getHizb(i);
        return ArabicSearchUtils.normalize(
          '${hizb.nameArabic} ${hizb.surahNameArabic} ${hizb.firstVerseSnippet} $i',
        );
      }(),
  };

  void _filterIndex() async {
    final query = _searchController.text.trim();
    final currentGen = ++_searchGeneration;

    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredSurahs = List.generate(114, (i) => i + 1);
          _filteredJuzs = List.generate(30, (i) => i + 1);
          _filteredHizbs = List.generate(60, (i) => i + 1);
          _filteredAyahs = const [];
          _searchFilterIndex = 0;
        });
      }
      return;
    }

    final normalizedQuery = ArabicSearchUtils.normalize(query);
    final isNumeric = int.tryParse(query) != null;
    final queryNumber = int.tryParse(query);

    final matchingSurahs = List.generate(114, (i) => i + 1).where((i) {
      if (isNumeric && queryNumber == i) return true;
      return _surahSearchIndex[i]?.contains(normalizedQuery) ?? false;
    }).toList();

    final matchingJuzs = List.generate(30, (i) => i + 1)
        .where((i) => _juzSearchIndex[i]?.contains(normalizedQuery) ?? false)
        .toList();

    final matchingHizbs = List.generate(60, (i) => i + 1)
        .where((i) => _hizbSearchIndex[i]?.contains(normalizedQuery) ?? false)
        .toList();

    if (mounted) {
      setState(() {
        _filteredSurahs = matchingSurahs;
        _filteredJuzs = matchingJuzs;
        _filteredHizbs = matchingHizbs;
      });
    }

    if (query.length >= 2) {
      final List<Map<String, dynamic>> rawList;
      if (_currentEditionId == 'hafs') {
        rawList = await compute(_performAyahSearch, query);
      } else {
        rawList = await _searchInstalledEdition(_currentEditionId, query);
      }
      if (_searchGeneration != currentGen || !mounted) return;

      final matchingAyahs = <QuranAyahMatch>[];
      for (final raw in rawList) {
        final sora = raw['sora'] as int;
        final ayaNo = raw['aya_no'] as int;
        final page = raw['page'] as int? ?? quran.getPageNumber(sora, ayaNo);
        final juz = raw['juz'] as int? ?? quran.getJuzNumber(sora, ayaNo);
        final surahName =
            raw['surahName'] as String? ?? quran.getSurahNameArabic(sora);
        final verseText =
            raw['text'] ?? quran.getVerse(sora, ayaNo, verseEndSymbol: false);

        matchingAyahs.add(
          QuranAyahMatch(
            surahNumber: sora,
            ayahNumber: ayaNo,
            pageNumber: page,
            juzNumber: juz,
            surahName: surahName,
            verseText: verseText,
            query: query,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _filteredAyahs = matchingAyahs;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _filteredAyahs = const [];
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _searchInstalledEdition(
    String editionId,
    String query,
  ) async {
    final QuranRiwayahId edition;
    try {
      edition = QuranRiwayahId.parse(editionId);
    } on FormatException {
      return const [];
    }
    final database = await QuranPackInstallService.openInstalled(edition);
    if (database == null) return const [];
    try {
      final matches = await database.searchAyahs(
        ArabicSearchUtils.normalize(query),
        limit: 100,
      );
      final result = <Map<String, dynamic>>[];
      final surahs = <int, QuranPackSurah>{};
      for (final match in matches) {
        var surah = surahs[match.surahNumber];
        if (surah == null) {
          surah = await database.getSurah(match.surahNumber);
          if (surah == null) continue;
          surahs[match.surahNumber] = surah;
        }
        result.add({
          'sora': match.surahNumber,
          'aya_no': match.ayahNumber,
          'text': match.displayText,
          'page': match.firstPage,
          'juz': match.juzNumber,
          'surahName': surah.nameArabic,
        });
      }
      return result;
    } catch (_) {
      return const [];
    } finally {
      await database.close();
    }
  }

  Future<void> _toggleBookmark(int surahNum) async {
    HapticFeedback.selectionClick();
    await BookmarkService.toggleSurahBookmark(surahNum);
    _loadData();
  }

  Future<void> _openSurah(int surahNum, {int? ayah}) async {
    final startTime = DateTime.now();
    final effectiveAyah = ayah ?? 1;
    final editionId = await EditionService.getCurrentEdition();
    if (editionId == null) {
      _showUnavailableEdition();
      return;
    }
    final targetPage = await _resolvePage(editionId, surahNum, effectiveAyah);
    if (targetPage == null) {
      _showUnavailableEdition();
      return;
    }
    if (editionId == 'hafs') QcfFontLoader.preloadPages(targetPage, radius: 2);

    if (editionId == 'hafs') {
      ReadingHistoryService.recordReading(
        surah: surahNum,
        ayah: effectiveAyah,
        page: targetPage,
      );
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _readerFor(
          editionId,
          page: targetPage,
          surah: surahNum,
          ayah: effectiveAyah,
        ),
      ),
    );

    final duration = DateTime.now().difference(startTime).inSeconds;
    if (duration > 5) {
      await _statsService.recordSession(
        durationSeconds: duration,
        versesRead: 0,
        surahNumber: surahNum,
      );
    }

    _loadData();
  }

  Future<void> _openPage(int pageNumber) async {
    final startTime = DateTime.now();
    final editionId = await EditionService.getCurrentEdition();
    if (editionId == null) {
      _showUnavailableEdition();
      return;
    }
    if (editionId == 'hafs') QcfFontLoader.preloadPages(pageNumber, radius: 2);

    if (editionId == 'hafs') {
      ReadingHistoryService.recordReading(
        surah: _lastRead?.surah ?? 1,
        ayah: _lastRead?.ayah ?? 1,
        page: pageNumber,
      );
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _readerFor(editionId, page: pageNumber),
      ),
    );

    final duration = DateTime.now().difference(startTime).inSeconds;
    if (duration > 5) {
      await _statsService.recordSession(
        durationSeconds: duration,
        versesRead: 0,
        surahNumber: _lastRead?.surah ?? 1,
      );
    }

    _loadData();
  }

  Future<void> _openJuz(int juzNumber) async {
    final editionId = await EditionService.getCurrentEdition();
    if (editionId == null) {
      _showUnavailableEdition();
      return;
    }
    if (editionId == 'hafs') {
      final location = quran.getSurahAndVersesFromJuz(juzNumber);
      final surah = location.keys.first;
      final ayah = location[surah]!.first;
      await _openPage(quran.getPageNumber(surah, ayah));
      return;
    }
    final QuranRiwayahId edition;
    try {
      edition = QuranRiwayahId.parse(editionId);
    } on FormatException {
      _showUnavailableEdition();
      return;
    }
    final database = await QuranPackInstallService.openInstalled(edition);
    if (database == null) {
      _showUnavailableEdition();
      return;
    }
    try {
      final start = await database.getJuzStartAyah(juzNumber);
      if (start == null) {
        _showUnavailableEdition();
        return;
      }
      final surahNumber = start.surahNumber;
      final ayahNumber = start.ayahNumber;
      await database.close();
      await _openSurah(surahNumber, ayah: ayahNumber);
    } finally {
      await database.close();
    }
  }

  Future<void> _openAyahMatch(QuranAyahMatch match) async {
    final startTime = DateTime.now();
    final editionId = await EditionService.getCurrentEdition();
    if (editionId == null) {
      _showUnavailableEdition();
      return;
    }
    final targetPage = await _resolvePage(
      editionId,
      match.surahNumber,
      match.ayahNumber,
    );
    if (targetPage == null) {
      _showUnavailableEdition();
      return;
    }
    if (editionId == 'hafs') QcfFontLoader.preloadPages(targetPage, radius: 2);

    if (editionId == 'hafs') {
      ReadingHistoryService.recordReading(
        surah: match.surahNumber,
        ayah: match.ayahNumber,
        page: targetPage,
      );
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _readerFor(
          editionId,
          page: targetPage,
          surah: match.surahNumber,
          ayah: match.ayahNumber,
        ),
      ),
    );

    final duration = DateTime.now().difference(startTime).inSeconds;
    if (duration > 5) {
      await _statsService.recordSession(
        durationSeconds: duration,
        versesRead: 0,
        surahNumber: match.surahNumber,
      );
    }

    _loadData();
  }

  Future<int?> _resolvePage(String editionId, int surah, int ayah) async {
    if (editionId == 'hafs') return quran.getPageNumber(surah, ayah);
    final QuranRiwayahId edition;
    try {
      edition = QuranRiwayahId.parse(editionId);
    } on FormatException {
      return null;
    }
    final database = await QuranPackInstallService.openInstalled(edition);
    if (database == null) return null;
    try {
      return (await database.getAyah(surah, ayah))?.firstPage;
    } finally {
      await database.close();
    }
  }

  Widget _readerFor(
    String editionId, {
    required int page,
    int? surah,
    int? ayah,
  }) {
    if (editionId == 'hafs') {
      return MushafPageViewer(
        initialPage: page,
        initialSurah: surah,
        initialAyah: ayah,
      );
    }
    return QuranPackReaderPage(
      editionId: QuranRiwayahId.parse(editionId),
      initialPage: page,
      initialSurah: surah,
      initialAyah: ayah,
    );
  }

  void _showUnavailableEdition() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('الرواية المحددة غير متاحة حالياً. اختر أو نزّل رواية.'),
      ),
    );
  }

  void _openQuickJump(BuildContext context) {
    HapticFeedback.lightImpact();
    QuickJumpSheet.show(context, onJumpToPage: _openPage);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: PrimaryAppBar(
        title: 'القرآن الكريم',
        showBack: false,
        actions: [
          AppIconButton(
            icon: Icons.library_books_rounded,
            tooltip: 'روايات المصحف والتنزيلات',
            color: palette.gold,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QuranRiwayahDownloadsPage(),
                ),
              );
              if (mounted) {
                await _loadData();
                _filterIndex();
              }
            },
          ),
          if (_currentEditionId == 'hafs')
            AppIconButton(
              icon: Icons.history_rounded,
              tooltip: 'سجل القراءة',
              color: palette.gold,
              onPressed: () =>
                  ReadingHistorySheet.show(context, onOpenPage: _openPage),
            ),
          AppIconButton(
            icon: Icons.explore_rounded,
            tooltip: 'الانتقال السريع',
            color: palette.gold,
            onPressed: () => _openQuickJump(context),
          ),
          AppIconButton(
            icon: Icons.bookmark_rounded,
            tooltip: 'المحفوظات',
            color: palette.gold,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarksPage()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: palette.gold))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  key: const ValueKey('quran_stats_banner'),
                  child: AnimatedSize(
                    duration: AppMotion.base,
                    curve: Curves.easeInOut,
                    child: isSearching
                        ? const SizedBox.shrink()
                        : Column(
                            key: const ValueKey('quran_stats_content'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Stats row (أيام التتابع • قراءة اليوم • المحفوظات)
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  AppSpace.lg,
                                  AppSpace.xs,
                                  AppSpace.lg,
                                  AppSpace.xs,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: QuranStatCard(
                                        label: 'أيام التتابع',
                                        value: '$_streak',
                                        icon:
                                            Icons.local_fire_department_rounded,
                                        iconColor: palette.gold,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpace.sm),
                                    Expanded(
                                      child: QuranStatCard(
                                        label: 'قراءة اليوم',
                                        value: '$_minutesToday د',
                                        icon: Icons.timer_outlined,
                                        iconColor: palette.primary,
                                        subtitle:
                                            '${(_minutesToday / _dailyGoal * 100).clamp(0, 100).toInt()}% من الهدف',
                                      ),
                                    ),
                                    const SizedBox(width: AppSpace.sm),
                                    Expanded(
                                      child: QuranStatCard(
                                        label: 'المحفوظات',
                                        value: '${_bookmarks.length}',
                                        icon: Icons.bookmark_rounded,
                                        iconColor: palette.gold,
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const BookmarksPage(),
                                            ),
                                          ).then((_) => _loadData());
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Last read banner (آخر قراءة)
                              if (_lastRead != null &&
                                  _currentEditionId == 'hafs')
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    AppSpace.lg,
                                    AppSpace.xs,
                                    AppSpace.lg,
                                    AppSpace.xs,
                                  ),
                                  child: QuranLastReadBanner(
                                    lastRead: _lastRead!,
                                    onTap: () => _openSurah(
                                      _lastRead!.surah,
                                      ayah: _lastRead!.ayah,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: AppSpace.xs),
                            ],
                          ),
                  ),
                ),

                // Pinned Category Tabs & Search Bar
                SliverPersistentHeader(
                  key: const ValueKey('quran_pinned_header'),
                  pinned: true,
                  delegate: QuranPinnedHeaderDelegate(
                    selectedTabIndex: _selectedTabIndex,
                    bookmarksCount: _bookmarks.length,
                    onTabSelected: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTabIndex = index);
                    },
                    searchController: _searchController,
                    searchFocusNode: _searchFocusNode,
                    onSearchChanged: _filterIndex,
                    isSearching: isSearching,
                    searchFilterIndex: _searchFilterIndex,
                    onSearchFilterSelected: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _searchFilterIndex = index);
                    },
                    surahsCount: _filteredSurahs.length,
                    ayahsCount: _filteredAyahs.length,
                  ),
                ),

                if (isSearching)
                  ...buildQuranSearchResultsSlivers(
                    context: context,
                    query: _searchController.text.trim(),
                    searchFilterIndex: _searchFilterIndex,
                    filteredSurahs: _filteredSurahs,
                    filteredAyahs: _filteredAyahs,
                    bookmarkedSurahSet: _bookmarks
                        .where((b) => b.isSurah)
                        .map((b) => b.surah)
                        .toSet(),
                    onOpenSurah: _openSurah,
                    onToggleBookmark: _toggleBookmark,
                    onOpenAyah: _openAyahMatch,
                    onResetSearch: () {
                      _searchController.clear();
                      _searchFocusNode.requestFocus();
                    },
                    onFilterChanged: (index) =>
                        setState(() => _searchFilterIndex = index),
                  )
                else if (_selectedTabIndex == 0)
                  ...QuranIndexSlivers.buildSurahsSlivers(
                    context: context,
                    filteredSurahs: _filteredSurahs,
                    bookmarkedSurahSet: _bookmarks
                        .where((b) => b.isSurah)
                        .map((b) => b.surah)
                        .toSet(),
                    onOpenSurah: _openSurah,
                    onToggleBookmark: _toggleBookmark,
                    onResetSearch: () => _searchController.clear(),
                    editionSurahs: _editionSurahs,
                  )
                else if (_selectedTabIndex == 1)
                  ...QuranIndexSlivers.buildJuzsSlivers(
                    context: context,
                    filteredJuzs: _filteredJuzs,
                    onOpenJuz: _openJuz,
                    onResetSearch: () => _searchController.clear(),
                  )
                else if (_selectedTabIndex == 2)
                  ...QuranIndexSlivers.buildHizbsSlivers(
                    context: context,
                    filteredHizbs: _filteredHizbs,
                    onOpenPage: _openPage,
                    onResetSearch: () => _searchController.clear(),
                    isHafsEdition: _currentEditionId == 'hafs',
                  )
                else ...[
                  if (_currentEditionId == 'hafs')
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: QuranBookmarksTabView(
                        bookmarks: _bookmarks,
                        onEmptyAction: () =>
                            setState(() => _selectedTabIndex = 0),
                        onReload: _loadData,
                      ),
                    )
                  else
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                        child: EmptyState(
                          icon: Icons.bookmark_outline_rounded,
                          title: 'المحفوظات مرتبطة بحفص حالياً',
                          subtitle:
                              'المحفوظات الحالية تستخدم ترقيم حفص. ارجع إلى رواية حفص لفتحها حتى لا تنتقل إلى آية مختلفة في الرواية المحددة.',
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
