import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';
import 'shamela_book_card.dart';

/// Compact scholarly book card designed for horizontal discipline bookshelves.
/// Enables rapid browsing across Islamic disciplines without vertical scroll fatigue.
class ShamelaShelfCard extends StatelessWidget {
  final ShamelaBook book;
  final VoidCallback onOpen;
  final void Function(ShamelaBook parent, List<ShamelaBook> shuruh)? onOpenShuruh;

  const ShamelaShelfCard({
    super.key,
    required this.book,
    required this.onOpen,
    this.onOpenShuruh,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final catColors = palette.category(book.category);
    final shuruh = ShamelaService.getShuruh(book.id);

    return SizedBox(
      width: 190,
      child: AppCard(
        onTap: onOpen,
        padding: const EdgeInsetsDirectional.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Level Pill & optional Shuruh Indicator ────
            Row(
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: catColors.bg,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    ShamelaBookCard.levelLabel(book.level),
                    style: textTheme.caption.copyWith(
                      color: catColors.fg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (shuruh.isNotEmpty && onOpenShuruh != null)
                  Semantics(
                    button: true,
                    label: 'شروح كتاب ${book.title}',
                    child: Material(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.pillRadius,
                      child: InkWell(
                        borderRadius: AppRadius.pillRadius,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onOpenShuruh!(book, shuruh);
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xs,
                            vertical: AppSpace.xxs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: AppIcon.xs,
                                color: palette.gold,
                              ),
                              const SizedBox(width: AppSpace.xxs),
                              Text(
                                '${shuruh.length}',
                                style: textTheme.caption.copyWith(
                                  color: palette.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
              book.authorDeath != null
                  ? '${book.author} (${book.authorDeath})'
                  : book.author,
              style: textTheme.caption.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppSpace.xs),

            // ── Bottom Action Hint ──────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: AppIcon.xs,
                  color: palette.textMuted,
                ),
                const SizedBox(width: AppSpace.xxs),
                Text(
                  'قراءة',
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
