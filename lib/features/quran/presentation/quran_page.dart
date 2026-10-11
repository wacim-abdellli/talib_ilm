import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/arabic_search_utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/services/reading_stats_service.dart';
import 'bookmarks_page.dart';
import 'widgets/juz_card.dart';
import 'widgets/mushaf_page_viewer.dart';
import 'widgets/quick_jump_sheet.dart';
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
  int _selectedTabIndex = 0; // 0: Surahs, 1: Juzs
  bool _isLoading = true;

  // Stats
  int _minutesToday = 0;
  int _streak = 0;
  final int _dailyGoal = 20; // minutes
  // Keys used by quran_library
  static const String _kMyLastSurahKey = 'dashboard_last_surah';
  static const String _kBookmarksKey = 'dashboard_fav_surahs';

  int? _lastOpenedSurah;
  List<String> _bookmarkedSurahsStr = [];

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

    final prefs = await SharedPreferences.getInstance();
    final lastSurah = prefs.getInt(_kMyLastSurahKey);
    final bookmarks = prefs.getStringList(_kBookmarksKey) ?? [];

    if (mounted) {
      setState(() {
        _minutesToday = daily['minutes'] ?? 0;
        _streak = streak;
        _lastOpenedSurah = lastSurah;
        _bookmarkedSurahsStr = bookmarks;
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
    final prefs = await SharedPreferences.getInstance();
    final strNum = surahNum.toString();
    setState(() {
      if (_bookmarkedSurahsStr.contains(strNum)) {
        _bookmarkedSurahsStr.remove(strNum);
      } else {
        _bookmarkedSurahsStr.add(strNum);
      }
    });
    await prefs.setStringList(_kBookmarksKey, _bookmarkedSurahsStr);
  }

  Future<void> _openSurah(int surahNum) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMyLastSurahKey, surahNum);

    setState(() => _lastOpenedSurah = surahNum);

    final startTime = DateTime.now();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafPageViewer(initialSurah: surahNum),
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
        surahNumber: _lastOpenedSurah ?? 1,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Text(
              _selectedTabIndex == 0 ? '١١٤ سورة' : '٣٠ جزء',
              style: textTheme.caption.copyWith(
                color: palette.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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
                // Stats Dashboard & Last Read Card (Collapsed during active search)
                if (!isSearching) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.xs,
                      AppSpace.lg,
                      AppSpace.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            label: 'أيام التتابع',
                            value: '$_streak',
                            icon: Icons.local_fire_department_rounded,
                            iconColor: palette.gold,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: _buildStatCard(
                            context: context,
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
                          child: _buildStatCard(
                            context: context,
                            label: 'المحفوظات',
                            value: '${_bookmarkedSurahsStr.length}',
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

                  // Last Read Card (If exists)
                  if (_lastOpenedSurah != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.xs,
                      ),
                      child: _buildLastReadCard(context, _lastOpenedSurah!),
                    ),

                  const SizedBox(height: AppSpace.xs),

                  // Wahi-Style Tabs: Surahs vs Juzs
                  _buildIndexTabs(context),
                ],

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
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
                          : 'ابحث عن جزء بالاسم أو الرقم أو الآية...',
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
                              onPressed: () {
                                _searchController.clear();
                              },
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.md,
                      ),
                    ),
                  ),
                ),

                // Content List (Surahs or Juzs) with Scrollable EmptyState to prevent ANY overflow
                Expanded(
                  child: _selectedTabIndex == 0
                      ? _buildSurahsList(context)
                      : _buildJuzsList(context),
                ),
              ],
            ),
    );
  }

  Widget _buildIndexTabs(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.xs),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'فهرس السور (١١٤)',
                isSelected: _selectedTabIndex == 0,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTabIndex = 0);
                },
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'فهرس الأجزاء (٣٠)',
                isSelected: _selectedTabIndex == 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTabIndex = 1);
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
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
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
        padding: const EdgeInsets.all(AppSpace.lg),
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'لا توجد نتائج',
          subtitle:
              'لم نتمكن من العثور على سورة تطابق بحثك. جرّب كتابة اسم السورة أو رقمها.',
          actionLabel: 'إعادة ضبط البحث',
          onAction: () {
            _searchController.clear();
          },
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredSurahs.length,
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSize.navClearance(context),
      ),
      itemBuilder: (context, index) {
        final surahNum = _filteredSurahs[index];
        final isBookmarked =
            _bookmarkedSurahsStr.contains(surahNum.toString());

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
        padding: const EdgeInsets.all(AppSpace.lg),
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'لا توجد نتائج',
          subtitle:
              'لم نتمكن من العثور على جزء يطابق بحثك. جرّب كتابة رقم الجزء أو اسم السورة.',
          actionLabel: 'إعادة ضبط البحث',
          onAction: () {
            _searchController.clear();
          },
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredJuzs.length,
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSize.navClearance(context),
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

  Widget _buildLastReadCard(BuildContext context, int lastSurah) {
    final palette = context.palette;
    final textTheme = context.text;
    final startPage = quran.getSurahPages(lastSurah)[0];

    return AppCard(
      onTap: () {
        HapticFeedback.lightImpact();
        _openSurah(lastSurah);
      },
      padding: const EdgeInsets.all(AppSpace.lg),
      border: Border.all(
        color: palette.gold.withValues(alpha: 0.35),
        width: 1.2,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.goldSoft,
              border: Border.all(
                color: palette.gold.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: palette.gold,
              size: AppIcon.md,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xs,
                      ),
                      decoration: BoxDecoration(
                        color: palette.goldSoft,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        'آخر قراءة',
                        style: textTheme.caption.copyWith(
                          color: palette.onGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      'صفحة $startPage',
                      style: textTheme.caption.copyWith(
                        color: palette.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'سورة ${quran.getSurahNameArabic(lastSurah)}',
                  style: textTheme.sacred.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: palette.gold.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تابع القراءة',
                  style: textTheme.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.gold,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: AppIcon.sm,
                  color: palette.gold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.xs),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: AppIcon.sm),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            value,
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: textTheme.caption.copyWith(
              color: palette.textMuted,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              subtitle,
              style: textTheme.caption.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
