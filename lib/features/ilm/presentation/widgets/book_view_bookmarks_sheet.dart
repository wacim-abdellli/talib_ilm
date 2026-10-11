import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_sheet.dart';

class BookmarkEntry {
  final String title;
  final String subtitle;
  final String? note;

  const BookmarkEntry({
    required this.title,
    required this.subtitle,
    this.note,
  });
}

class BookViewBookmarksSheet extends StatelessWidget {
  final List<BookmarkEntry> entries;

  const BookViewBookmarksSheet({
    super.key,
    required this.entries,
  });

  static Future<void> show(BuildContext context, List<BookmarkEntry> entries) {
    return AppSheet.show<void>(
      context: context,
      builder: (context) => BookViewBookmarksSheet(entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppSheet(
      titleText: 'الإشارات المرجعية',
      icon: Icons.bookmark_rounded,
      padding: EdgeInsets.zero,
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpace.xxl),
              child: Center(
                child: Text(
                  'لا توجد إشارات مرجعية محفوظة بعد',
                  style: context.text.bodySmall.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.all(AppSpace.lg),
              itemCount: entries.length,
              separatorBuilder: (_, _) => Divider(
                height: AppSpace.lg,
                color: palette.border,
              ),
              itemBuilder: (context, index) {
                final item = entries[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: context.text.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      item.subtitle,
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        item.note!,
                        style: context.text.bodySmall.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
