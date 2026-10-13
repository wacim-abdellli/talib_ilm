import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/primary_app_bar.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';
import '../widgets/shamela_fihris_sheet.dart';
import '../widgets/shamela_text_highlighter.dart';
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

  double _fontSizeDelta = 2.0;
  String _fontFamily = 'Amiri';
  double _lineHeight = 1.85;
  ShamelaReaderSurface _surface = ShamelaReaderSurface.normal;
  bool _isBookmarked = false;

  final Map<int, ShamelaPage> _pageCache = {};
  final Set<int> _loadingPages = {};
  final Map<int, String> _pageErrors = {};

  List<ShamelaChapter> _chapters = [];
  bool _isLoadingChapters = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 100;
    _pageController = PageController(initialPage: _currentPage - 1);

    _loadPage(_currentPage);
    _checkBookmark();
    _loadFihris();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        setState(() {
          _loadingPages.remove(pageNum);
          _pageErrors[pageNum] = 'تعذر تحميل الصفحة. يرجى التحقق من الاتصال بالإنترنت.';
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
        onFontSizeChanged: (delta) => setState(() => _fontSizeDelta = delta),
        onFontFamilyChanged: (family) => setState(() => _fontFamily = family),
        onLineHeightChanged: (lh) => setState(() => _lineHeight = lh),
        onSurfaceChanged: (surf) => setState(() => _surface = surf),
      ),
    );
  }

  Color _getBackgroundColor(AppPalette palette) {
    switch (_surface) {
      case ShamelaReaderSurface.normal:
        return palette.bg;
      case ShamelaReaderSurface.parchment:
        return palette.goldSoft;
      case ShamelaReaderSurface.night:
        return palette.brandDark;
    }
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
        appBar: PrimaryAppBar(
          title: widget.book.title,
          showBack: true,
          actions: [
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: _isBookmarked ? palette.gold : palette.text,
              ),
              tooltip: 'حفظ علامة مرجعية',
              onPressed: _toggleBookmark,
            ),
            IconButton(
              icon: Icon(Icons.format_size_rounded, color: palette.text),
              tooltip: 'تنسيق الخط وخيارات القراءة',
              onPressed: _showTypographySheet,
            ),
            IconButton(
              icon: Icon(Icons.list_alt_rounded, color: palette.text),
              tooltip: 'فهرس الكتاب',
              onPressed: _showFihrisSheet,
            ),
          ],
        ),
        body: Column(
          children: [
            // Metadata strip
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(bottom: BorderSide(color: palette.border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.book.author,
                      style: textTheme.caption.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'ص $_currentPage من $_totalPages',
                    style: textTheme.caption.copyWith(color: palette.textMuted),
                  ),
                ],
              ),
            ),

            // Reader Content View
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
                          CircularProgressIndicator(color: palette.gold, strokeWidth: 2),
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
                    return Center(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(AppSpace.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off_rounded, color: palette.textMuted, size: AppIcon.xl),
                            const SizedBox(height: AppSpace.md),
                            Text(
                              error,
                              style: textTheme.body.copyWith(color: palette.textMuted),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpace.lg),
                            AppButton(
                              label: 'إعادة المحاولة',
                              size: AppButtonSize.sm,
                              onPressed: () => _loadPage(pageNum),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (page == null) {
                    return const SizedBox.shrink();
                  }

                  return _buildPageContent(page, palette, textTheme);
                },
              ),
            ),

            // Bottom Navigation Footer
            _buildBottomFooter(palette, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(
    ShamelaPage page,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    // SelectionArea wraps the entire scrollable area allowing free vertical scrolling with zero gesture friction
    return SelectionArea(
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chapter Header Pill if present
              if (page.chapterTitle != null && page.chapterTitle!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(color: palette.gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    page.chapterTitle!,
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],

              // Enhanced body text with scholarly syntax coloring
              Text.rich(
                ShamelaTextHighlighter.buildSpans(
                  text: page.content,
                  palette: palette,
                  textTheme: textTheme,
                  fontFamily: _fontFamily,
                  fontSizeDelta: _fontSizeDelta,
                  lineHeight: _lineHeight,
                ),
                textAlign: TextAlign.start,
              ),

              // Footnotes (الحواشي والتحقيق) Section if present
              if (page.hamesh != null && page.hamesh!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                Divider(color: palette.gold.withValues(alpha: 0.4), height: 1),
                const SizedBox(height: AppSpace.sm),
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes_rounded, color: palette.primary, size: AppIcon.sm),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'الحواشي والتحقيق:',
                            style: textTheme.caption.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text.rich(
                        ShamelaTextHighlighter.buildSpans(
                          text: page.hamesh!,
                          palette: palette,
                          textTheme: textTheme,
                          fontFamily: _fontFamily,
                          fontSizeDelta: _fontSizeDelta * 0.7 - 2.0,
                          lineHeight: 1.6,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpace.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomFooter(AppPalette palette, AppTextTheme textTheme) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Next Page Button (RTL: forward in book)
            IconButton(
              icon: Icon(Icons.arrow_forward_ios_rounded, size: AppIcon.sm, color: palette.text),
              tooltip: 'الصفحة التالية',
              onPressed: _currentPage < _totalPages
                  ? () => _jumpToPage(_currentPage + 1)
                  : null,
            ),

            Expanded(
              child: Slider(
                value: _currentPage.toDouble(),
                min: 1.0,
                max: _totalPages.toDouble(),
                divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                activeColor: palette.gold,
                inactiveColor: palette.border,
                onChanged: (val) {
                  _jumpToPage(val.toInt());
                },
              ),
            ),

            // Previous Page Button (RTL: back in book)
            IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, size: AppIcon.sm, color: palette.text),
              tooltip: 'الصفحة السابقة',
              onPressed: _currentPage > 1
                  ? () => _jumpToPage(_currentPage - 1)
                  : null,
            ),

            // Actions: Copy & Share
            IconButton(
              icon: Icon(Icons.copy_rounded, size: AppIcon.sm, color: palette.textMuted),
              tooltip: 'نسخ الصفحة وتوثيقها',
              onPressed: _copyPageContent,
            ),
            IconButton(
              icon: Icon(Icons.share_rounded, size: AppIcon.sm, color: palette.textMuted),
              tooltip: 'مشاركة',
              onPressed: _sharePageContent,
            ),
          ],
        ),
      ),
    );
  }
}
