import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/primary_app_bar.dart';

class BookViewAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onResetProgress;
  final TabController tabController;

  const BookViewAppBar({
    super.key,
    required this.title,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onResetProgress,
    required this.tabController,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48.0);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return UnifiedAppBar(
      title: title,
      showBack: true,
      actions: [
        ListenableBuilder(
          listenable: themeService,
          builder: (context, _) {
            return IconButton(
              tooltip: themeService.themeDisplayName,
              onPressed: () {
                HapticFeedback.selectionClick();
                themeService.toggleTheme();
              },
              icon: Icon(
                themeService.themeIcon,
                color: palette.text,
              ),
            );
          },
        ),
        IconButton(
          tooltip: isFavorite
              ? AppStrings.bookFavoriteRemove
              : AppStrings.bookFavoriteAdd,
          onPressed: onToggleFavorite,
          icon: Icon(
            isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: isFavorite ? palette.gold : palette.text,
          ),
        ),
        IconButton(
          tooltip: AppStrings.bookResetProgress,
          onPressed: onResetProgress,
          icon: Icon(Icons.refresh_rounded, color: palette.text),
        ),
      ],
      bottom: TabBar(
        controller: tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: palette.primarySoft,
          borderRadius: AppRadius.smRadius,
        ),
        labelColor: palette.onPrimarySoft,
        unselectedLabelColor: palette.textMuted,
        labelStyle: textTheme.label,
        unselectedLabelStyle: textTheme.label,
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xs,
        ),
        tabs: const [
          Tab(text: AppStrings.bookMutnTab),
          Tab(text: AppStrings.bookSharhTab),
          Tab(text: AppStrings.bookLessonsTab),
        ],
      ),
    );
  }
}
