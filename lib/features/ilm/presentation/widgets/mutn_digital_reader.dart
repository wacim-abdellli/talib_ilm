import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../data/catalogs/mutun_audio_catalog.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/mutun_audio_service.dart';
import '../../data/services/shamela_service.dart';
import 'mutun_audio_player_hud.dart';
import 'scholarly_reader_hud.dart';
import 'shamela_fihris_sheet.dart';
import 'shamela_page_content.dart';
import 'shamela_typography_sheet.dart';

/// Reflowable digital text reader for Islamic Mutun with horizontal side sliding (PageView),
/// distraction-free immersive mode, unified scholarly toolbar, syntax coloring, and self-testing recall.
class MutnDigitalReaderView extends StatefulWidget {
  final IlmBook book;
  final MutunDigitalEntry digitalEntry;
  final int initialPage;
  final Future<void> Function(int page, int total) onPageChanged;
  final bool showControls;
  final VoidCallback onToggleControls;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onAddNote;
  final VoidCallback onShowBookmarks;

  const MutnDigitalReaderView({
    super.key,
    required this.book,
    required this.digitalEntry,
    required this.initialPage,
    required this.onPageChanged,
    required this.showControls,
    required this.onToggleControls,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onAddNote,
    required this.onShowBookmarks,
  });

  @override
  State<MutnDigitalReaderView> createState() => _MutnDigitalReaderViewState();
}

class _MutnDigitalReaderViewState extends State<MutnDigitalReaderView> {
  late int _currentPage;
  late int _totalPages;
  late final PageController _pageController;

  final Map<int, ShamelaPage> _pageCache = {};
  final Set<int> _loadingPages = {};
  final Map<int, String> _pageErrors = {};

  // Typography & Surface settings
  double _fontSizeDelta = 2.0;
  String _fontFamily = 'Amiri';
  double _lineHeight = 1.85;
  ShamelaReaderSurface _surface = ShamelaReaderSurface.normal;
  ShamelaAccentColor _accentColor = ShamelaAccentColor.emerald;

  // Memorization Mode (وضع التسميع والتحفيظ)
  bool _memorizationMode = false;

