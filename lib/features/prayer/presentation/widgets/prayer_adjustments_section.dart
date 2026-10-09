import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';

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
    final palette = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'تعديل التوقيت',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'تعديل التوقيت بالدقيقة (+ أو -)',
            style: context.text.caption.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          ...AdhanSettingsService.prayerNames.map((name) {
            final adj = settings.adjustments[name] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: context.text.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: palette.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAdjustButton(
                          context: context,
                          icon: Icons.remove_rounded,
                          tooltip: 'إنقاص دقيقة',
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
                          width: 48,
                          alignment: Alignment.center,
                          child: Text(
                            adj > 0 ? '+$adj' : '$adj',
                            style: context.text.label.copyWith(
                              fontWeight: FontWeight.w700,
                              color: adj == 0
                                  ? palette.textMuted
                                  : palette.primary,
                            ),
                          ),
                        ),
                        _buildAdjustButton(
                          context: context,
                          icon: Icons.add_rounded,
                          tooltip: 'زيادة دقيقة',
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
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.smRadius,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: AppSize.tap,
              minHeight: AppSize.tap,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: AppIcon.md, color: palette.primary),
          ),
        ),
      ),
    );
  }
}
