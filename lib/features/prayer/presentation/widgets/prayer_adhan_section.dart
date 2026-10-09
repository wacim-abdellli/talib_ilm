import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_service.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';

class PrayerAdhanSection extends StatelessWidget {
  final AdhanSettings settings;
  final bool isDark;
  final AdhanService adhanService;
  final ValueChanged<AdhanSettings> onSettingsChanged;

  const PrayerAdhanSection({
    super.key,
    required this.settings,
    required this.isDark,
    required this.adhanService,
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
            title: 'الأذان والصوت',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpace.md),

          // Enable toggle
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'تشغيل صوت الأذان',
                    style: context.text.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
                Switch(
                  value: settings.enabled,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    onSettingsChanged(settings.copyWith(enabled: val));
                  },
                  activeThumbColor: palette.primary,
                  activeTrackColor: palette.primarySoft,
                ),
              ],
            ),
          ),

          if (settings.enabled) ...[
            const SizedBox(height: AppSpace.md),

            // Muezzin selector
            DropdownButtonFormField<AdhanSound>(
              initialValue: settings.sound,
              style: context.text.body.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'صوت المؤذن',
                labelStyle: context.text.bodySmall.copyWith(
                  color: palette.textMuted,
                ),
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdRadius,
                  borderSide: BorderSide(color: palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdRadius,
                  borderSide: BorderSide(color: palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdRadius,
                  borderSide: BorderSide(color: palette.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: AdhanSound.makkah,
                  child: Text('مكة المكرمة'),
                ),
                DropdownMenuItem(
                  value: AdhanSound.madinah,
                  child: Text('المدينة المنورة'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  onSettingsChanged(settings.copyWith(sound: val));
                }
              },
            ),

            const SizedBox(height: AppSpace.md),

            // Volume slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مستوى الصوت',
                      style: context.text.bodySmall.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    Text(
                      '${settings.volume.toInt()}%',
                      style: context.text.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Icon(
                      Icons.volume_mute_rounded,
                      size: AppIcon.md,
                      color: palette.textMuted,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: palette.primary,
                          inactiveTrackColor: palette.border,
                          thumbColor: palette.primary,
                          overlayColor: palette.primarySoft,
                        ),
                        child: Slider(
                          value: settings.volume,
                          min: 0,
                          max: 100,
                          onChanged: (val) {
                            onSettingsChanged(settings.copyWith(volume: val));
                          },
                        ),
                      ),
                    ),
                    Icon(
                      Icons.volume_up_rounded,
                      size: AppIcon.md,
                      color: palette.primary,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpace.md),

            // Test button
            AppButton.tonal(
              label: 'تجربة صوت الأذان',
              icon: Icons.play_circle_outline_rounded,
              width: double.infinity,
              onPressed: () async {
                HapticFeedback.lightImpact();
                await adhanService.test(
                  settings.sound,
                  volume: settings.volume,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
