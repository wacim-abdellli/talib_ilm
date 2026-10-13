import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/asset_service.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/sharh_model.dart';
import '../../data/services/book_progress_service.dart';

class BookmarkEntry {
  final String title;
  final String subtitle;
  final String? note;

  const BookmarkEntry({
    required this.title,
    required this.subtitle,
    this.note,
  });
}

class BookViewBookmarksSheet extends StatelessWidget {
  final List<BookmarkEntry> entries;

  const BookViewBookmarksSheet({
    super.key,
    required this.entries,
  });

  static Future<void> show(BuildContext context, List<BookmarkEntry> entries) {
    return AppSheet.show<void>(
      context: context,
      builder: (context) => BookViewBookmarksSheet(entries: entries),
    );
  }

  static Future<void> loadAndShow({
    required BuildContext context,
    required BookProgressService progressService,
  }) async {
    final allProgress = await progressService.getAllProgress();
    final sharhBookmarks = await progressService.getAllSharhBookmarks();
    final sharhNotes = await progressService.getAllSharhNotes();
    final program = await AssetService.loadMutunProgram();

    final bookById = <String, IlmBook>{};
    final sharhByKey = <String, Sharh>{};
    for (final level in program.levels) {
      for (final book in level.books) {
        bookById[book.id] = book;
        for (final sharh in book.shuruh) {
          sharhByKey['${book.id}|${sharh.file}'] = sharh;
        }
      }
    }

    final entries = <BookmarkEntry>[];

    for (final progress in allProgress) {
      final bookTitle = progress.bookTitle.isNotEmpty
          ? progress.bookTitle
          : (bookById[progress.bookId]?.title ?? progress.bookId);
      for (final page in progress.bookmarkedPages) {
        final note = progress.notes[page];
        entries.add(
          BookmarkEntry(title: bookTitle, subtitle: 'صفحة $page', note: note),
        );
      }
    }

    for (final entry in sharhBookmarks.entries) {
      final sharh = sharhByKey[entry.key];
      final parts = entry.key.split('|');
      final bookId = parts.isNotEmpty ? parts.first : entry.key;
      final bookTitle = bookById[bookId]?.title ?? bookId;
      final sharhTitle = sharh?.title ?? 'شرح';
      final notes = sharhNotes[entry.key] ?? <int, String>{};
      for (final page in entry.value) {
        entries.add(
          BookmarkEntry(
            title: bookTitle,
            subtitle: '$sharhTitle • صفحة $page',
            note: notes[page],
          ),
        );
      }
    }

    entries.sort((a, b) => a.title.compareTo(b.title));

    if (!context.mounted) return;
    if (entries.isEmpty) {
      AppSnackbar.info(context, AppStrings.bookProgressSaved);
      return;
    }

    show(context, entries);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppSheet(
      titleText: 'الإشارات المرجعية',
      icon: Icons.bookmark_rounded,
      padding: EdgeInsets.zero,
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpace.xxl),
              child: Center(
                child: Text(
                  'لا توجد إشارات مرجعية محفوظة بعد',
                  style: context.text.bodySmall.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.all(AppSpace.lg),
              itemCount: entries.length,
              separatorBuilder: (_, _) => Divider(
                height: AppSpace.lg,
                color: palette.border,
              ),
              itemBuilder: (context, index) {
                final item = entries[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: context.text.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      item.subtitle,
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        item.note!,
                        style: context.text.bodySmall.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
