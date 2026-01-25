import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/services/quran_cache_service.dart';
import '../data/services/bookmark_service.dart';
import '../data/services/reading_stats_service.dart';
import '../data/models/quran_models.dart';
import '../data/services/quran_sync_service.dart';
import 'quran_reading_page.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  List<SurahMeta> _surahs = [];
  List<SurahMeta> _filteredSurahs = [];
  ReadingProgress? _lastRead;
  List<Bookmark> _bookmarks = [];

  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Smart Stats
  int _minutesToday = 0;
  int _streak = 0;
  final ReadingStatsService _statsService = ReadingStatsService();

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _loadData();
    _searchController.addListener(_filterSurahs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      // Ignore errors
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    bool isOffline = result.contains(ConnectivityResult.none);
    if (result.isEmpty) isOffline = true; // Safety

    if (_isOffline && !isOffline) {
      // Came online
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استعادة الاتصال. جاري التحديث...'),
            backgroundColor: Color(0xFF14B8A6),
          ),
        );
        _loadData();
      }
    }

    if (mounted) {
      setState(() => _isOffline = isOffline);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final surahs = await QuranRepository.getSurahList();
      final lastRead = await QuranRepository.getLastPosition();
      final bookmarks = await BookmarkService.getBookmarks();

      // Smart Stats
      final daily = await _statsService.getDailyStats();
      final streak = await _statsService.getStreak();

      if (mounted) {
        setState(() {
          _surahs = surahs;
          _filteredSurahs = surahs;
          _lastRead = lastRead.lastSurah > 0 ? lastRead : null;
          _bookmarks = bookmarks;
          _minutesToday = daily['minutes'] ?? 0;
          _streak = streak;
          _isLoading = false;
        });
        _filterSurahs();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // If offline and we have cache, we might have succeeded above (Repository handles cache).
          // If we are here, it means cache failed too or critical error.
          if (_isOffline) {
            _error = 'أنت غير متصل بالإنترنت ولا توجد بيانات محفوظة';
          } else {
            _error = 'تحقق من الاتصال بالإنترنت';
          }
          _isLoading = false;
        });
      }
    }
  }

  String _removeDiacritics(String text) {
    const diacritics = '[\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]';
    return text.replaceAll(RegExp(diacritics), '');
  }

  void _filterSurahs() {
    final query = _searchController.text.toLowerCase();
    final normalizedQuery = _removeDiacritics(query);

    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = _surahs;
      } else {
        _filteredSurahs = _surahs.where((s) {
          final normalizedName = _removeDiacritics(s.name);
          return normalizedName.contains(normalizedQuery) ||
              s.name.contains(query) ||
              s.englishName.toLowerCase().contains(query) ||
              s.number.toString() == query;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(isDark, responsive),

          if (_isOffline) _buildOfflineBanner(isDark, responsive),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await QuranRepository.getSurahList(forceRefresh: true);
                _loadData();
              },
              color: isDark ? AppColors.primaryNeon : AppColors.primary,
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              child: _isLoading
                  ? _buildShimmerLoading(isDark)
                  : _error != null
                  ? _buildErrorState(isDark, responsive)
                  : _buildContent(isDark, responsive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(bool isDark, Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isDark ? Colors.grey[800] : Colors.grey[300],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 8),
          Text(
            'لا يوجد اتصال بالإنترنت (وضع القراءة بدون اتصال)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: responsive.sp(12),
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Responsive responsive) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      color: isDark ? const Color(0xFF000000) : Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القرآن الكريم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: responsive.sp(24),
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_filteredSurahs.length} سورة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: responsive.sp(14),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, Responsive responsive) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة...',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF141414)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildHeroCard(isDark, responsive),
              _buildQuickStatsRow(isDark, responsive),
            ],
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final surah = _filteredSurahs[index];
            final lastReadAyah = _lastRead?.lastSurah == surah.number
                ? _lastRead?.lastAyah
                : null;
            final isBookmarked = _bookmarks.any((b) => b.surah == surah.number);

            return _SurahCard(
              surah: surah,
              isDark: isDark,
              responsive: responsive,
              lastReadAyah: lastReadAyah,
              isBookmarked: isBookmarked,
              onTap: () {
                // Get start page from surahStartPage map
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuranReadingPage(
                      surahNumber: surah.number,
                      surahName: surah.name,
                    ),
                  ),
                ).then((_) => _loadData());
              },
            );
          }, childCount: _filteredSurahs.length),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildHeroCard(bool isDark, Responsive responsive) {
    if (_lastRead == null) {
      // NEW USER CARD - Uses Gold/Warmth for Quran
      return Container(
        constraints: const BoxConstraints(minHeight: 180),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF5A4A28), AppColors.accent] // Dark gold
                : [AppColors.accent, AppColors.goldGlow], // Warm gold
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.mosque,
                size: 180,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ابدأ رحلتك القرآنية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: responsive.sp(22),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر سورة للبدء في القراءة والاستماع',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: responsive.sp(14),
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Scroll to surah list or open Al-Fatiha
                      if (_surahs.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QuranReadingPage(
                              surahNumber: 1,
                              surahName: _surahs.first.name,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'ابدأ من الفاتحة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // CONTINUE READING HERO CARD
    if (_surahs.isEmpty) return const SizedBox.shrink();

    final lastSurahMeta = _surahs.firstWhere(
      (s) => s.number == _lastRead!.lastSurah,
      orElse: () => _surahs[0],
    );
    final progress = lastSurahMeta.numberOfAyahs > 0
        ? (_lastRead!.lastAyah / lastSurahMeta.numberOfAyahs).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 400),
                reverseTransitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    QuranReadingPage(
                      surahNumber: _lastRead!.lastSurah,
                      surahName: lastSurahMeta.name,
                      initialAyah: _lastRead!.lastAyah,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
              ),
            )
            .then((_) => _loadData());
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 160, maxHeight: 200),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0D4A42), const Color(0xFF14B8A6)]
                : [const Color(0xFF0D4A42), const Color(0xFF0F766E)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Subtle pattern
              Positioned(
                right: -30,
                bottom: -30,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: Badge + Play button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'واصل القراءة',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFF14B8A6),
                            size: 24,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Surah name (with ellipsis for overflow)
                    Flexible(
                      child: Text(
                        lastSurahMeta.name,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: responsive.sp(24),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    Text(
                      'الآية ${_lastRead!.lastAyah} من ${lastSurahMeta.numberOfAyahs}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: responsive.sp(12),
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(bool isDark, Responsive responsive) {
    return Container(
      height: 64,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatPill(
            'مرجعيات',
            '${_bookmarks.length}',
            Icons.bookmark_rounded,
            const Color(0xFFFFD600),
            isDark,
          ),
          const SizedBox(width: 10),
          _buildStatPill(
            'قراءة اليوم',
            '$_minutesToday د',
            Icons.schedule_rounded,
            const Color(0xFF14B8A6),
            isDark,
          ),
          const SizedBox(width: 10),
          _buildStatPill(
            'التتابع',
            '$_streak',
            Icons.local_fire_department_rounded,
            const Color(0xFFFF6B6B),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return Center(
      child: StreamBuilder<double>(
        stream: QuranSyncService.instance.progressStream,
        builder: (context, snapshot) {
          final isDownloading = snapshot.hasData && snapshot.data! < 1.0;
          final progress = snapshot.data ?? 0.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: isDownloading
                    ? CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        strokeWidth: 4,
                        color: isDark
                            ? const Color(0xFF14B8A6)
                            : const Color(0xFF0D9488),
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                      )
                    : CircularProgressIndicator(
                        strokeWidth: 4,
                        color: isDark
                            ? const Color(0xFF14B8A6)
                            : const Color(0xFF0D9488),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                isDownloading
                    ? 'جاري تنزيل الملفات (${(progress * 100).toInt()}%)'
                    : 'جاري تحميل البيانات...',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              if (isDownloading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'يرجى عدم إغلاق التطبيق',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Responsive responsive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Error',
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'Cairo',
              fontSize: responsive.sp(16),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _checkInitialConnectivity();
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahCard extends StatefulWidget {
  final SurahMeta surah;
  final bool isDark;
  final Responsive responsive;
  final int? lastReadAyah;
  final bool isBookmarked;
  final VoidCallback onTap;

  const _SurahCard({
    required this.surah,
    required this.isDark,
    required this.responsive,
    required this.lastReadAyah,
    required this.isBookmarked,
    required this.onTap,
  });

  @override
  State<_SurahCard> createState() => _SurahCardState();
}

class _SurahCardState extends State<_SurahCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isLastRead = widget.lastReadAyah != null;
    final progress = isLastRead && widget.surah.numberOfAyahs > 0
        ? (widget.lastReadAyah! / widget.surah.numberOfAyahs).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Hero(
          tag: 'surah_card_${widget.surah.number}',
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isDark
                      ? [const Color(0xFF0A0A0A), const Color(0xFF0F0F0F)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isDark
                      ? const Color(0xFF1F1F1F)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.isDark
                                ? AppColors.primaryNeon
                                : AppColors.shadow)
                            .withValues(alpha: widget.isDark ? 0.05 : 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 1. LEFT - Surah Number Badge
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isDark
                            ? [
                                AppColors.primaryNeon.withValues(
                                  alpha: 0.9,
                                ), // Slightly reduced if fully opaque before
                                AppColors.primaryNeon.withValues(
                                  alpha: 0.6,
                                ), // Reduced from 0.8
                              ]
                            : [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (widget.isDark
                                      ? AppColors.primaryNeon
                                      : AppColors.primary)
                                  .withValues(alpha: 0.15), // Reduced from 0.3
                          blurRadius: 8, // Reduced from 12
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.surah.number}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        fontSize: widget.responsive.sp(22),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 2. MIDDLE - Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.surah.name,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: widget.responsive.sp(20),
                                  fontWeight: FontWeight.bold,
                                  color: widget.isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Revelation Icon
                            // Revelation Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.surah.isMakki
                                    ? const Color(0xFFFFA000).withValues(
                                        alpha: 0.15,
                                      ) // Amber/Gold
                                    : const Color(
                                        0xFF00BFA5,
                                      ).withValues(alpha: 0.15), // Teal/Green
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.surah.isMakki
                                      ? const Color(
                                          0xFFFFA000,
                                        ).withValues(alpha: 0.4)
                                      : const Color(
                                          0xFF00BFA5,
                                        ).withValues(alpha: 0.4),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.surah.isMakki
                                        ? Icons
                                              .filter_hdr_rounded // Mountain for Makki
                                        : Icons
                                              .mosque_rounded, // Mosque for Madani
                                    size: 10,
                                    color: widget.surah.isMakki
                                        ? const Color(0xFFFFA000)
                                        : const Color(0xFF00BFA5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.surah.isMakki ? 'مكية' : 'مدنية',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: widget.responsive.sp(10),
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                      color: widget.surah.isMakki
                                          ? const Color(0xFFFFA000)
                                          : const Color(0xFF00BFA5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              widget.surah.englishName,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: widget.isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: widget.responsive.sp(13),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Text(
                              '${widget.surah.numberOfAyahs} آية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: widget.isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: widget.responsive.sp(13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. RIGHT - Status
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Bookmark
                      if (widget.isBookmarked)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Icon(
                            Icons.star,
                            color: Color(0xFFFFD600),
                            size: 20,
                          ),
                        ),

                      // Last Read Status
                      if (isLastRead) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF14B8A6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'آية ${widget.lastReadAyah}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: const Color(0xFF14B8A6),
                                fontSize: widget.responsive.sp(12),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Progress Bar
                        Container(
                          width: 50,
                          height: 4,
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? const Color(0xFF1F1F1F)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          alignment:
                              Alignment.centerRight, // Arabic fill from right?
                          // For LTR LinearProgressIndicator is easier, but here custom container
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            alignment: Alignment.centerRight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF14B8A6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
