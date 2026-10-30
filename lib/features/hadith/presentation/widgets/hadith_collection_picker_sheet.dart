import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';

class HadithCollectionPickerSheet {
  static void show({
    required BuildContext context,
    required List<String> collections,
    required String selectedCollection,
    required ValueChanged<String> onSelected,
  }) {
    HapticFeedback.lightImpact();
    final palette = context.palette;
    final textTheme = context.text;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheetTopRadius,
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom Sheet Header
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpace.lg,
                  AppSpace.md,
                  AppSpace.sm,
                  AppSpace.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        'اختر كتاب الحديث أو المجموعة',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: palette.textMuted,
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Collection List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  itemCount: collections.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpace.xs),
                  itemBuilder: (context, index) {
                    final col = collections[index];
                    final isSelected = col == selectedCollection;
                    final isAll = col == 'الكل';

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppRadius.mdRadius,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onSelected(col);
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? palette.primarySoft
                                : palette.surfaceRaised,
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(
                              color: isSelected
                                  ? palette.primary
                                  : palette.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isAll
                                    ? Icons.all_inclusive_rounded
                                    : Icons.menu_book_rounded,
                                color: isSelected
                                    ? palette.primary
                                    : palette.textMuted,
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: Text(
                                  isAll
                                      ? 'الكل (جميع الصحاح والسنن والمصادر)'
                                      : col,
                                  style: textTheme.body.copyWith(
                                    color: isSelected
                                        ? palette.primary
                                        : palette.text,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: palette.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
