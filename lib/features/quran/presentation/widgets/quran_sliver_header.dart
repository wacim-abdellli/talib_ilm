import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

/// Pinned Sliver Persistent Header for the Quran Index
/// Hosting the 4 category tabs and the search text field.
class QuranPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int selectedTabIndex;
  final int bookmarksCount;
  final ValueChanged<int> onTabSelected;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final bool isSearching;
  final int searchFilterIndex;
  final ValueChanged<int>? onSearchFilterSelected;
  final int surahsCount;
  final int ayahsCount;

  const QuranPinnedHeaderDelegate({
    required this.selectedTabIndex,
    required this.bookmarksCount,
    required this.onTabSelected,
    required this.searchController,
    required this.onSearchChanged,
    this.isSearching = false,
    this.searchFilterIndex = 0,
    this.onSearchFilterSelected,
    this.surahsCount = 0,
    this.ayahsCount = 0,
  });

  @override
  double get minExtent => 108.0;

  @override
  double get maxExtent => 108.0;

  @override
  bool shouldRebuild(covariant QuranPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.selectedTabIndex != selectedTabIndex ||
        oldDelegate.bookmarksCount != bookmarksCount ||
        oldDelegate.searchController.text != searchController.text ||
        oldDelegate.isSearching != isSearching ||
        oldDelegate.searchFilterIndex != searchFilterIndex ||
        oldDelegate.surahsCount != surahsCount ||
        oldDelegate.ayahsCount != ayahsCount;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final palette = context.palette;
    final textTheme = context.text;

    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          top: AppSpace.xs,
          bottom: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          color: palette.bg,
          border: Border(
            bottom: BorderSide(
              color: overlapsContent
                  ? palette.border
                  : palette.border.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Index Category Tabs (السور، الأجزاء، الأحزاب، المحفوظات) OR Search Filter Tabs
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
            ),
            child: Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.xs),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: isSearching
                    ? [
                        Expanded(
                          child: _buildTabButton(
                            context: context,
                            title: 'الكل (${surahsCount + ayahsCount})',
                            isSelected: searchFilterIndex == 0,
                            onTap: () => onSearchFilterSelected?.call(0),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            context: context,
                            title: 'السور ($surahsCount)',
                            isSelected: searchFilterIndex == 1,
                            onTap: () => onSearchFilterSelected?.call(1),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            context: context,
                            title: 'الآيات ($ayahsCount)',
                            isSelected: searchFilterIndex == 2,
                            onTap: () => onSearchFilterSelected?.call(2),
                          ),
                        ),
                      ]
                    : [
                        Expanded(
                          child: _buildTabButton(
                            context: context,
                            title: 'السور (114)',
                            isSelected: selectedTabIndex == 0,
                            onTap: () => onTabSelected(0),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            context: context,
                            title: 'الأجزاء (30)',
                            isSelected: selectedTabIndex == 1,
                            onTap: () => onTabSelected(1),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            context: context,
                            title: 'الأحزاب (60)',
                            isSelected: selectedTabIndex == 2,
                            onTap: () => onTabSelected(2),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            context: context,
                            title: 'المحفوظات ($bookmarksCount)',
                            isSelected: selectedTabIndex == 3,
                            onTap: () => onTabSelected(3),
                          ),
                        ),
                      ],
              ),
            ),
          ),

          const SizedBox(height: AppSpace.xs),

          // 2. Search Field
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
            ),
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: searchController,
                textDirection: TextDirection.rtl,
                textInputAction: TextInputAction.search,
                style: textTheme.body.copyWith(color: palette.text),
                cursorColor: palette.primary,
                decoration: InputDecoration(
                  hintText: isSearching || selectedTabIndex != 3
                      ? 'ابحث عن سورة، آية، أو كلمة...'
                      : 'ابحث في المحفوظات والتدبر...',
                  hintStyle: textTheme.bodySmall.copyWith(
                    color: palette.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: palette.gold,
                    size: AppIcon.md,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: palette.textMuted,
                            size: AppIcon.sm,
                          ),
                          tooltip: 'مسح البحث',
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: palette.surfaceMuted,
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: BorderSide(color: palette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: BorderSide(color: palette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: BorderSide(
                      color: palette.gold,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTabButton({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: AnimatedContainer(
          duration: AppMotion.base,
          padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.sm),
          decoration: BoxDecoration(
            color: isSelected ? palette.surfaceRaised : Colors.transparent,
            borderRadius: AppRadius.pillRadius,
            border: isSelected
                ? Border.all(
                    color: palette.gold.withValues(alpha: 0.35),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected ? palette.shadow : null,
          ),
          child: Center(
            child: Text(
              title,
              style: context.text.label.copyWith(
                color: isSelected ? palette.gold : palette.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
