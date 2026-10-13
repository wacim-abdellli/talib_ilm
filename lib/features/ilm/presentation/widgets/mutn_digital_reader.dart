import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';
import 'mutn_memorization_view.dart';
import 'shamela_fihris_sheet.dart';
import 'shamela_text_highlighter.dart';
import 'shamela_typography_sheet.dart';

/// Reflowable digital text reader for Islamic Mutun with distraction-free
/// immersive mode, unified scholarly toolbar, syntax coloring, and self-testing recall.
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
  bool _isLoading = true;
  String? _errorMessage;
  ShamelaPage? _pageData;

  // Typography & Surface settings
  double _fontSizeDelta = 2.0;
  String _fontFamily = 'Amiri';
  double _lineHeight = 1.85;
  ShamelaReaderSurface _surface = ShamelaReaderSurface.normal;

  // Memorization Mode (وضع التسميع والتحفيظ)
  bool _memorizationMode = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, widget.digitalEntry.totalPages);
    _totalPages = widget.digitalEntry.totalPages;
    _loadPreferences();
    _fetchCurrentPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      _memorizationMode = prefs.getBool('mutn_memorization_mode') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mutn_reader_font_delta', _fontSizeDelta);
    await prefs.setString('mutn_reader_font_family', _fontFamily);
    await prefs.setDouble('mutn_reader_line_height', _lineHeight);
    await prefs.setInt('mutn_reader_surface', _surface.index);
    await prefs.setBool('mutn_memorization_mode', _memorizationMode);
  }

  Future<void> _fetchCurrentPage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final page = await ShamelaService.fetchPage(
        bookId: widget.digitalEntry.shamelaId,
        pageNumber: _currentPage,
      );

      if (!mounted) return;
      setState(() {
        _pageData = page;
        _isLoading = false;
      });

      widget.onPageChanged(_currentPage, _totalPages);

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل الصفحة. يرجى التحقق من الاتصال بالإنترنت.';
      });
    }
  }

  void _goToPage(int page) {
    final safe = page.clamp(1, _totalPages);
    if (safe == _currentPage) return;
    HapticFeedback.selectionClick();
    setState(() => _currentPage = safe);
    _fetchCurrentPage();
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
      ),
    );
  }

  void _openFihrisSheet() async {
    final chapters = await ShamelaService.fetchTableOfContents(
      widget.digitalEntry.shamelaId,
    );
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ShamelaFihrisSheet(
        chapters: chapters,
        isLoading: false,
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

    final Color bgColor;
    switch (_surface) {
      case ShamelaReaderSurface.parchment:
        bgColor = palette.goldSoft;
        break;
      case ShamelaReaderSurface.night:
        bgColor = palette.surface;
        break;
      case ShamelaReaderSurface.normal:
        bgColor = palette.bg;
        break;
    }

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // ── Reader Body (Tap to toggle distraction-free mode) ──
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: palette.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorView(palette, textTheme)
                    : InkWell(
                        onTap: widget.onToggleControls,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: _buildContentArea(palette, textTheme),
                      ),
          ),

          // ── Unified Bottom Scholarly HUD ───────────────────────
          AnimatedContainer(
            duration: AppMotion.base,
            height: widget.showControls ? 104.0 : 0.0,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: 104.0,
                child: _buildBottomNavHud(palette, textTheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(AppPalette palette, AppTextTheme textTheme) {
    final content = _pageData?.content ?? '';
    final chapter = _pageData?.chapterTitle;

    return SelectionArea(
      child: Scrollbar(
        controller: _scrollController,
        thickness: 3,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chapter header if present
              if (chapter != null && chapter.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.gold, width: 1),
                  ),
                  child: Text(
                    chapter,
                    style: textTheme.titleSmall.copyWith(
                      color: palette.gold,
                      fontFamily: _fontFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
              ],

              // Memorization view or standard scholarly view
              if (_memorizationMode)
                MutnMemorizationView(
                  content: content,
                  fontFamily: _fontFamily,
                  fontSizeDelta: _fontSizeDelta,
                  lineHeight: _lineHeight,
                )
              else
                Text.rich(
                  ShamelaTextHighlighter.buildSpans(
                    text: content,
                    palette: palette,
                    textTheme: textTheme,
                    fontSizeDelta: _fontSizeDelta,
                    fontFamily: _fontFamily,
                    lineHeight: _lineHeight,
                  ),
                  textAlign: TextAlign.start,
                ),

              // Footnotes / Hamesh
              if (_pageData?.hamesh != null && _pageData!.hamesh!.isNotEmpty) ...[
                const SizedBox(height: AppSpace.xl),
                Divider(color: palette.border, thickness: 1),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'الحاشية والتعليقات:',
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  _pageData!.hamesh!,
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                    height: 1.6,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavHud(AppPalette palette, AppTextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border(
          top: BorderSide(color: palette.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Fast Page Navigation
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xxs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: AppIcon.sm),
                  tooltip: 'الصفحة السابقة',
                  onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                  color: palette.text,
                ),
                InkWell(
                  onTap: _openFihrisSheet,
                  borderRadius: AppRadius.pillRadius,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(color: palette.border, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: AppIcon.xs,
                          color: palette.gold,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          'صفحة $_currentPage من $_totalPages',
                          style: textTheme.label.copyWith(
                            color: palette.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: AppIcon.sm),
                  tooltip: 'الصفحة التالية',
                  onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                  color: palette.text,
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: palette.border),

          // Row 2: Consolidated Scholarly Toolstrip
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xxs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildToolItem(
                  icon: widget.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: widget.isBookmarked ? 'محفوظة' : 'إشارة',
                  iconColor: widget.isBookmarked ? palette.gold : palette.text,
                  onTap: widget.onToggleBookmark,
                  onLongPress: widget.onShowBookmarks,
                  palette: palette,
                  textTheme: textTheme,
                ),
                _buildToolItem(
                  icon: Icons.edit_note_rounded,
                  label: 'ملاحظة',
                  iconColor: palette.text,
                  onTap: widget.onAddNote,
                  palette: palette,
                  textTheme: textTheme,
                ),
                _buildToolItem(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'الفهرس',
                  iconColor: palette.text,
                  onTap: _openFihrisSheet,
                  palette: palette,
                  textTheme: textTheme,
                ),
                _buildToolItem(
                  icon: _memorizationMode
                      ? Icons.visibility_off_rounded
                      : Icons.psychology_outlined,
                  label: 'تسميع',
                  iconColor: _memorizationMode ? palette.primary : palette.text,
                  bgColor: _memorizationMode ? palette.primarySoft : null,
                  onTap: _toggleMemorizationMode,
                  palette: palette,
                  textTheme: textTheme,
                ),
                _buildToolItem(
                  icon: Icons.text_format_rounded,
                  label: 'الخط',
                  iconColor: palette.text,
                  onTap: _openTypographySheet,
                  palette: palette,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? bgColor,
    required AppPalette palette,
    required AppTextTheme textTheme,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: AppRadius.smRadius,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xxs,
        ),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.transparent,
          borderRadius: AppRadius.smRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIcon.sm, color: iconColor),
            const SizedBox(height: AppSpace.xxs),
            Text(
              label,
              style: textTheme.caption.copyWith(
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(AppPalette palette, AppTextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: AppEmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'تعذر تحميل الصفحة',
          subtitle: _errorMessage ?? '',
          action: AppButton(
            label: 'إعادة المحاولة',
            onPressed: _fetchCurrentPage,
          ),
        ),
      ),
    );
  }
}
