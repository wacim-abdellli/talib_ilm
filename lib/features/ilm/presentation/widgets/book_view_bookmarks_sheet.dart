import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/services/book_progress_service.dart';
import '../../data/services/bookmark_entry_loader.dart';

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
                  _buildBookmarksList(context, bookmarks, palette, textTheme),
                  _buildNotesList(context, notes, palette, textTheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(
    BuildContext context,
    List<BookmarkEntry> bookmarks,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    if (bookmarks.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(AppSpace.xxl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppSize.tap,
                height: AppSize.tap,
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Icon(
                  Icons.bookmark_border_rounded,
                  color: palette.gold,
                  size: AppIcon.lg,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'لا توجد إشارات مرجعية محفوظة',
                style: textTheme.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'اضغط على أيقونة الإشارة أسفل شاشة القارئ لحفظ الصفحة أو الفقرة.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      itemCount: bookmarks.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, index) {
        final item = bookmarks[index];
        final pageBadgeText = item.totalPages != null && item.totalPages! > 0
            ? 'صفحة ${item.page} من ${item.totalPages}'
            : 'صفحة ${item.page}';

        return AppCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: () {
              Navigator.pop(context);
              widget.onSelectEntry?.call(item);
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.smRadius,
                      border: Border.all(
                        color: palette.gold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.bookmark_rounded,
                        color: palette.gold,
                        size: AppIcon.md,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row: Book Title + Page Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: textTheme.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: palette.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: palette.goldSoft,
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(
                                  color: palette.gold.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                pageBadgeText,
                                style: textTheme.caption.copyWith(
                                  color: palette.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Section/Chapter subtitle (multi-line to prevent truncation dots)
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.xxs),
                          Text(
                            item.subtitle,
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Attached note snippet if present
                        if (item.note != null && item.note!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpace.xs),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                            decoration: BoxDecoration(
                              color: palette.surfaceRaised,
                              borderRadius: AppRadius.smRadius,
                              border: Border.all(color: palette.border),
                            ),
                            child: Text(
                              item.note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.caption.copyWith(
                                color: palette.text,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'إزالة الإشارة',
                    constraints: const BoxConstraints(
                      minWidth: AppSize.tap,
                      minHeight: AppSize.tap,
                    ),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: palette.textMuted,
                      size: AppIcon.md,
                    ),
                    onPressed: () => _confirmDelete(item, isNote: false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesList(
    BuildContext context,
    List<BookmarkEntry> notes,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    if (notes.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(AppSpace.xxl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppSize.tap,
                height: AppSize.tap,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: palette.primary,
                  size: AppIcon.lg,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'لا توجد ملاحظات أو فوائد مدونة',
                style: textTheme.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'اضغط على أيقونة الملاحظة أسفل القارئ لتدوين فائدة على الصفحة الحالية.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, index) {
        final item = notes[index];
        final pageBadgeText = item.totalPages != null && item.totalPages! > 0
            ? 'صفحة ${item.page} من ${item.totalPages}'
            : 'صفحة ${item.page}';

        return AppCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: () {
              Navigator.pop(context);
              widget.onSelectEntry?.call(item);
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Page Pill Badge + Book Title + Action Buttons (No overflow!)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primarySoft,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: palette.primary.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          pageBadgeText,
                          style: textTheme.caption.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          item.title,
                          style: textTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: palette.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'تعديل الملاحظة',
                        constraints: const BoxConstraints(
                          minWidth: AppSize.tap,
                          minHeight: AppSize.tap,
                        ),
                        icon: Icon(
                          Icons.edit_rounded,
                          color: palette.primary,
                          size: AppIcon.sm,
                        ),
                        onPressed: () => _editNote(item),
                      ),
                      IconButton(
                        tooltip: 'حذف الملاحظة',
                        constraints: const BoxConstraints(
                          minWidth: AppSize.tap,
                          minHeight: AppSize.tap,
                        ),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: palette.textMuted,
                          size: AppIcon.sm,
                        ),
                        onPressed: () => _confirmDelete(item, isNote: true),
                      ),
                    ],
                  ),

                  // Row 2: Section/Chapter Subtitle on its own line (Fixes overflow and dots!)
                  if (item.subtitle.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpace.xxs,
                        bottom: AppSpace.xs,
                        start: AppSpace.xxs,
                      ),
                      child: Text(
                        item.subtitle,
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpace.xs),

                  // Row 3: Note Content Box (Selectable, full text, no clipping)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsetsDirectional.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: palette.surfaceRaised,
                      borderRadius: AppRadius.smRadius,
                      border: Border.all(color: palette.border),
                    ),
                    child: SelectableText(
                      item.note ?? '',
                      style: textTheme.body.copyWith(
                        color: palette.text,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
