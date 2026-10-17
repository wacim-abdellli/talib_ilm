import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/catalogs/mutun_audio_catalog.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import '../../data/services/mutun_audio_service.dart';
import 'mutun_rosette_icon.dart';

/// Refined scholarly card for syllabus mutun with reading & recitation audio actions.
class IlmMutnCard extends StatelessWidget {
  final IlmBook book;
  final BookProgress? progress;
  final VoidCallback onOpenReader;
  final VoidCallback onToggleFavorite;
  final bool? isFavoriteOverride;

  const IlmMutnCard({
    super.key,
    required this.book,
    required this.progress,
    required this.onOpenReader,
    required this.onToggleFavorite,
    this.isFavoriteOverride,
  });

  void _startAudioStream(BuildContext context) {
    HapticFeedback.mediumImpact();
    final audioService = MutunAudioService();
    final audioUrl = MutunAudioCatalog.getAudioUrl(book.id, reciterId: audioService.selectedReciter.id) ?? '';
    final totalParas = MutunAudioCatalog.getTotalParagraphs(book.id);

    audioService.playMatnAudio(
      bookId: book.id,
      audioUrl: audioUrl,
      paragraphIndex: 1,
      totalParagraphs: totalParas,
    );
    onOpenReader();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final digitalEntry = MutunDigitalCatalog.getEntry(book.id);
    final totalPages = digitalEntry != null && digitalEntry.totalPages > 0
        ? digitalEntry.totalPages
        : (book.totalPages > 0 ? book.totalPages : 1);
    final currentPage = progress?.currentPage ?? 0;
    final isCompleted = progress?.isCompleted ?? false;
    final isStarted = !isCompleted && currentPage > 1;
    final progressPercent = (progress?.progressPercentage ?? 0).round();
    final hasAudio = MutunAudioCatalog.hasAudio(book.id);
    final isFavorite = isFavoriteOverride ?? (progress?.isFavorite ?? false);
    final levelColors = palette.mutunLevel(book.level);

    return AppCard(
      onTap: onOpenReader,
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Row: Level & Subject Badges + Favorite Action ─────
          Row(
            children: [
              // Rosette + Level Badge (colored with authentic real book cover colors)
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
                    const SizedBox(width: AppSpace.xs),
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

              const SizedBox(width: AppSpace.xs),

              // Subject Tag
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: palette.border, width: 0.8),
                ),
                child: Text(
                  book.subject,
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ),

              const Spacer(),

              // Favorite Action
              Semantics(
                button: true,
                label: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                child: SizedBox(
                  width: AppSize.tap,
                  height: AppSize.tap,
                  child: IconButton(
                    tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorite ? palette.error : palette.textMuted,
                      size: AppIcon.md,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onToggleFavorite();
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.sm),

          // ── Title & Author ─────────────────────────────────────────
          Text(
            book.title,
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpace.xs),

          Row(
            children: [
              Icon(
                Icons.history_edu_rounded,
                size: AppIcon.sm,
                color: palette.textMuted,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  book.author,
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // ── Description ───────────────────────────────────────────
          if (book.description.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              book.description,
              style: textTheme.bodySmall.copyWith(
                color: palette.textMuted,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Audio recitation indicator ────────────────────────────
          if (hasAudio) ...[
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: AppIcon.sm,
                  color: palette.gold,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  'قراءة صوتية: د. عبد العزيز الصيني',
                  style: textTheme.caption.copyWith(
                    color: palette.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpace.md),

          // ── Divider ───────────────────────────────────────────────
          Divider(color: palette.border, height: 1),

          const SizedBox(height: AppSpace.sm),

          // ── Bottom Action Row: Read, Listen, and Progress ──────────
          Row(
            children: [
              // "قراءة المتن" Primary Action
              AppButton(
                label: 'قراءة المتن',
                icon: Icons.menu_book_rounded,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.sm,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onOpenReader();
                },
              ),

              if (hasAudio) ...[
                const SizedBox(width: AppSpace.xs),
                // "استماع" Action
                AppButton(
                  label: 'استماع',
                  icon: Icons.play_arrow_rounded,
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.sm,
                  onPressed: () => _startAudioStream(context),
                ),
              ],

              const Spacer(),

              // Pages or Reading Progress
              if (isCompleted)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
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
              else if (isStarted)
                Text(
                  '$progressPercent% مكتمل',
                  style: textTheme.caption.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  '$totalPages صفحة',
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
