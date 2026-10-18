import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/catalogs/mutun_audio_catalog.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import '../../data/services/shamela_service.dart';
import 'mutun_rosette_icon.dart';

/// Refined scholarly card for Mutun Talib Al-Ilm on horizontal bookshelves.
/// Features authentic printed book cover spine styling, reading progress, and clean RTL typography.
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
    final effectiveDigital = digitalEntry != null
        ? ShamelaService.getEffectiveTotalPages(
            digitalEntry.shamelaId,
            digitalEntry.totalPages,
          )
        : 0;
    final totalPages = effectiveDigital > 0
        ? effectiveDigital
        : (book.totalPages > 0 ? book.totalPages : 1);
    final isCompleted = progress?.isCompleted ?? false;
    final currentPage = progress?.currentPage ?? 0;
    final hasStarted = currentPage > 0 && !isCompleted;

    return SizedBox(
      width: 172,
      child: Semantics(
        button: true,
        label: 'متن ${book.title} ${book.level}',
        child: Material(
          color: palette.surface,
          borderRadius: AppRadius.mdRadius,
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenReader();
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
                        color: levelColors.fg,
                      ),
                    ),
                  ),

                  // ── 2. Scholarly Mutn Body ──
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpace.md, // indent past spine
                      AppSpace.sm,
                      AppSpace.sm,
                      AppSpace.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Meta Row: Level Badge with Rosette & Audio indicator
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
                                vertical: AppSpace.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: levelColors.bg,
                                borderRadius: AppRadius.pillRadius,
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
                              Container(
                                padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
                                decoration: BoxDecoration(
                                  color: palette.goldSoft,
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Icon(
                                  Icons.graphic_eq_rounded,
                                  size: AppIcon.xs,
                                  color: palette.gold,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: AppSpace.sm),

                        // Mutn Title: Right-aligned, bold, highly legible
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
                          book.author,
                          style: textTheme.caption.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: AppSpace.xs),

                        // Bottom Status Row: Completion / Progress / Page Count
                        Row(
                          children: [
                            if (isCompleted)
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.xs,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.category('aqidah').bg,
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: AppIcon.xs,
                                      color: palette.success,
                                    ),
                                    const SizedBox(width: AppSpace.xxs),
                                    Text(
                                      'مُكتمل',
                                      style: textTheme.caption.copyWith(
                                        color: palette.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (hasStarted)
                              Text(
                                'ص $currentPage من $totalPages',
                                style: textTheme.caption.copyWith(
                                  color: palette.primary,
                                  fontWeight: FontWeight.w600,
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
                              color: levelColors.fg,
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
