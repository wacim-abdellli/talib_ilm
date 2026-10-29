import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/models/salaf_gem.dart';

class SalafGemCard extends StatelessWidget {
  final SalafGem gem;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const SalafGemCard({
    super.key,
    required this.gem,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onCopy,
    required this.onShare,
  });

  String _getScholarInitial(String author) {
    final clean = author
        .replaceAll('قال', '')
        .replaceAll('بن', ' ')
        .replaceAll('أبي', ' ')
        .replaceAll('ابن', ' ')
        .replaceAll('رحمه الله', '')
        .replaceAll('رضي الله عنه', '')
        .trim();
    if (clean.isEmpty) return 'س';
    return clean.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final initial = _getScholarInitial(gem.author);

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: palette.border,
        ),
      ),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scholar Monogram + Name + Category Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Monogram
              Container(
                width: AppSpace.xl,
                height: AppSpace.xl,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.primary,
                  ),
                ),
                child: Text(
                  initial,
                  style: textTheme.caption.copyWith(
                    color: palette.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gem.author,
                      style: textTheme.titleSmall.copyWith(
                        color: palette.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (gem.role.isNotEmpty)
                      Text(
                        gem.role,
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: palette.border,
                  ),
                ),
                child: Text(
                  gem.category,
                  style: textTheme.caption.copyWith(
                    color: palette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),

          // Sacred Quote Body with Quotation Accent
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Text(
              gem.text,
              style: textTheme.sacred.copyWith(
                color: palette.text,
                height: 1.85,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: AppSpace.sm),

          // Source Citation Box
          if (gem.sourceRef.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: palette.textSubtle,
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    gem.sourceRef,
                    style: textTheme.caption.copyWith(
                      color: palette.textSubtle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
          ],

          // Footer: Topic tag and Action Buttons
          Row(
            children: [
              if (gem.topic.isNotEmpty)
                Text(
                  '#${gem.topic}',
                  style: textTheme.caption.copyWith(
                    color: palette.gold,
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                color: palette.textMuted,
                tooltip: 'نسخ النص',
                onPressed: onCopy,
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                color: palette.textMuted,
                tooltip: 'مشاركة كبطاقة',
                onPressed: onShare,
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isFavorite ? palette.gold : palette.textMuted,
                ),
                tooltip: isFavorite ? 'إزالة من المفضلة' : 'حفظ في المفضلة',
                onPressed: onToggleFavorite,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
