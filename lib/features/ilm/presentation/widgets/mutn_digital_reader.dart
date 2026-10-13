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

/// Lightning-fast, reflowable digital text reader for Islamic Mutun
/// with scholarly syntax coloring, custom typography, reading surfaces,
/// and an interactive Memorization / Self-Testing mode.
class MutnDigitalReaderView extends StatefulWidget {
  final IlmBook book;
  final MutunDigitalEntry digitalEntry;
  final int initialPage;
  final Future<void> Function(int page, int total) onPageChanged;

  const MutnDigitalReaderView({
    super.key,
    required this.book,
    required this.digitalEntry,
    required this.initialPage,
    required this.onPageChanged,
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
        bgColor = palette.bg;
        break;
      case ShamelaReaderSurface.normal:
        bgColor = palette.bg;
        break;
    }

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // ── Quick Controls Bar ─────────────────────────────────
          _buildQuickActionBar(palette, textTheme),

          // ── Reader Body ────────────────────────────────────────
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
                    : _buildContentArea(palette, textTheme),
          ),

          // ── Bottom Navigation HUD ──────────────────────────────
          _buildBottomNavHud(palette, textTheme),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar(AppPalette palette, AppTextTheme textTheme) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border(
          bottom: BorderSide(color: palette.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Chapter / Index button
          InkWell(
            onTap: _openFihrisSheet,
            borderRadius: AppRadius.smRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.format_list_bulleted_rounded,
                    size: AppIcon.sm,
                    color: palette.text,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'الفهرس',
                    style: textTheme.caption.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Memorization Mode (وضع التحفيظ)
          InkWell(
            onTap: _toggleMemorizationMode,
            borderRadius: AppRadius.smRadius,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                color: _memorizationMode
                    ? palette.primarySoft
                    : Colors.transparent,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: _memorizationMode
                      ? palette.primary
                      : palette.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _memorizationMode
                        ? Icons.visibility_off_rounded
                        : Icons.psychology_outlined,
                    size: AppIcon.sm,
                    color: _memorizationMode
                        ? palette.primary
                        : palette.textMuted,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'وضع التسميع',
                    style: textTheme.caption.copyWith(
                      color: _memorizationMode
                          ? palette.primary
                          : palette.textMuted,
                      fontWeight: _memorizationMode
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: AppSpace.xs),

          // Typography settings
          IconButton(
            icon: Icon(
              Icons.text_format_rounded,
              color: palette.text,
              size: AppIcon.md,
            ),
            tooltip: 'تخصيص الخط والورق',
            onPressed: _openTypographySheet,
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
                      fontWeight: FontWeight.bold,
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
                    fontWeight: FontWeight.bold,
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
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border(
          top: BorderSide(color: palette.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous page button (RTL forward)
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: AppIcon.sm),
            tooltip: 'الصفحة السابقة',
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            color: palette.text,
          ),

          // Page counter pill
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: palette.border, width: 1),
            ),
            child: Text(
              'صفحة $_currentPage من $_totalPages',
              style: textTheme.label.copyWith(
                color: palette.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Next page button (RTL backward)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: AppIcon.sm),
            tooltip: 'الصفحة التالية',
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            color: palette.text,
          ),
        ],
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
