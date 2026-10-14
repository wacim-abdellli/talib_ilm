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
            'تحدد الزوايا الفلكية لحساب صلاتي الفجر والعشاء وفق الهيئات الإسلامية الرسمية',
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
                  'أوقات الظهر والعصر والمغرب ثابتة فلكياً بحركة الشمس وظلها في كل العالم، بينما يختلف حساب الفجر والعشاء حسب زاوية انخفاض ضوء الشفق تحت الأفق لكل منطقة.\n\n'
                  '• التلقائي (الموصى به): يحدد التطبيق الهيئة الرسمية المعتمدة لدولتك تلقائياً عبر GPS.\n'
                  '• رابطة العالم الإسلامي: المعتمدة رسمياً في الجزائر والمغرب العربي وأوروبا (فجر 18° / عشاء 17°).\n'
                  '• أم القرى: المعتمدة في المملكة العربية السعودية والخليج.\n'
                  '• الهيئة المصرية: المعتمدة في مصر وإفريقيا وبلاد الشام.\n\n'
                  'جميع الحسابات تعمل بدقة عبر خوارزميات Batoul Apps (Adhan) الرسمية.',
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
                    constraints: const BoxConstraints(
                      minHeight: AppSize.tap,
                    ),
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
                            style: context.text.body.copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
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
        ],
      ),
    );
  }
}
