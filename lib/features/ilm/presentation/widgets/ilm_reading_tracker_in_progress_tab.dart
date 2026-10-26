import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';

class IlmReadingTrackerInProgressTab extends StatelessWidget {
  final List<BookProgress> inProgressBooks;
  final Map<String, IlmBook> bookCatalog;
  final void Function(String bookId) onOpenBook;

  const IlmReadingTrackerInProgressTab({
    super.key,
    required this.inProgressBooks,
    required this.bookCatalog,
    required this.onOpenBook,
  });

  String _formatLastRead(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins <= 1 ? 'منذ دقيقة' : 'منذ $mins دقيقة';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1
          ? 'منذ ساعة'
          : hours == 2
              ? 'منذ ساعتين'
              : 'منذ $hours ساعات';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1
          ? 'أمس'
          : days == 2
              ? 'منذ يومين'
              : 'منذ $days أيام';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (inProgressBooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: AppIcon.hero,
                color: palette.textMuted,
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'لا توجد متون قيد المدارسة حالياً',
                style: textTheme.titleSmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'اختر متناً أو كتاباً مباركاً من المكتبة للبدء في مدارسته وقراءته',
                style: textTheme.bodySmall.copyWith(
                  color: palette.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsetsDirectional.all(AppSpace.xl),
      itemCount: inProgressBooks.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpace.md),
      itemBuilder: (context, index) {
        final progress = inProgressBooks[index];
        final book = bookCatalog[progress.bookId];
        final title = book?.title ?? progress.bookTitle;
        final author = book?.author ?? 'علم شرعي';
        final total = progress.totalPages > 0 ? progress.totalPages : 1;
        final current = progress.currentPage.clamp(1, total);
        final ratio = (current / total).clamp(0.0, 1.0);
        final percentText = '${(ratio * 100).toInt()}%';

        return Material(
          color: palette.surface,
          borderRadius: AppRadius.lgRadius,
          child: InkWell(
            borderRadius: AppRadius.lgRadius,
            onTap: () {
              Navigator.of(context).pop();
              onOpenBook(progress.bookId);
            },
            child: Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: palette.border, width: 0.9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: textTheme.titleSmall.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpace.xxs),
                            Text(
                              author,
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primarySoft,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          percentText,
                          style: textTheme.caption.copyWith(
                            color: palette.onPrimarySoft,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: palette.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpace.sm),

                  // Footer info and action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark_outline_rounded,
                            size: AppIcon.xs,
                            color: palette.textMuted,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'صفحة $current من $total',
                            style: textTheme.captionBold.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Text(
                            '• ${_formatLastRead(progress.lastReadDate)}',
                            style: textTheme.caption.copyWith(
                              color: palette.textSubtle,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'متابعة',
                            style: textTheme.caption.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xxs),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: AppIcon.xs,
                            color: palette.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
