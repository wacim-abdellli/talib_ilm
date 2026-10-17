import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/catalogs/mutun_categories_catalog.dart';
import 'matn_overview_page.dart';

/// Sub-category matn list page mirroring media_1792193058783.jpg.
class MutunCategoryItemsPage extends StatelessWidget {
  final MutunCategory category;

  const MutunCategoryItemsPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: tokens.headerBrown,
        foregroundColor: tokens.headerTitle,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'قائمة المتون',
          style: textTheme.titleSmall.copyWith(
            color: tokens.headerTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Breadcrumb Sub-bar ──────────────────────────────────
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              color: palette.surfaceMuted,
              child: Text(
                'جميع المتون / ${category.title}',
                style: textTheme.caption.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // ── Matn Cards List ─────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.md,
                ),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: category.items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpace.sm),
                itemBuilder: (context, index) {
                  final item = category.items[index];
                  return _buildMatnCard(
                    context: context,
                    item: item,
                    palette: palette,
                    textTheme: textTheme,
                    tokens: tokens,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatnCard({
    required BuildContext context,
    required MutunItem item,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required MutunThemeTokens tokens,
  }) {
    return Semantics(
      button: true,
      label: '${item.title}، ${item.countLabel}',
      child: Material(
        color: tokens.cardBg,
        borderRadius: AppRadius.mdRadius,
        child: InkWell(
          borderRadius: AppRadius.mdRadius,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              buildFadeRoute(page: MatnOverviewPage(item: item)),
            );
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSize.tap * 1.2),
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
                // ── Matn Title and Lines Count ──────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: textTheme.body.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        item.countLabel,
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpace.sm),

                // ── Left Chevron ────────────────────────────────────
                Icon(
                  Icons.chevron_left_rounded,
                  color: palette.textMuted.withValues(alpha: 0.6),
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
