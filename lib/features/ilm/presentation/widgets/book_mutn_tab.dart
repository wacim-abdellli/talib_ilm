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

enum MutnReaderMode {
  curriculum,
  shamela,
  pdf,
}

class BookMutnTab extends StatefulWidget {
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
  State<BookMutnTab> createState() => _BookMutnTabState();
}

class _BookMutnTabState extends State<BookMutnTab> {
  late MutnReaderMode _mode;

  @override
  void initState() {
    super.initState();
    if (MutunCurriculumCatalog.hasBook(widget.book.id)) {
      _mode = MutnReaderMode.curriculum;
    } else if (MutunDigitalCatalog.hasDigitalText(widget.book.id)) {
      _mode = MutnReaderMode.shamela;
    } else {
      _mode = MutnReaderMode.pdf;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final curriculumBook = MutunCurriculumCatalog.getBook(widget.book.id);
    final digitalEntry = MutunDigitalCatalog.getEntry(widget.book.id);

    // 1. Authentic Curriculum Continuous Reader (Word-for-Word Audio Synced)
    if (_mode == MutnReaderMode.curriculum && curriculumBook != null) {
      return MutnCurriculumReaderView(
        book: widget.book,
        curriculumBook: curriculumBook,
        audioService: MutunAudioService(),
        onAddNote: widget.onAddNote,
        onSwitchToShamela: digitalEntry != null
            ? () => setState(() => _mode = MutnReaderMode.shamela)
            : null,
        onSwitchToPdf: widget.book.pdfPath != null
            ? () => setState(() => _mode = MutnReaderMode.pdf)
            : null,
      );
    }

    // 2. Maktaba Shamela Digital Reader
    if (_mode == MutnReaderMode.shamela && digitalEntry != null) {
      return FutureBuilder<int>(
        future: widget.mutunInitialPage,
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
            book: widget.book,
            digitalEntry: digitalEntry,
            initialPage: snapshot.data!,
            onPageChanged: widget.onPageChanged,
            showControls: widget.showControls,
            onToggleControls: widget.onToggleControls,
            isBookmarked: widget.isBookmarked,
            onToggleBookmark: widget.onToggleBookmark,
            onAddNote: widget.onAddNote,
            onShowBookmarks: widget.onShowBookmarks,
            onSwitchToCurriculum: curriculumBook != null
                ? () => setState(() => _mode = MutnReaderMode.curriculum)
                : null,
          );
        },
      );
    }

    // 3. Fallback to PDF Viewer
    if (widget.book.pdfPath != null) {
      return FutureBuilder<int>(
        future: widget.mutunInitialPage,
        builder: (context, snapshot) {
          return PdfViewerPage(
            assetPath: widget.book.pdfPath!,
            title: widget.book.title,
            initialPage: snapshot.data ?? 1,
            showAppBar: false,
            onPageChanged: (page, total) => widget.onPageChanged(page, total),
            isBookmarked: widget.isBookmarked,
            onBookmarkToggle: widget.onToggleBookmark,
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
