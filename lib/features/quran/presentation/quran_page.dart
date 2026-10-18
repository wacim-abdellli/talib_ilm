import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:quran/quran.dart' as quran;

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/utils/arabic_search_utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/models/hizb_catalog.dart';
import '../data/services/bookmark_service.dart';
import '../data/services/reading_history_service.dart';
import '../data/services/reading_stats_service.dart';
import 'bookmarks_page.dart';
import 'widgets/mushaf_page_viewer.dart';
import 'widgets/quick_jump_sheet.dart';
import 'widgets/quran_ayah_search_card.dart';
import 'widgets/quran_bookmarks_tab_view.dart';
import 'widgets/quran_index_slivers.dart';
import 'widgets/quran_search_results_view.dart';
import 'widgets/quran_sliver_header.dart';
import 'widgets/quran_stats_banner.dart';
import 'widgets/reading_history_sheet.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final TextEditingController _searchController = TextEditingController();
  final ReadingStatsService _statsService = ReadingStatsService();

  List<int> _filteredSurahs = List.generate(114, (i) => i + 1);
  List<int> _filteredJuzs = List.generate(30, (i) => i + 1);
  List<int> _filteredHizbs = List.generate(60, (i) => i + 1);
  List<QuranAyahMatch> _filteredAyahs = const [];
  int _searchFilterIndex = 0; // 0: All, 1: Surahs, 2: Ayahs
  int _selectedTabIndex = 0; // 0: Surahs, 1: Juzs, 2: Hizbs, 3: Bookmarks
  bool _isLoading = true;

  // Stats
  int _minutesToday = 0;
  int _streak = 0;
  final int _dailyGoal = 20; // minutes

  LastRead? _lastRead;
  List<Bookmark> _bookmarks = [];
  Timer? _searchDebounce;

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
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final daily = await _statsService.getDailyStats();
      final streak = await _statsService.getStreak();
      final lastRead = await BookmarkService.getLastRead();
      final bookmarks = await BookmarkService.getBookmarks();

      if (mounted) {
        setState(() {
          _minutesToday = daily['minutes'] ?? 0;
          _streak = streak;
          _lastRead = lastRead;
          _bookmarks = bookmarks;
          _isLoading = false;
        });
        QcfFontLoader.preloadPages(lastRead.page, radius: 2);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        final snippet = quran.getVerse(firstSurah, firstVerse, verseEndSymbol: false);
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

  void _filterIndex() {
    final query = _searchController.text.trim();
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

    final matchingAyahs = <QuranAyahMatch>[];
    if (query.length >= 2) {
      final searchResult = searchWords(query, limit: 100);
      final rawList = searchResult['result'] as List? ?? const [];
      for (final raw in rawList) {
        if (raw is Map) {
          final sora = (raw['sora'] as num).toInt();
          final ayaNo = (raw['aya_no'] as num).toInt();
          final page = quran.getPageNumber(sora, ayaNo);
          final juz = quran.getJuzNumber(sora, ayaNo);
          final surahName = quran.getSurahNameArabic(sora);
          final verseText = raw['text']?.toString() ??
              quran.getVerse(sora, ayaNo, verseEndSymbol: false);

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
      }
    }

    if (mounted) {
      setState(() {
        _filteredSurahs = matchingSurahs;
        _filteredJuzs = matchingJuzs;
        _filteredHizbs = matchingHizbs;
        _filteredAyahs = matchingAyahs;
      });
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
    final targetPage = quran.getPageNumber(surahNum, effectiveAyah);
    QcfFontLoader.preloadPages(targetPage, radius: 2);

    ReadingHistoryService.recordReading(
      surah: surahNum,
      ayah: effectiveAyah,
      page: targetPage,
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafPageViewer(
          initialSurah: surahNum,
          initialAyah: effectiveAyah,
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
    QcfFontLoader.preloadPages(pageNumber, radius: 2);

    ReadingHistoryService.recordReading(
      surah: _lastRead?.surah ?? 1,
      ayah: _lastRead?.ayah ?? 1,
      page: pageNumber,
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafPageViewer(initialPage: pageNumber),
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

  Future<void> _openAyahMatch(QuranAyahMatch match) async {
    final startTime = DateTime.now();
    QcfFontLoader.preloadPages(match.pageNumber, radius: 2);

    ReadingHistoryService.recordReading(
      surah: match.surahNumber,
      ayah: match.ayahNumber,
      page: match.pageNumber,
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafPageViewer(
          initialPage: match.pageNumber,
          initialSurah: match.surahNumber,
          initialAyah: match.ayahNumber,
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
            icon: Icons.history_rounded,
            tooltip: 'سجل القراءة',
            color: palette.gold,
            onPressed: () => ReadingHistorySheet.show(
              context,
              onOpenPage: _openPage,
            ),
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
              slivers: [
                if (!isSearching)
                  SliverToBoxAdapter(
                    child: Column(
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
                                  icon: Icons.local_fire_department_rounded,
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
                                        builder: (_) => const BookmarksPage(),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Last read banner (آخر قراءة)
                        if (_lastRead != null)
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

                // Pinned Category Tabs & Search Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: QuranPinnedHeaderDelegate(
                    selectedTabIndex: _selectedTabIndex,
                    bookmarksCount: _bookmarks.length,
                    onTabSelected: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTabIndex = index);
                    },
                    searchController: _searchController,
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
                    onResetSearch: () => _searchController.clear(),
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
                  )
                else if (_selectedTabIndex == 1)
                  ...QuranIndexSlivers.buildJuzsSlivers(
                    context: context,
                    filteredJuzs: _filteredJuzs,
                    onOpenPage: _openPage,
                    onResetSearch: () => _searchController.clear(),
                  )
                else if (_selectedTabIndex == 2)
                  ...QuranIndexSlivers.buildHizbsSlivers(
                    context: context,
                    filteredHizbs: _filteredHizbs,
                    onOpenPage: _openPage,
                    onResetSearch: () => _searchController.clear(),
                  )
                else
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: QuranBookmarksTabView(
                      bookmarks: _bookmarks,
                      onEmptyAction: () =>
                          setState(() => _selectedTabIndex = 0),
                      onReload: _loadData,
                    ),
                  ),
              ],
            ),
    );
  }
}
