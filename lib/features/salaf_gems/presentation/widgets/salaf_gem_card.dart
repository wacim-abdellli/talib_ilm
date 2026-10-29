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
  final double fontScale;

  const SalafGemCard({
    super.key,
    required this.gem,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onCopy,
    required this.onShare,
    this.fontScale = 1.0,
  });

  String _formatCategory(String cat) {
    if (cat.contains('الصحابة')) return 'مِنْ أَقْوَالِ الصَّحَابَةِ';
    if (cat.contains('النبوي') || cat.contains('نبوية')) return 'وَصَايَا نَبَوِيَّةٌ شَرِيفَة';
    if (cat.contains('العلم')) return 'فِي طَلَبِ العِلْمِ وَآدَابِهِ';
    if (cat.contains('زهد') || cat.contains('رقائق')) return 'رَقَائِقُ القُلُوبِ وَالزُّهْد';
    if (cat.contains('عقدية')) return 'فَوَائِدُ عَقْدِيَّةٌ سَلَفِيَّة';
    return 'مِنْ دُرَرِ السَّلَفِ الصَّالِحِ';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final categoryLabel = _formatCategory(gem.category);

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
          // Scholar Name + Dignified Category Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gold Scholar Accent Marker
              Container(
                width: AppSpace.xs,
                height: AppSpace.lg,
                decoration: BoxDecoration(
                  color: palette.gold,
                  borderRadius: AppRadius.pillRadius,
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
                  categoryLabel,
                  style: textTheme.caption.copyWith(
                    color: palette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),

          // Sacred Quote Body with Quotation Frame and Shakl-friendly Line Height
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Text(
              '«${gem.cleanText}»',
              style: textTheme.sacredSmall.copyWith(
                color: palette.text,
                height: 1.85,
              ),
              textScaler: TextScaler.linear(fontScale),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: AppSpace.sm),

          // Source Citation Box (العَزْوُ وَالتَّخْرِيجُ)
          if (gem.sourceRef.isNotEmpty) ...[
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: palette.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: palette.gold,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      'العَزْوُ وَالتَّخْرِيجُ: ${gem.sourceRef}',
                      style: textTheme.caption.copyWith(
                        color: palette.textSubtle,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xs),
          ],

          // Footer: Topic Tag and Tactical Action Buttons
          Row(
            children: [
              if (gem.topic.isNotEmpty)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    '#${gem.topic}',
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                color: palette.textMuted,
                tooltip: 'نسخ الأثر والتخريج',
                onPressed: onCopy,
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                color: palette.textMuted,
                tooltip: 'مشاركة البطاقة الدعوية',
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
