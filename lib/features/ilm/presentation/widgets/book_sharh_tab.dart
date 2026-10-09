import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/last_activity_service.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/sharh_model.dart';
import 'continue_sharh_card.dart';
import 'sharh_card.dart';

class BookSharhTab extends StatelessWidget {
  final List<Sharh> shuruh;
  final Sharh? lastSharh;
  final PdfPageInfo? lastSharhPage;
  final String? lastSharhFile;
  final VoidCallback onGoToMutn;
  final ValueChanged<Sharh> onOpenSharh;

  const BookSharhTab({
    super.key,
    required this.shuruh,
    required this.lastSharh,
    required this.lastSharhPage,
    required this.lastSharhFile,
    required this.onGoToMutn,
    required this.onOpenSharh,
  });

  String _difficultyLabel(int index) {
    if (index == 0) return AppStrings.difficultyBeginner;
    if (index == 1) return AppStrings.difficultyIntermediate;
    return AppStrings.difficultyAdvanced;
  }

  @override
  Widget build(BuildContext context) {
    if (shuruh.isEmpty) {
      return Padding(
        padding: AppUi.cardPadding,
        child: EmptyState(
          icon: Icons.menu_book_outlined,
          title: AppStrings.bookSharhEmptyTitle,
          subtitle: AppStrings.bookSharhEmptyMessage,
          actionLabel: AppStrings.bookSharhEmptyAction,
          onAction: onGoToMutn,
        ),
      );
    }

    return Column(
      children: [
        if (lastSharh != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppUi.paddingMD,
              AppUi.paddingMD,
              AppUi.paddingMD,
              0,
            ),
            child: ContinueSharhCard(
              sharh: lastSharh!,
              pageInfo: lastSharhPage,
              onTap: () => onOpenSharh(lastSharh!),
            ),
          ),
        if (lastSharh != null) const SizedBox(height: AppUi.gapMD),
        Expanded(
          child: ListView.separated(
            padding: AppUi.cardPadding,
            itemCount: shuruh.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppUi.gapMD),
            itemBuilder: (context, index) {
              final sharh = shuruh[index];

              return SharhCard(
                title: sharh.title,
                scholar: sharh.scholar,
                difficulty: _difficultyLabel(index),
                recommended: index == 0,
                isLastRead: sharh.file == lastSharhFile,
                onTap: () => onOpenSharh(sharh),
              );
            },
          ),
        ),
      ],
    );
  }
}
