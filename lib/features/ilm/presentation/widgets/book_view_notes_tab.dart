import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/services/bookmark_entry_loader.dart';

class BookViewNotesTab extends StatelessWidget {
  final List<BookmarkEntry> notes;
  final void Function(BookmarkEntry entry)? onSelectEntry;
  final void Function(BookmarkEntry entry) onEditNote;
  final void Function(BookmarkEntry entry) onDeleteNote;

  const BookViewNotesTab({
    super.key,
    required this.notes,
    this.onSelectEntry,
    required this.onEditNote,
    required this.onDeleteNote,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (notes.isEmpty) {
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
                  color: palette.primarySoft,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: palette.primary,
                  size: AppIcon.lg,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'لا توجد ملاحظات أو فوائد مدونة',
                style: textTheme.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'اضغط على أيقونة الملاحظة أسفل القارئ لتدوين فائدة على الصفحة الحالية.',
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
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, index) {
        final item = notes[index];
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Page Pill Badge + Book Title + Action Buttons (No overflow!)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primarySoft,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: palette.primary.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          pageBadgeText,
                          style: textTheme.caption.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          item.title,
                          style: textTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: palette.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'تعديل الملاحظة',
                        constraints: const BoxConstraints(
                          minWidth: AppSize.tap,
                          minHeight: AppSize.tap,
                        ),
                        icon: Icon(
                          Icons.edit_rounded,
                          color: palette.primary,
                          size: AppIcon.sm,
                        ),
                        onPressed: () => onEditNote(item),
                      ),
                      IconButton(
                        tooltip: 'حذف الملاحظة',
                        constraints: const BoxConstraints(
                          minWidth: AppSize.tap,
                          minHeight: AppSize.tap,
                        ),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: palette.textMuted,
                          size: AppIcon.sm,
                        ),
                        onPressed: () => onDeleteNote(item),
                      ),
                    ],
                  ),

                  // Row 2: Section/Chapter Subtitle on its own line (Fixes overflow and dots!)
                  if (item.subtitle.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpace.xxs,
                        bottom: AppSpace.xs,
                        start: AppSpace.xxs,
                      ),
                      child: Text(
                        item.subtitle,
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpace.xs),

                  // Row 3: Note Content Box (Selectable, full text, no clipping)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsetsDirectional.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: palette.surfaceRaised,
                      borderRadius: AppRadius.smRadius,
                      border: Border.all(color: palette.border),
                    ),
                    child: SelectableText(
                      item.note ?? '',
                      style: textTheme.body.copyWith(
                        color: palette.text,
                        height: 1.5,
                      ),
                    ),
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
