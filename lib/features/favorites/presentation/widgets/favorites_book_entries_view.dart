import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../ilm/data/services/bookmark_entry_loader.dart';

class FavoritesBookEntriesView extends StatelessWidget {
  final List<BookmarkEntry> entries;
  final void Function(BookmarkEntry entry) onSelect;
  final void Function(BookmarkEntry entry) onRemoveBookmark;
  final void Function(BookmarkEntry entry) onRemoveNote;
  final void Function(BookmarkEntry entry) onEditNote;

  const FavoritesBookEntriesView({
    super.key,
    required this.entries,
    required this.onSelect,
    required this.onRemoveBookmark,
    required this.onRemoveNote,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(AppSpace.xl),
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
                  Icons.collections_bookmark_rounded,
                  color: palette.gold,
                  size: AppIcon.lg,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'لا توجد إشارات أو ملاحظات كتب بعد',
                style: textTheme.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'أثناء قراءة أي متن أو شرح، اضغط على زر الإشارة أو الملاحظة أسفل القارئ لحفظ الفوائد والصفحات والرجوع إليها هنا في أي وقت.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall.copyWith(
                  color: palette.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bookmarks = entries.where((e) => e.isBookmark).toList();
    final notes = entries.where((e) => e.note != null && e.note!.trim().isNotEmpty).toList();

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.lg,
      ),
      children: [
        if (bookmarks.isNotEmpty) ...[
          Text(
            'إشارات القراءة المرجعية (${bookmarks.length})',
            style: textTheme.titleSmall.copyWith(color: palette.text),
          ),
          const SizedBox(height: AppSpace.sm),
          ...bookmarks.map(
            (item) => Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: AppRadius.mdRadius,
                  onTap: () => onSelect(item),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.md,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppSize.tap,
                          height: AppSize.tap,
                          decoration: BoxDecoration(
                            color: palette.goldSoft,
                            borderRadius: AppRadius.smRadius,
                          ),
                          child: Icon(
                            Icons.bookmark_rounded,
                            color: palette.gold,
                            size: AppIcon.md,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: textTheme.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpace.xxs),
                              Text(
                                item.subtitle,
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                              if (item.note != null && item.note!.trim().isNotEmpty) ...[
                                const SizedBox(height: AppSpace.xs),
                                Container(
                                  padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: AppSpace.xs,
                                    vertical: AppSpace.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.surfaceRaised,
                                    borderRadius: AppRadius.smRadius,
                                  ),
                                  child: Text(
                                    item.note!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.caption.copyWith(
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        AppIconButton(
                          tooltip: 'إزالة الإشارة',
                          onPressed: () => onRemoveBookmark(item),
                          icon: Icons.bookmark_remove_rounded,
                          color: palette.gold,
                          iconSize: AppIcon.md,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        if (notes.isNotEmpty) ...[
          Text(
            'ملاحظات وفوائد المطالعة (${notes.length})',
            style: textTheme.titleSmall.copyWith(color: palette.text),
          ),
          const SizedBox(height: AppSpace.sm),
          ...notes.map(
            (item) => Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: AppRadius.mdRadius,
                  onTap: () => onSelect(item),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
                                vertical: AppSpace.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: palette.primarySoft,
                                borderRadius: AppRadius.pillRadius,
                              ),
                              child: Text(
                                item.subtitle,
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
                              icon: Icon(
                                Icons.edit_rounded,
                                color: palette.primary,
                                size: AppIcon.sm,
                              ),
                              onPressed: () => onEditNote(item),
                            ),
                            IconButton(
                              tooltip: 'حذف الملاحظة',
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: palette.textMuted,
                                size: AppIcon.sm,
                              ),
                              onPressed: () => onRemoveNote(item),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                          decoration: BoxDecoration(
                            color: palette.surfaceRaised,
                            borderRadius: AppRadius.smRadius,
                            border: Border.all(color: palette.border),
                          ),
                          child: Text(
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
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        SizedBox(height: AppSize.navClearance(context)),
      ],
    );
  }
}
