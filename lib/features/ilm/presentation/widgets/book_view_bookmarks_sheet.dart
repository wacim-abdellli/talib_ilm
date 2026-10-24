import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/services/book_progress_service.dart';
import '../../data/services/bookmark_entry_loader.dart';
import 'book_view_bookmarks_tab.dart';
import 'book_view_notes_tab.dart';

export '../../data/services/bookmark_entry_loader.dart' show BookmarkEntry;

class BookViewBookmarksSheet extends StatefulWidget {
  final List<BookmarkEntry> entries;
  final String? currentBookId;
  final int initialTab;
  final void Function(BookmarkEntry entry)? onSelectEntry;
  final Future<void> Function(BookmarkEntry entry)? onDeleteBookmark;
  final Future<void> Function(BookmarkEntry entry)? onDeleteNote;
  final Future<void> Function(BookmarkEntry entry, String newText)? onEditNote;

  const BookViewBookmarksSheet({
    super.key,
    required this.entries,
    this.currentBookId,
    this.initialTab = 0,
    this.onSelectEntry,
    this.onDeleteBookmark,
    this.onDeleteNote,
    this.onEditNote,
  });

  static Future<void> show(
    BuildContext context,
    List<BookmarkEntry> entries, {
    String? currentBookId,
    int initialTab = 0,
    void Function(BookmarkEntry entry)? onSelectEntry,
    Future<void> Function(BookmarkEntry entry)? onDeleteBookmark,
    Future<void> Function(BookmarkEntry entry)? onDeleteNote,
    Future<void> Function(BookmarkEntry entry, String newText)? onEditNote,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.88,
      builder: (context) => BookViewBookmarksSheet(
        entries: entries,
        currentBookId: currentBookId,
        initialTab: initialTab,
        onSelectEntry: onSelectEntry,
        onDeleteBookmark: onDeleteBookmark,
        onDeleteNote: onDeleteNote,
        onEditNote: onEditNote,
      ),
    );
  }

  static Future<void> loadAndShow({
    required BuildContext context,
    required BookProgressService progressService,
    String? currentBookId,
    int initialTab = 0,
    void Function(BookmarkEntry entry)? onSelectEntry,
  }) async {
    final entries = await BookmarkEntryLoader.loadAll(progressService);
    if (!context.mounted) return;

    if (entries.isEmpty) {
      AppSnackbar.info(context, 'لا توجد إشارات مرجعية أو ملاحظات محفوظة بعد');
      return;
    }

    show(
      context,
      entries,
      currentBookId: currentBookId,
      initialTab: initialTab,
      onSelectEntry: onSelectEntry,
      onDeleteBookmark: (item) async {
        if (item.sharhFile != null) {
          await progressService.removeSharhBookmark(item.bookId, item.sharhFile!, item.page);
        } else {
          await progressService.removeBookmark(item.bookId, item.page);
        }
      },
      onDeleteNote: (item) async {
        if (item.sharhFile != null) {
          await progressService.deleteSharhNote(item.bookId, item.sharhFile!, item.page);
        } else {
          await progressService.deleteNote(item.bookId, item.page);
        }
      },
      onEditNote: (item, newText) async {
        if (item.sharhFile != null) {
          await progressService.saveSharhNote(item.bookId, item.sharhFile!, item.page, newText);
        } else {
          await progressService.saveNote(item.bookId, item.page, newText);
        }
      },
    );
  }

  @override
  State<BookViewBookmarksSheet> createState() => _BookViewBookmarksSheetState();
}

