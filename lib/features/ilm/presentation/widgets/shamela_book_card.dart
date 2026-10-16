import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';

/// Minimalist, scholarly book card for Maktaba Shamela with clean level indicator
/// and integrated parent-child commentary link.
class ShamelaBookCard extends StatelessWidget {
  final ShamelaBook book;
  final bool isDownloaded;
  final double? downloadProgress;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final void Function(ShamelaBook parent, List<ShamelaBook> shuruh) onOpenShuruh;

  const ShamelaBookCard({
    super.key,
    required this.book,
    required this.isDownloaded,
    required this.downloadProgress,
    required this.onOpen,
    required this.onDownload,
    required this.onOpenShuruh,
  });

  static String levelLabel(int level) {
    switch (level) {
      case 1:
        return 'تمهيدي';
      case 2:
        return 'تأصيلي';
      case 3:
        return 'مطولات';
      default:
        return 'عام';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final shuruh = ShamelaService.getShuruh(book.id);
    final parentBook = book.parentBookId != null
        ? ShamelaService.getParentBook(book.parentBookId!)
        : null;

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppIcon.hero,
                height: AppIcon.hero,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.smRadius,
                  border: Border.all(color: palette.border, width: 0.8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.auto_stories_outlined,
                  color: palette.primary,
                  size: AppIcon.sm,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Clean, minimalist level indicator (No emojis)
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceRaised,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: palette.border,
                              width: 0.7,
                            ),
                          ),
                          child: Text(
                            levelLabel(book.level),
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Category Pill
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceMuted,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Text(
                            book.category,
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      book.title,
                      style: textTheme.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text.rich(
                      TextSpan(
                        text: book.author,
                        style: textTheme.caption.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          if (book.authorDeath != null) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: '(${book.authorDeath})',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // If search result is a commentary, indicate parent book cleanly
          if (parentBook != null) ...[
            const SizedBox(height: AppSpace.xs),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.smRadius,
                border: Border.all(color: palette.border, width: 0.6),
              ),
              child: Text(
                'شرح لمتن: ${parentBook.title}',
                style: textTheme.caption.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          if (book.description.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              book.description,
              style: textTheme.bodySmall.copyWith(
                color: palette.textMuted,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Minimalist Shuruh Button for Parent Books ───────────────────
          if (shuruh.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppRadius.smRadius,
                onTap: () => onOpenShuruh(book, shuruh),
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(
                      color: palette.border,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: AppIcon.xs,
                        color: palette.primary,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        '${shuruh.length} شروح معتمدة',
                        style: textTheme.caption.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpace.xxs),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: AppIcon.sm,
                        color: palette.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpace.sm),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: AppSpace.xs),

          // Actions Bar: Read vs Offline Download
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              Text(
                '${book.totalPages} صفحة',
                style: textTheme.caption.copyWith(color: palette.textMuted),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (downloadProgress != null) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        value: downloadProgress,
                        color: palette.primary,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'جاري التحميل ${(downloadProgress! * 100).toInt()}%',
                      style: textTheme.caption.copyWith(color: palette.primary),
                    ),
                  ] else if (isDownloaded) ...[
                    Icon(
                      Icons.offline_pin_rounded,
                      color: palette.success,
                      size: AppIcon.sm,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    Text(
                      'محمّل للقراءة بدون إنترنت',
                      style: textTheme.caption.copyWith(
                        color: palette.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: onDownload,
                      icon: Icon(
                        Icons.cloud_download_rounded,
                        size: AppIcon.sm,
                        color: palette.primary,
                      ),
                      label: Text(
                        'تحميل للقراءة بدون إنترنت',
                        style: textTheme.caption.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpace.sm),
                  AppButton(
                    size: AppButtonSize.sm,
                    label: 'قراءة الكتاب',
                    onPressed: onOpen,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
