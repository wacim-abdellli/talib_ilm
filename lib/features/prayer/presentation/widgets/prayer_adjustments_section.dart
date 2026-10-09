import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/theme_colors.dart';
import '../../../../core/services/adhan_settings_service.dart';

class PrayerAdjustmentsSection extends StatelessWidget {
  final AdhanSettings settings;
  final bool isDark;
  final ValueChanged<AdhanSettings> onSettingsChanged;

  const PrayerAdjustmentsSection({
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
                child: Icon(Icons.tune_outlined, size: 18, color: context.primaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                'تعديل التوقيت',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'تعديل التوقيت بالدقيقة (+ أو -)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...AdhanSettingsService.prayerNames.map((name) {
            final adj = settings.adjustments[name] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAdjustButton(
                          context: context,
                          icon: Icons.remove_rounded,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            final updated = Map<String, int>.from(
                              settings.adjustments,
                            );
                            updated[name] = adj - 1;
                            onSettingsChanged(
                              settings.copyWith(adjustments: updated),
                            );
                          },
                        ),
                        Container(
                          width: 50,
                          alignment: Alignment.center,
                          child: Text(
                            adj > 0 ? '+$adj' : '$adj',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: adj == 0
                                  ? context.textSecondaryColor
                                  : context.primaryColor,
                            ),
                          ),
                        ),
                        _buildAdjustButton(
                          context: context,
                          icon: Icons.add_rounded,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            final updated = Map<String, int>.from(
                              settings.adjustments,
                            );
                            updated[name] = adj + 1;
                            onSettingsChanged(
                              settings.copyWith(adjustments: updated),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: context.primaryColor),
        ),
      ),
    );
  }
}
