import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/mutun_models.dart';
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
    final digitalEntry = MutunDigitalCatalog.getEntry(book.id);

    if (digitalEntry == null) {
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
}
