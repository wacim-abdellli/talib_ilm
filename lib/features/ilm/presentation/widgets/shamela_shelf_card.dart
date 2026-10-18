import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';
import 'shamela_book_card.dart';

/// Refined scholarly book card for horizontal discipline bookshelves.
/// Features an authentic classical leather spine accent, clear RTL typography,
/// and distinct level/commentary indicators without visual crowding.
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
      width: 172,
      child: Semantics(
        button: true,
        label: 'كتاب ${book.title} للشيخ ${book.author}',
        child: Material(
          color: palette.surface,
          borderRadius: AppRadius.mdRadius,
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: () {
              HapticFeedback.selectionClick();
              onOpen();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: palette.border, width: 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // ── 1. Classical Book Spine Accent (Start / RTL Right Edge) ──
                  PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    start: 0,
                    width: AppSpace.xxs,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: catColors.fg,
                      ),
                    ),
                  ),

                  // ── 2. Scholarly Book Body ──
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpace.md, // generous indent past book spine
                      AppSpace.sm,
                      AppSpace.sm,
                      AppSpace.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Meta Row: Level Pill & Commentary Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
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

                        // Book Title: Highly legible, right-aligned, 2 lines max
                        Expanded(
                          child: Text(
                            book.title,
                            style: textTheme.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.35,
                              color: palette.text,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: AppSpace.xxs),

                        // Author Attribution
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

                        // Bottom Action Row: Page Count & Reading Trigger
                        Row(
                          children: [
                            Icon(
                              Icons.auto_stories_outlined,
                              size: AppIcon.xs,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: AppSpace.xxs),
                            Text(
                              book.totalPages > 0
                                  ? '${book.totalPages} ص'
                                  : 'قراءة',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: AppIcon.xs,
                              color: catColors.fg,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
