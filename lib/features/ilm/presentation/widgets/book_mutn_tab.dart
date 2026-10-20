import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late final MutunAudioService _audioService;
  int _selectedEdition = 0;

  @override
  void initState() {
    super.initState();
    _audioService = MutunAudioService();
    _loadSelectedEdition();
  }

  Future<void> _loadSelectedEdition() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('mutn_selected_edition_${widget.book.id}');
    if (saved != null && mounted) {
      setState(() => _selectedEdition = saved);
    }
  }

  void _onSelectEdition(int edition) {
    if (_selectedEdition == edition) return;
    setState(() => _selectedEdition = edition);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('mutn_selected_edition_${widget.book.id}', edition);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final curriculumBook = MutunCurriculumCatalog.getBook(widget.book.id);
    final digitalEntry = MutunDigitalCatalog.getEntry(widget.book.id);

    // If both curriculum syllabus and full digital book exist, offer dual-edition switcher
    final hasDualEditions = curriculumBook != null && digitalEntry != null;

    Widget readerContent;

    if (hasDualEditions) {
      if (_selectedEdition == 0) {
        readerContent = MutnCurriculumReaderView(
          book: widget.book,
          curriculumBook: curriculumBook,
          audioService: _audioService,
          onAddNote: widget.onAddNote,
          showControls: widget.showControls,
          onToggleControls: widget.onToggleControls,
          isBookmarked: widget.isBookmarked,
          onToggleBookmark: widget.onToggleBookmark,
          onShowBookmarks: widget.onShowBookmarks,
          onSwitchToFullBook: () => _onSelectEdition(1),
          fullBookLabel: 'قراءة الكتاب كاملاً (${digitalEntry.totalPages} صفحة)',
          onPageChanged: widget.onPageChanged,
        );
      } else {
        readerContent = _buildDigitalReader(palette, digitalEntry);
      }

      return Column(
        children: [
          // ── Dual Edition Mode Switcher Pill ───────────────────────
          Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              color: palette.surface,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _onSelectEdition(0),
                      borderRadius: AppRadius.pillRadius,
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: AppSpace.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedEdition == 0
                              ? palette.primarySoft
                              : palette.surfaceRaised,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: _selectedEdition == 0
                                ? palette.primary
                                : palette.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.record_voice_over_rounded,
                              size: AppIcon.sm,
                              color: _selectedEdition == 0
                                  ? palette.primary
                                  : palette.textMuted,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              'متن الحفظ (${curriculumBook.totalParagraphs} فقرة)',
                              style: textTheme.caption.copyWith(
                                color: _selectedEdition == 0
                                    ? palette.primary
                                    : palette.textMuted,
                                fontWeight: _selectedEdition == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: InkWell(
                      onTap: () => _onSelectEdition(1),
                      borderRadius: AppRadius.pillRadius,
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: AppSpace.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedEdition == 1
                              ? palette.primarySoft
                              : palette.surfaceRaised,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: _selectedEdition == 1
                                ? palette.primary
                                : palette.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: AppIcon.sm,
                              color: _selectedEdition == 1
                                  ? palette.primary
                                  : palette.textMuted,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              'الكتاب كاملاً (${digitalEntry.totalPages} صفحة)',
                              style: textTheme.caption.copyWith(
                                color: _selectedEdition == 1
                                    ? palette.primary
                                    : palette.textMuted,
                                fontWeight: _selectedEdition == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Active Reader View ────────────────────────────────────
          Expanded(child: readerContent),
        ],
      );
    }

    // 1. Authentic Curriculum Reader (for single-edition mutun)
    if (curriculumBook != null) {
      return MutnCurriculumReaderView(
        book: widget.book,
        curriculumBook: curriculumBook,
        audioService: _audioService,
        onAddNote: widget.onAddNote,
        showControls: widget.showControls,
        onToggleControls: widget.onToggleControls,
        isBookmarked: widget.isBookmarked,
        onToggleBookmark: widget.onToggleBookmark,
        onShowBookmarks: widget.onShowBookmarks,
        onPageChanged: widget.onPageChanged,
      );
    }

    // 2. Digital Text Reader (single-edition digital books)
    if (digitalEntry != null) {
      return _buildDigitalReader(palette, digitalEntry);
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

  Widget _buildDigitalReader(
    AppPalette palette,
    MutunDigitalEntry digitalEntry,
  ) {
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
        final resolvedPage = (snapshot.data != null && snapshot.data! > 1)
            ? snapshot.data!
            : digitalEntry.startPage;

        return MutnDigitalReaderView(
          book: widget.book,
          digitalEntry: digitalEntry,
          initialPage: resolvedPage,
          onPageChanged: widget.onPageChanged,
          showControls: widget.showControls,
          onToggleControls: widget.onToggleControls,
          isBookmarked: widget.isBookmarked,
          onToggleBookmark: widget.onToggleBookmark,
          onAddNote: widget.onAddNote,
          onShowBookmarks: widget.onShowBookmarks,
        );
      },
    );
  }
}
