import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/services/quran_page_service.dart';
import '../data/services/quran_sync_service.dart';
import 'widgets/mushaf_page_widget.dart';
import 'widgets/navigation_slider.dart';
import '../data/services/quran_settings_service.dart';
import 'widgets/reading_settings_sheet.dart';
import 'widgets/parchment_background.dart';
import 'dart:ui'; // For ImageFilter

/// Main Mushaf Viewer - Progressive Hybrid Offline Mode
class MushafViewerPage extends StatefulWidget {
  final int initialPage;
  final int? surahNumber;

  const MushafViewerPage({super.key, this.initialPage = 1, this.surahNumber});

  @override
  State<MushafViewerPage> createState() => _MushafViewerPageState();
}

class _MushafViewerPageState extends State<MushafViewerPage> {
  late PageController _pageController;
  late ScrollController _scrollController;

  int _currentPage = 1;
  bool _showControls = true;
  bool _isDark = false;
  double _fontSize = 22;
  bool _useEnglishNumbers = false;
  bool _isVerticalScroll = false;
  String _fontFamily = 'Amiri';
  bool _showTajweed = false;

  // Page cache logic
  final Map<int, QuranPageData> _pageCache = {};
  final Set<int> _loadingPages = {};
  final Set<int> _failedPages = {};

  // Download State
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadError;

