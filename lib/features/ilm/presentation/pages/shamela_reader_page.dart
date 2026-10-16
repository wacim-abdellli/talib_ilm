import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';
import '../widgets/book_view_bookmarks_sheet.dart';
import '../widgets/book_view_controls.dart' show BookNoteDialog;
import '../widgets/scholarly_reader_hud.dart';
import '../widgets/shamela_fihris_sheet.dart';
import '../widgets/shamela_page_content.dart';
import '../widgets/shamela_reader_top_bar.dart';
import '../widgets/shamela_typography_sheet.dart';

class ShamelaReaderPage extends StatefulWidget {
  final ShamelaBook book;
  final int initialPage;

  const ShamelaReaderPage({
    super.key,
    required this.book,
    this.initialPage = 1,
  });

  @override
  State<ShamelaReaderPage> createState() => _ShamelaReaderPageState();
}

class _ShamelaReaderPageState extends State<ShamelaReaderPage> {
  late PageController _pageController;
  late int _currentPage;
  late int _totalPages;

  bool _showControls = true;
  bool _memorizationMode = false;
  double _fontSizeDelta = 2.0;
  String _fontFamily = 'Amiri';
  double _lineHeight = 1.85;
  ShamelaReaderSurface _surface = ShamelaReaderSurface.normal;
  ShamelaAccentColor _accentColor = ShamelaAccentColor.emerald;
  bool _isBookmarked = false;

  final Map<int, ShamelaPage> _pageCache = {};
  final Set<int> _loadingPages = {};
  final Map<int, String> _pageErrors = {};

  final TextEditingController _noteController = TextEditingController();
  List<ShamelaChapter> _chapters = [];
  bool _isLoadingChapters = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 100;
    _pageController = PageController(initialPage: _currentPage - 1);

