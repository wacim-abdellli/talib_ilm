import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import 'app_button.dart';

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
    final palette = context.palette;
    final progress = _totalPages > 0 ? _currentPage / _totalPages : 0.0;

    return Scaffold(
      backgroundColor: _nightMode ? AppPalette.dark.bg : palette.bg,
      body: Stack(
        children: [
          // 1. PDF Viewer with Night Mode & Brightness
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
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
                      color: Theme.of(context)
                          .colorScheme
                          .scrim
                          .withValues(alpha: 1.0 - _brightness),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Custom Top Bar
          if (widget.showAppBar)
            AnimatedPositioned(
              duration: AppMotion.base,
              top: _controlsVisible ? 0 : -AppSize.navH * 2,
              left: 0,
              right: 0,
              child: _buildTopBar(progress),
            ),

          // 3. Bottom Control Bar
          AnimatedPositioned(
            duration: AppMotion.base,
            bottom: _controlsVisible ? 0 : -AppSize.navH * 2,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double progress) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: BoxDecoration(
        color: palette.surfaceRaised.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: palette.border, width: 1),
        ),
        boxShadow: palette.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: AppSize.navH,
            child: Row(
              children: [
                AppIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'رجوع',
                  onPressed: () => Navigator.maybePop(context),
                  color: palette.text,
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    style: textTheme.titleSmall.copyWith(
                      color: palette.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onResetRequested != null)
                  AppIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'إعادة',
                    onPressed: widget.onResetRequested,
                    color: palette.textMuted,
                  ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: palette.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              palette.primary,
            ),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised.withValues(alpha: 0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(
          top: BorderSide(
            color: palette.border,
            width: 1,
          ),
        ),
        boxShadow: palette.shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Page Indicator / Goto
                  InkWell(
                    onTap: () {
                      _resetHideTimer();
                      _showJumpDialog();
                    },
                    borderRadius: AppRadius.smRadius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.sm,
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: textTheme.label.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // 2. Brightness
                  AppIconButton(
                    icon: _brightness < 0.5
                        ? Icons.brightness_low_rounded
                        : Icons.brightness_high_rounded,
                    tooltip: 'السطوع',
                    color: palette.textMuted,
                    onPressed: () {
                      _resetHideTimer();
                      _showBrightnessDialog();
                    },
                  ),

                  // 3. Zoom
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        button: true,
                        label: 'تصغير',
                        child: InkWell(
                          onTap: () {
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
                          borderRadius: AppRadius.smRadius,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.sm,
                            ),
                            child: Text(
                              'A-',
                              style: textTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'تكبير',
                        child: InkWell(
                          onTap: () {
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
                          borderRadius: AppRadius.smRadius,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.sm,
                            ),
                            child: Text(
                              'A+',
                              style: textTheme.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 4. Bookmark
                  AppIconButton(
                    icon: widget.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    tooltip: 'إشارة مرجعية',
                    color: widget.isBookmarked ? palette.gold : palette.textMuted,
                    onPressed: () {
                      _resetHideTimer();
                      widget.onBookmarkToggle?.call();
                    },
                  ),

                  // 5. Night Mode
                  AppIconButton(
                    icon: _nightMode
                        ? Icons.wb_sunny_rounded
                        : Icons.nights_stay_rounded,
                    tooltip: 'الوضع الليلي',
                    color: _nightMode ? palette.gold : palette.textMuted,
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
      ),
    );
  }

  void _showBrightnessDialog() {
    final palette = context.palette;
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(
              bottom: AppSize.navH + AppSpace.xl,
              left: AppSpace.xl,
              right: AppSpace.xl,
            ),
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: palette.border),
              boxShadow: palette.shadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    Icons.brightness_low_rounded,
                    size: AppIcon.md,
                    color: palette.textMuted,
                  ),
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setInnerState) {
                        return Slider(
                          value: _brightness,
                          activeColor: palette.primary,
                          onChanged: (val) {
                            setInnerState(() {});
                            setState(() => _brightness = val);
                            _resetHideTimer();
                          },
                        );
                      },
                    ),
                  ),
                  Icon(
                    Icons.brightness_high_rounded,
                    size: AppIcon.md,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showJumpDialog() async {
    if (_totalPages == 0) return;

    final palette = context.palette;
    final textTheme = context.text;
    final controller = TextEditingController(text: _currentPage.toString());
    final requested = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xlRadius,
          ),
          title: Text(
            AppStrings.pdfJumpTitle,
            style: textTheme.titleSmall.copyWith(color: palette.text),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              final parsed = int.tryParse(value);
              Navigator.pop(dialogContext, parsed);
            },
            style: textTheme.body.copyWith(color: palette.text),
            decoration: InputDecoration(
              hintText: '1 - $_totalPages',
              hintStyle: textTheme.caption.copyWith(color: palette.textSubtle),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppStrings.pdfJumpCancel,
                style: textTheme.label.copyWith(color: palette.textMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.pop(dialogContext, value);
              },
              child: Text(
                AppStrings.pdfJumpGo,
                style: textTheme.label.copyWith(color: palette.primary),
              ),
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
