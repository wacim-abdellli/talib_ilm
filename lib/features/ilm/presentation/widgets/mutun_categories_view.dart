import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/catalogs/mutun_categories_catalog.dart';
import '../pages/mutun_category_items_page.dart';
import 'mutun_rosette_icon.dart';

/// Clean scholarly Mutun categories list view mirroring media_1792193056991.jpg.
class MutunCategoriesView extends StatelessWidget {
  final VoidCallback? onSearchTap;

  const MutunCategoriesView({
    super.key,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sub-bar: جميع المتون ──────────────────────────────────
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.sm,
            ),
            child: Text(
              'جميع المتون',
              style: textTheme.caption.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ── Categories List ───────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs,
              ),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: MutunCategoriesCatalog.categories.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpace.sm),
              itemBuilder: (context, index) {
                final category = MutunCategoriesCatalog.categories[index];
                return _buildCategoryCard(
                  context: context,
                  category: category,
                  palette: palette,
                  textTheme: textTheme,
                  tokens: tokens,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required MutunCategory category,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required MutunThemeTokens tokens,
  }) {
    return Semantics(
      button: true,
      label: category.title,
      child: Material(
        color: tokens.cardBg,
        borderRadius: AppRadius.mdRadius,
        child: InkWell(
          borderRadius: AppRadius.mdRadius,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              buildFadeRoute(
                page: MutunCategoryItemsPage(category: category),
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSize.tap * 1.15),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: tokens.cardBorder, width: 1.0),
              boxShadow: palette.shadow,
            ),
            child: Row(
              children: [
                // ── 8-point Rosette Icon ────────────────────────────
                MutunRosetteIcon(
                  color: tokens.rosetteGold,
                  size: AppIcon.lg,
                ),

                const SizedBox(width: AppSpace.md),

                // ── Category Title ──────────────────────────────────
                Expanded(
                  child: Text(
                    category.title,
                    style: textTheme.body.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: AppSpace.sm),

                // ── Left Chevron ────────────────────────────────────
                Icon(
                  Icons.chevron_left_rounded,
                  color: palette.textMuted.withValues(alpha: 0.5),
                  size: AppIcon.lg,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