  // Table of Contents (الفهرس)
  List<ShamelaChapter> _chapters = [];
  bool _isLoadingChapters = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, widget.digitalEntry.totalPages);
    _totalPages = widget.digitalEntry.totalPages;
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadPreferences();
    _loadChapters();
    _preloadSurroundingPages(_currentPage);
  }

  void _loadChapters() async {
    setState(() => _isLoadingChapters = true);
    try {
      final chapters = await ShamelaService.fetchTableOfContents(
        widget.digitalEntry.shamelaId,
      );
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _isLoadingChapters = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingChapters = false);
    }
  }

  @override
  void dispose() {
    ShamelaService.saveLastReadPage(
      widget.digitalEntry.shamelaId,
      _currentPage,
    );
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fontSizeDelta = prefs.getDouble('mutn_reader_font_delta') ?? 2.0;
      _fontFamily = prefs.getString('mutn_reader_font_family') ?? 'Amiri';
      _lineHeight = prefs.getDouble('mutn_reader_line_height') ?? 1.85;
      final surfIndex = prefs.getInt('mutn_reader_surface') ?? 0;
      _surface = ShamelaReaderSurface.values[surfIndex.clamp(0, 2)];
      final accIndex = prefs.getInt('shamela_reader_accent') ?? 0;
      _accentColor = ShamelaAccentColor
          .values[accIndex.clamp(0, ShamelaAccentColor.values.length - 1)];
      _memorizationMode = prefs.getBool('mutn_memorization_mode') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mutn_reader_font_delta', _fontSizeDelta);
    await prefs.setString('mutn_reader_font_family', _fontFamily);
    await prefs.setDouble('mutn_reader_line_height', _lineHeight);
    await prefs.setInt('mutn_reader_surface', _surface.index);
    await prefs.setInt('shamela_reader_accent', _accentColor.index);
    await prefs.setBool('mutn_memorization_mode', _memorizationMode);
  }

  void _preloadSurroundingPages(int pageNum) {
    for (final offset in [0, 1, -1]) {
      final target = pageNum + offset;
      if (target >= 1 && target <= _totalPages) {
        _loadPage(target);
      }
    }
  }

  Future<void> _loadPage(int pageNum) async {
    if (_pageCache.containsKey(pageNum) || _loadingPages.contains(pageNum)) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _loadingPages.add(pageNum);
      _pageErrors.remove(pageNum);
    });

    try {
      final page = await ShamelaService.fetchPage(
        bookId: widget.digitalEntry.shamelaId,
        pageNumber: pageNum,
      );
      if (!mounted) return;
      setState(() {
        _pageCache[pageNum] = page;
        _loadingPages.remove(pageNum);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPages.remove(pageNum);
        _pageErrors[pageNum] =
            'تعذر تحميل الصفحة $pageNum. يرجى التحقق من الاتصال بالإنترنت.';
      });
    }
  }

  void _onPageViewChanged(int index) {
    final pageNum = index + 1;
    if (pageNum == _currentPage) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentPage = pageNum;
    });
    _preloadSurroundingPages(pageNum);
    ShamelaService.saveLastReadPage(widget.digitalEntry.shamelaId, pageNum);
    widget.onPageChanged(pageNum, _totalPages);
  }

  void _goToPage(int page) {
    final safe = page.clamp(1, _totalPages);
    if (safe == _currentPage) return;
    HapticFeedback.selectionClick();
    setState(() => _currentPage = safe);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(safe - 1);
    }
    _preloadSurroundingPages(safe);
    ShamelaService.saveLastReadPage(widget.digitalEntry.shamelaId, safe);
    widget.onPageChanged(safe, _totalPages);
  }

  void _openTypographySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ShamelaTypographySheet(
        fontSizeDelta: _fontSizeDelta,
        fontFamily: _fontFamily,
        lineHeight: _lineHeight,
        surface: _surface,
        accentColor: _accentColor,
        onFontSizeChanged: (delta) {
          setState(() => _fontSizeDelta = delta);
          _savePreferences();
        },
        onFontFamilyChanged: (family) {
          setState(() => _fontFamily = family);
          _savePreferences();
        },
        onLineHeightChanged: (lh) {
          setState(() => _lineHeight = lh);
          _savePreferences();
        },
        onSurfaceChanged: (surf) {
          setState(() => _surface = surf);
          _savePreferences();
        },
        onAccentColorChanged: (accent) {
          setState(() => _accentColor = accent);
          _savePreferences();
        },
      ),
    );
  }

  void _openFihrisSheet() {
    HapticFeedback.lightImpact();
    if (_chapters.isEmpty && !_isLoadingChapters) {
      _loadChapters();
    }

    AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.85,
      builder: (sheetContext) => ShamelaFihrisSheet(
        chapters: _chapters,
        isLoading: _isLoadingChapters && _chapters.isEmpty,
        currentPage: _currentPage,
        onPageSelected: (page) => _goToPage(page),
      ),
    );
  }

  void _toggleMemorizationMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _memorizationMode = !_memorizationMode;
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final bgColor = ReaderSurfaceColors.getTokens(_surface, isDark: palette.isDark).bg;

    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // ── Quick Jump Bar « الانتقال السريع » ────────────────────
          AnimatedContainer(
            duration: AppMotion.fast,
            height: widget.showControls ? 36.0 : 0.0,
            color: palette.surfaceMuted,
            child: widget.showControls
                ? Center(
                    child: InkWell(
                      onTap: _openFihrisSheet,
                      borderRadius: AppRadius.pillRadius,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.xxs,
                        ),
                        child: Text(
                          '« الانتقال السريع »',
                          style: textTheme.caption.copyWith(
                            color: tokens.rosetteGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Reader Body: Horizontal Swipe (Slide side) PageView ──
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: _onPageViewChanged,
                itemBuilder: (context, index) {
                  final pageNum = index + 1;
                  final page = _pageCache[pageNum];
                  final isLoading = _loadingPages.contains(pageNum);
                  final error = _pageErrors[pageNum];

                  if (isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: palette.gold,
                            strokeWidth: 2.5,
                          ),
                          const SizedBox(height: AppSpace.md),
                          Text(
                            'جاري استحضار الصفحة $pageNum من المتن...',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(AppSpace.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              color: palette.textMuted,
                              size: AppIcon.xl,
                            ),
                            const SizedBox(height: AppSpace.md),
                            Text(
                              error,
                              style: textTheme.body.copyWith(
                                color: palette.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpace.lg),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: AppSpace.sm,
                              runSpacing: AppSpace.sm,
                              children: [
                                AppButton(
                                  label: 'إعادة المحاولة',
                                  size: AppButtonSize.sm,
                                  onPressed: () => _loadPage(pageNum),
                                ),
                                if (widget.book.pdfPath != null)
                                  AppButton(
                                    label: 'نسخة PDF (بدون إنترنت)',
                                    variant: AppButtonVariant.tonal,
                                    size: AppButtonSize.sm,
                                    icon: Icons.picture_as_pdf_rounded,
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PdfViewerPage(
                                            assetPath: widget.book.pdfPath!,
                                            title: widget.book.title,
                                            initialPage: pageNum,
                                            onPageChanged: (p, t) =>
                                                widget.onPageChanged(p, t),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (page == null) {
                    return const SizedBox.shrink();
                  }

                  return BookPageTapDetector(
                    onTap: widget.onToggleControls,
                    child: ShamelaPageContent(
                      page: page,
                      surface: _surface,
                      memorizationMode: _memorizationMode,
                      fontFamily: _fontFamily,
                      fontSizeDelta: _fontSizeDelta,
                      lineHeight: _lineHeight,
                      accentColor: _accentColor,
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Mutun Audio Player HUD ───────────────────────────────
          if (MutunAudioCatalog.hasAudio(widget.book.id))
            MutunAudioPlayerHud(
              audioService: MutunAudioService(),
              onOpenQuickJump: _openFihrisSheet,
            ),

          // ── Unified Bottom Scholarly HUD ───────────────────────
          ScholarlyReaderHud(
            currentPage: _currentPage,
            totalPages: _totalPages,
            isBookmarked: widget.isBookmarked,
            memorizationMode: _memorizationMode,
            showControls: widget.showControls,
            accentColor: _accentColor,
            surface: _surface,
            onPreviousPage: _currentPage > 1
                ? () => _goToPage(_currentPage - 1)
                : null,
            onNextPage: _currentPage < _totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
            onPageIndicatorTap: _openFihrisSheet,
            onToggleBookmark: widget.onToggleBookmark,
            onShowBookmarks: widget.onShowBookmarks,
            onAddNote: widget.onAddNote,
            onOpenFihris: _openFihrisSheet,
            onToggleMemorization: _toggleMemorizationMode,
            onOpenTypography: _openTypographySheet,
          ),
        ],
      ),
    );
  }
}
