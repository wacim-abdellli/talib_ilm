import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/services/bookmark_entry_loader.dart';

class BookViewBookmarksTab extends StatelessWidget {
  final List<BookmarkEntry> bookmarks;
  final void Function(BookmarkEntry entry)? onSelectEntry;
  final void Function(BookmarkEntry entry) onDeleteBookmark;

  const BookViewBookmarksTab({
    super.key,
    required this.bookmarks,
    this.onSelectEntry,
    required this.onDeleteBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (bookmarks.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(AppSpace.xxl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppSize.tap,
                height: AppSize.tap,
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Icon(
                  Icons.bookmark_border_rounded,
                  color: palette.gold,
                  size: AppIcon.lg,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'لا توجد إشارات مرجعية محفوظة',
                style: textTheme.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'اضغط على أيقونة الإشارة أسفل شاشة القارئ لحفظ الصفحة أو الفقرة.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      itemCount: bookmarks.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, index) {
        final item = bookmarks[index];
        final pageBadgeText = item.totalPages != null && item.totalPages! > 0
            ? 'صفحة ${item.page} من ${item.totalPages}'
            : 'صفحة ${item.page}';

        return AppCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: () {
              Navigator.pop(context);
              onSelectEntry?.call(item);
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.smRadius,
                      border: Border.all(
                        color: palette.gold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.bookmark_rounded,
                        color: palette.gold,
                        size: AppIcon.md,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row: Book Title + Page Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: textTheme.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: palette.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: palette.goldSoft,
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(
                                  color: palette.gold.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                pageBadgeText,
                                style: textTheme.caption.copyWith(
                                  color: palette.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Section/Chapter subtitle (multi-line to prevent truncation dots)
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.xxs),
                          Text(
                            item.subtitle,
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Attached note snippet if present
                        if (item.note != null && item.note!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpace.xs),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                            decoration: BoxDecoration(
                              color: palette.surfaceRaised,
                              borderRadius: AppRadius.smRadius,
                              border: Border.all(color: palette.border),
                            ),
                            child: Text(
                              item.note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.caption.copyWith(
                                color: palette.text,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'إزالة الإشارة',
                    constraints: const BoxConstraints(
                      minWidth: AppSize.tap,
                      minHeight: AppSize.tap,
                    ),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: palette.textMuted,
                      size: AppIcon.md,
                    ),
                    onPressed: () => onDeleteBookmark(item),
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
