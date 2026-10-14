import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../../../shared/widgets/app_tag.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
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
  final ValueChanged<IlmBook> onNavigateToBook;
  final ValueChanged<String> onToggleFavorite;

  const ScholarlyBookCard({
    super.key,
    required this.book,
    required this.progress,
    this.isRecommended = false,
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
    final isCompleted = (progress?.isCompleted ?? false) ||
        (progress?.completedDate != null) ||
        (totalPages > 0 && currentPage >= totalPages);
    final isStarted = !isCompleted &&
        progress != null &&
        (currentPage > 1 || (progress?.totalReadingTimeMinutes ?? 0) > 0);
    final isFavorite = progress?.isFavorite ?? false;

    return AppCard(
      onTap: () => onNavigateToBook(book),
      padding: const EdgeInsets.all(AppSpace.md),
      border: Border.all(
        color: isCompleted
            ? palette.success.withAlpha(90)
            : isStarted
                ? palette.primary.withAlpha(90)
                : palette.border,
        width: isCompleted || isStarted ? 1.5 : 1,
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

          // ── Resources indicator if digital text or shuruh exist ─
          if (MutunDigitalCatalog.hasDigitalText(book.id) ||
              book.shuruh.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Icon(
                  MutunDigitalCatalog.hasDigitalText(book.id)
                      ? Icons.auto_stories_rounded
                      : Icons.menu_book_outlined,
                  size: AppIcon.sm,
                  color: MutunDigitalCatalog.hasDigitalText(book.id)
                      ? palette.gold
                      : palette.textSubtle,
                ),
                const SizedBox(width: AppSpace.xxs),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (MutunDigitalCatalog.hasDigitalText(book.id))
                          TextSpan(
                            text: 'نص محقق',
                            style: context.text.caption.copyWith(
                              color: palette.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (MutunDigitalCatalog.hasDigitalText(book.id) &&
                            book.shuruh.isNotEmpty)
                          TextSpan(
                            text: ' • ',
                            style: context.text.caption.copyWith(
                              color: palette.textSubtle,
                            ),
                          ),
                        if (book.shuruh.isNotEmpty)
                          TextSpan(
                            text: '${book.shuruh.length} شروح',
                            style: context.text.caption.copyWith(
                              color: palette.textSubtle,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),

          // ── Footer Status & Progress ────────────────────────────
          if (isCompleted) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppProgress(
                  progress: 1.0,
                  color: palette.success,
                ),
                const SizedBox(height: AppSpace.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'مُتَمَّم بفضل الله',
                        style: context.text.caption.copyWith(
                          color: palette.success,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    if (totalPages > 0)
                      Text(
                        '$totalPages صفحة',
                        style: context.text.caption.copyWith(
                          color: palette.textSubtle,
                        ),
                        maxLines: 1,
                      ),
                  ],
                ),
              ],
            ),
          ] else if (isStarted) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppProgress(
                  progress: progressValue,
                  color: categoryColors.fg,
                ),
                const SizedBox(height: AppSpace.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'التقدم: ${(progressValue * 100).round()}%',
                        style: context.text.caption.copyWith(
                          color: categoryColors.fg,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    if (totalPages > 0)
                      Text(
                        'صـ $currentPage من $totalPages',
                        style: context.text.caption.copyWith(
                          color: palette.textSubtle,
                        ),
                        maxLines: 1,
                      ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'لم يبدأ بعد',
                    style: context.text.caption.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                if (totalPages > 0)
                  Text(
                    '$totalPages صفحة',
                    style: context.text.caption.copyWith(
                      color: palette.textSubtle,
                    ),
                    maxLines: 1,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
