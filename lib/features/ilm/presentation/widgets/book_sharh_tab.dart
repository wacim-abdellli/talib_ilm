import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../core/services/last_activity_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_states.dart';
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: AppEmptyState(
            icon: Icons.menu_book_outlined,
            title: AppStrings.bookSharhEmptyTitle,
            subtitle: AppStrings.bookSharhEmptyMessage,
            action: AppButton(
              label: AppStrings.bookSharhEmptyAction,
              onPressed: onGoToMutn,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (lastSharh != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.lg,
              AppSpace.xl,
              0,
            ),
            child: ContinueSharhCard(
              sharh: lastSharh!,
              pageInfo: lastSharhPage,
              onTap: () => onOpenSharh(lastSharh!),
            ),
          ),
        if (lastSharh != null) const SizedBox(height: AppSpace.md),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpace.xl),
            itemCount: shuruh.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpace.md),
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
