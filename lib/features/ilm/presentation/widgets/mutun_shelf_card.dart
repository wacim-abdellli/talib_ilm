import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/catalogs/mutun_audio_catalog.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import 'mutun_rosette_icon.dart';

/// Compact card for Mutun Talib Al-Ilm on horizontal bookshelves.
/// Features authentic printed book cover colors and progress status.
class MutunShelfCard extends StatelessWidget {
  final IlmBook book;
  final BookProgress? progress;
  final VoidCallback onOpenReader;

  const MutunShelfCard({
    super.key,
    required this.book,
    required this.progress,
    required this.onOpenReader,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final levelColors = palette.mutunLevel(book.level);
    final hasAudio = MutunAudioCatalog.hasAudio(book.id);
    final digitalEntry = MutunDigitalCatalog.getEntry(book.id);
    final totalPages = digitalEntry != null && digitalEntry.totalPages > 0
        ? digitalEntry.totalPages
        : (book.totalPages > 0 ? book.totalPages : 1);
    final isCompleted = progress?.isCompleted ?? false;

    return SizedBox(
      width: 200,
      child: AppCard(
        onTap: onOpenReader,
        padding: const EdgeInsetsDirectional.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Level Badge with Authentic Book Color ────
            Row(
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: levelColors.bg,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(color: levelColors.border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MutunRosetteIcon(
                        size: AppIcon.xs,
                        color: levelColors.fg,
                      ),
                      const SizedBox(width: AppSpace.xxs),
                      Text(
                        book.level,
                        style: textTheme.caption.copyWith(
                          color: levelColors.fg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (hasAudio)
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: AppIcon.xs,
                    color: palette.gold,
                  ),
              ],
            ),

            const SizedBox(height: AppSpace.sm),

            // ── Book Title ──────────────────────────────────────────
            Expanded(
              child: Text(
                book.title,
                style: textTheme.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: palette.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: AppSpace.xs),

            // ── Author ──────────────────────────────────────────────
            Text(
              book.author,
              style: textTheme.caption.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppSpace.xs),

            // ── Bottom Info Row ─────────────────────────────────────
            Row(
              children: [
                if (isCompleted)
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.xs,
                      vertical: AppSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.success.withValues(alpha: 0.12),
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      'مُكتمل',
                      style: textTheme.caption.copyWith(
                        color: palette.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    '$totalPages صفحة',
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                const Spacer(),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: AppIcon.xs,
                  color: palette.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
