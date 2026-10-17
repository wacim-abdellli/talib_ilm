import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app.dart';
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
  final VoidCallback? onSwitchToCurriculum;

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
    this.onSwitchToCurriculum,
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

  // Authentic Audio Service & Overlay Visibility
  final MutunAudioService _audioService = MutunAudioService();
  bool _showAudioBar = false;

  @override
  void initState() {
    super.initState();
    themeService.addListener(_onThemeChanged);
    _showAudioBar = MutunAudioCatalog.hasAudio(widget.book.id);
    _audioService.activeParagraphNotifier.addListener(_onActiveParagraphChanged);
    _audioService.isPlayingNotifier.addListener(_onAudioPlayingChanged);
    _currentPage = widget.initialPage.clamp(1, widget.digitalEntry.totalPages);
    _totalPages = widget.digitalEntry.totalPages;
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadPreferences();
    _loadChapters();
    _preloadSurroundingPages(_currentPage);
  }

  void _onActiveParagraphChanged() {
    final active = _audioService.activeParagraphNotifier.value;
    if (active == null || !_audioService.isPlayingNotifier.value) return;

    final targetPage = _getPageForParagraph(widget.book.id, active, _totalPages);
    if (targetPage != _currentPage && targetPage >= 1 && targetPage <= _totalPages) {
      _goToPage(targetPage);
    }
  }

  void _onAudioPlayingChanged() {
    if (_audioService.isPlayingNotifier.value && !_showAudioBar) {
      if (mounted) {
        setState(() => _showAudioBar = true);
      }
    }
  }

  int _getPageForParagraph(String bookId, int paragraphIndex, int totalPages) {
    if (bookId == 'bk_nawaqid_islam') {
      return paragraphIndex <= 5 ? 1 : 2;
    }
    if (bookId == 'bk_qawaid_arba') {
      if (paragraphIndex <= 2) return 1;
      if (paragraphIndex <= 3) return 2;
      if (paragraphIndex <= 6) return 3;
      return 4;
    }
    final totalParas = MutunAudioCatalog.getTotalParagraphs(bookId);
    if (totalParas <= 1) return 1;
    final ratio = (paragraphIndex - 1) / totalParas;
    final page = (ratio * totalPages).floor() + 1;
    return page.clamp(1, totalPages);
  }

  int _getStartingParagraphForPage(String bookId, int pageNum, int totalPages) {
    if (bookId == 'bk_nawaqid_islam') {
      return pageNum == 1 ? 1 : 6;
    }
    if (bookId == 'bk_qawaid_arba') {
      if (pageNum == 1) return 1;
      if (pageNum == 2) return 3;
      if (pageNum == 3) return 4;
      return 7;
    }
    final totalParas = MutunAudioCatalog.getTotalParagraphs(bookId);
    if (totalParas <= 1) return 1;
    final start = ((pageNum - 1) * totalParas / totalPages).round() + 1;
    return start.clamp(1, totalParas);
  }

  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {
      if (themeService.isDark) {
        _surface = ShamelaReaderSurface.night;
      } else {
        if (_surface == ShamelaReaderSurface.night) {
          _surface = ShamelaReaderSurface.normal;
        }
      }
    });
    _savePreferences();
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
    themeService.removeListener(_onThemeChanged);
    _audioService.activeParagraphNotifier.removeListener(_onActiveParagraphChanged);
    _audioService.isPlayingNotifier.removeListener(_onAudioPlayingChanged);
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
      final savedSurface = ShamelaReaderSurface.values[surfIndex.clamp(0, 2)];
      if (themeService.isDark) {
        _surface = ShamelaReaderSurface.night;
      } else {
        _surface = savedSurface == ShamelaReaderSurface.night
            ? ShamelaReaderSurface.normal
            : savedSurface;
      }
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

    return Container(
      color: bgColor,
      child: Column(
        children: [
          if (widget.onSwitchToCurriculum != null)
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                border: Border(
                  bottom: BorderSide(color: palette.border, width: 0.8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الشرح الموسع (المكتبة الشاملة)',
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  if (MutunAudioCatalog.hasAudio(widget.book.id))
                    InkWell(
                      onTap: () => setState(() => _showAudioBar = !_showAudioBar),
                      borderRadius: AppRadius.pillRadius,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: _showAudioBar
                              ? palette.gold.withValues(alpha: 0.25)
                              : palette.gold.withValues(alpha: 0.12),
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: palette.gold,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.headphones_rounded,
                              size: AppIcon.xs,
                              color: palette.gold,
                            ),
                            const SizedBox(width: AppSpace.xxs),
                            Text(
                              _showAudioBar ? 'إخفاء الصوت' : 'استماع للمتن',
                              style: textTheme.caption.copyWith(
                                color: palette.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
                      startingParagraphIndex: _getStartingParagraphForPage(
                        widget.book.id,
                        pageNum,
                        _totalPages,
                      ),
                      audioService: _audioService,
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Mutun Audio Player HUD ───────────────────────────────
          if (MutunAudioCatalog.hasAudio(widget.book.id) && _showAudioBar)
            MutunAudioPlayerHud(
              audioService: _audioService,
              bookId: widget.book.id,
              onOpenQuickJump: _openFihrisSheet,
              onClose: () => setState(() => _showAudioBar = false),
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
            onToggleAudio: MutunAudioCatalog.hasAudio(widget.book.id)
                ? () => setState(() => _showAudioBar = !_showAudioBar)
                : null,
            isAudioActive: _showAudioBar,
          ),
        ],
      ),
    );
  }
}
