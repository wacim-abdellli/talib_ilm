import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/last_activity_service.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../data/models/sharh_model.dart';
import '../../data/services/book_progress_service.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة ملاحظة', style: AppTextStyles.heading3),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            hintText: 'اكتب ملاحظتك هنا...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.progressService.saveSharhNote(
                widget.bookId,
                widget.sharh.file,
                _currentPage,
                _noteController.text,
              );
              _noteController.clear();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              await _loadSharhData();
              if (context.mounted) {
                AppSnackbar.success(context, 'تم حفظ الملاحظة');
              }
            },
            child: const Text('حفظ'),
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

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إشارات الشرح', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  final pages = _bookmarkedPages.toList()..sort();
                  return ListView.separated(
                    itemCount: pages.length,
                    separatorBuilder: (_, _) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      final note = _notes[page];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('صفحة $page', style: AppTextStyles.bodyMedium),
                          if (note != null && note.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(note, style: AppTextStyles.bodySmall),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: _isBookmarked
                ? AppColors.primary
                : AppColors.surface,
            onPressed: _toggleBookmark,
            child: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'sharh_note_fab',
            mini: true,
            backgroundColor: AppColors.surface,
            onPressed: _showNoteDialog,
            child: const Icon(Icons.note_add, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'sharh_bookmarks_fab',
            mini: true,
            backgroundColor: AppColors.surface,
            onPressed: _showBookmarksList,
            child: const Icon(Icons.list, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
