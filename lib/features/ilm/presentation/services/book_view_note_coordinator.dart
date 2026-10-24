import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/services/book_progress_service.dart';
import '../widgets/book_view_controls.dart' show BookNoteDialog;

abstract final class BookViewNoteCoordinator {
  static Future<void> showNoteDialog({
    required BuildContext context,
    required String bookId,
    required int currentPage,
    required int totalPages,
    required TextEditingController noteController,
    required Future<BookProgressService> Function() getProgressService,
    required Future<void> Function({int? totalPages}) ensureBookInitialized,
    required void Function({int initialTab}) onShowBookmarksAndNotes,
  }) async {
    final progressService = await getProgressService();
    final progress = await progressService.getBookProgress(bookId);
    final targetPage = currentPage > 0 ? currentPage : 1;
    final existingNote = progress?.notes[targetPage] ?? '';
    noteController.text = existingNote;

    if (!context.mounted) return;
    BookNoteDialog.show(
      context,
      controller: noteController,
      hasExistingNote: existingNote.isNotEmpty,
      onDelete: existingNote.isNotEmpty
          ? () async {
              await progressService.deleteNote(bookId, targetPage);
              noteController.clear();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              AppSnackbar.info(context, 'تم حذف الملاحظة (صفحة $targetPage)');
            }
          : null,
      onShowAllNotes: () {
        Navigator.of(context).pop();
        onShowBookmarksAndNotes(initialTab: 1);
      },
      onSave: () async {
        final text = noteController.text.trim();
        final service = await getProgressService();
        await ensureBookInitialized(totalPages: totalPages);
        if (text.isEmpty) {
          await service.deleteNote(bookId, targetPage);
        } else {
          await service.saveNote(
            bookId,
            targetPage,
            text,
          );
        }
        noteController.clear();
        if (!context.mounted) return;
        Navigator.of(context).pop();
        AppSnackbar.success(
          context,
          text.isEmpty
              ? 'تم حذف الملاحظة'
              : 'تم حفظ الملاحظة على صفحة $targetPage',
        );
      },
    );
  }
}
