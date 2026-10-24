import '../../../../core/models/favorite_item.dart';
import '../../../../core/services/asset_service.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/services/last_activity_service.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/services/book_progress_service.dart';
import '../../data/services/shamela_service.dart';

abstract final class BookViewPersistenceDelegate {
  static Future<String> resolveBookLevel(String bookId) async {
    try {
      final program = await AssetService.loadMutunProgram();
      for (final level in program.levels) {
        if (level.books.any((book) => book.id == bookId)) {
          return level.title;
        }
      }
    } catch (_) {}
    return 'غير محدد';
  }

  static Future<int> resolveInitialMutunPage({
    required IlmBook book,
    required int? initialPage,
    required int totalPages,
    required String mutunPdfKey,
    required LastActivityService lastActivityService,
    required BookProgressService progressService,
    required MutunDigitalEntry? digitalEntry,
  }) async {
    int resolvedPage = initialPage ?? 1;

    if (initialPage == null) {
      try {
        final info = await lastActivityService.getPdfPage(mutunPdfKey);
        if (info != null && info.page > resolvedPage) {
          resolvedPage = info.page;
        }
      } catch (_) {}

      try {
        final progress = await progressService.getBookProgress(book.id);
        if (progress != null && progress.currentPage > resolvedPage) {
          resolvedPage = progress.currentPage;
        }
      } catch (_) {}

      if (digitalEntry != null) {
        try {
          final shamelaPage =
              await ShamelaService.getLastReadPage(digitalEntry.shamelaId);
          if (shamelaPage > resolvedPage) {
            resolvedPage = shamelaPage;
          }
        } catch (_) {}
      }
    }

    final maxPage = totalPages > 0
        ? totalPages
        : (digitalEntry?.totalPages ??
            (book.totalPages > 0 ? book.totalPages : 1));
    return resolvedPage.clamp(1, maxPage);
  }

  static Future<void> ensureBookInitialized({
    required IlmBook book,
    required String bookLevelLabel,
    required int totalPages,
    required BookProgressService progressService,
  }) async {
    final digitalEntry = MutunDigitalCatalog.getEntry(book.id);
    final canonicalTotal = (digitalEntry != null && digitalEntry.totalPages > 0)
        ? digitalEntry.totalPages
        : (book.totalPages > 0 ? book.totalPages : 0);
    final safePages = totalPages > canonicalTotal
        ? totalPages
        : (canonicalTotal > 0 ? canonicalTotal : (totalPages <= 0 ? 1 : totalPages));

    await progressService.initializeBook(
      bookId: book.id,
      bookTitle: book.title,
      level: bookLevelLabel,
      totalPages: safePages,
    );
  }

  static void persistLastPositionSync({
    required String bookId,
    required String mutunPdfKey,
    required int currentPage,
    required int totalPages,
    required LastActivityService lastActivityService,
  }) {
    lastActivityService.savePdfPage(
      key: mutunPdfKey,
      page: currentPage,
      total: totalPages > 0 ? totalPages : 1,
    );
    final digitalEntry = MutunDigitalCatalog.getEntry(bookId);
    if (digitalEntry != null) {
      ShamelaService.saveLastReadPage(digitalEntry.shamelaId, currentPage);
    }
  }

  static Future<bool> loadFavorite({
    required String bookId,
    required FavoritesService favoritesService,
    required BookProgressService progressService,
  }) async {
    final saved = await favoritesService.isFavorite(
      FavoriteType.book,
      bookId,
    );
    await progressService.setFavorite(bookId, saved);
    return saved;
  }

  static Future<bool> toggleFavorite({
    required IlmBook book,
    required FavoritesService favoritesService,
    required BookProgressService progressService,
  }) async {
    final saved = await favoritesService.toggle(
      FavoriteItem(
        type: FavoriteType.book,
        id: book.id,
        title: book.title,
        subtitle: book.author,
      ),
    );
    await progressService.setFavorite(book.id, saved);
    return saved;
  }
}
