import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/theme_colors.dart';

Future<int?> showSetTargetSheet({
  required BuildContext context,
  required int? currentTarget,
}) {
  final controller = TextEditingController(
    text: currentTarget != null ? currentTarget.toString() : '',
  );

  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: context.goldColor.withValues(alpha: isDark ? 0.3 : 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.outlineVariantColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.flag_rounded, color: context.goldColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    AppStrings.targetTitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quick preset pills
              Text(
                'أهداف مقترحة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [33, 100, 1000].map((preset) {
                  final isCurrent = currentTarget == preset;
                  return InkWell(
                    onTap: () => Navigator.pop(context, preset),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? context.goldColor.withValues(alpha: 0.2)
                            : context.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent ? context.goldColor : context.outlineVariantColor,
                        ),
                      ),
                      child: Text(
                        '$preset مرة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? context.goldColor : context.textPrimaryColor,
                        ),
                      ),
                    ),
                  );
                }).toList()
                  ..add(
                    InkWell(
                      onTap: () => Navigator.pop(context, 0),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: currentTarget == null
                              ? context.primaryColor.withValues(alpha: 0.2)
                              : context.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: currentTarget == null
                                ? context.primaryColor
                                : context.outlineVariantColor,
                          ),
                        ),
                        child: Text(
                          'بدون هدف (حر)',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            color: currentTarget == null
                                ? context.primaryColor
                                : context.textPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
              ),
              const SizedBox(height: 20),
              Text(
                'أو حدد رقماً مخصصاً:',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: false,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        hintText: 'مثال: 500',
                        filled: true,
                        fillColor: context.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.outlineVariantColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.goldColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      final val = int.tryParse(controller.text);
                      Navigator.pop(context, val);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: context.goldColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'حفظ',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                    ),
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
