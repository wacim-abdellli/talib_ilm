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
  final VoidCallback? onShowBookmarksAndNotes;
  final TabController tabController;

  const BookViewAppBar({
    super.key,
    required this.title,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onResetProgress,
    this.onShowBookmarksAndNotes,
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
        if (onShowBookmarksAndNotes != null)
          IconButton(
            tooltip: 'المحفوظات والملاحظات',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onShowBookmarksAndNotes,
            icon: Icon(
              Icons.collections_bookmark_rounded,
              color: palette.gold,
            ),
          ),
        IconButton(
          tooltip: isFavorite
              ? 'إزالة من المفضلة (قائمة المحفوظات)'
              : 'إضافة إلى المفضلة (قائمة المحفوظات)',
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onToggleFavorite,
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? palette.error : palette.text,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'خيارات إضافية',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Icon(Icons.more_vert_rounded, color: palette.text),
          color: palette.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smRadius,
            side: BorderSide(color: palette.border),
          ),
          onSelected: (value) {
            if (value == 'theme') {
              HapticFeedback.selectionClick();
              themeService.toggleTheme();
            } else if (value == 'reset') {
              onResetProgress();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'theme',
              child: ListenableBuilder(
                listenable: themeService,
                builder: (context, _) {
                  return Row(
                    children: [
                      Icon(
                        themeService.themeIcon,
                        color: palette.text,
                        size: AppIcon.sm,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        themeService.themeDisplayName,
                        style: textTheme.bodySmall.copyWith(
                          color: palette.text,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            PopupMenuItem(
              value: 'reset',
              child: Row(
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: palette.text,
                    size: AppIcon.sm,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    AppStrings.bookResetProgress,
                    style: textTheme.bodySmall.copyWith(
                      color: palette.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: tabController,
        dividerColor: Colors.transparent,
        dividerHeight: 0.0,
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
