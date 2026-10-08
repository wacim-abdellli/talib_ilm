import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/theme_colors.dart';
import '../data/services/reading_stats_service.dart';
import 'quran_library_wrapper.dart';
import 'bookmarks_page.dart';

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
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.04,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back_ios_rounded,
                              color: accentColor,
                              size: 16,
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'آخر قراءة',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: accentColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'سورة ${quran.getSurahNameArabic(_lastOpenedSurah!)}',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 19,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.auto_stories_rounded,
                                color: accentColor,
                                size: 20,
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
                  child: ListView.builder(
                    itemCount: _filteredSurahs.length,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemBuilder: (context, index) {
                      final surahNum = _filteredSurahs[index];
                      final surahName = quran.getSurahNameArabic(surahNum);
                      final versesCount = quran.getVerseCount(surahNum);
                      final place = quran.getPlaceOfRevelation(surahNum);
                      final isBookmarked = _bookmarkedSurahsStr.contains(
                        surahNum.toString(),
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: context.outlineColor.withValues(
                              alpha: isDark ? 0.12 : 0.08,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.15 : 0.03,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _openSurah(surahNum);
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withValues(alpha: 0.1),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              '$surahNum',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: accentColor,
                              ),
                            ),
                          ),
                          title: Text(
                            'سورة $surahName',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                              color: textColor,
                            ),
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: context.islamicGreenColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  place == 'Makkah' ? 'مكية' : 'مدنية',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: context.islamicGreenColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$versesCount آية',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '•',
                                style: TextStyle(color: mutedColor),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                quran.getSurahName(surahNum),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: isBookmarked ? accentColor : mutedColor,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _toggleBookmark(surahNum);
                            },
                          ),
                        ),
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
