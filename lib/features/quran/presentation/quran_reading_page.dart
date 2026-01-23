import 'dart:ui'; // For ImageFilter
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
// Unused import removed
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/utils/responsive.dart';
import '../data/models/quran_models.dart';
import '../data/services/quran_cache_service.dart';
import '../data/services/bookmark_service.dart';
import 'widgets/reading_settings_sheet.dart';
import 'widgets/quran_audio_player.dart';
import 'widgets/ayah_context_menu.dart';
import 'widgets/parchment_background.dart';
import 'dart:async';
import '../data/services/reading_stats_service.dart';

class QuranReadingPage extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? initialAyah; // 1-based

  const QuranReadingPage({
    super.key,
    required this.surahNumber,
    required this.surahName,
    this.initialAyah,
  });

  @override
  State<QuranReadingPage> createState() => _QuranReadingPageState();
}

class _QuranReadingPageState extends State<QuranReadingPage>
    with WidgetsBindingObserver {
  late int _currentSurahNumber;
  Surah? _surah;
  bool _isLoading = true;
  String? _error;
  late PageController _pageController;

  bool _showControls = true;
  ScrollController? _scrollController;

  // Settings
  QuranReadingSettings _settings = QuranReadingSettings();
  bool _isBookmarked = false;
  int? _highlightedAyahId;

  // Audio
  // Audio
  bool _showAudioPlayer = false;

  // Smart Features
  final ReadingStatsService _statsService = ReadingStatsService();
  final Stopwatch _sessionTimer = Stopwatch();
  Timer? _autoSaveTimer;
  final Set<int> _readVerses = {}; // Unique verses read this session

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionTimer.start();
    _startAutoSaveTimer();

    _currentSurahNumber = widget.surahNumber;
    _pageController = PageController(
      initialPage: (widget.initialAyah ?? 1) - 1,
    );
    WakelockPlus.enable();
    _loadSettings();
    _loadSurahData();
    // Hide controls after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_sessionTimer.isRunning) {
        _saveCurrentPosition();
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.bookmark_added, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'تم حفظ الموضع تلقائياً',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF14B8A6).withValues(alpha: 0.8),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(milliseconds: 1500),
              width: 200,
            ),
          );
        }
      }
    });
  }

  void _saveCurrentPosition() {
    if (_surah == null || !_pageController.hasClients) return;
    final index = _pageController.page?.round() ?? 0;
    _trackProgress(index);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _recordSession();
    WakelockPlus.disable();
    _pageController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _sessionTimer.stop();
      _recordSession(); // Auto-save on minimize
    } else if (state == AppLifecycleState.resumed) {
      _sessionTimer.start();
    }
  }

  Future<void> _recordSession() async {
    if (_sessionTimer.elapsed.inSeconds < 5) return;
    await _statsService.recordSession(
      durationSeconds: _sessionTimer.elapsed.inSeconds,
      versesRead: _readVerses.length,
      surahNumber: _currentSurahNumber,
    );
    // Reset for next segment if app continues
    _sessionTimer.reset();
    _readVerses.clear();
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _sessionTimer.start();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load persisted values with safe defaults
    final fontSize = prefs.getDouble('quran_fontSize') ?? 28.0;
    final nightMode = prefs.getBool('quran_nightMode') ?? false;
    final readingModeIndex =
        prefs.getInt('quran_readingMode') ?? 0; // Default: Single Verse (0)
    final fontFamily = prefs.getString('quran_fontFamily') ?? 'hafs';
    final reciter = prefs.getString('quran_reciter') ?? 'alafasy';

    // Convert reading mode index to Enum
    ReadingMode mode = ReadingMode.values.length > readingModeIndex
        ? ReadingMode.values[readingModeIndex]
        : ReadingMode.singleVerse;

    if (mounted) {
      setState(() {
        _settings = _settings.copyWith(
          fontSize: fontSize,
          nightMode: nightMode,
          readingMode: mode,
          fontFamily: fontFamily,
          reciter: reciter,
        );
      });
    }
  }

  Future<void> _saveSettings(QuranReadingSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_fontSize', settings.fontSize);
    await prefs.setBool('quran_nightMode', settings.nightMode);
    await prefs.setInt('quran_readingMode', settings.readingMode.index);
    await prefs.setString('quran_fontFamily', settings.fontFamily);
    await prefs.setString('quran_reciter', settings.reciter);
  }

  void _handleSettingsChange(QuranReadingSettings newSettings) {
    if (newSettings.readingMode != _settings.readingMode) {
      _switchReadingMode(newSettings.readingMode);
    }

    setState(() {
      _settings = newSettings;
    });
    _saveSettings(newSettings);
  }

  void _updateSettings(QuranReadingSettings newSettings) {
    _handleSettingsChange(newSettings);
  }

  void _switchReadingMode(ReadingMode newMode) {
    // If surah is null, we can't do anything.
    if (_surah == null) return;

    int targetIndex = 0;
    // Handle case where controller is attached (SingleVerse/Page) vs not (Continuous)
    final currentIndex = _pageController.hasClients
        ? (_pageController.page?.round() ?? 0)
        : 0;

    // Logic to map current position to new mode's index system
    if (_settings.readingMode == ReadingMode.singleVerse &&
        newMode == ReadingMode.page) {
      // From Ayah Index -> Page Index (relative to surah pages)
      if (currentIndex < _surah!.ayahs.length) {
        final ayah = _surah!.ayahs[currentIndex];
        // Calculate which page index this ayah falls into
        Map<int, List<Ayah>> pages = {};
        for (var a in _surah!.ayahs) {
          if (!pages.containsKey(a.page)) pages[a.page] = [];
          pages[a.page]!.add(a);
        }
        final pageKeys = pages.keys.toList()..sort();
        targetIndex = pageKeys.indexOf(ayah.page);
        if (targetIndex == -1) targetIndex = 0;
      }
    } else if (_settings.readingMode == ReadingMode.page &&
        newMode == ReadingMode.singleVerse) {
      // From Page Index -> Ayah Index (First ayah of that page)
      Map<int, List<Ayah>> pages = {};
      for (var a in _surah!.ayahs) {
        if (!pages.containsKey(a.page)) pages[a.page] = [];
        pages[a.page]!.add(a);
      }
      final pageKeys = pages.keys.toList()..sort();

      if (currentIndex >= 0 && currentIndex < pageKeys.length) {
        final pageNum = pageKeys[currentIndex];
        final firstAyah = pages[pageNum]?.first;
        if (firstAyah != null) {
          targetIndex = firstAyah.numberInSurah - 1; // 0-based index
        }
      }
    } else {
      // For continuous strings or generic resets
      targetIndex = 0;
    }

    // Re-create controller to avoid animation jumps
    if (_pageController.hasClients) {
      _pageController.dispose();
    }
    _pageController = PageController(initialPage: targetIndex);
    // We don't dispose old immediately if it's currently attached to view in build?
    // Actually safe to replace, build will pick it up next frame.
    //oldController.dispose(); // Can rely on GC or explicit dispose later? safest to just let variable overwrite.
  }

  Future<void> _loadSurahData([int? startAyah]) async {
    // If loading a new surah (not initial), reset loading state
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final surah = await QuranRepository.getSurah(_currentSurahNumber);

      if (mounted) {
        setState(() {
          _surah = surah;
          _isLoading = false;
        });

        // If we have a target ayah (e.g. from transition), jump to it
        // The PageController might need re-attaching or jumping if it's already built
        if (startAyah != null && _pageController.hasClients) {
          _pageController.jumpToPage(startAyah - 1);
        }

        _checkBookmarkStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في تحميل السورة';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _advanceToNextSurah() async {
    if (_currentSurahNumber >= 114) return;

    _currentSurahNumber++;
    // Load next surah and jump to Ayah 1 (index 0)
    await _loadSurahData(1);
    // Note: _loadSurahData handles the jump
  }

  Future<void> _trackProgress(int index) async {
    if (_surah == null) return;
    // Add to smart tracker
    _readVerses.add(index);

    final ayah = _surah!.ayahs[index];
    await QuranRepository.updateProgress(
      surahNumber: _currentSurahNumber,
      ayahNumber: ayah.numberInSurah,
      pageNumber: ayah.page,
      juzNumber: ayah.juz,
    );

    // Achievement: Surah Completion
    if (index == _surah!.ayahs.length - 1) {
      _showPremiumToast(
        'أتممت سورة ${_surah!.name} بفضل الله! 🎉',
        icon: Icons.check_circle_outline,
        color: const Color(0xFFFFD600), // Gold
      );
      HapticFeedback.heavyImpact();
    }
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    if (_surah == null || !_pageController.hasClients) {
      return;
    }
    // Safety check for index
    if (!_pageController.hasClients) return;

    int index = 0;
    try {
      index = _pageController.page?.round() ?? 0;
    } catch (e) {
      index = 0;
    }

    if (index < _surah!.ayahs.length) {
      final ayah = _surah!.ayahs[index];
      final isBookmarked = await BookmarkService.isBookmarked(
        _currentSurahNumber,
        ayah.numberInSurah,
      );
      if (mounted) {
        setState(() => _isBookmarked = isBookmarked);
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (_surah == null) return;
    final index = _pageController.page?.round() ?? 0;
    final ayah = _surah!.ayahs[index];

    if (_isBookmarked) {
      await BookmarkService.removeBookmark(
        _currentSurahNumber,
        ayah.numberInSurah,
      );
      _showPremiumToast('تم حذف المرجعية', icon: Icons.bookmark_border);
    } else {
      await BookmarkService.addBookmark(
        _currentSurahNumber,
        ayah.numberInSurah,
        note: _surah!.name,
      );
      _showPremiumToast(
        'تم حفظ المرجعية',
        icon: Icons.bookmark,
        color: const Color(0xFFFFD600),
      );
    }
    _checkBookmarkStatus();
  }

  void _onSettingsPressed() {
    ReadingSettingsSheet.show(
      context,
      settings: _settings,
      onSettingsChanged: _handleSettingsChange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.nightMode;
    final bgColor = _settings.backgroundColor;

    // If loading initial data
    if (_isLoading && _surah == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
        ),
      );
    }

    if (_error != null && _surah == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(height: 24),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _loadSurahData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'العودة للقائمة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_surah == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text(
            _error ?? 'حدث خطأ في تحميل السورة',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Stack(
            children: [
              // CONTENT
              Positioned.fill(
                child: ParchmentBackground(
                  isDark: isDark,
                  child: _buildReadingBody(),
                ),
              ),

              // APP BAR (Overlay - Premium)
              // APP BAR (Floating Glass - Premium)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: SafeArea(
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.92,
                              height: 60,
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.black : Colors.white)
                                    .withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12,
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: NavigationToolbar(
                                centerMiddle: true,
                                leading: Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    tooltip: 'رجوع',
                                    splashRadius: 24,
                                  ),
                                ),
                                middle: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _surah?.name ?? widget.surahName,
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    Container(
                                      height: 3,
                                      width: 20,
                                      margin: const EdgeInsets.only(top: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF14B8A6),
                                        borderRadius: BorderRadius.circular(
                                          1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: IconButton(
                                        icon: Icon(
                                          _isBookmarked
                                              ? Icons.bookmark_rounded
                                              : Icons.bookmark_border_rounded,
                                          size: 22,
                                          color: const Color(0xFF14B8A6),
                                        ),
                                        onPressed: _toggleBookmark,
                                        tooltip: 'حفظ المرجعية',
                                        splashRadius: 24,
                                      ),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.tune_rounded,
                                          size: 22,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        onPressed: _onSettingsPressed,
                                        tooltip: 'الإعدادات',
                                        splashRadius: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // FLOATING FOOTER CONTROLS
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.92,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.black : Colors.white)
                                      .withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12,
                                    width: 0.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'الجزء ${_surah != null && _surah!.ayahs.isNotEmpty ? _surah!.ayahs.first.juz : 1}',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          'آية ${(_pageController.hasClients ? (_pageController.page?.round() ?? 0) + 1 : 1)} من ${_surah?.numberOfAyahs ?? 0}',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value:
                                            (_pageController.hasClients &&
                                                _surah != null &&
                                                _surah!.numberOfAyahs > 0)
                                            ? (((_pageController.page
                                                              ?.round() ??
                                                          0) +
                                                      1) /
                                                  _surah!.numberOfAyahs)
                                            : 0,
                                        backgroundColor: isDark
                                            ? Colors.white10
                                            : Colors.black12,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF14B8A6),
                                            ),
                                        minHeight: 4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildFooterIconButton(
                                          Icons.playlist_play_rounded,
                                          'الفهرس',
                                          isDark,
                                          () {},
                                        ),
                                        _buildFooterIconButton(
                                          Icons.play_circle_fill_rounded,
                                          'تشغيل',
                                          isDark,
                                          () => setState(
                                            () => _showAudioPlayer = true,
                                          ),
                                          isPrimary: true,
                                        ),
                                        _buildFooterIconButton(
                                          Icons.search_rounded,
                                          'بحث',
                                          isDark,
                                          () {},
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // AUDIO PLAYER BOTTOM SHEET
              if (_showAudioPlayer && _surah != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: QuranAudioPlayer(
                    ayah:
                        _surah!.ayahs[_pageController.hasClients
                            ? (_pageController.page?.round() ?? 0)
                            : 0],
                    surahName: _surah!.name,
                    reciterId: _settings.reciter, // Use setting
                    onNext: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    onPrevious: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),

              // CLOSE AUDIO BUTTON (When audio is active)
              if (_showAudioPlayer)
                Positioned(
                  bottom: 100, // Above player
                  right: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.black54,
                    child: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _showAudioPlayer = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPremiumToast(String message, {IconData? icon, Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: (color ?? const Color(0xFF14B8A6)).withValues(
          alpha: 0.95,
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildReadingBody() {
    // FOCUS MODE (Default)
    if (_settings.readingMode == ReadingMode.singleVerse) {
      return GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: PageView.builder(
          controller: _pageController,
          reverse: true,
          itemCount: _surah!.ayahs.length + (_currentSurahNumber < 114 ? 1 : 0),
          onPageChanged: (index) {
            HapticFeedback.selectionClick();
            setState(() => _showControls = false);
            if (index < _surah!.ayahs.length) _trackProgress(index);
          },
          itemBuilder: (context, index) {
            if (index == _surah!.ayahs.length) {
              return _NextSurahLoader(
                nextSurahNumber: _currentSurahNumber + 1,
                onLoad: _advanceToNextSurah,
                isDark: _settings.nightMode,
              );
            }
            return _PremiumAyahView(
              ayah: _surah!.ayahs[index],
              surahNumber: _currentSurahNumber,
              surahName: _surah!.name,
              totalAyahs: _surah!.numberOfAyahs,
              settings: _settings,
              onTap: () => setState(() => _showControls = !_showControls),
              showActions: _showControls,
            );
          },
        ),
      );
    }
    // CONTINUOUS FLOW MODE (Mushaf Style Scroll)
    else if (_settings.readingMode == ReadingMode.continuous) {
      return GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
          child: Column(
            children: [
              // HEADER (Surah Name)
              if (_surah != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'سورة ${_surah!.name}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF14B8A6),
                    ),
                  ),
                ),

              // RUNNING TEXT
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text.rich(
                  TextSpan(
                    children: _surah!.ayahs.expand((ayah) {
                      final isHighlighted =
                          _highlightedAyahId == ayah.numberInSurah;
                      final highlightColor = _settings.nightMode
                          ? const Color(0xFF00D9C0).withValues(alpha: 0.2)
                          : const Color(0xFFD4A853).withValues(alpha: 0.25);

                      return [
                        TextSpan(
                          text: '${ayah.text} ',
                          style: TextStyle(
                            fontFamily: _settings.fontStyle == 'traditional'
                                ? 'Cairo'
                                : 'Amiri',
                            fontSize: _settings.fontSize,
                            color: _settings.nightMode
                                ? Colors.white
                                : Colors.black,
                            height: 2.2,
                            backgroundColor: isHighlighted
                                ? highlightColor
                                : Colors.transparent,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              setState(() {
                                _highlightedAyahId = ayah.numberInSurah;
                              });
                              HapticFeedback.selectionClick();
                              await AyahContextMenu.show(
                                context,
                                surah: _currentSurahNumber,
                                ayah: ayah.numberInSurah,
                                ayahText: ayah.text,
                                isDark: _settings.nightMode,
                              );
                              if (mounted) {
                                setState(() {
                                  _highlightedAyahId = null;
                                });
                              }
                            },
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _VerseMarker(
                            surahNumber: _currentSurahNumber,
                            number: ayah.numberInSurah,
                            verseText: ayah.text,
                            isDark: _settings.nightMode,
                            fontSize: _settings.fontSize,
                          ),
                        ),
                        const TextSpan(text: '  '),
                      ];
                    }).toList(),
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),

              const SizedBox(height: 32),

              // Next Surah Loader
              _NextSurahLoader(
                nextSurahNumber: _currentSurahNumber + 1,
                onLoad: _advanceToNextSurah,
                isDark: _settings.nightMode,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }
    // MUSHAF PAGE MODE (Grouped)
    else {
      // MUSHAF PAGE MODE (Grouped)
      Map<int, List<Ayah>> pages = {};
      for (var a in _surah!.ayahs) {
        if (!pages.containsKey(a.page)) pages[a.page] = [];
        pages[a.page]!.add(a);
      }
      final pageKeys = pages.keys.toList()..sort();

      return GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: PageView.builder(
          reverse: true,
          itemCount: pageKeys.length + (_currentSurahNumber < 114 ? 1 : 0),
          onPageChanged: (index) {
            // Track progress when viewing last page
            if (index < pageKeys.length) {
              final pageAyahs = pages[pageKeys[index]]!;
              for (var ayah in pageAyahs) {
                _readVerses.add(ayah.numberInSurah - 1);
              }
              // If this is the last page, track completion
              if (index == pageKeys.length - 1) {
                _trackProgress(_surah!.ayahs.length - 1);
              }
            }
          },
          itemBuilder: (context, index) {
            // Show "Next Surah" loader at the end
            if (index == pageKeys.length) {
              return _NextSurahLoader(
                nextSurahNumber: _currentSurahNumber + 1,
                onLoad: _advanceToNextSurah,
                isDark: _settings.nightMode,
              );
            }
            final pageAyahs = pages[pageKeys[index]]!;
            final isDark = _settings.nightMode;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.4),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text.rich(
                        TextSpan(
                          children: pageAyahs.expand((ayah) {
                            return [
                              TextSpan(
                                text: '${ayah.text} ',
                                style: TextStyle(
                                  fontFamily:
                                      _settings.fontStyle == 'traditional'
                                      ? 'Cairo'
                                      : 'Amiri',
                                  fontSize: _settings.fontSize * 0.8,
                                  color: isDark ? Colors.white : Colors.black,
                                  height: 2.0,
                                ),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: _VerseMarker(
                                  surahNumber: _currentSurahNumber,
                                  number: ayah.numberInSurah,
                                  verseText: ayah.text,
                                  isDark: isDark,
                                  fontSize: _settings.fontSize,
                                ),
                              ),
                              const TextSpan(text: '  '), // Small gap
                            ];
                          }).toList(),
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Premium Page Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1A1A1A),
                                  const Color(0xFF2D2D2D),
                                ]
                              : [const Color(0xFFF5F5F5), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF14B8A6,
                            ).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${pageKeys[index]}',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF14B8A6)
                              : const Color(0xFF0D9488),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildFooterIconButton(
    IconData icon,
    String label,
    bool isDark,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isPrimary ? const Color(0xFF14B8A6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isPrimary
                    ? null
                    : Border.all(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
              ),
              child: Icon(
                icon,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _NextSurahLoader extends StatefulWidget {
  final int nextSurahNumber;
  final VoidCallback onLoad;
  final bool isDark;

  const _NextSurahLoader({
    required this.nextSurahNumber,
    required this.onLoad,
    required this.isDark,
  });

  @override
  State<_NextSurahLoader> createState() => _NextSurahLoaderState();
}

class _NextSurahLoaderState extends State<_NextSurahLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Surah names for display
  static const _surahNames = [
    '',
    'الفاتحة',
    'البقرة',
    'آل عمران',
    'النساء',
    'المائدة',
    'الأنعام',
    'الأعراف',
    'الأنفال',
    'التوبة',
    'يونس',
    'هود',
    'يوسف',
    'الرعد',
    'إبراهيم',
    'الحجر',
    'النحل',
    'الإسراء',
    'الكهف',
    'مريم',
    'طه',
    'الأنبياء',
    'الحج',
    'المؤمنون',
    'النور',
    'الفرقان',
    'الشعراء',
    'النمل',
    'القصص',
    'العنكبوت',
    'الروم',
    'لقمان',
    'السجدة',
    'الأحزاب',
    'سبأ',
    'فاطر',
    'يس',
    'الصافات',
    'ص',
    'الزمر',
    'غافر',
    'فصلت',
    'الشورى',
    'الزخرف',
    'الدخان',
    'الجاثية',
    'الأحقاف',
    'محمد',
    'الفتح',
    'الحجرات',
    'ق',
    'الذاريات',
    'الطور',
    'النجم',
    'القمر',
    'الرحمن',
    'الواقعة',
    'الحديد',
    'المجادلة',
    'الحشر',
    'الممتحنة',
    'الصف',
    'الجمعة',
    'المنافقون',
    'التغابن',
    'الطلاق',
    'التحريم',
    'الملك',
    'القلم',
    'الحاقة',
    'المعارج',
    'نوح',
    'الجن',
    'المزمل',
    'المدثر',
    'القيامة',
    'الإنسان',
    'المرسلات',
    'النبأ',
    'النازعات',
    'عبس',
    'التكوير',
    'الإنفطار',
    'المطففين',
    'الإنشقاق',
    'البروج',
    'الطارق',
    'الأعلى',
    'الغاشية',
    'الفجر',
    'البلد',
    'الشمس',
    'الليل',
    'الضحى',
    'الشرح',
    'التين',
    'العلق',
    'القدر',
    'البينة',
    'الزلزلة',
    'العاديات',
    'القارعة',
    'التكاثر',
    'العصر',
    'الهمزة',
    'الفيل',
    'قريش',
    'الماعون',
    'الكوثر',
    'الكافرون',
    'النصر',
    'المسد',
    'الإخلاص',
    'الفلق',
    'الناس',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    // Delay before auto-advancing to show the card
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) widget.onLoad();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextName = widget.nextSurahNumber <= 114
        ? _surahNames[widget.nextSurahNumber]
        : '';

    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: const Color(0xFF14B8A6),
                ),
                const SizedBox(height: 16),
                Text(
                  'أتممت السورة بفضل الله! 🎉',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'السورة التالية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'سورة $nextName',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF14B8A6),
                        ),
                      ),
                      Text(
                        '(${widget.nextSurahNumber})',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'جاري الانتقال...',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: widget.isDark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumAyahView extends StatefulWidget {
  final Ayah ayah;
  final int surahNumber;
  final String surahName;
  final int totalAyahs;
  final QuranReadingSettings settings;
  final VoidCallback onTap;
  final bool showActions;

  const _PremiumAyahView({
    required this.ayah,
    required this.surahNumber,
    required this.surahName,
    required this.totalAyahs,
    required this.settings,
    required this.onTap,
    required this.showActions,
  });

  @override
  State<_PremiumAyahView> createState() => _PremiumAyahViewState();
}

class _PremiumAyahViewState extends State<_PremiumAyahView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PremiumAyahView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ayah.numberInSurah != oldWidget.ayah.numberInSurah) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.settings.nightMode;
    final responsive = Responsive(context);

    // Background should be handled by parent (ParchmentBackground)
    const bgColor = Colors.transparent;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          color: bgColor, // Fill screen
          child: Stack(
            children: [
              // Main Content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 80), // More space for header
                    // ANIMATED BADGE
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: GestureDetector(
                        onTap: () => _showContextMenu(context),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: CustomPaint(
                            painter: AyahMarkerPainter(
                              color: const Color(0xFF14B8A6),
                              isDark: isDark,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.ayah.numberInSurah}',
                                style: TextStyle(
                                  fontFamily: 'Amiri', // Classical font
                                  fontSize: responsive.sp(20),
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // BISMILLAH (Conditional)
                    if (widget.ayah.numberInSurah == 1 &&
                        widget.surahName != 'سورة التوبة') ...[
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                          style: TextStyle(
                            fontFamily:
                                widget.settings.fontStyle == 'traditional'
                                ? 'Cairo'
                                : 'Amiri',
                            fontSize: widget.settings.fontSize,
                            color: isDark ? Colors.white : Colors.black,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // ARABIC TEXT HERO
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        widget.ayah.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: widget.settings.fontStyle == 'traditional'
                              ? 'Cairo'
                              : 'Amiri',
                          fontSize: 36, // Larger and more readable
                          height: 2.2,
                          color: isDark ? Colors.white : Colors.black,
                          shadows: isDark
                              ? [
                                  Shadow(
                                    color: const Color(
                                      0xFF14B8A6,
                                    ).withValues(alpha: 0.1),
                                    blurRadius: 20,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // END MARKER
                    Icon(
                      Icons.local_florist, // Ornamental placeholder
                      size: 28,
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.8),
                    ),

                    const SizedBox(height: 32),

                    // TRANSLATION BOX
                    if (widget.settings.showTranslation &&
                        widget.ayah.translation != null)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A1A1A).withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border(
                              left: const BorderSide(
                                color: Color(0xFF14B8A6),
                                width: 4,
                              ),
                            ),
                          ),
                          child: Text(
                            widget.ayah.translation!,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontFamily: 'Cairo', // Clean font
                              fontSize: 17,
                              height: 1.8,
                              color: isDark
                                  ? const Color(0xFFA1A1A1)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 120), // Bottom padding
                  ],
                ),
              ),

              // ACTION BUTTONS (Floating Slide Up)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                bottom: widget.showActions ? 100 : -80, // Above bottom controls
                left: 40,
                right: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            Icons.copy,
                            isDark,
                            () => _copyAyah(),
                          ),
                          _buildActionButton(Icons.share, isDark, () {}),
                          _buildActionButton(
                            Icons.bookmark_border,
                            isDark,
                            () {},
                          ),
                          _buildActionButton(
                            Icons.menu_book,
                            isDark,
                            () => _showContextMenu(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    AyahContextMenu.show(
      context,
      surah: widget.surahNumber,
      ayah: widget.ayah.numberInSurah,
      ayahText: widget.ayah.text,
      isDark: widget.settings.nightMode,
    );
  }

  void _copyAyah() {
    final text =
        '${widget.ayah.text}\n\n[سورة ${widget.surahName} : ${widget.ayah.numberInSurah}]';
    Clipboard.setData(ClipboardData(text: text));
  }

  Widget _buildActionButton(IconData icon, bool isDark, VoidCallback onTap) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : Colors.black54,
        ),
      ),
    );
  }
}

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;
  final double scale;

  const ScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(milliseconds: 100),
    this.scale = 0.95,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Verse Number Marker - Tappable for Context Menu
class _VerseMarker extends StatelessWidget {
  final int surahNumber;
  final int number;
  final String verseText;
  final bool isDark;
  final double fontSize;

  const _VerseMarker({
    required this.surahNumber,
    required this.number,
    required this.verseText,
    required this.isDark,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    const markerColor = Color(0xFF00D9C0);

    return GestureDetector(
      onTap: () {
        AyahContextMenu.show(
          context,
          surah: surahNumber,
          ayah: number,
          ayahText: verseText,
          isDark: isDark,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 36,
        height: 36,
        child: CustomPaint(
          painter: AyahMarkerPainter(color: markerColor, isDark: isDark),
          child: Center(
            child: Text(
              _toArabicNumber(number),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: markerColor,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}

class AyahMarkerPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  AyahMarkerPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    // 1. Outer circle
    canvas.drawCircle(center, radius * 0.88, paint);

    // 2. Inner circle (thinner)
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius * 0.70, innerPaint);

    // 3. Crown/Bow ornament at the top
    final topY = center.dy - (radius * 0.88);
    final crownPath = Path();

    // Left bow
    crownPath.moveTo(center.dx - 5, topY + 1);
    crownPath.quadraticBezierTo(center.dx - 3, topY - 4, center.dx, topY - 5);
    // Right bow
    crownPath.quadraticBezierTo(
      center.dx + 3,
      topY - 4,
      center.dx + 5,
      topY + 1,
    );

    canvas.drawPath(crownPath, paint);

    // 4. Small bottom dot
    final bottomY = center.dy + (radius * 0.88);
    canvas.drawCircle(
      Offset(center.dx, bottomY + 2),
      1.5,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant AyahMarkerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}
