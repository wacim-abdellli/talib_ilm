import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../data/catalogs/mutun_curriculum_catalog.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/services/mutun_audio_service.dart';
import 'mutn_curriculum_reader_view.dart';
import 'mutn_digital_reader.dart';

class BookMutnTab extends StatelessWidget {
  final IlmBook book;
  final Future<int> mutunInitialPage;
  final Future<void> Function(int page, int total) onPageChanged;
  final bool showControls;
  final VoidCallback onToggleControls;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onAddNote;
  final VoidCallback onShowBookmarks;

  const BookMutnTab({
    super.key,
    required this.book,
    required this.mutunInitialPage,
    required this.onPageChanged,
    required this.showControls,
    required this.onToggleControls,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onAddNote,
    required this.onShowBookmarks,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final curriculumBook = MutunCurriculumCatalog.getBook(book.id);
    final digitalEntry = MutunDigitalCatalog.getEntry(book.id);

    // 1. Digital Text Reader (Authentic Pages + Audio Sync)
    if (digitalEntry != null) {
      return FutureBuilder<int>(
        future: mutunInitialPage,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: palette.primary,
                strokeWidth: 2.5,
              ),
            );
          }
          return MutnDigitalReaderView(
            book: book,
            digitalEntry: digitalEntry,
            initialPage: snapshot.data!,
            onPageChanged: onPageChanged,
            showControls: showControls,
            onToggleControls: onToggleControls,
            isBookmarked: isBookmarked,
            onToggleBookmark: onToggleBookmark,
            onAddNote: onAddNote,
            onShowBookmarks: onShowBookmarks,
          );
        },
      );
    }

    // 2. Curriculum Text Reader Fallback (if no digital edition available)
    if (curriculumBook != null) {
      return MutnCurriculumReaderView(
        book: book,
        curriculumBook: curriculumBook,
        audioService: MutunAudioService(),
        onAddNote: onAddNote,
      );
    }

    // 3. Fallback to PDF Viewer
    if (book.pdfPath != null) {
      return FutureBuilder<int>(
        future: mutunInitialPage,
        builder: (context, snapshot) {
          return PdfViewerPage(
            assetPath: book.pdfPath!,
            title: book.title,
            initialPage: snapshot.data ?? 1,
            showAppBar: false,
            onPageChanged: (page, total) => onPageChanged(page, total),
            isBookmarked: isBookmarked,
            onBookmarkToggle: onToggleBookmark,
          );
        },
      );
    }

    // 4. Empty State
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: AppEmptyState(
          icon: Icons.menu_book_outlined,
          title: AppStrings.bookMutnEmptyTitle,
          subtitle: AppStrings.bookMutnEmptyMessage,
          action: AppButton(
            label: AppStrings.actionBack,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}
