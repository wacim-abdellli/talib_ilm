import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/theme_colors.dart';

class BookViewControls extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onAddNote;
  final VoidCallback onShowBookmarks;

  const BookViewControls({
    super.key,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onAddNote,
    required this.onShowBookmarks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'bookmark_fab',
          mini: true,
          backgroundColor: isBookmarked
              ? context.goldColor
              : context.surfaceContainer,
          onPressed: onToggleBookmark,
          child: Icon(
            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isBookmarked ? Colors.white : context.goldColor,
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'note_fab',
          mini: true,
          backgroundColor: context.surfaceContainer,
          onPressed: onAddNote,
          child: const Icon(Icons.note_add_rounded, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'bookmarks_fab',
          mini: true,
          backgroundColor: context.surfaceContainer,
          onPressed: onShowBookmarks,
          child: const Icon(Icons.list_alt_rounded, color: AppColors.primary),
        ),
      ],
    );
  }
}

class BookNoteDialog extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const BookNoteDialog({
    super.key,
    required this.controller,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => BookNoteDialog(
        controller: controller,
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة ملاحظة', style: AppTextStyles.heading3),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'اكتب ملاحظتك هنا...',
          border: OutlineInputBorder(),
        ),
        maxLines: 5,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: onSave,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
