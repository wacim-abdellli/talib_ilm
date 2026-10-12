import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/utils/arabic_search_utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/services/bookmark_service.dart';
import '../data/services/reading_stats_service.dart';
import 'bookmarks_page.dart';
import 'widgets/juz_card.dart';
import 'widgets/mushaf_page_viewer.dart';
import 'widgets/quick_jump_sheet.dart';
import 'widgets/quran_bookmarks_tab_view.dart';
import 'widgets/quran_stats_banner.dart';
import 'widgets/surah_card.dart';

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
  int _selectedTabIndex = 0; // 0: Surahs, 1: Juzs, 2: Bookmarks
  bool _isLoading = true;

  // Stats
  int _minutesToday = 0;
  int _streak = 0;
  final int _dailyGoal = 20; // minutes

  LastRead? _lastRead;
  List<Bookmark> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterIndex);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
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
    }
  }

  void _filterIndex() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredSurahs = List.generate(114, (i) => i + 1);
          _filteredJuzs = List.generate(30, (i) => i + 1);
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _filteredSurahs = List.generate(114, (i) => i + 1).where((surahNum) {
          final nameAr = quran.getSurahNameArabic(surahNum);
          final nameEn = quran.getSurahName(surahNum);
          return ArabicSearchUtils.matches(nameAr, query) ||
              nameEn.toLowerCase().contains(query.toLowerCase()) ||
              surahNum.toString().contains(query);
        }).toList();

        _filteredJuzs = List.generate(30, (i) => i + 1).where((juzNum) {
          final map = quran.getSurahAndVersesFromJuz(juzNum);
          final firstSurah = map.keys.first;
          final firstVerse = map[firstSurah]!.first;
          final surahName = quran.getSurahNameArabic(firstSurah);
          final snippet = quran.getVerse(firstSurah, firstVerse, verseEndSymbol: false);
          final label = 'الجزء $juzNum';
          return ArabicSearchUtils.matches(label, query) ||
              ArabicSearchUtils.matches(surahName, query) ||
              ArabicSearchUtils.matches(snippet, query) ||
              juzNum.toString().contains(query);
        }).toList();
      });
    }
  }

  Future<void> _toggleBookmark(int surahNum) async {
    HapticFeedback.selectionClick();
    await BookmarkService.toggleBookmark(surahNum, 1);
    _loadData();
  }

  Future<void> _openSurah(int surahNum, {int? ayah}) async {
    final startTime = DateTime.now();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafPageViewer(
          initialSurah: surahNum,
          initialAyah: ayah ?? 1,
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

  void _openQuickJump(BuildContext context) {
    HapticFeedback.lightImpact();
    QuickJumpSheet.show(context, onJumpToPage: _openPage);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: PrimaryAppBar(
        title: 'القرآن الكريم',
        showBack: false,
        actions: [
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
          : Column(
              children: [
                if (!isSearching) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpace.lg,
                      AppSpace.xs,
                      AppSpace.lg,
                      AppSpace.sm,
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

                  if (_lastRead != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.xs,
                      ),
                      child: QuranLastReadBanner(
                        lastRead: _lastRead!,
                        onTap: () => _openSurah(_lastRead!.surah, ayah: _lastRead!.ayah),
                      ),
                    ),

                  const SizedBox(height: AppSpace.xs),
                  _buildIndexTabs(context),
                ],

                // Search Bar
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpace.lg,
                    AppSpace.sm,
                    AppSpace.lg,
                    AppSpace.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    style: textTheme.body.copyWith(color: palette.text),
                    decoration: InputDecoration(
                      hintText: _selectedTabIndex == 0
                          ? 'ابحث عن سورة بالاسم أو الرقم...'
                          : _selectedTabIndex == 1
                              ? 'ابحث عن جزء بالاسم أو الرقم أو الآية...'
                              : 'ابحث في المحفوظات والتدبر...',
                      hintStyle: textTheme.bodySmall.copyWith(
                        color: palette.textMuted,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: palette.gold,
                        size: AppIcon.md,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? AppIconButton(
                              icon: Icons.clear_rounded,
                              tooltip: 'مسح البحث',
                              color: palette.textMuted,
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: palette.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.lgRadius,
                        borderSide: BorderSide(color: palette.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.lgRadius,
                        borderSide: BorderSide(color: palette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.lgRadius,
                        borderSide: BorderSide(
                          color: palette.gold,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.md,
                      ),
                    ),
                  ),
                ),

                // Content List (Surahs, Juzs, or Bookmarks)
                Expanded(
                  child: _selectedTabIndex == 0
                      ? _buildSurahsList(context)
                      : _selectedTabIndex == 1
                          ? _buildJuzsList(context)
                          : QuranBookmarksTabView(
                              bookmarks: _bookmarks,
                              onEmptyAction: () => setState(() => _selectedTabIndex = 0),
                              onReload: _loadData,
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildIndexTabs(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
      child: Container(
        padding: const EdgeInsetsDirectional.all(AppSpace.xs),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'السور (114)',
                isSelected: _selectedTabIndex == 0,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTabIndex = 0);
                },
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'الأجزاء (30)',
                isSelected: _selectedTabIndex == 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTabIndex = 1);
                },
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'المحفوظات (${_bookmarks.length})',
                isSelected: _selectedTabIndex == 2,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTabIndex = 2);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: AnimatedContainer(
          duration: AppMotion.base,
          padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.sm),
          decoration: BoxDecoration(
            color: isSelected ? palette.surfaceRaised : Colors.transparent,
            borderRadius: AppRadius.pillRadius,
            boxShadow: isSelected ? palette.shadow : null,
          ),
          child: Center(
            child: Text(
              title,
              style: context.text.label.copyWith(
                color: isSelected ? palette.gold : palette.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahsList(BuildContext context) {
    if (_filteredSurahs.isEmpty) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'لا توجد نتائج',
          subtitle:
              'لم نتمكن من العثور على سورة تطابق بحثك. جرّب كتابة اسم السورة أو رقمها.',
          actionLabel: 'إعادة ضبط البحث',
          onAction: () => _searchController.clear(),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredSurahs.length,
      padding: EdgeInsetsDirectional.only(
        start: AppSpace.lg,
        end: AppSpace.lg,
        bottom: AppSize.navClearance(context),
      ),
      itemBuilder: (context, index) {
        final surahNum = _filteredSurahs[index];
        final isBookmarked = _bookmarks.any((b) => b.surah == surahNum);

        return SurahCard(
          surahNumber: surahNum,
          isBookmarked: isBookmarked,
          onTap: () => _openSurah(surahNum),
          onBookmarkTap: () => _toggleBookmark(surahNum),
        );
      },
    );
  }

  Widget _buildJuzsList(BuildContext context) {
    if (_filteredJuzs.isEmpty) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'لا توجد نتائج',
          subtitle:
              'لم نتمكن من العثور على جزء يطابق بحثك. جرّب كتابة رقم الجزء أو اسم السورة.',
          actionLabel: 'إعادة ضبط البحث',
          onAction: () => _searchController.clear(),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredJuzs.length,
      padding: EdgeInsetsDirectional.only(
        start: AppSpace.lg,
        end: AppSpace.lg,
        bottom: AppSize.navClearance(context),
      ),
      itemBuilder: (context, index) {
        final juzNum = _filteredJuzs[index];
        return JuzCard(
          juzNumber: juzNum,
          onTap: () {
            final map = quran.getSurahAndVersesFromJuz(juzNum);
            final firstSurah = map.keys.first;
            final firstVerse = map[firstSurah]!.first;
            final page = quran.getPageNumber(firstSurah, firstVerse);
            _openPage(page);
          },
        );
      },
    );
  }
}
