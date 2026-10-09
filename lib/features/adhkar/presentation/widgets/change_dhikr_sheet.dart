import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../data/adhkar_models.dart';

Future<int?> showChangeDhikrSheet({
  required BuildContext context,
  required List<AthkarItem> options,
  required int currentIndex,
  required bool isTasbeeh,
}) {
  final palette = context.palette;

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          border: Border.all(
            color: palette.border,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpace.md),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.xl,
                AppSpace.lg,
                AppSpace.xl,
                AppSpace.md,
              ),
              child: Row(
                children: [
                  Icon(
                    isTasbeeh
                        ? Icons.all_inclusive_rounded
                        : Icons.favorite_rounded,
                    color: palette.primary,
                    size: AppIcon.lg,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    isTasbeeh ? 'اختر صيغة التسبيح' : 'اختر صيغة الاستغفار',
                    style: context.text.titleSmall.copyWith(
                      color: palette.text,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.border),
            Flexible(
              child: ListView.separated(
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
            ),
          ],
        ),
      );
    },
  );
}
