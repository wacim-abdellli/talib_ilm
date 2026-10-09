import 'package:flutter/material.dart';

import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/theme_colors.dart';

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
      builder: (context) => BookViewBookmarksSheet(entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإشارات المرجعية',
            style: AppTextStyles.heading2.copyWith(
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = entries[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.note!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
