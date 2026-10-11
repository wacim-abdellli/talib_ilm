import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../data/adhkar_models.dart';

Future<int?> showChangeDhikrSheet({
  required BuildContext context,
  required List<AthkarItem> options,
  required int currentIndex,
  required bool isTasbeeh,
}) {
  final palette = context.palette;

  return AppSheet.show<int>(
    context: context,
    builder: (context) {
      return AppSheet(
        titleText: isTasbeeh ? 'اختر صيغة التسبيح' : 'اختر صيغة الاستغفار',
        icon: isTasbeeh ? Icons.all_inclusive_rounded : Icons.favorite_rounded,
        padding: EdgeInsets.zero,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          itemCount: options.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpace.sm),
          itemBuilder: (context, index) {
            final item = options[index];
            final isSelected = index == currentIndex;
            return InkWell(
              onTap: () => Navigator.pop(context, index),
              borderRadius: AppRadius.mdRadius,
              child: Container(
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: isSelected ? palette.primarySoft : palette.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: isSelected ? palette.primary : palette.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.arabic,
                            style: context.text.sacred.copyWith(
                              color: palette.text,
                              height: 1.5,
                            ),
                          ),
                          if (item.fadl.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.xs),
                            Text(
                              item.fadl,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    if (isSelected)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: AppIcon.sm,
                          color: palette.onPrimary,
                        ),
                      )
                    else if (item.target > 0)
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: AppRadius.smRadius,
                        ),
                        child: Text(
                          '${item.target}x',
                          style: context.text.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
