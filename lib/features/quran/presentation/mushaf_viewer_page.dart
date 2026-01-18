import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/services/quran_page_service.dart';
import '../data/services/quran_sync_service.dart';
import 'widgets/mushaf_page_widget.dart';

/// Main Mushaf Viewer - Page-based horizontal PageView
class MushafViewerPage extends StatefulWidget {
  final int initialPage;
  final int? surahNumber;

  const MushafViewerPage({super.key, this.initialPage = 1, this.surahNumber});

  @override
  State<MushafViewerPage> createState() => _MushafViewerPageState();
}

class _MushafViewerPageState extends State<MushafViewerPage> {
  late PageController _pageController;
  int _currentPage = 1;
  bool _showControls = true;
  bool _isDark = false;
  double _fontSize = 22;
  bool _useEnglishNumbers = false;
  bool _isVerticalScroll = false;

  // Page cache (in-memory for quick access)
  final Map<int, QuranPageData> _pageCache = {};
  final Set<int> _loadingPages = {};
  final Set<int> _failedPages = {};

  bool _isReady = false; // "QuranReady" flag (Step 951)

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: 604 - _currentPage);

    // Initial Readiness Check
    _checkReadiness();

    // Auto-hide controls
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  Future<void> _checkReadiness() async {
    final ready = await QuranSyncService.instance.isQuranDownloaded();
    if (ready) {
      if (mounted) setState(() => _isReady = true);
      _preloadPages(_currentPage);
    } else {
      // Start Sync Flow
      QuranSyncService.instance.startFullSync();
      // Listen for completion
      QuranSyncService.instance.progressStream.listen((progress) {
        if (progress >= 1.0 && mounted) {
          setState(() => _isReady = true);
          _preloadPages(_currentPage); // Load first pages immediately
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _preloadPages(int centerPage) {
    // Preload current, 1 previous, and 3 next pages
    // The service handles caching, so we just trigger it
    QuranPageService.preloadPage(centerPage);

    // Also trigger previous page
    if (centerPage > 1) {
      QuranPageService.preloadPage(centerPage - 1);
    }
  }

  Future<void> _loadPage(int pageNumber) async {
    // Check memory cache first
    if (_pageCache.containsKey(pageNumber)) return;

    // Prevent double loading unless it previously failed
    if (_loadingPages.contains(pageNumber)) return;

    setState(() {
      _loadingPages.add(pageNumber);
      _failedPages.remove(pageNumber);
    });

    // Get from service (disk cache or API)
    final data = await QuranPageService.getPage(pageNumber);

    if (mounted) {
      setState(() {
        _loadingPages.remove(pageNumber);
        if (data != null) {
          _pageCache[pageNumber] = data;
        } else {
          _failedPages.add(pageNumber);
        }
      });
    }
  }

  void _onPageChanged(int index) {
    final newPage = _isVerticalScroll ? index + 1 : 604 - index;
    setState(() => _currentPage = newPage);
    HapticFeedback.selectionClick();
    _preloadPages(newPage);
  }

  void _toggleScrollDirection(bool isVertical) {
    setState(() {
      _isVerticalScroll = isVertical;
      // Re-initialize controller to match new index mapping
      final newIndex = _isVerticalScroll
          ? _currentPage - 1
          : 604 - _currentPage;
      _pageController = PageController(initialPage: newIndex);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= 604) {
      final index = _isVerticalScroll ? page - 1 : 604 - page;
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // OFFLINE-FIRST: Blocking Download UI
    if (!_isReady) {
      return Scaffold(
        backgroundColor: _isDark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFFFFBF6),
        body: Center(
          child: StreamBuilder<double>(
            stream: QuranSyncService.instance.progressStream,
            builder: (context, snapshot) {
              final progress = snapshot.data ?? 0.0;
              final percent = (progress * 100).toInt();

              if (snapshot.hasError) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Download Failed",
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: _isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          QuranSyncService.instance.startFullSync(),
                      child: const Text("Retry"),
                    ),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF00D9C0)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Downloading Quran Resources...",
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF00D9C0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("$percent%"),
                  const SizedBox(height: 24),
                  const Text(
                    "One-time setup for offline reading.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    final bgColor = _isDark ? Colors.black : const Color(0xFFFAF8F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main PageView with safe area
            SafeArea(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: _isVerticalScroll
                    ? Axis.vertical
                    : Axis.horizontal,
                reverse:
                    false, // We handle RTL/Direction manually via index math
                physics: const PageScrollPhysics(), // Standard paging physics
                onPageChanged: _onPageChanged,
                itemCount: 604,
                itemBuilder: (context, index) {
                  final pageNumber = _isVerticalScroll
                      ? index + 1
                      : 604 - index;
                  // Micro animation for page transition
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildPage(pageNumber),
                  );
                },
              ),
            ),

            // Top Controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildTopBar(),
            ),

            // Bottom Controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Settings Handle
                    GestureDetector(
                      onTap: _showSettings,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _isDark ? Colors.white54 : Colors.black54,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int pageNumber) {
    final data = _pageCache[pageNumber];

    if (data != null) {
      return MushafPageWidget(
        pageData: data,
        fontSize: _fontSize,
        isDark: _isDark,
        useEnglishNumbers: _useEnglishNumbers,
      );
    }

    if (_failedPages.contains(pageNumber)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 48,
              color: _isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              'فشل تحميل الصفحة',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: _isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadPage(pageNumber),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A853),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      );
    }

    // Loading state - trigger load and show skeleton
    if (!_loadingPages.contains(pageNumber)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPage(pageNumber);
      });
    }
    return MushafPageSkeleton(isDark: _isDark);
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (_isDark ? Colors.black : Colors.white).withValues(alpha: 0.95),
            (_isDark ? Colors.black : Colors.white).withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios,
              color: _isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (_isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'صفحة $_currentPage من 604',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: _isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const Spacer(),
          // Settings - Removed to move to bottom sheet
          const SizedBox(
            width: 48,
          ), // Placeholder to keep title centered if needed, or just remove spacer
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 16,
        right: 16,
        top: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            (_isDark ? Colors.black : Colors.white).withValues(alpha: 0.95),
            (_isDark ? Colors.black : Colors.white).withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          // Previous page
          IconButton(
            onPressed: _currentPage < 604
                ? () => _goToPage(_currentPage + 1)
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: (_isDark ? Colors.white : Colors.black).withValues(
                alpha: _currentPage < 604 ? 1.0 : 0.3,
              ),
            ),
          ),

          // Page slider with thin track
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: _isDark
                      ? const Color(0xFF00D9C0)
                      : const Color(0xFFD4A853),
                  inactiveTrackColor: (_isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                ),
                child: Slider(
                  value: _currentPage.toDouble(),
                  min: 1,
                  max: 604,
                  activeColor: _isDark
                      ? const Color(0xFF00D9C0)
                      : const Color(0xFFD4A853),
                  onChanged: (value) => _goToPage(value.round()),
                ),
              ),
            ),
          ),

          // Next page
          IconButton(
            onPressed: _currentPage > 1
                ? () => _goToPage(_currentPage - 1)
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: (_isDark ? Colors.white : Colors.black).withValues(
                alpha: _currentPage > 1 ? 1.0 : 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإعدادات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Dark mode toggle
              SwitchListTile(
                title: Text(
                  'الوضع الليلي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _isDark ? Colors.white : Colors.black,
                  ),
                ),
                value: _isDark,
                onChanged: (value) {
                  setModalState(() => _isDark = value);
                  setState(() => _isDark = value);
                },
                activeColor: const Color(0xFF00D9C0),
              ),

              // Font size
              ListTile(
                title: Text(
                  'حجم الخط',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _isDark ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Slider(
                  value: _fontSize,
                  min: 18,
                  max: 32,
                  divisions: 14,
                  label: _fontSize.round().toString(),
                  activeColor: const Color(0xFFD4A853),
                  onChanged: (value) {
                    setModalState(() => _fontSize = value);
                    setState(() => _fontSize = value);
                  },
                ),
              ),

              // Vertical Scroll toggle
              SwitchListTile(
                title: Text(
                  'التمرير العمودي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _isDark ? Colors.white : Colors.black,
                  ),
                ),
                value: _isVerticalScroll,
                onChanged: _toggleScrollDirection,
                activeColor: const Color(0xFF00D9C0),
              ),

              // Number format toggle
              SwitchListTile(
                title: Text(
                  'أرقام إنجليزية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _isDark ? Colors.white : Colors.black,
                  ),
                ),
                value: _useEnglishNumbers,
                onChanged: (value) {
                  setModalState(() => _useEnglishNumbers = value);
                  setState(() => _useEnglishNumbers = value);
                },
                activeColor: const Color(0xFF00D9C0),
              ),

              // Go to specific page
              ListTile(
                title: Text(
                  'الانتقال لصفحة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _isDark ? Colors.white : Colors.black,
                  ),
                ),
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '$_currentPage',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page >= 1 && page <= 604) {
                        _goToPage(page);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
