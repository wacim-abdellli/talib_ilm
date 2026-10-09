import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';

class BookMutnTab extends StatelessWidget {
  final String mutunPdfPath;
  final Future<int> mutunInitialPage;
  final GlobalKey<PdfViewerPageState> mutnPdfKey;
  final Future<void> Function(int page, int total) onPageChanged;

  const BookMutnTab({
    super.key,
    required this.mutunPdfPath,
    required this.mutunInitialPage,
    required this.mutnPdfKey,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (mutunPdfPath.isEmpty) {
      return Padding(
        padding: AppUi.cardPadding,
        child: EmptyState(
          icon: Icons.menu_book_outlined,
          title: AppStrings.bookMutnEmptyTitle,
          subtitle: AppStrings.bookMutnEmptyMessage,
          actionLabel: AppStrings.actionBack,
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    return FutureBuilder<int>(
      future: mutunInitialPage,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return PdfViewerPage(
          key: mutnPdfKey,
          title: AppStrings.bookMutnTitle,
          assetPath: mutunPdfPath,
          showAppBar: false,
          initialPage: snapshot.data!,
          onPageChanged: onPageChanged,
        );
      },
    );
  }
}
