import 'dart:ui'; // For ImageFilter
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../data/models/quran_models.dart';
import '../data/services/quran_cache_service.dart';
import '../data/services/bookmark_service.dart';
import '../data/tajweed_rules.dart';
import 'widgets/reading_settings_sheet.dart';
import 'widgets/quran_audio_player.dart';
import 'widgets/ayah_context_menu.dart';
import 'widgets/parchment_background.dart';
import 'dart:async';
import 'package:quran/quran.dart' as quran;
import '../data/services/reading_stats_service.dart'; // Restored Import

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
  bool _showAudioPlayer = false;
  int? _playingAyahNumber; // Currently playing ayah number in surah

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

    WakelockPlus.enable();
    _currentSurahNumber = widget.surahNumber;
    
    // Set immersive status bar - PURE BLACK / TRANSPARENT
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000), // Pure Black
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Calculate initial page based on Surah/Ayah for Mushaf mode
    int initialPage = 0;
    if (widget.initialAyah != null) {
      initialPage =
          quran.getPageNumber(widget.surahNumber, widget.initialAyah!) - 1;
    } else {
      initialPage = quran.getPageNumber(widget.surahNumber, 1) - 1;
    }

    _pageController = PageController(initialPage: initialPage);
    _loadSettings();
    _loadSurahData(); // Keep loading surah for context/audio
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
              backgroundColor: const Color(0xFF2E8B57).withValues(alpha: 0.8),
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
    _saveCurrentPosition(); // Auto-save reading position on exit
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
    final showTajweed = prefs.getBool('quran_showTajweed') ?? false;
    final useEnglishNumbers = prefs.getBool('quran_useEnglishNumbers') ?? false;

    // Convert reading mode index to Enum
    ReadingMode mode = ReadingMode.values.length > readingModeIndex
        ? ReadingMode.values[readingModeIndex]
        : ReadingMode.singleVerse;

    if (mounted) {
      // Calculate correct initial page based on reading mode
      int initialPage = 0;
      if (mode == ReadingMode.singleVerse) {
        // For single verse mode, use ayah index (0-based)
        initialPage = (widget.initialAyah ?? 1) - 1;
      } else {
        // For page/mushaf mode, use Quran page index (0-based for 604 pages)
        if (widget.initialAyah != null) {
          initialPage = quran.getPageNumber(widget.surahNumber, widget.initialAyah!) - 1;
        } else {
          initialPage = quran.getPageNumber(widget.surahNumber, 1) - 1;
        }
      }

      // Re-create page controller with correct initial page
      if (_pageController.hasClients || _pageController.initialPage != initialPage) {
        _pageController.dispose();
        _pageController = PageController(initialPage: initialPage);
      }

      setState(() {
        _settings = _settings.copyWith(
          fontSize: fontSize,
          nightMode: nightMode,
          readingMode: mode,
          fontFamily: fontFamily,
          reciter: reciter,
          showTajweed: showTajweed,
          useEnglishNumbers: useEnglishNumbers,
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
    await prefs.setBool('quran_showTajweed', settings.showTajweed);
    await prefs.setBool('quran_useEnglishNumbers', settings.useEnglishNumbers);
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
      // From Ayah Index -> Mushaf Page Index (0-603)
      if (currentIndex < _surah!.ayahs.length) {
        final ayah = _surah!.ayahs[currentIndex];
        // Get the actual Quran page number and convert to 0-based index
        targetIndex = quran.getPageNumber(_currentSurahNumber, ayah.numberInSurah) - 1;
      } else {
        // Default to first page of current surah
        targetIndex = quran.getPageNumber(_currentSurahNumber, 1) - 1;
      }
    } else if (_settings.readingMode == ReadingMode.page &&
        newMode == ReadingMode.singleVerse) {
      // From Mushaf Page Index (0-603) -> Ayah Index within current surah
      final mushafPage = currentIndex + 1; // Convert to 1-based page number
      
      // Find the first ayah of current surah on this page
      int ayahIndex = 0;
      for (int i = 0; i < _surah!.ayahs.length; i++) {
        final ayahPage = quran.getPageNumber(_currentSurahNumber, _surah!.ayahs[i].numberInSurah);
        if (ayahPage >= mushafPage) {
          ayahIndex = i;
          break;
        }
      }
      targetIndex = ayahIndex;
    } else {
      // For continuous strings or generic resets
      targetIndex = 0;
    }

    // Re-create controller to avoid animation jumps
    if (_pageController.hasClients) {
      _pageController.dispose();
    }
    _pageController = PageController(initialPage: targetIndex);
  }

  Future<void> _loadSurahData([int? startAyah]) async {
    // If loading a new surah (not initial), reset loading state
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Safety check for LateInitializationError during hot reload
      int surahNum;
      try {
        surahNum = _currentSurahNumber;
      } catch (_) {
        surahNum = widget.surahNumber;
        _currentSurahNumber = surahNum;
      }

      final surah = await QuranRepository.getSurah(surahNum);

      if (mounted) {
        if (surah == null) {
          setState(() {
            _error = 'تعذر تحميل السورة. يرجى التحقق من اتصالك بالإنترنت.';
            _isLoading = false;
          });
        } else {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ: $e';
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

    // Achievement: Surah Completion (silent - just haptic)
    if (index == _surah!.ayahs.length - 1) {
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
      HapticFeedback.lightImpact(); // Silent feedback
    } else {
      await BookmarkService.addBookmark(
        _currentSurahNumber,
        ayah.numberInSurah,
        note: _surah!.name,
      );
      HapticFeedback.mediumImpact(); // Silent feedback
    }
    _checkBookmarkStatus();
  }

  void _showAyahContextMenu() {
    if (_surah == null || !_pageController.hasClients) return;
    final index = _pageController.page?.round() ?? 0;
    if (index >= _surah!.ayahs.length) return;
    final ayah = _surah!.ayahs[index];
    
    AyahContextMenu.show(
      context,
      surah: _currentSurahNumber,
      ayah: ayah.numberInSurah,
      ayahText: ayah.text,
      isDark: _settings.nightMode,
      onPlayAudio: () => _playAyahAudio(_currentSurahNumber, ayah.numberInSurah),
    );
  }

  void _onSettingsPressed() {
    ReadingSettingsSheet.show(
      context,
      settings: _settings,
      onSettingsChanged: _handleSettingsChange,
    );
  }

  /// Format number based on settings (Arabic or English)
  String _formatNumber(int number) {
    if (_settings.useEnglishNumbers) {
      return number.toString();
    }
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  /// Convert any Arabic-Indic digits in a text to English digits
  /// Handles both standard Arabic-Indic (٠-٩) and Extended Arabic-Indic (۰-۹)
  String _formatDigitsInText(String text) {
    if (!_settings.useEnglishNumbers) return text;
    // Standard Arabic-Indic numerals (U+0660-U+0669)
    const arabicIndicMap = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    // Extended Arabic-Indic numerals (U+06F0-U+06F9) - used in Persian/Urdu
    const extendedArabicIndicMap = {
      '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
      '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
    };
    String result = text;
    // Replace standard Arabic-Indic digits
    result = result.replaceAllMapped(
      RegExp('[٠-٩]'),
      (m) => arabicIndicMap[m.group(0)!]!,
    );
    // Replace extended Arabic-Indic digits
    result = result.replaceAllMapped(
      RegExp('[۰-۹]'),
      (m) => extendedArabicIndicMap[m.group(0)!]!,
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.nightMode;
    // FORCED: Pure Black for OLED dark mode
    final bgColor = isDark 
        ? const Color(0xFF000000)  // PURE BLACK (FORCED)
        : const Color(0xFFFAF6ED); // Warm cream for light mode

    // If loading initial data
    if (_isLoading && _surah == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)), // Teal
        ),
      );
    }

    if (_error != null && _surah == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Back button row
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Main content
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated icon container
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E8B57).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: Color(0xFF2E8B57),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Title
                      Text(
                        'لا يوجد اتصال بالإنترنت',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Description
                      Text(
                        'يتطلب تحميل السورة لأول مرة اتصالاً بالإنترنت.\nبعد التحميل، ستتمكن من القراءة بدون إنترنت.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Retry button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _loadSurahData(),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E8B57),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Bottom tip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.amber.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'نصيحة: حمّل السور التي تقرأها كثيراً للقراءة بدون إنترنت',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                          ),
                        ),
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveCurrentPosition(); // Auto-save on system back button
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent, // Allow child taps (ayah badges)
          onTap: () {
            setState(() {
              _showControls = !_showControls;
              // Dismiss audio player on tap anywhere
              if (_showAudioPlayer) {
                _showAudioPlayer = false;
                _playingAyahNumber = null;
              }
            });
          },
          child: Stack(
            children: [
              // ═══════════════════════════════════════════════════════════════
              // READING SURFACE (PURE) - No persistent controls
              // ═══════════════════════════════════════════════════════════════
              Positioned.fill(
                child: _buildReadingBody(),
              ),

              // ═══════════════════════════════════════════════════════════════
              // INTERACTION OVERLAY - Only appears on tap
              // ═══════════════════════════════════════════════════════════════
              IgnorePointer(
                ignoring: !_showControls,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _showControls ? 1 : 0,
                  child: Container(
                    color: Colors.transparent,
                    child: SafeArea(
                      child: Column(
                        children: [
                          // ═══════════════ TOP BAR - All controls ═══════════════
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Back button
                                _buildControlButton(
                                  icon: Icons.arrow_forward_ios_rounded,
                                  onTap: () {
                                    _saveCurrentPosition();
                                    Navigator.pop(context);
                                  },
                                ),
                                
                                const SizedBox(width: 4),
                                
                                // Settings button
                                _buildControlButton(
                                  icon: Icons.tune_rounded,
                                  onTap: _onSettingsPressed,
                                  isAccent: true,
                                ),
                                
                                const Spacer(),
                                
                                // Surah name - center
                                Text(
                                  _settings.readingMode == ReadingMode.singleVerse
                                      ? (_surah?.name ?? widget.surahName)
                                      : _getMushafPageSurahName(),
                                  style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                
                                const Spacer(),
                                
                                // Bookmark button
                                _buildControlButton(
                                  icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                  onTap: _toggleBookmark,
                                  isActive: _isBookmarked,
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ═══════════════ AUDIO PLAYER (when active) ═══════════════
              if (_showAudioPlayer && _surah != null && _playingAyahNumber != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: QuranAudioPlayer(
                    key: const ValueKey('quran_audio_player'),
                    ayah: _surah!.ayahs[0], // Base ayah for global number calc
                    surahName: _surah!.name,
                    surahNumber: _currentSurahNumber,
                    totalAyahs: _surah!.ayahs.length,
                    reciterId: _settings.reciter,
                    startingAyahNumber: _playingAyahNumber!,
                    onAyahChanged: (ayahNum) {
                      if (mounted && _playingAyahNumber != ayahNum) {
                        setState(() => _playingAyahNumber = ayahNum);
                      }
                    },
                    onClose: () {
                      if (mounted) {
                        setState(() {
                          _showAudioPlayer = false;
                          _playingAyahNumber = null;
                        });
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the proper AppBar with clean structure
  PreferredSizeWidget _buildAppBar(bool isDark, Color bgColor) {
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Settings button
            _buildAppBarButton(
              icon: Icons.tune_rounded,
              onTap: _onSettingsPressed,
              color: isDark ? Colors.white70 : Colors.black54,
              isDark: isDark,
            ),
            
            const SizedBox(width: 10),
            
            // Center title container
            Expanded(
              child: Container(
                height: 44, // Fixed height to prevent overflow
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _settings.readingMode == ReadingMode.singleVerse
                          ? (_surah?.name ?? widget.surahName)
                          : _getMushafPageSurahName(),
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.1,
                        color: isDark
                            ? const Color(0xFFE8D4A0)
                            : const Color(0xFF5D4E37),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _settings.readingMode == ReadingMode.singleVerse
                          ? 'آية ${_formatNumber((_pageController.hasClients ? (_pageController.page?.round() ?? 0) + 1 : 1))} من ${_formatNumber(_surah?.numberOfAyahs ?? 0)}'
                          : 'صفحة ${_formatNumber(_getMushafCurrentPage())} • جزء ${_formatNumber(_getMushafCurrentJuz())}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        height: 1.2,
                        color: Color(0xFF2E8B57),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 10),
            
            // Bookmark button
            _buildAppBarButton(
              icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              onTap: _toggleBookmark,
              color: const Color(0xFFD4AF37),
              isDark: isDark,
            ),
            
            const SizedBox(width: 8),
            
            // Back button (RTL - arrow forward)
            _buildAppBarButton(
              icon: Icons.arrow_forward_ios,
              onTap: () {
                _saveCurrentPosition();
                Navigator.pop(context);
              },
              color: isDark ? Colors.white : Colors.black87,
              isDark: isDark,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Build floating header that appears on tap
  Widget _buildFloatingHeader(bool isDark, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Settings button
                _buildHeaderButton(
                  icon: Icons.tune_rounded,
                  onTap: _onSettingsPressed,
                  color: isDark ? Colors.white70 : Colors.black54,
                  isDark: isDark,
                ),
                
                const SizedBox(width: 8),
                
                // Center title
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _settings.readingMode == ReadingMode.singleVerse
                            ? (_surah?.name ?? widget.surahName)
                            : _getMushafPageSurahName(),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.2,
                          color: isDark
                              ? const Color(0xFFE8D4A0)
                              : const Color(0xFF5D4E37),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _settings.readingMode == ReadingMode.singleVerse
                            ? 'آية ${_formatNumber((_pageController.hasClients ? (_pageController.page?.round() ?? 0) + 1 : 1))} من ${_formatNumber(_surah?.numberOfAyahs ?? 0)}'
                            : 'صفحة ${_formatNumber(_getMushafCurrentPage())} • جزء ${_formatNumber(_getMushafCurrentJuz())}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          height: 1.2,
                          color: Color(0xFF2E8B57),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Bookmark button
                _buildHeaderButton(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  onTap: _toggleBookmark,
                  color: const Color(0xFFD4AF37),
                  isDark: isDark,
                ),
                
                const SizedBox(width: 8),
                
                // Back button
                _buildHeaderButton(
                  icon: Icons.arrow_forward_ios,
                  onTap: () {
                    _saveCurrentPosition();
                    Navigator.pop(context);
                  },
                  color: isDark ? Colors.white : Colors.black87,
                  isDark: isDark,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to build floating header buttons
  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
    double size = 20,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }

  /// Helper to build consistent AppBar buttons
  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
    double size = 20,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }

  /// Helper to build control buttons for the overlay
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isAccent = false,
    bool isActive = false,
    double size = 20,
  }) {
    final Color bgColor = isAccent 
        ? const Color(0xFFFFC107)
        : isActive 
            ? const Color(0xFFFFC107).withValues(alpha: 0.2)
            : const Color(0xFF2A2A2A);
    final Color iconColor = isAccent 
        ? const Color(0xFF1A1A1A)
        : isActive 
            ? const Color(0xFFFFC107)
            : Colors.white.withValues(alpha: 0.9);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: size, color: iconColor),
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
        backgroundColor: (color ?? const Color(0xFF2E8B57)).withValues(
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

  // Helper methods for Mushaf page info in header
  String _getMushafPageSurahName() {
    if (!_pageController.hasClients) return 'المصحف الشريف';
    final pageNum = (_pageController.page?.round() ?? 0) + 1;
    final pageData = quran.getPageData(pageNum);
    if (pageData.isEmpty) return 'المصحف الشريف';
    final surahNum = pageData.first['surah'] as int?;
    if (surahNum == null || surahNum <= 0) return 'المصحف الشريف';
    return quran.getSurahNameArabic(surahNum);
  }

  int _getMushafCurrentPage() {
    if (!_pageController.hasClients) return 1;
    return (_pageController.page?.round() ?? 0) + 1;
  }

  int _getMushafCurrentJuz() {
    if (!_pageController.hasClients) return 1;
    final pageNum = (_pageController.page?.round() ?? 0) + 1;
    final pageData = quran.getPageData(pageNum);
    if (pageData.isEmpty) return 1;
    final surahNum = (pageData.first['surah'] as int?) ?? 1;
    final startAyah = (pageData.first['start'] as int?) ?? 1;
    return quran.getJuzNumber(surahNum, startAyah);
  }

  Widget _buildReadingBody() {
    if (_settings.readingMode == ReadingMode.singleVerse) {
      if (_surah == null) return const SizedBox();
      return GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: PageView.builder(
          controller: _pageController,
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
            );
          },
        ),
      );
    }
    // MUSHAF PAGE MODE (Replaces Continuous & Old Page Mode)
    else {
      // MUSHAF PAGE MODE (Fixed Layout using quran package)
      return GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: PageView.builder(
          controller: _pageController,
          itemCount: 604,
          physics: const BouncingScrollPhysics(),
          pageSnapping: true,
          onPageChanged: (index) {
            HapticFeedback.selectionClick();
            // Check for surah transition
            _checkSurahTransition(index + 1);
            
            // Auto-sync audio player with page change
            if (_showAudioPlayer && _playingAyahNumber != null) {
              final pageNum = index + 1;
              final pageData = quran.getPageData(pageNum);
              if (pageData.isNotEmpty) {
                final firstRange = pageData.first;
                final surahOnPage = firstRange['surah'] as int?;
                final startAyah = firstRange['start'] as int?;
                if (surahOnPage == _currentSurahNumber && startAyah != null) {
                  // Update playing ayah to first ayah on the new page
                  _playingAyahNumber = startAyah;
                }
              }
            }
            
            setState(() {}); // Refresh to update header with new page info
          },
          itemBuilder: (context, index) {
            // Animated page with scale/fade effect for book-like feel
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = (_pageController.page ?? index.toDouble()) - index;
                  // Smooth curve: pages scale down and fade as they move away
                  value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                }
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..scale(value),
                  child: Opacity(
                    opacity: value.clamp(0.6, 1.0),
                    child: child,
                  ),
                );
              },
              child: _buildMushafFullPage(index + 1),
            );
          },
        ),
      );
    }
  }

  // Track previous surah for transition detection
  int? _lastSurahOnPage;
  
  void _checkSurahTransition(int pageNum) {
    final pageData = quran.getPageData(pageNum);
    if (pageData.isEmpty) return;
    
    final firstSurah = pageData.first['surah'] as int?;
    if (firstSurah == null) return;
    
    // Check if we entered a new surah
    if (_lastSurahOnPage != null && _lastSurahOnPage != firstSurah) {
      final surahName = quran.getSurahNameArabic(firstSurah);
      _showSurahTransitionNotice(surahName, firstSurah);
    }
    _lastSurahOnPage = firstSurah;
  }
  
  void _showSurahTransitionNotice(String surahName, int surahNumber) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
            const SizedBox(width: 12),
            Text(
              'بدأت سورة $surahName',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
          ],
        ),
        backgroundColor: _settings.nightMode 
            ? const Color(0xFF2D2D2D)
            : const Color(0xFF4A4A4A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
    HapticFeedback.mediumImpact();
  }

  Widget _buildMushafFullPage(int pageNum) {
    final bool isDark = _settings.nightMode;
    
    // SIMPLIFIED MODERN PALETTE
    final Color textColor = isDark 
        ? const Color(0xFFEDEDED)  // Soft White (SIMPLIFIED)
        : const Color(0xFF2C1810);
    final Color goldColor = isDark 
        ? const Color(0xFFFFC107)  // Amber
        : const Color(0xFF8B6914);
    
    // Get Page Metadata
    final List<Map<String, dynamic>> pageData =
        List<Map<String, dynamic>>.from(quran.getPageData(pageNum));
    
    int firstSurah = _currentSurahNumber;
    int juzNum = 1;
    String surahName = '';
    if (pageData.isNotEmpty) {
      final firstRange = pageData.first;
      firstSurah = (firstRange['surah'] as int?) ?? _currentSurahNumber;
      final startAyah = (firstRange['start'] as int?) ?? 1;
      juzNum = quran.getJuzNumber(firstSurah, startAyah);
      surahName = quran.getSurahNameArabic(firstSurah);
    }
    
    final subtleColor = isDark 
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.3);
    
    return Container(
      color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF6ED),
      child: SafeArea(
        child: Column(
          children: [
            // ═══════════════ TOP CORNERS - Surah & Juz (Mushaf style) ═══════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left corner - Juz number
                  Text(
                    'الجزء ${_formatNumber(juzNum)}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      color: subtleColor,
                    ),
                  ),
                  // Right corner - Surah name
                  Text(
                    surahName,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      color: subtleColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // ═══════════════ QURAN TEXT ═══════════════
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildMushafPageContent(pageNum, isDark, textColor, goldColor),
              ),
            ),
            
            // ═══════════════ BOTTOM - Page Number Only ═══════════════
            Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 2),
              child: Text(
                '${_formatNumber(pageNum)}',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: subtleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SIMPLIFIED Header - no gradients, no patterns, just text
  Widget _buildMushafHeader(int surahNum, int juzNum, int pageNum, bool isDark, Color goldColor, Color textColor, Color frameColor) {
    return Container(
      color: Colors.transparent, // NO GRADIENT
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // Juz - simple text
            Text(
              'الجزء ${_formatNumber(juzNum)}',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                color: goldColor.withValues(alpha: 0.7),
              ),
            ),
            
            const Spacer(),
            
            // Surah Name - center
            Text(
              'سورة ${quran.getSurahNameArabic(surahNum)}',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFEDEDED) : const Color(0xFF2C1810),
              ),
            ),
            
            const Spacer(),
            
            // Page number - simple text
            Text(
              _formatNumber(pageNum),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                color: goldColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the actual Mushaf page content - SIMPLIFIED
  // SIMPLIFIED: Removed unused frameColor parameter
  Widget _buildMushafPageContent(int pageNum, bool isDark, Color textColor, Color goldColor) {
    final pageData = quran.getPageData(pageNum);
    if (pageData.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use fontSize from settings (range: 18-44)
        final double fontSize = _settings.fontSize;

        // SIMPLIFIED: Just padding, no FittedBox/SizedBox constraints
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SingleChildScrollView(
            child: _buildCleanPageContent(pageNum, pageData, fontSize, isDark, textColor, goldColor),
          ),
        );
      },
    );
  }

  // SIMPLIFIED page content builder
  Widget _buildCleanPageContent(
    int pageNum,
    List<dynamic> pageData,
    double fontSize,
    bool isDark,
    Color textColor,
    Color goldColor,
  ) {
    final List<InlineSpan> spans = [];
    
    // Process each surah range on this page
    for (int rangeIndex = 0; rangeIndex < pageData.length; rangeIndex++) {
      final range = pageData[rangeIndex];
      final int surahNum = range['surah'] as int;
      final int startAyah = range['start'] as int;
      final int endAyah = range['end'] as int;
      
      // Check if this is the start of a surah (ayah 1)
      if (startAyah == 1) {
        // Add surah header as widget span
        spans.add(WidgetSpan(
          child: Padding(
            padding: EdgeInsets.only(
              top: rangeIndex > 0 ? 20 : 0,
              bottom: 12,
            ),
            child: _buildCompactSurahHeader(surahNum, goldColor, textColor, isDark),
          ),
        ));
        
        // Add Basmala for applicable surahs (not Al-Fatiha, not At-Tawba)
        if (surahNum != 1 && surahNum != 9) {
          spans.add(WidgetSpan(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: fontSize * 1.15,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  color: goldColor,
                ),
              ),
            ),
          ));
        }
      }
      
      // Add verses for this range
      for (int ayah = startAyah; ayah <= endAyah; ayah++) {
        String verseText = quran.getVerse(surahNum, ayah, verseEndSymbol: false);
        
        // Skip Basmala in verse 1 (we show it separately as header)
        // This catches various Unicode representations
        if (ayah == 1 && surahNum != 9) {
          // More robust Basmala removal pattern
          verseText = verseText.replaceFirst(
            RegExp(r'^[\s\u200B]*بِسْمِ.*?الرَّحِيمِ[\s\u200B]*', unicode: true),
            '',
          ).trim();
          // Also try simpler pattern if first didn't match
          if (verseText.contains('بسم الله')) {
            verseText = verseText.replaceFirst(
              RegExp(r'بسم الله[^\s]*\s+الرحم[اٰ]ن[^\s]*\s+الرحيم', unicode: true),
              '',
            ).trim();
          }
          if (verseText.isEmpty) continue;
        }
        
        // Check if this ayah is currently playing
        final bool isPlayingAyah = _showAudioPlayer && 
            _playingAyahNumber == ayah && 
            surahNum == _currentSurahNumber;
        
        // SIMPLIFIED text style with highlight for playing ayah
        spans.add(TextSpan(
          text: '$verseText ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: isPlayingAyah ? const Color(0xFFFFC107) : textColor,
            height: 2.2,
            shadows: isPlayingAyah ? [
              Shadow(
                color: const Color(0xFFFFC107).withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ] : null,
          ),
        ));
        
        // Add verse number circle - TAPPABLE for ayah options
        final verseNum = _formatNumber(ayah);
        final int currentSurah = surahNum;
        final int currentAyah = ayah;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _buildTappableVerseBadge(verseNum, goldColor, isDark, fontSize, currentSurah, currentAyah, isPlaying: isPlayingAyah),
        ));
        
        // Add sajda indicator if applicable
        if (_isSajdaVerse(surahNum, ayah)) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _buildSajdaIndicator(isDark),
          ));
        }
        
        // Add space after verse number
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }
  
  // Elegant surah header with decorative styling
  Widget _buildCompactSurahHeader(int surahNum, Color goldColor, Color textColor, bool isDark) {
    final surahName = quran.getSurahNameArabic(surahNum);
    final versesCount = quran.getVerseCount(surahNum);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decorative top line
          Row(
            children: [
              Expanded(child: Container(height: 1, color: goldColor.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('﴾', style: TextStyle(fontSize: 20, color: goldColor)),
              ),
              Expanded(child: Container(height: 1, color: goldColor.withValues(alpha: 0.3))),
            ],
          ),
          const SizedBox(height: 16),
          
          // Surah name - elegant
          Text(
            'سُورَةُ $surahName',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: isDark ? const Color(0xFFFDFBF7) : const Color(0xFF2C1810),
            ),
          ),
          const SizedBox(height: 6),
          
          // Verse count
          Text(
            '${_formatNumber(versesCount)} آية',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          
          // Decorative bottom line
          Row(
            children: [
              Expanded(child: Container(height: 1, color: goldColor.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('﴿', style: TextStyle(fontSize: 20, color: goldColor)),
              ),
              Expanded(child: Container(height: 1, color: goldColor.withValues(alpha: 0.3))),
            ],
          ),
        ],
      ),
    );
  }
  
  // TAPPABLE verse badge - elegant Quran-style marker
  Widget _buildTappableVerseBadge(String number, Color goldColor, bool isDark, double fontSize, int surahNum, int ayahNum, {bool isPlaying = false}) {
    final badgeColor = isPlaying ? const Color(0xFFFFC107) : goldColor;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Use existing AyahContextMenu component
        final String ayahText = quran.getVerse(surahNum, ayahNum, verseEndSymbol: false);
        AyahContextMenu.show(
          context,
          surah: surahNum,
          ayah: ayahNum,
          ayahText: ayahText,
          isDark: isDark,
          onPlayAudio: () => _playAyahAudio(surahNum, ayahNum),
          onShare: () => _shareAyah(surahNum, ayahNum, ayahText),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isPlaying ? badgeColor.withValues(alpha: 0.2) : null,
          border: Border.all(color: badgeColor.withValues(alpha: isPlaying ? 1.0 : 0.6), width: isPlaying ? 2 : 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isPlaying ? [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ] : null,
        ),
        child: Text(
          number,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: fontSize * 0.55,
            fontWeight: FontWeight.w600,
            color: badgeColor,
          ),
        ),
      ),
    );
  }

  // Check if a verse has sajda (prostration)
  bool _isSajdaVerse(int surah, int ayah) {
    // Complete list of 15 sajda verses in the Quran (most agreed upon)
    // Format: List of (surah, ayah) pairs
    const sajdaVerses = [
      (7, 206),   // Al-A'raf
      (13, 15),   // Ar-Ra'd
      (16, 50),   // An-Nahl (some say 49)
      (17, 109),  // Al-Isra
      (19, 58),   // Maryam
      (22, 18),   // Al-Hajj (first sajda)
      (22, 77),   // Al-Hajj (second sajda)
      (25, 60),   // Al-Furqan
      (27, 26),   // An-Naml
      (32, 15),   // As-Sajda
      (38, 24),   // Sad
      (41, 38),   // Fussilat
      (53, 62),   // An-Najm
      (84, 21),   // Al-Inshiqaq
      (96, 19),   // Al-Alaq
    ];
    
    return sajdaVerses.any((v) => v.$1 == surah && v.$2 == ayah);
  }
  
  // Sajda indicator widget with amber color
  Widget _buildSajdaIndicator(bool isDark) {
    const amberColor = Color(0xFFFFC107);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: amberColor.withValues(alpha: isDark ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: amberColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: amberColor.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline,
            size: 14,
            color: amberColor,
          ),
          const SizedBox(width: 4),
          Text(
            'سجدة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: amberColor,
              shadows: [
                Shadow(
                  color: amberColor.withValues(alpha: 0.4),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Corner ornament for traditional Mushaf decoration
  Widget _buildCornerOrnament(Color goldColor, bool isDark) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            goldColor.withValues(alpha: isDark ? 0.08 : 0.06),
            goldColor.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '◆',
          style: TextStyle(
            fontSize: 12,
            color: goldColor.withValues(alpha: isDark ? 0.2 : 0.15),
          ),
        ),
      ),
    );
  }
  
  // Grand elegant footer with ornamental design
  // SIMPLIFIED FOOTER - just page number, transparent background
  Widget _buildMushafFooter(int pageNum, bool isDark, Color goldColor, Color frameColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.transparent,
      child: Center(
        child: Text(
          'صفحة ${_formatNumber(pageNum)}',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFEDEDED).withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // Helper methods for ayah actions
  void _playAyahAudio(int surah, int ayah) {
    // Show audio player starting from the specific ayah
    setState(() {
      _showAudioPlayer = true;
      _playingAyahNumber = ayah;
    });
  }

  void _shareAyah(int surah, int ayah, String text) {
    // TODO: Implement sharing
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
          color: isPrimary ? const Color(0xFF2E8B57) : Colors.transparent,
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
                color: const Color(0xFF2E8B57).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E8B57).withValues(alpha: 0.2),
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
                  color: const Color(0xFF2E8B57),
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
                    color: const Color(0xFF2E8B57).withValues(alpha: 0.1),
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
                          color: const Color(0xFF2E8B57),
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
                        color: Color(0xFF2E8B57),
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

  const _PremiumAyahView({
    required this.ayah,
    required this.surahNumber,
    required this.surahName,
    required this.totalAyahs,
    required this.settings,
    required this.onTap,
  });

  @override
  State<_PremiumAyahView> createState() => _PremiumAyahViewState();
}

class _PremiumAyahViewState extends State<_PremiumAyahView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    // Premium color palette
    final primaryColor = const Color(0xFF10B981); // Teal (replaces Emerald)
    final goldAccent = const Color(0xFFD4A853);
    final textColor = isDark
        ? const Color(0xFFF5F5F5)
        : const Color(0xFF1A1A1A);
    final subtleTextColor = isDark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF6B7280);
    // Dynamic font size based on settings and screen
    final baseFontSize = widget.settings.fontSize;
    final arabicFontSize = isTablet ? baseFontSize * 1.2 : baseFontSize;
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Main Content with elegant scroll
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: isTablet ? 80 : 20,
                  right: isTablet ? 80 : 20,
                  top: 16,
                  bottom: 40,
                ),
                child: AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 100),

                      // Premium Ayah Number Badge
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            // Stop propagation and show context menu
                            _showContextMenu(context);
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        const Color(0xFF2D2D2D),
                                        const Color(0xFF1A1A1A),
                                      ]
                                    : [
                                        const Color(0xFFFFFBF5),
                                        const Color(0xFFF5EFE6),
                                      ],
                              ),
                              border: Border.all(
                                color: goldAccent.withValues(alpha: 0.6),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: goldAccent.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _formatNumber(widget.ayah.numberInSurah),
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: goldAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // BISMILLAH (Conditional)
                      if (widget.ayah.numberInSurah == 1 &&
                          widget.surahName != 'سورة التوبة') ...[
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: goldAccent.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isDark
                                    ? [
                                        Colors.transparent,
                                        goldAccent.withValues(alpha: 0.05),
                                      ]
                                    : [
                                        Colors.transparent,
                                        goldAccent.withValues(alpha: 0.08),
                                      ],
                              ),
                            ),
                            child: Text(
                              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                              style: TextStyle(
                                fontFamily: widget.settings.fontFamily == 'hafs'
                                    ? 'Amiri'
                                    : 'Cairo',
                                fontSize: arabicFontSize * 0.9,
                                fontWeight: FontWeight.w500,
                                color: goldAccent,
                                height: 1.8,
                                letterSpacing: 2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],

                      // Main Arabic Text - Hero Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 48 : 20,
                            vertical: 40,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E).withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : goldAccent.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : goldAccent.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: widget.settings.showTajweed
                              ? TajweedText(
                                  text: _removeBasmalaIfFirst(widget.ayah.text, widget.ayah.numberInSurah, widget.surahNumber),
                                  fontSize: arabicFontSize,
                                  nightMode: isDark,
                                  showTajweed: true,
                                  textAlign: TextAlign.center,
                                )
                              : Text(
                                  _removeBasmalaIfFirst(widget.ayah.text, widget.ayah.numberInSurah, widget.surahNumber),
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily:
                                        widget.settings.fontFamily == 'hafs'
                                        ? 'Amiri'
                                        : 'Cairo',
                                    fontSize: arabicFontSize,
                                    height: 2.4,
                                    color: textColor,
                                    letterSpacing: 1.0,
                                    wordSpacing: 12,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Elegant Divider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  goldAccent.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: goldAccent.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: goldAccent.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 50,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  goldAccent.withValues(alpha: 0.7),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // Translation Box - Premium Design
                      if (widget.settings.showTranslation &&
                          widget.ayah.translation != null)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(
                                      0xFF1A1A1A,
                                    ).withValues(alpha: 0.7)
                                  : const Color(
                                      0xFFFAFAFA,
                                    ).withValues(alpha: 0.95),
                              // Use ClipPath instead of borderRadius with non-uniform border
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left accent bar
                                Container(
                                  width: 5,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'الترجمة',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.translate_rounded,
                                              size: 16,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        widget.ayah.translation!,
                                        textAlign: TextAlign.justify,
                                        textDirection: TextDirection.rtl,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 17,
                                          height: 2.0,
                                          color: subtleTextColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Surah Info Footer
                      const SizedBox(height: 36),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${widget.surahName}  •  آية ${_formatNumber(widget.ayah.numberInSurah)} من ${_formatNumber(widget.totalAyahs)}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: subtleTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 120), // Extra space for bottom controls
                    ],
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
    HapticFeedback.lightImpact();
  }

  String _formatNumber(int number) {
    if (widget.settings.useEnglishNumbers) {
      return number.toString();
    }
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  /// Remove Basmala from first ayah text since we render it separately.
  /// Exceptions:
  ///   - Surah Al-Fatiha (1): Basmala is the ayah itself.
  ///   - Surah At-Tawbah (9): No basmala shown.
  String _removeBasmalaIfFirst(String text, int ayahNumber, int surahNumber) {
    if (ayahNumber != 1 || surahNumber == 1 || surahNumber == 9) {
      return text;
    }

    // Normalize leading whitespace & zero-width characters.
    String trimmed = text.replaceFirst(RegExp(r'^[\s\uFEFF]+'), '');

    // Use canonical verse text from quran package (without Basmala).
    final canonical = quran.getVerse(
      surahNumber,
      ayahNumber,
      verseEndSymbol: false,
    ).trim();

    if (canonical.isEmpty) return trimmed;

    final idx = trimmed.indexOf(canonical);
    if (idx >= 0) {
      return trimmed.substring(idx).trimLeft();
    }

    return canonical;
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

// DELETED: AyahMarkerPainter, _ArabesquePatternPainter, _NoiseTexturePainter
// These were causing visual clutter - SIMPLIFIED
