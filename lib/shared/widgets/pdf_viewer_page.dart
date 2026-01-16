import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../app/constants/app_strings.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/app_ui.dart';

class PdfViewerPage extends StatefulWidget {
  final String assetPath;
  final String title;
  final int initialPage;
  final void Function(int page, int totalPages)? onPageChanged;
  final bool showAppBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final VoidCallback? onResetRequested;

  // New params for bookmarking
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;

  const PdfViewerPage({
    super.key,
    required this.assetPath,
    required this.title,
    this.initialPage = 1,
    this.onPageChanged,
    this.showAppBar = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.onResetRequested,
    this.isBookmarked = false,
    this.onBookmarkToggle,
  });

  @override
  State<PdfViewerPage> createState() => PdfViewerPageState();
}

class PdfViewerPageState extends State<PdfViewerPage> {
  late final PdfViewerController _controller;
  int _currentPage = 1;
  int _totalPages = 0;

  // Controls State
  bool _controlsVisible = true;
  Timer? _hideTimer;
  double _brightness = 1.0; // 1.0 = full brightness, 0.0 = dark
  bool _nightMode = false;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _currentPage = widget.initialPage < 1 ? 1 : widget.initialPage;
    _loadSettings();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveSettings();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _brightness = prefs.getDouble('pdf_brightness') ?? 1.0;
        _nightMode = prefs.getBool('pdf_night_mode') ?? false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pdf_brightness', _brightness);
    await prefs.setBool('pdf_night_mode', _nightMode);
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controlsVisible) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _resetHideTimer() {
    if (_controlsVisible) {
      _startHideTimer();
    }
  }

  Future<void> _jumpToPage(int page) async {
    if (_totalPages == 0) return;
    final safePage = page < 1 ? 1 : (page > _totalPages ? _totalPages : page);
    _controller.jumpToPage(safePage);
  }

  void resetToStart() {
    if (_totalPages == 0) return;
    _controller.jumpToPage(1);
    setState(() => _currentPage = 1);
  }

  @override
  Widget build(BuildContext context) {
    // Top progress calculation
    final progress = _totalPages > 0 ? _currentPage / _totalPages : 0.0;

    return Scaffold(
      backgroundColor: _nightMode ? const Color(0xFF1E1E1E) : Colors.white,
      body: Stack(
        children: [
          // 1. PDF Viewer with Night Mode & Brightness
          GestureDetector(
            onTap: _toggleControls,
            child: ColorFiltered(
              colorFilter: _nightMode
                  ? const ColorFilter.matrix([
                      -1, 0, 0, 0, 255, // Invert Red
                      0, -1, 0, 0, 255, // Invert Green
                      0, 0, -1, 0, 255, // Invert Blue
                      0, 0, 0, 1, 0, // Alpha
                    ])
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Stack(
                children: [
                  SfPdfViewer.asset(
                    widget.assetPath,
                    controller: _controller,
                    initialPageNumber: _currentPage,
                    scrollDirection: PdfScrollDirection.vertical,
                    pageLayoutMode: PdfPageLayoutMode.continuous,
                    enableDoubleTapZooming: true,
                    canShowScrollHead: false,
                    canShowScrollStatus: false,
                    onDocumentLoaded: (details) {
                      if (!mounted) return;
                      final total = details.document.pages.count;
                      final safePage = _currentPage < 1
                          ? 1
                          : (_currentPage > total ? total : _currentPage);
                      if (safePage != _currentPage) {
                        _controller.jumpToPage(safePage);
                      }
                      setState(() {
                        _totalPages = total;
                        _currentPage = safePage;
                      });
                    },
                    onPageChanged: (details) {
                      if (!mounted) return;
                      setState(() => _currentPage = details.newPageNumber);
                      widget.onPageChanged?.call(
                        details.newPageNumber,
                        _totalPages,
                      );
                    },
                    onTap: (details) {
                      _toggleControls();
                    },
                  ),
                  // Brightness Overlay
                  IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 1.0 - _brightness),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Custom Top Bar
          AnimatedPositioned(
            duration: AppUi.animationMedium,
            top: _controlsVisible ? 0 : -80,
            left: 0,
            right: 0,
            child: _buildTopBar(progress),
          ),

          // 3. Bottom Control Bar
          AnimatedPositioned(
            duration: AppUi.animationMedium,
            bottom: _controlsVisible ? 0 : -100, // Hide completely
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double progress) {
    return Container(
      height: 80, // Allow space for status bar
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Bar Content
          SizedBox(
            height: 56, // Standard Toolbar Height
            child: Row(
              children: [
                const BackButton(),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppText.body.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onResetRequested != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: widget.onResetRequested,
                  ),
              ],
            ),
          ),
          // Linear Progress Indicator at bottom edge
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 80, // Increased to fit controls comfortably + safe area if needed
      margin: EdgeInsets.only(bottom: 0), // Anchored to bottom
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Page Indicator / Goto
                _ControlAction(
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    _resetHideTimer();
                    _showJumpDialog();
                  },
                ),

                // 2. Brightness
                _ControlAction(
                  icon: _brightness < 0.5
                      ? Icons.brightness_low
                      : Icons.brightness_high,
                  onTap: () {
                    _resetHideTimer();
                    _showBrightnessDialog();
                  },
                ),

                // 3. Zoom / Font Size
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Text(
                        'A-',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        _resetHideTimer();
                        if (_zoomLevel > 1.0) {
                          setState(
                            () => _zoomLevel = (_zoomLevel - 0.25).clamp(
                              1.0,
                              3.0,
                            ),
                          );
                          _controller.zoomLevel = _zoomLevel;
                        }
                      },
                    ),
                    IconButton(
                      icon: const Text(
                        'A+',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        _resetHideTimer();
                        if (_zoomLevel < 3.0) {
                          setState(
                            () => _zoomLevel = (_zoomLevel + 0.25).clamp(
                              1.0,
                              3.0,
                            ),
                          );
                          _controller.zoomLevel = _zoomLevel;
                        }
                      },
                    ),
                  ],
                ),

                // 4. Bookmark
                IconButton(
                  icon: Icon(
                    widget.isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: widget.isBookmarked
                        ? AppColors.accent
                        : AppColors.textPrimary,
                  ),
                  onPressed: () {
                    _resetHideTimer();
                    widget.onBookmarkToggle?.call();
                  },
                ),

                // 5. Night Mode
                IconButton(
                  icon: Icon(
                    _nightMode ? Icons.wb_sunny : Icons.nights_stay,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    _resetHideTimer();
                    setState(() => _nightMode = !_nightMode);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBrightnessDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Don't dim rest
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 90, left: 20, right: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppUi.shadowMD,
            ),
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  const Icon(Icons.brightness_low, size: 20),
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setInnerState) {
                        return Slider(
                          value: _brightness,
                          onChanged: (val) {
                            setInnerState(() {});
                            setState(() => _brightness = val);
                            _resetHideTimer();
                          },
                        );
                      },
                    ),
                  ),
                  const Icon(Icons.brightness_high, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showJumpDialog() async {
    // ... existing logic ...
    // Keeping it simple since I'm rewriting the file
    if (_totalPages == 0) return;

    final controller = TextEditingController(text: _currentPage.toString());
    final requested = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.pdfJumpTitle, style: AppText.heading),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              final parsed = int.tryParse(value);
              Navigator.pop(context, parsed);
            },
            decoration: InputDecoration(
              hintText: '1 - $_totalPages',
              hintStyle: AppText.caption,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.pdfJumpCancel, style: AppText.body),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.pop(context, value);
              },
              child: Text(AppStrings.pdfJumpGo, style: AppText.body),
            ),
          ],
        );
      },
    );

    if (requested != null) {
      await _jumpToPage(requested);
    }
  }
}

class _ControlAction extends StatelessWidget {
  final Widget? child;
  final IconData? icon;
  final VoidCallback onTap;

  const _ControlAction({this.child, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: child ?? Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }
}
