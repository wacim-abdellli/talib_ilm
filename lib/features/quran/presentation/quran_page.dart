import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
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
  int _dailyGoal = 20; // minutes
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
      if (mounted)
        setState(() => _filteredSurahs = List.generate(114, (i) => i + 1));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Lux Black & Gold Theme Colors
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFDF8F0);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFE8DED0)
        : const Color(0xFF3D2B1F);
    final accentColor = const Color(0xFFD4A853);
    final mutedColor = textColor.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'القرآن الكريم',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: accentColor),
            onPressed: () {
              // Optional settings
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      // Streak Card
                      Expanded(
                        child: _buildStatCard(
                          label: 'أيام التتابع',
                          value: '$_streak',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(
                            0xFFFF5252,
                          ), // Red/Orange for streak
                          cardColor: cardColor,
                          textColor: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time Card
                      Expanded(
                        child: _buildStatCard(
                          label: 'قراءة اليوم',
                          value: '$_minutesToday د',
                          icon: Icons.timer_outlined,
                          color: const Color(0xFF10B981), // Green
                          cardColor: cardColor,
                          textColor: textColor,
                          subtitle:
                              '${(_minutesToday / _dailyGoal * 100).clamp(0, 100).toInt()}% من الهدف',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bookmarks (Fake/Entry) Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookmarksPage(),
                              ),
                            ).then((_) => _loadData()); // Refresh on return
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
                      vertical: 4,
                    ),
                    child: InkWell(
                      onTap: () => _openSurah(_lastOpenedSurah!),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
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
                                    fontSize: 10,
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'سورة ${quran.getSurahNameArabic(_lastOpenedSurah!)}',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 18,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.history_edu_rounded,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ════════ SEARCH ════════
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: textColor, fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن سورة...',
                      hintStyle: TextStyle(color: mutedColor),
                      prefixIcon: Icon(Icons.search, color: accentColor),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),

                // ════════ SURAH LIST ════════
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredSurahs.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final surahNum = _filteredSurahs[index];
                      final surahName = quran.getSurahNameArabic(surahNum);
                      final versesCount = quran.getVerseCount(surahNum);
                      final place = quran.getPlaceOfRevelation(surahNum);
                      final isBookmarked = _bookmarkedSurahsStr.contains(
                        surahNum.toString(),
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _openSurah(surahNum),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor, // Solid Gold
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '$surahNum',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                          title: Text(
                            'سورة $surahName',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 22, // Larger
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: textColor,
                            ),
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  place == 'Makkah' ? 'مكية' : 'مدنية',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10,
                                    color: const Color(
                                      0xFF10B981,
                                    ), // Green for type
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
                              const Text('•'),
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
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isBookmarked ? accentColor : mutedColor,
                            ),
                            onPressed: () => _toggleBookmark(surahNum),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: textColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
