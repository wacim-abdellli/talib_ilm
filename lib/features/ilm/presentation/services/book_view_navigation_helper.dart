import 'package:flutter/material.dart';

import '../../../../core/services/asset_service.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../data/catalogs/mutun_curriculum_catalog.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/sharh_model.dart';
import '../../data/services/bookmark_entry_loader.dart';
import '../pages/book_view_page.dart';

abstract final class BookViewNavigationHelper {
  static Future<void> navigateToEntry({
    required BuildContext context,
    required BookmarkEntry entry,
    required IlmBook currentBook,
    required TabController tabController,
    required GlobalKey<PdfViewerPageState> mutnPdfKey,
    required Set<int> bookmarkedPages,
    required void Function({
      required int targetParagraph,
      required int currentPage,
      required int totalPages,
      required bool isBookmarked,
    }) onUpdateMutnState,
    required void Function(Sharh sharh) onOpenSharh,
  }) async {
    if (entry.bookId == currentBook.id) {
      if (entry.sharhFile != null) {
        tabController.animateTo(1);
        final sharh = currentBook.shuruh.firstWhere(
          (s) => s.file == entry.sharhFile,
          orElse: () => currentBook.shuruh.first,
        );
        onOpenSharh(sharh);
      } else {
        tabController.animateTo(0);

        final curriculum = MutunCurriculumCatalog.getBook(currentBook.id);
        final digital = MutunDigitalCatalog.getEntry(currentBook.id);
        final totalParas = curriculum?.totalParagraphs ?? 0;
        final totalPages = digital?.totalPages ??
            (currentBook.totalPages > 0 ? currentBook.totalPages : 1);

        final targetPara = (totalPages > 0 && totalParas > 0)
            ? (((entry.page - 1) * totalParas) ~/ totalPages) + 1
            : entry.page;

        onUpdateMutnState(
          targetParagraph: targetPara,
          currentPage: entry.page,
          totalPages: totalPages,
          isBookmarked: bookmarkedPages.contains(entry.page),
        );

        mutnPdfKey.currentState?.jumpToPage(entry.page);
        if (context.mounted) {
          AppSnackbar.info(context, 'انتقال إلى صفحة ${entry.page}');
        }
      }
    } else {
      final program = await AssetService.loadMutunProgram();
      IlmBook? targetBook;
      for (final lvl in program.levels) {
        for (final b in lvl.books) {
          if (b.id == entry.bookId) {
            targetBook = b;
            break;
          }
        }
      }
      if (targetBook != null && context.mounted) {
        Navigator.of(context).push(
          buildFadeRoute(
            page: BookViewPage(
              book: targetBook,
              initialPage: entry.page,
              autoOpenSharhFile: entry.sharhFile,
            ),
          ),
        );
      }
    }
  }
}
