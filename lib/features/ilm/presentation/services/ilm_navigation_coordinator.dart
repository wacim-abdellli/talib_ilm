import 'package:flutter/material.dart';

import '../../../../core/models/favorite_item.dart';
import '../../../../core/services/favorites_service.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/catalogs/turath_catalog.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/motivation_service.dart';
import '../widgets/ilm_reading_tracker_sheet.dart';
import '../widgets/motivation_widgets.dart';

/// Helper coordinator for Ilm reading tracker, favorite syncing, and milestone dialogs.
class IlmNavigationCoordinator {
  const IlmNavigationCoordinator._();

  static void openBookFromTracker({
    required BuildContext context,
    required String bookId,
    required Map<String, IlmBook> bookCatalog,
    required Map<String, BookProgress> progressById,
    required void Function(ShamelaBook book) onOpenShamelaReader,
    required void Function(IlmBook book) onNavigateToBook,
  }) {
    if (bookId.startsWith('shamela_')) {
      final shamelaId = int.tryParse(bookId.replaceFirst('shamela_', ''));
      if (shamelaId != null) {
        final match = TurathCatalog.books.cast<ShamelaBook?>().firstWhere(
              (b) => b?.id == shamelaId,
              orElse: () => null,
            );
        if (match != null) {
          onOpenShamelaReader(match);
          return;
        }
        final p = progressById[bookId];
        if (p != null) {
          onOpenShamelaReader(
            ShamelaBook(
              id: shamelaId,
              title: p.bookTitle,
              author: 'علم شرعي',
              category: p.level,
              categoryId: 0,
              totalPages: p.totalPages,
            ),
          );
          return;
        }
      }
    }

    final book = bookCatalog[bookId];
    if (book != null) {
      onNavigateToBook(book);
    }
  }

  static Future<void> showReadingProgressSheet({
    required BuildContext context,
    required Map<String, BookProgress> progressById,
    required int totalLibraryBooks,
    required Map<String, IlmBook> bookCatalog,
    required void Function(String bookId) onOpenBook,
  }) async {
    final inProgress = progressById.values
        .where((p) =>
            (!p.isCompleted || p.currentPage < p.totalPages) &&
            p.currentPage > 1)
        .toList()
      ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));

    final completed = progressById.values
        .where((p) => p.isCompleted)
        .toList()
      ..sort((a, b) => (b.completedDate ?? b.lastReadDate)
          .compareTo(a.completedDate ?? a.lastReadDate));

    await IlmReadingTrackerSheet.show(
      context: context,
      inProgressBooks: inProgress,
      completedBooks: completed,
      totalLibraryBooks: totalLibraryBooks,
      bookCatalog: bookCatalog,
      onOpenBook: onOpenBook,
    );
  }

  static Future<void> reconcileFavorites({
    required Set<String> favoriteBookIds,
    required Map<String, BookProgress> progressById,
    required Map<String, IlmBook> bookCatalog,
    required Future<void> Function(String bookId, bool isFav)? setProgressFavorite,
  }) async {
    final syncTasks = <Future>[];
    for (final bookId in favoriteBookIds) {
      if (progressById.containsKey(bookId)) {
        final p = progressById[bookId]!;
        if (!p.isFavorite) {
          progressById[bookId] = p.copyWith(isFavorite: true);
          final t = setProgressFavorite?.call(bookId, true);
          if (t != null) syncTasks.add(t);
        }
      }
    }
    for (final p in progressById.values) {
      if (p.isFavorite && !favoriteBookIds.contains(p.bookId)) {
        final book = bookCatalog[p.bookId];
        if (book != null) {
          favoriteBookIds.add(p.bookId);
          syncTasks.add(
            FavoritesService().add(
              FavoriteItem(
                id: book.id,
                title: book.title,
                type: FavoriteType.book,
                subtitle: book.author,
              ),
            ),
          );
        }
      }
    }
    if (syncTasks.isNotEmpty) {
      await Future.wait(syncTasks);
    }
  }

  static void checkAndCelebrateBookFinish({
    required BuildContext context,
    required IlmBook book,
    required bool wasCompleted,
    required BookProgress? progressNow,
  }) {
    final isCompletedNow = progressNow?.isCompleted ?? false;
    final digitalEntry = MutunDigitalCatalog.getEntry(book.id);
    final expectedTotal = digitalEntry != null && digitalEntry.totalPages > 0
        ? digitalEntry.totalPages
        : (book.totalPages > 0
              ? book.totalPages
              : (progressNow?.totalPages ?? 0));
    final isGenuinelyFinished =
        isCompletedNow &&
        expectedTotal > 1 &&
        (progressNow?.currentPage ?? 0) >= expectedTotal;

    if (!wasCompleted && isGenuinelyFinished) {
      MilestoneCelebrationDialog.show(
        context,
        MilestoneTrigger(
          type: MilestoneType.booksCount,
          title: 'أحسنت!',
          message: 'أتممت كتاب "${book.title}" بفضل الله.',
          icon: '🌿',
          verse: 'وَقُل رَّبِّ زِدْنِي عِلْمًا',
          verseRef: 'سورة طه: 114',
        ),
      );
    }
  }
}
