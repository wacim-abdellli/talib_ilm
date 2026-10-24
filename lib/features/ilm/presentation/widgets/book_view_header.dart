import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import 'book_view_app_bar.dart';

class BookViewHeader extends StatelessWidget {
  final bool showControls;
  final String bookTitle;
  final int currentPage;
  final int totalPages;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onResetProgress;
  final VoidCallback onShowBookmarksAndNotes;
  final TabController tabController;

  const BookViewHeader({
    super.key,
    required this.showControls,
    required this.bookTitle,
    required this.currentPage,
    required this.totalPages,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onResetProgress,
    required this.onShowBookmarksAndNotes,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final topBarHeight = topPadding + kToolbarHeight + 48.0;
    final minimalBarHeight = topPadding + 42.0;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      height: showControls ? topBarHeight : minimalBarHeight,
      decoration: BoxDecoration(
        color: showControls ? context.palette.surfaceRaised : context.palette.bg,
        border: Border(
          bottom: BorderSide(
            color: showControls
                ? context.palette.border
                : context.palette.border.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            // Minimal header when controls hidden
            Positioned(
              top: topPadding,
              left: AppSpace.md,
              right: AppSpace.md,
              height: 42.0,
              child: AnimatedOpacity(
                duration: AppMotion.fast,
                curve: AppMotion.easeOut,
                opacity: showControls ? 0.0 : 1.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        bookTitle,
                        style: context.text.titleSmall.copyWith(
                          color: context.palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: context.palette.goldSoft,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: context.palette.gold.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'صفحة $currentPage من $totalPages',
                        style: context.text.caption.copyWith(
                          color: context.palette.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Full App Bar when controls visible
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topBarHeight,
              child: IgnorePointer(
                ignoring: !showControls,
                child: AnimatedOpacity(
                  duration: AppMotion.fast,
                  curve: AppMotion.easeOut,
                  opacity: showControls ? 1.0 : 0.0,
                  child: BookViewAppBar(
                    title: bookTitle,
                    isFavorite: isFavorite,
                    onToggleFavorite: onToggleFavorite,
                    onResetProgress: onResetProgress,
                    onShowBookmarksAndNotes: onShowBookmarksAndNotes,
                    tabController: tabController,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
