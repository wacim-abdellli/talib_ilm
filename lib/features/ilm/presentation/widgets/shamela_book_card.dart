import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/catalogs/mutun_audio_catalog.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';

/// Minimalist, scholarly book card for Maktaba Shamela with clean level indicator
/// and integrated parent-child commentary link.
class ShamelaBookCard extends StatefulWidget {
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
  State<ShamelaBookCard> createState() => _ShamelaBookCardState();
}

class _ShamelaBookCardState extends State<ShamelaBookCard> {
  late Future<bool> _isDownloadedFuture;

  @override
  void initState() {
    super.initState();
    _isDownloadedFuture = ShamelaService.isBookDownloaded(widget.book.id);
  }

  @override
  void didUpdateWidget(covariant ShamelaBookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.book.id != oldWidget.book.id ||
        widget.isDownloaded != oldWidget.isDownloaded) {
      _isDownloadedFuture = ShamelaService.isBookDownloaded(widget.book.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final book = widget.book;
    final shuruh = ShamelaService.getShuruh(book.id);
    final hasAudio = MutunAudioCatalog.hasShamelaAudio(book.id);
    final parentBook = book.parentBookId != null
        ? ShamelaService.getParentBook(book.parentBookId!)
        : null;

    return FutureBuilder<bool>(
      future: _isDownloadedFuture,
      initialData: widget.isDownloaded,
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? widget.isDownloaded;

        return AppCard(
          onTap: widget.onOpen,
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
                                ShamelaBookCard.levelLabel(book.level),
                                style: textTheme.captionBold.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ),
                            if (isDownloaded) ...[
                              const SizedBox(width: AppSpace.xs),
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
                                  'محفوظ',
                                  style: textTheme.captionBold.copyWith(
                                    color: palette.onPrimarySoft,
                                  ),
                                ),
                              ),
                            ],
                            if (hasAudio) ...[
                              const SizedBox(width: AppSpace.xs),
                              Builder(
                                builder: (_) {
                                  final entry =
                                      MutunAudioCatalog.getShamelaEntry(book.id);
                                  final voiceCount = entry?.sources.length ?? 1;
                                  final badgeText = voiceCount > 1
                                      ? 'صوتي · $voiceCount'
                                      : 'صوتي';
                                  return Container(
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                      horizontal: AppSpace.sm,
                                      vertical: AppSpace.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.goldSoft,
                                      borderRadius: AppRadius.pillRadius,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.graphic_eq_rounded,
                                          size: AppIcon.sm,
                                          color: palette.onPrimarySoft,
                                        ),
                                        const SizedBox(width: AppSpace.xxs),
                                        Text(
                                          badgeText,
                                          style:
                                              textTheme.captionBold.copyWith(
                                            color: palette.onPrimarySoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                            const SizedBox(width: AppSpace.xs),
                            // Category Pill
                            Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Container(
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text.rich(
                          TextSpan(
                            text: book.author,
                            style: textTheme.captionBold.copyWith(
                              color: palette.primary,
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
                style: textTheme.captionBold.copyWith(
                  color: palette.primary,
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

          // ── Prominent Shuruh Banner for Parent Books ───────────────────
          if (shuruh.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Material(
              color: palette.goldSoft,
              borderRadius: AppRadius.smRadius,
              child: InkWell(
                borderRadius: AppRadius.smRadius,
                onTap: () => widget.onOpenShuruh(book, shuruh),
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(
                      color: palette.gold.withAlpha(150),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: AppIcon.xs,
                        color: palette.gold,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          'تصفح شروح وتعليقات الكتاب (${shuruh.length} شروح متوفرة)',
                          style: textTheme.caption.copyWith(
                            color: palette.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xxs),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: AppIcon.xs,
                        color: palette.gold,
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
                '${ShamelaService.getEffectiveTotalPages(book.id, book.totalPages)} صفحة',
                style: textTheme.caption.copyWith(color: palette.textMuted),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.downloadProgress != null) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        value: widget.downloadProgress,
                        color: palette.primary,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'جاري التحميل ${(widget.downloadProgress! * 100).toInt()}%',
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
                      onPressed: widget.onDownload,
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
                    onPressed: widget.onOpen,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  },
);
  }
}
