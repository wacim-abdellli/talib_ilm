import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/theme_colors.dart';
import '../../../../core/services/adhan_service.dart';
import '../../../../core/services/adhan_settings_service.dart';

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
                child: Icon(
                  Icons.volume_up_outlined,
                  size: 18,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الأذان والصوت',
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

          // Enable toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  'تشغيل صوت الأذان',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: settings.enabled,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    onSettingsChanged(settings.copyWith(enabled: val));
                  },
                  activeThumbColor: context.primaryColor,
                  activeTrackColor: context.primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          if (settings.enabled) ...[
            const SizedBox(height: 16),

            // Muezzin selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                ),
              ),
              child: DropdownButtonFormField<AdhanSound>(
                initialValue: settings.sound,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: context.textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'صوت المؤذن',
                  labelStyle: TextStyle(
                    fontFamily: 'Cairo',
                    color: context.textSecondaryColor,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
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
            ),

            const SizedBox(height: 16),

            // Volume slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مستوى الصوت',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    Text(
                      '${settings.volume.toInt()}%',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.volume_mute_rounded,
                      size: 20,
                      color: context.textSecondaryColor,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: context.primaryColor,
                          inactiveTrackColor: context.primaryColor.withValues(alpha: 0.2),
                          thumbColor: context.primaryColor,
                          overlayColor: context.primaryColor.withValues(alpha: 0.15),
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
                      size: 20,
                      color: context.primaryColor,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Test button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await adhanService.test(
                    settings.sound,
                    volume: settings.volume,
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline_rounded,
                        color: context.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تجربة صوت الأذان',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
