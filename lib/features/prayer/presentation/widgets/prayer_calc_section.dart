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
            title: 'طريقة الحساب',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpace.md),
          ...AdhanSettingsService.calculationMethods.entries.map((entry) {
            final isSelected = settings.calculationMethod == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
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
                    padding: const EdgeInsets.all(AppSpace.md),
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
