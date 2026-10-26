import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialog.dart';

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
  final bool hasExistingNote;
  final VoidCallback? onDelete;
  final VoidCallback? onShowAllNotes;

  const BookNoteDialog({
    super.key,
    required this.controller,
    required this.onSave,
    this.hasExistingNote = false,
    this.onDelete,
    this.onShowAllNotes,
  });

  static Future<void> show(
    BuildContext context, {
    required TextEditingController controller,
    required VoidCallback onSave,
    bool hasExistingNote = false,
    VoidCallback? onDelete,
    VoidCallback? onShowAllNotes,
  }) {
    return AppDialog.show(
      context: context,
      builder: (context) => BookNoteDialog(
        controller: controller,
        onSave: onSave,
        hasExistingNote: hasExistingNote,
        onDelete: onDelete,
        onShowAllNotes: onShowAllNotes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppDialog(
      title: hasExistingNote ? 'تعديل الملاحظة' : 'إضافة ملاحظة',
      icon: Icons.edit_note_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            style: textTheme.body,
            decoration: InputDecoration(
              hintText: 'اكتب ملاحظتك هنا...',
              hintStyle: textTheme.bodySmall.copyWith(color: palette.textMuted),
            ),
            minLines: 3,
            maxLines: 5,
          ),
          if (onShowAllNotes != null) ...[
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: InkWell(
                borderRadius: AppRadius.smRadius,
                onTap: onShowAllNotes,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: AppSpace.xxs,
                    horizontal: AppSpace.xxs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.collections_bookmark_outlined,
                        size: AppIcon.xs,
                        color: palette.gold,
                      ),
                      const SizedBox(width: AppSpace.xxs),
                      Text(
                        'عرض جميع الملاحظات والإشارات',
                        style: textTheme.captionBold.copyWith(
                          color: palette.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (hasExistingNote && onDelete != null)
          AppButton.text(
            label: 'حذف',
            onPressed: onDelete,
            size: AppButtonSize.sm,
          ),
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