    _loadPreferences();
    _loadPage(_currentPage);
    _checkBookmark();
    _loadFihris();
  }
  @override
  void dispose() {
    ShamelaService.saveLastReadPage(widget.book.id, _currentPage);
    _pageController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fontSizeDelta = prefs.getDouble('shamela_reader_font_delta') ?? 2.0;
      _fontFamily = prefs.getString('shamela_reader_font_family') ?? 'Amiri';
      _lineHeight = prefs.getDouble('shamela_reader_line_height') ?? 1.85;
      final surfIndex = prefs.getInt('shamela_reader_surface') ?? 0;
      _surface = ShamelaReaderSurface.values[surfIndex.clamp(0, 2)];
      final accIndex = prefs.getInt('shamela_reader_accent') ?? 0;
      _accentColor = ShamelaAccentColor
          .values[accIndex.clamp(0, ShamelaAccentColor.values.length - 1)];
      _memorizationMode = prefs.getBool('shamela_memorization_mode') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('shamela_reader_font_delta', _fontSizeDelta);
    await prefs.setString('shamela_reader_font_family', _fontFamily);
    await prefs.setDouble('shamela_reader_line_height', _lineHeight);
    await prefs.setInt('shamela_reader_surface', _surface.index);
    await prefs.setInt('shamela_reader_accent', _accentColor.index);
    await prefs.setBool('shamela_memorization_mode', _memorizationMode);
  }

  Future<void> _checkBookmark() async {
    final bookmarked = await ShamelaService.isPageBookmarked(
      widget.book.id,
      _currentPage,
    );
    if (mounted) setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.selectionClick();
    final nowBookmarked = await ShamelaService.toggleBookmark(
      widget.book.id,
      _currentPage,
    );
    if (!mounted) return;
    setState(() => _isBookmarked = nowBookmarked);
    AppSnackbar.success(
      context,
      nowBookmarked
          ? 'تم حفظ علامة في الصفحة $_currentPage'
          : 'تمت إزالة العلامة من الصفحة $_currentPage',
    );
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _toggleMemorizationMode() {
    HapticFeedback.mediumImpact();
    setState(() => _memorizationMode = !_memorizationMode);
    _savePreferences();
  }

  Future<void> _openNoteDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'shamela_note_${widget.book.id}_$_currentPage';
    _noteController.text = prefs.getString(key) ?? '';

    if (!mounted) return;
    BookNoteDialog.show(
      context,
      controller: _noteController,
      onSave: () async {
        final text = _noteController.text.trim();
        if (text.isEmpty) {
          await prefs.remove(key);
        } else {
          await prefs.setString(key, text);
        }
        _noteController.clear();
        if (!mounted) return;
        Navigator.of(context).pop();
        AppSnackbar.success(context, 'تم حفظ الملاحظة للصفحة $_currentPage');
      },
    );
  }

  Future<void> _showBookmarksSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('shamela_bookmarks') ?? [];
    final prefix = '${widget.book.id}_';
    final pages = list
        .where((s) => s.startsWith(prefix))
        .map((s) => int.tryParse(s.substring(prefix.length)))
        .whereType<int>()
        .toList()
      ..sort();

    if (!mounted) return;
    if (pages.isEmpty) {
      AppSnackbar.info(context, 'لا توجد إشارات مرجعية محفوظة في هذا الكتاب');
      return;
    }

    final entries = pages
        .map((p) => BookmarkEntry(
              title: widget.book.title,
              subtitle: 'صفحة $p',
              note: prefs.getString('shamela_note_${widget.book.id}_$p'),
            ))
        .toList();

    BookViewBookmarksSheet.show(context, entries);
  }

  Future<void> _loadFihris() async {
    final list = await ShamelaService.fetchTableOfContents(widget.book.id);
    if (mounted) {
      setState(() {
        _chapters = list;
        _isLoadingChapters = false;
      });
    }
  }

  Future<void> _loadPage(int pageNum) async {
    if (_pageCache.containsKey(pageNum) || _loadingPages.contains(pageNum)) return;

    setState(() {
      _loadingPages.add(pageNum);
      _pageErrors.remove(pageNum);
    });

    try {
      final page = await ShamelaService.fetchPage(
        bookId: widget.book.id,
        pageNumber: pageNum,
      );
      if (mounted) {
        setState(() {
          _pageCache[pageNum] = page;
          _loadingPages.remove(pageNum);
        });
      }
      ShamelaService.saveLastReadPage(widget.book.id, pageNum);
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        final isNotFound =
            errorStr.contains('404') || errorStr.contains('غير متوفرة');
        setState(() {
          _loadingPages.remove(pageNum);
          if (isNotFound && pageNum > 1) {
            _totalPages = pageNum - 1;
            _pageErrors[pageNum] =
                'نهاية الكتاب. لقد أتممت قراءة جميع صفحات هذا الشرح المبارك ($_totalPages صفحة).';
          } else {
            _pageErrors[pageNum] =
                'تعذر تحميل الصفحة. يرجى التحقق من الاتصال بالإنترنت.';
          }
        });
      }
    }
  }

  void _onPageChanged(int index) {
    final pageNum = index + 1;
    setState(() {
      _currentPage = pageNum;
    });
    _checkBookmark();
    _loadPage(pageNum);

    if (pageNum < _totalPages) _loadPage(pageNum + 1);
    if (pageNum > 1) _loadPage(pageNum - 1);
  }

  void _jumpToPage(int pageNum) {
    if (pageNum < 1 || pageNum > _totalPages) return;
    HapticFeedback.selectionClick();
    _pageController.jumpToPage(pageNum - 1);
  }

  void _copyPageContent() {
    final page = _pageCache[_currentPage];
    if (page == null) return;
    HapticFeedback.selectionClick();

    final text = '${page.content}\n\n[من كتاب: ${widget.book.title} للمؤلف: ${widget.book.author} - ص: $_currentPage]';
    Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.success(context, 'تم نسخ نص الصفحة مع التوثيق العلمي');
  }

  void _sharePageContent() {
    final page = _pageCache[_currentPage];
    if (page == null) return;
    HapticFeedback.selectionClick();

    final text = '${page.content}\n\n[من كتاب: ${widget.book.title} للمؤلف: ${widget.book.author} - ص: $_currentPage]';
    Share.share(text);
  }

  void _showFihrisSheet() {
    HapticFeedback.lightImpact();
    AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.85,
      builder: (ctx) => ShamelaFihrisSheet(
        chapters: _chapters,
        isLoading: _isLoadingChapters,
        currentPage: _currentPage,
        onPageSelected: (p) => _jumpToPage(p),
      ),
    );
  }

  void _showTypographySheet() {
    HapticFeedback.lightImpact();
    AppSheet.show<void>(
      context: context,
      builder: (ctx) => ShamelaTypographySheet(
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

  void _toggleSurfaceMode() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_surface == ShamelaReaderSurface.night) {
        _surface = ShamelaReaderSurface.normal;
      } else {
        _surface = ShamelaReaderSurface.night;
      }
    });
    _savePreferences();
  }

  Color _getBackgroundColor(AppPalette palette) {
    return ReaderSurfaceColors.getTokens(_surface, isDark: palette.isDark).bg;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final bgColor = _getBackgroundColor(palette);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          children: [
            // ── 1. Prestigious Scholarly Top Bar (Hides smoothly on immersion) ──
            ShamelaReaderTopBar(
              title: widget.book.title,
              author: widget.book.author,
              currentPage: _currentPage,
              totalPages: _totalPages,
              showControls: _showControls,
              bgColor: bgColor,
              accentColor: _accentColor,
              surface: _surface,
              onBack: () => Navigator.maybePop(context),
              onCopy: _copyPageContent,
              onToggleSurface: _toggleSurfaceMode,
            ),

            // ── 2. Reflowable Digital Reader Body ─────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: _onPageChanged,
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
                            'جاري استحضار الصفحة $pageNum من المكتبة...',
                            style: textTheme.caption.copyWith(color: palette.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  if (error != null) {
                    final isEnd = error.contains('نهاية الكتاب');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(AppSpace.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEnd
                                  ? Icons.auto_stories_rounded
                                  : Icons.wifi_off_rounded,
                              color: isEnd ? palette.gold : palette.textMuted,
                              size: AppIcon.xl,
                            ),
                            const SizedBox(height: AppSpace.md),
                            Text(
                              error,
                              style: textTheme.body.copyWith(
                                color: isEnd ? palette.text : palette.textMuted,
                                fontWeight: isEnd
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpace.lg),
                            AppButton(
                              label: isEnd
                                  ? 'العودة للصفحة السابقة'
                                  : 'إعادة المحاولة',
                              size: AppButtonSize.sm,
                              onPressed: () => isEnd
                                  ? _jumpToPage(_totalPages)
                                  : _loadPage(pageNum),
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
                    onTap: _toggleControls,
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

            // ── 3. Unified Bottom Scholarly HUD (Exact same as Mutun) ─────────
            ScholarlyReaderHud(
              currentPage: _currentPage,
              totalPages: _totalPages,
              isBookmarked: _isBookmarked,
              memorizationMode: _memorizationMode,
              showControls: _showControls,
              accentColor: _accentColor,
              surface: _surface,
              onPreviousPage: _currentPage > 1 ? () => _jumpToPage(_currentPage - 1) : null,
              onNextPage: _currentPage < _totalPages ? () => _jumpToPage(_currentPage + 1) : null,
              onPageIndicatorTap: _showFihrisSheet,
              onToggleBookmark: _toggleBookmark,
              onShowBookmarks: _showBookmarksSheet,
              onAddNote: _openNoteDialog,
              onOpenFihris: _showFihrisSheet,
              onToggleMemorization: _toggleMemorizationMode,
              onOpenTypography: _showTypographySheet,
              onShare: _sharePageContent,
            ),
          ],
        ),
      ),
    );
  }
}