  // Auto-hide controls timer
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: 604 - _currentPage);
    _scrollController = ScrollController();

    _ensureChunkForPage(_currentPage);

    // Auto-hide controls after 3 seconds
    _startHideControlsTimer();

    QuranSyncService.instance.progressStream.listen((p) {
      if (mounted) setState(() => _downloadProgress = p);
    });

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await QuranSettingsService.instance.loadSettings();
    if (mounted) {
      setState(() {
        if (settings.containsKey('isDark')) _isDark = settings['isDark'];
        if (settings.containsKey('fontSize')) _fontSize = settings['fontSize'];
        if (settings.containsKey('useEnglishNumbers')) {
          _useEnglishNumbers = settings['useEnglishNumbers'];
        }
        if (settings.containsKey('fontFamily')) {
          _fontFamily = settings['fontFamily'];
        }
        if (settings.containsKey('showTajweed')) {
          _showTajweed = settings['showTajweed'];
        }
        // Important: Update Controller if vertical scroll loaded
        // However, we don't persist Vertical Scroll in Step 1157 yet.
        // We add it now but default is false.
        // Assuming user toggle logic handles switch.
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  Future<void> _ensureChunkForPage(int pageNumber) async {
    final chunkIndex = (pageNumber - 1) ~/ 20 + 1;
    final isDownloaded = await QuranSyncService.instance.isChunkDownloaded(
      chunkIndex,
    );

    if (!isDownloaded) {
      if (mounted) {
        setState(() {
          _isDownloading = true;
          _downloadError = null;
        });
      }

      try {
        await QuranSyncService.instance.downloadChunk(chunkIndex);
      } catch (e) {
        if (mounted) setState(() => _downloadError = "Download Failed");
      } finally {
        if (mounted) {
          setState(() => _isDownloading = false);
          _loadPage(pageNumber);
        }
      }
    } else {
      _loadPage(pageNumber);
    }
  }

  void _preloadPages(int centerPage) {
    QuranPageService.preloadPage(centerPage);
    if (centerPage > 1) QuranPageService.preloadPage(centerPage - 1);
    if (centerPage < 604) QuranPageService.preloadPage(centerPage + 1);
  }

  Future<void> _loadPage(int pageNumber) async {
    if (_pageCache.containsKey(pageNumber)) return;
    if (_loadingPages.contains(pageNumber)) return;

    setState(() {
      _loadingPages.add(pageNumber);
      _failedPages.remove(pageNumber);
    });

    final data = await QuranPageService.getPage(pageNumber);

    if (mounted) {
      setState(() {
        _loadingPages.remove(pageNumber);
        if (data != null) {
          _pageCache[pageNumber] = data;
        } else {
          _ensureChunkForPage(pageNumber); // Retry Chunk Check
        }
      });
    }
  }

  void _onPageChanged(int index) {
    final newPage = 604 - index;
    setState(() => _currentPage = newPage);
    HapticFeedback.selectionClick();
    _preloadPages(newPage);
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _showSettings() {
    // Map local state to QuranReadingSettings
    final currentSettings = QuranReadingSettings(
      nightMode: _isDark,
      fontSize: _fontSize,
      useEnglishNumbers: _useEnglishNumbers,
      fontFamily: _fontFamily,
      showTajweed: _showTajweed, // Pass current value
      // Default or inferred values for others
      readingMode: ReadingMode.page,
      reciter: 'alafasy', // Default
    );

    ReadingSettingsSheet.show(
      context,
      settings: currentSettings,
      onSettingsChanged: (newSettings) {
        setState(() {
          _isDark = newSettings.nightMode;
          _fontSize = newSettings.fontSize;
          _useEnglishNumbers = newSettings.useEnglishNumbers;
          _fontFamily = newSettings.fontFamily;
          _showTajweed = newSettings.showTajweed; // Update logic

          // Helper to map ReadingMode back to scroll direction if needed
          // For now we keep vertical scroll separate toggle in settings if we want
          // or infer it.
        });

        // Save individual prefs
        QuranSettingsService.instance.saveSetting(
          QuranSettingsService.keyDarkMode,
          newSettings.nightMode,
        );
        QuranSettingsService.instance.saveSetting(
          QuranSettingsService.keyFontSize,
          newSettings.fontSize,
        );
        QuranSettingsService.instance.saveSetting(
          QuranSettingsService.keyEnglishNumbers,
          newSettings.useEnglishNumbers,
        );
        QuranSettingsService.instance.saveSetting(
          QuranSettingsService.keyFontFamily,
          newSettings.fontFamily,
        );
        QuranSettingsService.instance.saveSetting(
          'showTajweed',
          newSettings.showTajweed,
        );
      },
    );
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  Widget _buildPage(int pageNumber) {
    if (_pageCache.containsKey(pageNumber)) {
      return MushafPageWidget(
        pageData: _pageCache[pageNumber]!,
        isDark: _isDark,
        fontSize: _fontSize,
        useEnglishNumbers: _useEnglishNumbers,
        fontFamily: _fontFamily,
        showTajweed: _showTajweed,
        enableScroll:
            !_isVerticalScroll, // Disable inner scroll if Vertical (ListView)
      );
    }

    if (!_loadingPages.contains(pageNumber)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPage(pageNumber);
      });
    }

    return MushafPageSkeleton(isDark: _isDark);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFBF6);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _toggleControls,
            child: Container(
              color: bgColor,
              child: SafeArea(
                child: Stack(
                  children: [
                    if (_isVerticalScroll)
                      // VERTICAL MODE (ListView)
                      Scrollbar(
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: 604,
                          itemBuilder: (context, index) {
                            final page = index + 1;
                            // Use NotificationListener slightly differently or rely on user scroll
                            return _buildPage(page);
                          },
                        ),
                      )
                    else
                      // HORIZONTAL MODE (PageView)
                      PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.horizontal,
                        reverse:
                            true, // RTL: Swipe left = next page, Swipe right = previous
                        physics: const PageScrollPhysics(),
                        onPageChanged: _onPageChanged,
                        itemCount: 604,
                        itemBuilder: (context, index) {
                          final pageNumber = 604 - index;
                          return ParchmentBackground(
                            isDark: _isDark,
                            // Hide borders in page view to avoid double borders
                            showBorders: false,
                            child: _buildPage(pageNumber),
                          );
                        },
                      ),

                    // STATUS OVERLAY
                    if (_isDownloading)
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            decoration: BoxDecoration(
                              color: _isDark
                                  ? Colors.black.withValues(alpha: 0.8)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: _isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (_downloadError == null)
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: _isDark
                                                ? const Color(0xFF00D9C0)
                                                : const Color(0xFFD4A853),
                                          ),
                                        )
                                      else
                                        Icon(
                                          Icons.wifi_off_rounded,
                                          color: Colors.red.shade400,
                                        ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _downloadError != null
                                                  ? "Download Failed"
                                                  : "Downloading Quran Data...", // Changed from "Chunk" to "Data" for better UX
                                              style: TextStyle(
                                                color: _isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontFamily: 'Cairo',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _downloadError != null
                                                  ? "Check your internet connection and try again."
                                                  : "Internet connection is required for first-time use.",
                                              style: TextStyle(
                                                color: _isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                                fontFamily: 'Cairo',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_downloadError != null)
                                        IconButton(
                                          icon: Icon(
                                            Icons.refresh,
                                            color: _isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          onPressed: () =>
                                              _ensureChunkForPage(_currentPage),
                                        ),
                                    ],
                                  ),
                                  if (_downloadProgress > 0 &&
                                      _downloadError == null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: _downloadProgress,
                                              backgroundColor: _isDark
                                                  ? Colors.white12
                                                  : Colors.black12,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    _isDark
                                                        ? const Color(
                                                            0xFF00D9C0,
                                                          )
                                                        : const Color(
                                                            0xFFD4A853,
                                                          ),
                                                  ),
                                              minHeight: 6,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "${(_downloadProgress * 100).toInt()}%",
                                            style: TextStyle(
                                              color: _isDark
                                                  ? Colors.white54
                                                  : Colors.black45,
                                              fontSize: 12,
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
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
          ),

          // Custom Floating Header
          // Custom Floating Header
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
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: (_isDark ? Colors.black : Colors.white)
                                .withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _isDark ? Colors.white12 : Colors.black12,
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
                                  color: _isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                onPressed: _goBack,
                                tooltip: 'رجوع',
                                splashRadius: 24,
                              ),
                            ),
                            middle: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "صفحة $_currentPage",
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _isDark
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
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Material(
                              color: Colors.transparent,
                              child: IconButton(
                                icon: Icon(
                                  Icons.tune_rounded,
                                  size: 22,
                                  color: _isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                onPressed: _showSettings,
                                tooltip: 'الإعدادات',
                                splashRadius: 24,
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
          ),

          // Custom Floating Footer (Slider)
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
                              color: (_isDark ? Colors.black : Colors.white)
                                  .withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _isDark
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
                            child: QuranNavigationSlider(
                              currentPage: _currentPage,
                              isDark: _isDark,
                              onPageChanged: _jumpToPage,
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
        ],
      ),
    );
  }

  void _jumpToPage(int page) {
    if (page >= 1 && page <= 604) {
      final index = 604 - page;
      _pageController.jumpToPage(index);
      setState(() => _currentPage = page);
      _ensureChunkForPage(page);
    }
  }
}
