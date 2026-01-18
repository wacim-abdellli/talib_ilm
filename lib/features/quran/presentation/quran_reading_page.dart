import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
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

  // Audio
  // Audio
  bool _showAudioPlayer = false;

  // Smart Features
  final ReadingStatsService _statsService = ReadingStatsService();
  final Stopwatch _sessionTimer = Stopwatch();
  Timer? _autoSaveTimer;
  final Set<int> _readVerses = {}; // Unique verses read this session

  Widget _buildCircleButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: color ?? (isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }

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
    // Load settings from prefs if needed, or use defaults
    // For now simple load/save implemented in sheet
    // We try to load saved font size etc
    final fontSize = prefs.getDouble('quran_fontSize') ?? 28.0;
    final nightMode = prefs.getBool('quran_nightMode') ?? false;
    // ... load other settings ...
    if (mounted) {
      setState(() {
        _settings = _settings.copyWith(
          fontSize: fontSize,
          nightMode: nightMode,
          // Load others...
        );
      });
    }
  }

  Future<void> _saveSettings(QuranReadingSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_fontSize', settings.fontSize);
    await prefs.setBool('quran_nightMode', settings.nightMode);
    // ... save others
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
      onSettingsChanged: (newSettings) {
        setState(() => _settings = newSettings);
        _saveSettings(newSettings);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.nightMode;
    final bgColor = _settings.backgroundColor;
    final responsive = Responsive(context);

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
              _buildReadingBody(),

              // APP BAR (Overlay - Premium)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: _showControls ? 0 : -140, // Height increased
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: 130 + MediaQuery.of(context).padding.top,
                      ),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: 0.8),
                        border: Border(
                          bottom: BorderSide(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.05),
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ROW 1: Navigation & Title
                          Row(
                            children: [
                              // Back Button
                              _buildCircleButton(
                                icon: Icons.arrow_back,
                                isDark: isDark,
                                onTap: () => Navigator.pop(context),
                              ),

                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _surah?.name ?? '',
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontWeight: FontWeight.bold,
                                        fontSize: responsive.sp(18),
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${_surah?.number ?? 0} سورة',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: responsive.sp(10),
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              Row(
                                children: [
                                  _buildCircleButton(
                                    icon: Icons.settings_outlined,
                                    isDark: isDark,
                                    onTap: _onSettingsPressed,
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, anim) {
                                      return ScaleTransition(
                                        scale: anim,
                                        child: child,
                                      );
                                    },
                                    child: Container(
                                      key: ValueKey(_isBookmarked),
                                      child: _buildCircleButton(
                                        icon: _isBookmarked
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        isDark: isDark,
                                        color: _isBookmarked
                                            ? const Color(0xFFFFD600)
                                            : null,
                                        onTap: () {
                                          HapticFeedback.mediumImpact();
                                          _toggleBookmark();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ROW 2: Progress & Mode
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Progress Text
                              Expanded(
                                child: Text(
                                  'آية ${(_pageController.hasClients ? (_pageController.page?.round() ?? 0) + 1 : 1)} من ${_surah?.numberOfAyahs ?? 0}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: responsive.sp(12),
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // MODE SWITCHER
                              Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildModeButton(
                                      ReadingMode.singleVerse,
                                      Icons.center_focus_strong,
                                      isDark,
                                      "تركيز",
                                    ),
                                    Container(
                                      width: 1,
                                      height: 16,
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                    _buildModeButton(
                                      ReadingMode.continuous,
                                      Icons.view_stream_rounded,
                                      isDark,
                                      "سرد",
                                    ),
                                    Container(
                                      width: 1,
                                      height: 16,
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                    _buildModeButton(
                                      ReadingMode.page,
                                      Icons.menu_book_rounded,
                                      isDark,
                                      "مصحف",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value:
                                  (_pageController.hasClients &&
                                      _surah != null &&
                                      _surah!.numberOfAyahs > 0)
                                  ? (((_pageController.page?.round() ?? 0) +
                                            1) /
                                        _surah!.numberOfAyahs)
                                  : 0,
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF14B8A6),
                              ),
                              minHeight: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // BOTTOM CONTROLS (Overlay)
              // If Audio Player is visible, show it, else show controls
              // Actually, we stack them.
              if (_showControls && !_showAudioPlayer)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withValues(
                        alpha: 0.9,
                      ),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.format_list_bulleted),
                          color: isDark ? Colors.white : Colors.black,
                          onPressed: () {
                            // Show Juz/Page list? Placeholder
                          },
                        ),

                        // Play Audio Button
                        FloatingActionButton(
                          onPressed: () {
                            setState(() => _showAudioPlayer = true);
                          },
                          backgroundColor: const Color(0xFF14B8A6),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          color: isDark ? Colors.white : Colors.black,
                          onPressed: () {
                            // Share logic
                          },
                        ),
                      ],
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

  void _updateSettings(QuranReadingSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _saveSettings(newSettings);
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
    // CONTINUOUS FLOW MODE
    else if (_settings.readingMode == ReadingMode.continuous) {
      return GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 100),
          itemCount: _surah!.ayahs.length + (_currentSurahNumber < 114 ? 1 : 0),
          separatorBuilder: (context, index) => const Divider(height: 32),
          itemBuilder: (context, index) {
            // Show "Next Surah" loader at the end
            if (index == _surah!.ayahs.length) {
              return _NextSurahLoader(
                nextSurahNumber: _currentSurahNumber + 1,
                onLoad: _advanceToNextSurah,
                isDark: _settings.nightMode,
              );
            }
            final ayah = _surah!.ayahs[index];
            final isDark = _settings.nightMode;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF14B8A6)),
                    ),
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                Text(
                  ayah.text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: _settings.fontSize * 0.9,
                    color: isDark ? Colors.white : Colors.black,
                    height: 2.2,
                  ),
                ),
                if (_settings.showTranslation && ayah.translation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    ayah.translation!,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }
    // MUSHAF PAGE MODE (Grouped)
    else {
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
                    ? Colors.black
                    : const Color(0xFFFFF9E6), // Cream for mushaf
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
                                  fontFamily: 'Amiri',
                                  fontSize: _settings.fontSize * 0.8,
                                  color: isDark ? Colors.white : Colors.black,
                                  height: 2.0,
                                ),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF14B8A6),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${ayah.numberInSurah}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'Cairo',
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
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
                    Text(
                      '${pageKeys[index]}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildModeButton(
    ReadingMode mode,
    IconData icon,
    bool isDark,
    String tooltip,
  ) {
    final isActive = _settings.readingMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _updateSettings(_settings.copyWith(readingMode: mode));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF14B8A6) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive
                ? Colors.white
                : (isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      ),
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
              gradient: LinearGradient(
                colors: widget.isDark
                    ? [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)]
                    : [const Color(0xFFFFF9E6), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
  final String surahName;
  final int totalAyahs;
  final QuranReadingSettings settings;
  final VoidCallback onTap;
  final bool showActions;

  const _PremiumAyahView({
    required this.ayah,
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

    // Background Color logic: Pure Black or Cream
    final bgColor = isDark ? Colors.black : const Color(0xFFFDFBF7);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
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
                    const SizedBox(height: 60), // Space for header
                    // ANIMATED BADGE
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: const Color(
                              0xFF14B8A6,
                            ).withValues(alpha: 0.5),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF14B8A6).withValues(alpha: 0.2),
                              const Color(0xFFFFD700).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Text(
                          '${widget.ayah.numberInSurah}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: responsive.sp(18),
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
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
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                          style: TextStyle(
                            fontFamily: 'Amiri',
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
                          fontFamily: 'Amiri', // Premium Uthmanic feel
                          fontSize: 32, // Larger
                          height: 2.5,
                          letterSpacing: 0.5,
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
                                ? const Color(0xFF0F0F0F)
                                : const Color(0xFFF8FAFC),
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
                          _buildActionButton(Icons.copy, isDark, () {}),
                          _buildActionButton(Icons.share, isDark, () {}),
                          _buildActionButton(
                            Icons.bookmark_border,
                            isDark,
                            () {},
                          ), // Logic needs connection
                          _buildActionButton(
                            Icons.menu_book,
                            isDark,
                            () {},
                          ), // Tafsir
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
