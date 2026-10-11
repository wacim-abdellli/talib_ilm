import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';

Future<int?> showSetTargetSheet({
  required BuildContext context,
  required int? currentTarget,
}) {
  final controller = TextEditingController(
    text: currentTarget != null ? currentTarget.toString() : '',
  );
  final palette = context.palette;

  return AppSheet.show<int?>(
    context: context,
    builder: (context) {
      return AppSheet(
        titleText: AppStrings.targetTitle,
        icon: Icons.flag_rounded,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهداف مقترحة',
              style: context.text.label.copyWith(
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [33, 100, 1000].map((preset) {
                final isCurrent = currentTarget == preset;
                return InkWell(
                  onTap: () => Navigator.pop(context, preset),
                  borderRadius: AppRadius.mdRadius,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent ? palette.primarySoft : palette.surface,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: isCurrent ? palette.primary : palette.border,
                      ),
                    ),
                    child: Text(
                      '$preset مرة',
                      style: context.text.label.copyWith(
                        color: isCurrent ? palette.onPrimarySoft : palette.text,
                      ),
                    ),
                  ),
                );
              }).toList()
                ..add(
                  InkWell(
                    onTap: () => Navigator.pop(context, 0),
                    borderRadius: AppRadius.mdRadius,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        color: currentTarget == null
                            ? palette.primarySoft
                            : palette.surface,
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(
                          color: currentTarget == null
                              ? palette.primary
                              : palette.border,
                        ),
                      ),
                      child: Text(
                        'بدون هدف (حر)',
                        style: context.text.label.copyWith(
                          color: currentTarget == null
                              ? palette.onPrimarySoft
                              : palette.text,
                        ),
                      ),
                    ),
                  ),
                ),
            ),
            const SizedBox(height: AppSpace.xl),
            Text(
              'أو حدد رقماً مخصصاً:',
              style: context.text.label.copyWith(
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: context.text.titleSmall.copyWith(
                      color: palette.text,
                    ),
                    decoration: InputDecoration(
                      hintText: 'مثال: 500',
                      filled: true,
                      fillColor: palette.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.mdRadius,
                        borderSide: BorderSide(color: palette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdRadius,
                        borderSide: BorderSide(
                          color: palette.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.md,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                AppButton(
                  label: 'حفظ',
                  onPressed: () {
                    final val = int.tryParse(controller.text);
                    Navigator.pop(context, val);
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
