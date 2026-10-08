import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/theme_colors.dart';
import '../data/services/reading_stats_service.dart';
import 'quran_library_wrapper.dart';
import 'bookmarks_page.dart';
import '../../../shared/widgets/empty_state.dart';
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
  bool _isLoading = true;

  // Stats
  int _minutesToday = 0;
  int _streak = 0;
  final int _dailyGoal = 20; // minutes
  // Keys used by quran_library
  static const String _kMyLastSurahKey = 'dashboard_last_surah';
  static const String _kBookmarksKey =
      'dashboard_fav_surahs'; // Same key as BookmarksPage

  int? _lastOpenedSurah;
  List<String> _bookmarkedSurahsStr = []; // Store as Strings for ease

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterSurahs);
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

  void _filterSurahs() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() => _filteredSurahs = List.generate(114, (i) => i + 1));
      }
      return;
    }

    if (mounted) {
      setState(() {
        _filteredSurahs = List.generate(114, (i) => i + 1).where((surahNum) {
          final nameAr = quran.getSurahNameArabic(surahNum);
          final nameEn = quran.getSurahName(surahNum);
          return nameAr.contains(query) ||
              nameEn.toLowerCase().contains(query.toLowerCase()) ||
              surahNum.toString().contains(query);
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

    // Start Timer
    final startTime = DateTime.now();

    // Navigate
    if (!mounted) return;

    // Push and wait
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfessionalQuranScreen(initialSurah: surahNum),
      ),
    );

    // On Return:
    final duration = DateTime.now().difference(startTime).inSeconds;
    if (duration > 5) {
      // Only record if stayed > 5 seconds
      await _statsService.recordSession(
        durationSeconds: duration,
        versesRead: 0,
        surahNumber: surahNum,
      );
    }

    _loadData(); // Refresh stats
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bgColor = context.backgroundColor;
    final cardColor = context.surfaceContainer;
    final textColor = context.textPrimaryColor;
    final accentColor = context.goldColor;
    final mutedColor = context.textSecondaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'القرآن الكريم',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: textColor,
              ),
            ),
            Text(
              '١١٤ سورة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_rounded, color: accentColor),
            tooltip: 'المحفوظات',
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
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : Column(
              children: [
                // ════════ STATS DASHBOARD ════════
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      // Streak Card
                      Expanded(
                        child: _buildStatCard(
                          label: 'أيام التتابع',
                          value: '$_streak',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFE57373), // Warm coral
                          cardColor: cardColor,
                          textColor: textColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Time Card
                      Expanded(
                        child: _buildStatCard(
                          label: 'قراءة اليوم',
                          value: '$_minutesToday د',
                          icon: Icons.timer_outlined,
                          color: context.islamicGreenColor,
                          cardColor: cardColor,
                          textColor: textColor,
                          subtitle:
                              '${(_minutesToday / _dailyGoal * 100).clamp(0, 100).toInt()}% من الهدف',
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Bookmarks Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookmarksPage(),
                              ),
                            ).then((_) => _loadData());
                          },
                          child: _buildStatCard(
                            label: 'المحفوظات',
                            value: '${_bookmarkedSurahsStr.length}',
                            icon: Icons.bookmark_rounded,
                            color: accentColor,
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ════════ LAST READ (If exists) ════════
                if (_lastOpenedSurah != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _openSurah(_lastOpenedSurah!);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF1E2828),
                                    const Color(0xFF141C1C),
                                  ]
                                : [
                                    const Color(0xFFFFFDF8),
                                    const Color(0xFFF7F3EB),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.3),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.04,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Ornate Quran Icon
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                Icons.auto_stories_rounded,
                                color: accentColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'آخر قراءة',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 10,
                                        color: accentColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'سورة ${quran.getSurahNameArabic(_lastOpenedSurah!)}',
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 20,
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action Button Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(
                                  alpha: isDark ? 0.2 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'تابع القراءة',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 11,
                                    color: accentColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ════════ SEARCH ════════
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: textColor, fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن سورة بالاسم أو الرقم...',
                      hintStyle: TextStyle(
                        color: mutedColor,
                        fontFamily: 'Cairo',
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: accentColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: mutedColor,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.outlineColor.withValues(alpha: 0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.outlineColor.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: accentColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                // ════════ SURAH LIST ════════
                Expanded(
                  child: _filteredSurahs.isEmpty
                      ? Center(
                          child: EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'لا توجد نتائج',
                            subtitle:
                                'لم نتمكن من العثور على سورة تطابق بحثك. جرّب البحث برقم السورة أو اسمها.',
                            actionLabel: 'إعادة ضبط البحث',
                            onAction: () {
                              _searchController.clear();
                            },
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredSurahs.length,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemBuilder: (context, index) {
                            final surahNum = _filteredSurahs[index];
                            final isBookmarked = _bookmarkedSurahsStr.contains(
                              surahNum.toString(),
                            );

                            return SurahCard(
                              surahNumber: surahNum,
                              isBookmarked: isBookmarked,
                              onTap: () => _openSurah(surahNum),
                              onBookmarkTap: () => _toggleBookmark(surahNum),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDark ? 0.2 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
