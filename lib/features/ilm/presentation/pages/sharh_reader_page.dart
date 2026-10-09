import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../core/services/last_activity_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../data/models/sharh_model.dart';
import '../../data/services/book_progress_service.dart';
import '../widgets/book_view_bookmarks_sheet.dart';

class SharhReaderPage extends StatefulWidget {
  final String bookId;
  final Sharh sharh;
  final String pdfPath;
  final String pdfKey;
  final int initialPage;
  final BookProgressService progressService;
  final LastActivityService lastActivityService;

  const SharhReaderPage({
    super.key,
    required this.bookId,
    required this.sharh,
    required this.pdfPath,
    required this.pdfKey,
    required this.initialPage,
    required this.progressService,
    required this.lastActivityService,
  });

  @override
  State<SharhReaderPage> createState() => _SharhReaderPageState();
}

class _SharhReaderPageState extends State<SharhReaderPage> {
  final TextEditingController _noteController = TextEditingController();
  final Set<int> _bookmarkedPages = <int>{};
  Map<int, String> _notes = <int, String>{};
  int _currentPage = 1;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage < 1 ? 1 : widget.initialPage;
    _loadSharhData();
  }

  Future<void> _loadSharhData() async {
    final pages = await widget.progressService.getSharhBookmarks(
      widget.bookId,
      widget.sharh.file,
    );
    final notes = await widget.progressService.getSharhNotes(
      widget.bookId,
      widget.sharh.file,
    );
    if (!mounted) return;
    setState(() {
      _bookmarkedPages
        ..clear()
        ..addAll(pages);
      _notes = notes;
      _isBookmarked = _bookmarkedPages.contains(_currentPage);
    });
  }

  void _handlePageChanged(int page, int total) {
    if (total <= 0) return;
    final safeTotal = total < page ? page : total;
    setState(() {
      _currentPage = page;
      _isBookmarked = _bookmarkedPages.contains(page);
    });
    widget.lastActivityService.savePdfPage(
      key: widget.pdfKey,
      page: page,
      total: safeTotal,
    );
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkedPages.contains(_currentPage)) {
      await widget.progressService.removeSharhBookmark(
        widget.bookId,
        widget.sharh.file,
        _currentPage,
      );
    } else {
      await widget.progressService.addSharhBookmark(
        widget.bookId,
        widget.sharh.file,
        _currentPage,
      );
    }
    await _loadSharhData();
  }

  void _showNoteDialog() {
    _noteController.text = _notes[_currentPage] ?? '';
    final palette = context.palette;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surfaceRaised,
        title: Text('إضافة ملاحظة', style: context.text.titleSmall),
        content: TextField(
          controller: _noteController,
          style: context.text.body,
          decoration: InputDecoration(
            hintText: 'اكتب ملاحظتك هنا...',
            hintStyle: context.text.bodySmall.copyWith(color: palette.textMuted),
          ),
          maxLines: 5,
        ),
        actions: [
          AppButton.text(
            label: 'إلغاء',
            onPressed: () => Navigator.pop(dialogContext),
            size: AppButtonSize.sm,
          ),
          AppButton(
            label: 'حفظ',
            onPressed: () async {
              await widget.progressService.saveSharhNote(
                widget.bookId,
                widget.sharh.file,
                _currentPage,
                _noteController.text,
              );
              _noteController.clear();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              await _loadSharhData();
              if (mounted) {
                AppSnackbar.success(context, 'تم حفظ الملاحظة');
              }
            },
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _showBookmarksList() {
    if (_bookmarkedPages.isEmpty) {
      AppSnackbar.info(context, 'لا توجد إشارات مرجعية');
      return;
    }

    final pages = _bookmarkedPages.toList()..sort();
    final entries = pages
        .map(
          (p) => BookmarkEntry(
            title: widget.sharh.title,
            subtitle: 'صفحة $p',
            note: _notes[p],
          ),
        )
        .toList();

    BookViewBookmarksSheet.show(context, entries);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return PdfViewerPage(
      title: widget.sharh.title,
      assetPath: widget.pdfPath,
      initialPage: widget.initialPage,
      onPageChanged: _handlePageChanged,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'sharh_bookmark_fab',
            mini: true,
            elevation: 2,
            backgroundColor:
                _isBookmarked ? palette.goldFill : palette.surfaceRaised,
            onPressed: _toggleBookmark,
            child: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? palette.onGold : palette.gold,
              size: AppIcon.md,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          FloatingActionButton(
            heroTag: 'sharh_note_fab',
            mini: true,
            elevation: 2,
            backgroundColor: palette.surfaceRaised,
            onPressed: _showNoteDialog,
            child: Icon(
              Icons.note_add,
              color: palette.primary,
              size: AppIcon.md,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          FloatingActionButton(
            heroTag: 'sharh_bookmarks_fab',
            mini: true,
            elevation: 2,
            backgroundColor: palette.surfaceRaised,
            onPressed: _showBookmarksList,
            child: Icon(
              Icons.list,
              color: palette.primary,
              size: AppIcon.md,
            ),
          ),
        ],
      ),
    );
  }
}
