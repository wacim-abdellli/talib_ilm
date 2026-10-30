import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/asset_service.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/catalogs/mutun_audio_catalog.dart';
import '../../data/catalogs/turath_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/mutun_audio_service.dart';
import '../../data/services/shamela_service.dart';
import '../pages/book_view_page.dart';
import '../pages/shamela_reader_page.dart';

/// Central navigation coordinator that returns the user directly to the
/// exact book, reading page, and active audio player session from any screen.
class BookAudioNavigationHelper {
  const BookAudioNavigationHelper._();

  /// Resolves the currently playing/active book and pushes the appropriate reader
  /// page with the audio player HUD already visible and synced to live playback.
  static Future<bool> returnToActiveBook(BuildContext context) async {
    final audioService = MutunAudioService();
    final bookId = audioService.activeBookIdNotifier.value;
    if (bookId == null) return false;

    HapticFeedback.lightImpact();

    // 1. Classical Heritage Books from Maktaba Shamela
    if (bookId.startsWith('shamela_')) {
      final shamelaId = int.tryParse(bookId.replaceFirst('shamela_', ''));
      if (shamelaId != null) {
        ShamelaBook? shamelaBook = TurathCatalog.books
            .cast<ShamelaBook?>()
            .firstWhere((b) => b?.id == shamelaId, orElse: () => null);

        if (shamelaBook == null) {
          final entry = MutunAudioCatalog.getEntry(bookId);
          shamelaBook = ShamelaBook(
            id: shamelaId,
            title: entry?.title ?? 'كتاب تراثي',
            author: 'تراث إسلامي',
            category: 'خزانة التراث',
            categoryId: 0,
            totalPages: 100,
          );
        }

        final lastPage = await ShamelaService.getLastReadPage(shamelaId);
        final initialPage = lastPage > 0 ? lastPage : 1;

        if (context.mounted) {
          await Navigator.push(
            context,
            buildFadeRoute(
              page: ShamelaReaderPage(
                book: shamelaBook,
                initialPage: initialPage,
                initialShowAudio: true,
              ),
            ),
          );
          return true;
        }
        return false;
      }
    }

    // 2. Syllabus Mutun Books (متون طالب العلم)
    try {
      final program = await AssetService.loadMutunProgram();
      final resolvedKey = MutunAudioCatalog.resolveBookId(bookId);
      final catalogEntry = MutunAudioCatalog.getEntry(bookId);
      IlmBook? matchedBook;

      for (final lvl in program.levels) {
        for (final b in lvl.books) {
          if (b.id == bookId ||
              b.id == resolvedKey ||
              MutunAudioCatalog.resolveBookId(b.id) == resolvedKey ||
              (catalogEntry != null && b.title == catalogEntry.title) ||
              (catalogEntry != null && catalogEntry.title.contains(b.title))) {
            matchedBook = b;
            break;
          }
        }
        if (matchedBook != null) break;
      }

      if (matchedBook != null && context.mounted) {
        await Navigator.push(
          context,
          buildFadeRoute(
            page: BookViewPage(
              book: matchedBook,
              initialTabIndex: 0,
            ),
          ),
        );
        return true;
      }
    } catch (_) {}

    // 3. Fallback: Search TurathCatalog by title match
    final entry = MutunAudioCatalog.getEntry(bookId);
    if (entry != null) {
      final shamelaMatch = TurathCatalog.books.cast<ShamelaBook?>().firstWhere(
            (b) =>
                b != null &&
                (b.title == entry.title ||
                    entry.title.contains(b.title) ||
                    b.title.contains(entry.title)),
            orElse: () => null,
          );
      if (shamelaMatch != null) {
        final lastPage = await ShamelaService.getLastReadPage(shamelaMatch.id);
        if (context.mounted) {
          await Navigator.push(
            context,
            buildFadeRoute(
              page: ShamelaReaderPage(
                book: shamelaMatch,
                initialPage: lastPage > 0 ? lastPage : 1,
                initialShowAudio: true,
              ),
            ),
          );
          return true;
        }
      }
    }

    return false;
  }
}
