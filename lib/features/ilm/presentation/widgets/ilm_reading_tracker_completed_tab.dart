import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';

class IlmReadingTrackerCompletedTab extends StatelessWidget {
  final List<BookProgress> completedBooks;
  final Map<String, IlmBook> bookCatalog;
  final void Function(String bookId) onOpenBook;

  const IlmReadingTrackerCompletedTab({
    super.key,
    required this.completedBooks,
    required this.bookCatalog,
    required this.onOpenBook,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (completedBooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: AppIcon.hero,
                color: palette.textMuted,
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'لم تكتمل أي متون بعد',
                style: textTheme.titleSmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'واصل القراءة اليومية لإنهاء متونك الشرعية ونيل شرف ختمها مباركة',
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
      itemCount: completedBooks.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpace.md),
      itemBuilder: (context, index) {
        final progress = completedBooks[index];
        final book = bookCatalog[progress.bookId];
        final title = book?.title ?? progress.bookTitle;
        final author = book?.author ?? 'علم شرعي';
        final total = progress.totalPages > 0 ? progress.totalPages : 1;

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
                border: Border.all(
                  color: palette.gold.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: palette.gold,
                      size: AppIcon.md,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
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
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          'تمت قراءة كامل المتن ($total صفحة)',
                          style: textTheme.captionBold.copyWith(
                            color: palette.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  AppButton(
                    label: 'مراجعة',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.tonal,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOpenBook(progress.bookId);
                    },
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
