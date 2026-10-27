import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';

class PrayerCalcSection extends StatelessWidget {
  final AdhanSettings settings;
  final bool isDark;
  final ValueChanged<AdhanSettings> onSettingsChanged;

  const PrayerCalcSection({
    super.key,
    required this.settings,
    required this.isDark,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'طريقة الحساب الفلكي للمواقيت',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'تنتج الطرق الفلكية تقديرات تختلف باختلاف الإحداثيات والمنطقة الزمنية وطريقة الحساب، وقد لا تطابق جدولاً حكومياً محلياً.',
            style: context.text.caption.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpace.md),

          // Informative guide card
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: AppIcon.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'ما هي طريقة الحساب؟',
                      style: context.text.label.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'تُحسب المواقيت من الموقع والتاريخ والمنطقة الزمنية. وتختلف النتائج حسب زوايا الفجر والعشاء، وطريقة حساب العصر، والتعديلات المحلية. لا يوجد جدول حكومي موحّد يخدم جميع دول العالم.\n\n'
                  '• التلقائي: يختار إعداداً فلكياً وفق قواعد التطبيق ورمز الدولة؛ لا يجلب جدول وزارة الشؤون الدينية أو جهة حكومية مباشرة.\n'
                  '• رابطة العالم الإسلامي، أم القرى، والهيئة المصرية: مجموعات إعدادات حساب فلكي، ولا يعني اختيارها أن التطبيق يزامن جدولاً حكومياً محلياً.\n\n'
                  'للمطابقة مع جدول رسمي لمدينة بعينها، قارن المدينة والتاريخ والمنطقة الزمنية والطريقة، ثم استخدم تعديلات الدقائق المتاحة عند الحاجة. قد تظل فروق محلية أو موسمية.',
                  style: context.text.caption.copyWith(
                    color: palette.text,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          ...AdhanSettingsService.calculationMethods.entries.map((entry) {
            final isSelected = settings.calculationMethod == entry.key;
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSettingsChanged(
                      settings.copyWith(calculationMethod: entry.key),
                    );
                  },
                  borderRadius: AppRadius.mdRadius,
                  child: Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.md),
                    constraints: const BoxConstraints(minHeight: AppSize.tap),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.primarySoft
                          : palette.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: isSelected ? palette.primary : palette.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? palette.primary
                              : palette.textSubtle,
                          size: AppIcon.md,
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            entry.value,
                            style:
                                (isSelected
                                        ? context.text.bodyHeavy
                                        : context.text.bodyMedium)
                                    .copyWith(
                                      color: isSelected
                                          ? palette.onPrimarySoft
                                          : palette.text,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: AppSpace.lg),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpace.lg),

          const SectionHeader(
            title: 'المذهب الفقهي (حساب صلاة العصر)',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'يحدد وقت دخول صلاة العصر فلكياً استناداً إلى طول ظل الشاخص:',
            style: context.text.caption.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpace.md),

          ...AdhanSettingsService.madhabs.entries.map((entry) {
            final isSelected = (settings.madhab == entry.key);
            final title = entry.key == 'shafi'
                ? 'جمهور الفقهاء (شافعي، مالكي، حنبلي)'
                : 'المذهب الحنفي';
            final desc = entry.key == 'shafi'
                ? 'يبدأ العصر إذا صار ظل الشيء مثله (المعتمد في أكثر العالم الإسلامي)'
                : 'يبدأ العصر إذا صار ظل الشيء مثليه (تأخير وقت العصر)';

            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSettingsChanged(settings.copyWith(madhab: entry.key));
                  },
                  borderRadius: AppRadius.mdRadius,
                  child: Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.md),
                    constraints: const BoxConstraints(minHeight: AppSize.tap),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.primarySoft
                          : palette.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: isSelected ? palette.primary : palette.border,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            top: AppSpace.xxs,
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? palette.primary
                                : palette.textSubtle,
                            size: AppIcon.md,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style:
                                    (isSelected
                                            ? context.text.bodyHeavy
                                            : context.text.bodyBold)
                                        .copyWith(
                                          color: isSelected
                                              ? palette.onPrimarySoft
                                              : palette.text,
                                        ),
                              ),
                              const SizedBox(height: AppSpace.xxs),
                              Text(
                                desc,
                                style: context.text.caption.copyWith(
                                  color: isSelected
                                      ? palette.onPrimarySoft.withValues(
                                          alpha: 0.85,
                                        )
                                      : palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
