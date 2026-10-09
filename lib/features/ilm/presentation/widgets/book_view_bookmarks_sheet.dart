import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

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

  static void show(BuildContext context, List<BookmarkEntry> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookViewBookmarksSheet(entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            'الإشارات المرجعية',
            style: context.text.titleSmall.copyWith(
              color: palette.text,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
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
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpace.md),
        ],
      ),
    );
  }
}
