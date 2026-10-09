import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';

Future<int?> showSetTargetSheet({
  required BuildContext context,
  required int? currentTarget,
}) {
  final controller = TextEditingController(
    text: currentTarget != null ? currentTarget.toString() : '',
  );
  final palette = context.palette;

  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpace.xl,
            AppSpace.lg,
            AppSpace.xl,
            AppSpace.xxl,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Icon(
                    Icons.flag_rounded,
                    color: palette.primary,
                    size: AppIcon.lg,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    AppStrings.targetTitle,
                    style: context.text.titleSmall.copyWith(
                      color: palette.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              // Quick preset pills
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
        ),
      );
    },
  );
}
