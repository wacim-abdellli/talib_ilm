import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/theme_colors.dart';
import '../../../../core/services/adhan_settings_service.dart';

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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calculate_outlined, size: 18, color: context.primaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                'طريقة الحساب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...AdhanSettingsService.calculationMethods.entries.map((entry) {
            final isSelected = settings.calculationMethod == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSettingsChanged(
                      settings.copyWith(calculationMethod: entry.key),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                context.primaryColor,
                                context.primaryColor.withValues(alpha: 0.85),
                              ],
                            )
                          : null,
                      color: isSelected ? null : context.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? context.primaryColor
                            : context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? Colors.white
                              : context.textSecondaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : context.textPrimaryColor,
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
