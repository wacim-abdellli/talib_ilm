import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';

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
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'bookmark_fab',
          mini: true,
          elevation: 2,
          backgroundColor:
              isBookmarked ? palette.goldFill : palette.surfaceRaised,
          onPressed: onToggleBookmark,
          child: Icon(
            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isBookmarked ? palette.onGold : palette.gold,
            size: AppIcon.md,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        FloatingActionButton(
          heroTag: 'note_fab',
          mini: true,
          elevation: 2,
          backgroundColor: palette.surfaceRaised,
          onPressed: onAddNote,
          child: Icon(
            Icons.note_add_rounded,
            color: palette.primary,
            size: AppIcon.md,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        FloatingActionButton(
          heroTag: 'bookmarks_fab',
          mini: true,
          elevation: 2,
          backgroundColor: palette.surfaceRaised,
          onPressed: onShowBookmarks,
          child: Icon(
            Icons.list_alt_rounded,
            color: palette.primary,
            size: AppIcon.md,
          ),
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
    final palette = context.palette;

    return AlertDialog(
      backgroundColor: palette.surfaceRaised,
      title: Text('إضافة ملاحظة', style: context.text.titleSmall),
      content: TextField(
        controller: controller,
        style: context.text.body,
        decoration: InputDecoration(
          hintText: 'اكتب ملاحظتك هنا...',
          hintStyle: context.text.bodySmall.copyWith(color: palette.textMuted),
        ),
        maxLines: 5,
      ),
      actions: [
        AppButton.text(
          label: 'إلغاء',
          onPressed: () => Navigator.pop(context),
          size: AppButtonSize.sm,
        ),
        AppButton(
          label: 'حفظ',
          onPressed: onSave,
          size: AppButtonSize.sm,
        ),
      ],
    );
  }
}
