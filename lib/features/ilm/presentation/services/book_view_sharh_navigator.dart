import 'package:flutter/material.dart';

import '../../../../app/constants/app_assets.dart';
import '../../../../core/services/last_activity_service.dart';
import '../../../../core/services/last_sharh_service.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/catalogs/turath_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/shamela_models.dart';
import '../../data/models/sharh_model.dart';
import '../../data/services/book_progress_service.dart';
import '../../data/services/shamela_service.dart';
import '../pages/shamela_reader_page.dart';
import '../pages/sharh_reader_page.dart';

class BookSharhState {
  final String? lastSharhFile;
  final Sharh? lastSharh;
  final PdfPageInfo? lastSharhPage;
  final Map<String, int> shuruhPages;

  const BookSharhState({
    this.lastSharhFile,
    this.lastSharh,
    this.lastSharhPage,
    required this.shuruhPages,
  });
}

abstract final class BookViewSharhNavigator {
  static Future<BookSharhState> loadSharhState({
    required IlmBook book,
    required LastSharhService lastSharhService,
    required LastActivityService lastActivityService,
  }) async {
    final file = await lastSharhService.get(book.id);
    final sharh = book.shuruh.where((s) => s.file == file).firstOrNull;

    final Map<String, int> pages = {};
    for (final s in book.shuruh) {
      if (s.shamelaId != null) {
        final page = await ShamelaService.getLastReadPage(s.shamelaId!);
        if (page > 1) {
          pages[s.file] = page;
        }
      } else {
        final key = lastActivityService.pdfKeyForSharh(book.id, s.file);
        final pageInfo = await lastActivityService.getPdfPage(key);
        if (pageInfo != null && pageInfo.page > 1) {
          pages[s.file] = pageInfo.page;
        }
      }
    }

    PdfPageInfo? info;
    if (file != null) {
      if (sharh != null && sharh.shamelaId != null) {
        final page =
            pages[file] ?? await ShamelaService.getLastReadPage(sharh.shamelaId!);
        final total = sharh.totalPages ?? 50;
        info = PdfPageInfo(page: page, total: total);
      } else {
        final key = lastActivityService.pdfKeyForSharh(book.id, file);
        info = await lastActivityService.getPdfPage(key);
      }
    }

    return BookSharhState(
      lastSharhFile: file,
      lastSharh: sharh,
      lastSharhPage: info,
      shuruhPages: pages,
    );
  }

  static Future<void> openSharh({
    required BuildContext context,
    required IlmBook book,
    required Sharh sharh,
    required LastSharhService lastSharhService,
    required LastActivityService lastActivityService,
    required Future<BookProgressService> Function() getProgressService,
    required Future<void> Function() onReload,
  }) async {
    await lastSharhService.save(book.id, sharh.file);
    await lastActivityService.setLastSharh(book.id, sharh.file);

    if (sharh.shamelaId != null) {
      final match = TurathCatalog.books
          .where((b) => b.id == sharh.shamelaId)
          .firstOrNull;
      final totalPages = sharh.totalPages ?? match?.totalPages ?? 50;
      final shamelaBook = match?.copyWith(totalPages: totalPages) ??
          ShamelaBook(
            id: sharh.shamelaId!,
            title: sharh.title,
            author: sharh.scholar,
            category: 'شروح المتون',
            categoryId: 1,
            totalPages: totalPages,
            description: sharh.description ?? sharh.title,
          );

      final initialPage =
          await ShamelaService.getLastReadPage(sharh.shamelaId!);

      if (!context.mounted) return;

      await Navigator.push(
        context,
        buildFadeRoute(
          page: ShamelaReaderPage(
            book: shamelaBook,
            initialPage: initialPage,
          ),
        ),
      );

      await onReload();
      return;
    }

    final pdfPath = AppAssets.sharhPdf(book.id, sharh.file);
    final pdfKey = lastActivityService.pdfKeyForSharh(
      book.id,
      sharh.file,
    );
    final initialPage = await lastActivityService
        .getPdfPage(pdfKey)
        .then((info) => info?.page ?? 1);

    final progressService = await getProgressService();
    if (!context.mounted) return;

    await Navigator.push(
      context,
      buildFadeRoute(
        page: SharhReaderPage(
          bookId: book.id,
          sharh: sharh,
          pdfPath: pdfPath,
          pdfKey: pdfKey,
          initialPage: initialPage,
          progressService: progressService,
          lastActivityService: lastActivityService,
        ),
      ),
    );

    await onReload();
  }
}