class _BookViewBookmarksSheetState extends State<BookViewBookmarksSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late List<BookmarkEntry> _items;
  bool _filterCurrentBookOnly = false;

  @override
  void initState() {
    super.initState();
    _items = List<BookmarkEntry>.from(widget.entries);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(_onTabChanged);
    if (widget.currentBookId != null &&
        _items.any((e) => e.bookId == widget.currentBookId)) {
      _filterCurrentBookOnly = true;
    }
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  List<BookmarkEntry> get _filteredEntries {
    if (_filterCurrentBookOnly && widget.currentBookId != null) {
      return _items.where((e) => e.bookId == widget.currentBookId).toList();
    }
    return _items;
  }

  List<BookmarkEntry> get _bookmarksList =>
      _filteredEntries.where((e) => e.isBookmark).toList();

  List<BookmarkEntry> get _notesList => _filteredEntries
      .where((e) => e.note != null && e.note!.trim().isNotEmpty)
      .toList();

  void _confirmDelete(BookmarkEntry item, {required bool isNote}) {
    HapticFeedback.lightImpact();
    AppDialog.show<void>(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: isNote ? 'حذف الملاحظة' : 'حذف الإشارة المرجعية',
        icon: Icons.delete_outline_rounded,
        content: Text(
          isNote
              ? 'هل أنت متأكد من رغبتك في حذف هذه الملاحظة؟'
              : 'هل أنت متأكد من إزالة هذه الإشارة المرجعية؟',
          style: dialogCtx.text.body,
        ),
        actions: [
          AppButton.text(
            label: 'إلغاء',
            onPressed: () => Navigator.pop(dialogCtx),
            size: AppButtonSize.sm,
          ),
          AppButton(
            label: 'حذف',
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (isNote) {
                await widget.onDeleteNote?.call(item);
                setState(() {
                  final idx = _items.indexOf(item);
                  if (idx >= 0) {
                    if (item.isBookmark) {
                      _items[idx] = item.copyWith(note: '');
                    } else {
                      _items.removeAt(idx);
                    }
                  }
                });
                if (mounted) {
                  AppSnackbar.info(context, 'تم حذف الملاحظة');
                }
              } else {
                await widget.onDeleteBookmark?.call(item);
                setState(() {
                  final idx = _items.indexOf(item);
                  if (idx >= 0) {
                    if (item.note != null && item.note!.trim().isNotEmpty) {
                      _items[idx] = item.copyWith(isBookmark: false);
                    } else {
                      _items.removeAt(idx);
                    }
                  }
                });
                if (mounted) {
                  AppSnackbar.info(context, 'تمت إزالة الإشارة المرجعية');
                }
              }
            },
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _editNote(BookmarkEntry item) {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(text: item.note ?? '');

    AppDialog.show<void>(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: 'تعديل الملاحظة',
        icon: Icons.edit_note_rounded,
        content: TextField(
          controller: controller,
          style: dialogCtx.text.body,
          decoration: InputDecoration(
            hintText: 'اكتب ملاحظتك هنا...',
            hintStyle: dialogCtx.text.bodySmall.copyWith(
              color: dialogCtx.palette.textMuted,
            ),
          ),
          minLines: 3,
          maxLines: 6,
        ),
        actions: [
          AppButton.text(
            label: 'إلغاء',
            onPressed: () => Navigator.pop(dialogCtx),
            size: AppButtonSize.sm,
          ),
          AppButton(
            label: 'حفظ',
            onPressed: () async {
              final newText = controller.text.trim();
              Navigator.pop(dialogCtx);
              await widget.onEditNote?.call(item, newText);
              setState(() {
                final idx = _items.indexOf(item);
                if (idx >= 0) {
                  _items[idx] = item.copyWith(note: newText);
                }
              });
              if (mounted) {
                AppSnackbar.success(context, 'تم تحديث الملاحظة');
              }
            },
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final bookmarks = _bookmarksList;
    final notes = _notesList;

    return AppSheet(
      titleText: 'المحفوظات والملاحظات',
      icon: Icons.collections_bookmark_rounded,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              dividerHeight: 0.0,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: AppRadius.smRadius,
              ),
              labelColor: palette.onPrimarySoft,
              unselectedLabelColor: palette.textMuted,
              labelStyle: textTheme.label.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: textTheme.label,
              tabs: [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_rounded, size: AppIcon.sm),
                        const SizedBox(width: AppSpace.xs),
                        Text('الإشارات (${bookmarks.length})'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_rounded, size: AppIcon.sm),
                        const SizedBox(width: AppSpace.xs),
                        Text('الملاحظات (${notes.length})'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.currentBookId != null)
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final isNotesTab = _tabController.index == 1;
                final currentBookCount = isNotesTab
                    ? _items
                        .where((e) =>
                            e.bookId == widget.currentBookId &&
                            e.note != null &&
                            e.note!.trim().isNotEmpty)
                        .length
                    : _items
                        .where((e) =>
                            e.bookId == widget.currentBookId && e.isBookmark)
                        .length;
                final allBooksCount = isNotesTab
                    ? _items
                        .where((e) =>
                            e.note != null && e.note!.trim().isNotEmpty)
                        .length
                    : _items.where((e) => e.isBookmark).length;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.xxs,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: AppRadius.pillRadius,
                        onTap: () =>
                            setState(() => _filterCurrentBookOnly = true),
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: _filterCurrentBookOnly
                                ? palette.primarySoft
                                : palette.surface,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: _filterCurrentBookOnly
                                  ? palette.primary
                                  : palette.border,
                            ),
                          ),
                          child: Text(
                            'هذا الكتاب ($currentBookCount)',
                            style: textTheme.caption.copyWith(
                              color: _filterCurrentBookOnly
                                  ? palette.primary
                                  : palette.textMuted,
                              fontWeight: _filterCurrentBookOnly
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      InkWell(
                        borderRadius: AppRadius.pillRadius,
                        onTap: () =>
                            setState(() => _filterCurrentBookOnly = false),
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: !_filterCurrentBookOnly
                                ? palette.primarySoft
                                : palette.surface,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: !_filterCurrentBookOnly
                                  ? palette.primary
                                  : palette.border,
                            ),
                          ),
                          child: Text(
                            'جميع الكتب ($allBooksCount)',
                            style: textTheme.caption.copyWith(
                              color: !_filterCurrentBookOnly
                                  ? palette.primary
                                  : palette.textMuted,
                              fontWeight: !_filterCurrentBookOnly
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          Flexible(
            child: SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  BookViewBookmarksTab(
                    bookmarks: bookmarks,
                    onSelectEntry: widget.onSelectEntry,
                    onDeleteBookmark: (item) => _confirmDelete(item, isNote: false),
                  ),
                  BookViewNotesTab(
                    notes: notes,
                    onSelectEntry: widget.onSelectEntry,
                    onEditNote: _editNote,
                    onDeleteNote: (item) => _confirmDelete(item, isNote: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
