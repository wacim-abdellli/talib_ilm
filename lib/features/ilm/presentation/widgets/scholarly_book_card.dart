import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../../../shared/widgets/app_tag.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';

/// A luxury Islamic manuscript card for the scholarly library.
///
/// Designed to evoke the prestige of classical leather-bound mutun with:
/// - Category-tinted accent ribbon and Islamic typography.
/// - Author attribution with feather/scholar icon.
/// - Reading progress bar and completion jewel seal.
/// - Minimum 48dp tap targets with ripple feedback and semantics.
class ScholarlyBookCard extends StatelessWidget {
  final IlmBook book;
  final BookProgress? progress;
  final bool isRecommended;
  final String? matchSnippet;
  final ValueChanged<IlmBook> onNavigateToBook;
  final ValueChanged<String> onToggleFavorite;

  const ScholarlyBookCard({
    super.key,
    required this.book,
    required this.progress,
    this.isRecommended = false,
    this.matchSnippet,
    required this.onNavigateToBook,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final categoryColors = palette.category(book.subject);

    final totalPages = book.totalPages > 0
        ? book.totalPages
        : (progress?.totalPages ?? 0);
    final currentPage = progress?.currentPage ?? 0;
    final progressValue = totalPages > 0
        ? (currentPage / totalPages).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = progress?.isCompleted ?? false;
    final isStarted = progress != null && currentPage > 1;
    final isFavorite = progress?.isFavorite ?? false;

    return AppCard(
      onTap: () => onNavigateToBook(book),
      padding: const EdgeInsets.all(AppSpace.md),
      border: Border.all(
        color: isCompleted
            ? palette.primary.withAlpha(90)
            : isRecommended
                ? palette.gold.withAlpha(120)
                : palette.border,
        width: isRecommended || isCompleted ? 1.5 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Category Tag & Favorite Action ──────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: AppTag(
                  label: book.subject.trim(),
                  subject: book.subject.trim(),
                ),
              ),
              Semantics(
                label: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                button: true,
                child: SizedBox(
                  width: AppSize.tap,
                  height: AppSize.tap,
                  child: IconButton(
                    tooltip:
                        isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? palette.error : palette.textMuted,
                      size: AppIcon.md,
                    ),
                    onPressed: () => onToggleFavorite(book.id),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.sm),

          // ── Title ───────────────────────────────────────────────
          Text(
            book.title,
            style: context.text.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpace.xs),

          // ── Author Attribution ──────────────────────────────────
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
                  style: context.text.caption.copyWith(
                    color: palette.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // ── Resources indicator if shuruh exist ─────────────────
          if (book.shuruh.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: AppIcon.sm,
                  color: palette.textSubtle,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  '${book.shuruh.length} شروح ميسرة',
                  style: context.text.caption.copyWith(
                    color: palette.textSubtle,
                  ),
                ),
              ],
            ),
          ],

          // ── Contextual Search Match Snippet ─────────────────────
          if (matchSnippet != null && matchSnippet!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: palette.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: AppIcon.sm,
                    color: palette.primary,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      matchSnippet!,
                      style: context.text.caption.copyWith(
                        color: palette.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // ── Footer Status & Progress ────────────────────────────
          if (isCompleted) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: AppRadius.smRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: AppIcon.sm,
                    color: palette.success,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'مُتَمَّم بفضل الله',
                    style: context.text.caption.copyWith(
                      color: palette.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isStarted) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppProgress(progress: progressValue),
                const SizedBox(height: AppSpace.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progressValue * 100).round()}%',
                      style: context.text.caption.copyWith(
                        color: categoryColors.fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (totalPages > 0)
                      Text(
                        'صـ $currentPage من $totalPages',
                        style: context.text.caption.copyWith(
                          color: palette.textSubtle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  isRecommended
                      ? Icons.auto_awesome_rounded
                      : Icons.arrow_forward_rounded,
                  size: AppIcon.sm,
                  color: isRecommended ? palette.gold : palette.textSubtle,
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    isRecommended ? 'ابدأ كأول خطوة ✨' : 'ابدأ المدارسة',
                    style: context.text.caption.copyWith(
                      color: isRecommended ? palette.gold : palette.textSubtle,
                      fontWeight:
                          isRecommended ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
