import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_service.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'prayer_notification_tester.dart';

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
    final textTheme = context.text;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'الأذان وتنبيهات الصلاة',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpace.md),

          // ── Master Enable Toggle ──────────────────────────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفعيل تنبيهات الصلاة',
                        style: textTheme.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        'تنبيهات دخول الوقت على شاشة القفل والأذان',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
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
            const SizedBox(height: AppSpace.lg),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: AppSpace.md),

            // ── Default Notification Mode Selector ──────────────────────
            Text(
              'نمط التنبيه الافتراضي',
              style: textTheme.label.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpace.sm),

            _buildModePill(
              context: context,
              palette: palette,
              textTheme: textTheme,
              mode: PrayerNotificationMode.adhan,
              title: 'أذان كامل',
              subtitle: 'سماع صوت الأذان كاملاً عند دخول وقت الصلاة',
              icon: Icons.mosque_rounded,
            ),
            const SizedBox(height: AppSpace.xs),
            _buildModePill(
              context: context,
              palette: palette,
              textTheme: textTheme,
              mode: PrayerNotificationMode.takbeer,
              title: 'تكبير وتنبيه موجز',
              subtitle: 'تكبيرات الأذان مع تنبيه "حان الآن وقت الصلاة"',
              icon: Icons.campaign_rounded,
            ),
            const SizedBox(height: AppSpace.xs),
            _buildModePill(
              context: context,
              palette: palette,
              textTheme: textTheme,
              mode: PrayerNotificationMode.tone,
              title: 'نغمة تنبيه هادئة',
              subtitle: 'نغمة الهاتف القياسية القصيرة دون أذان',
              icon: Icons.notifications_active_rounded,
            ),
            const SizedBox(height: AppSpace.xs),
            _buildModePill(
              context: context,
              palette: palette,
              textTheme: textTheme,
              mode: PrayerNotificationMode.silent,
              title: 'إشعار صامت مرئي',
              subtitle: 'ظهور إشعار الصلاة على الشاشة بدون أي صوت',
              icon: Icons.notifications_none_rounded,
            ),

            const SizedBox(height: AppSpace.lg),

            // ── Muezzin Selector (When Adhan or Takbeer active) ───────────
            if (settings.defaultMode == PrayerNotificationMode.adhan ||
                settings.defaultMode == PrayerNotificationMode.takbeer) ...[
              DropdownButtonFormField<AdhanSound>(
                initialValue: settings.sound,
                style: textTheme.body.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'صوت المؤذن',
                  labelStyle: textTheme.bodySmall.copyWith(
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
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AdhanSound.makkah,
                    child: Text('أذان الحرم المكي الشريف'),
                  ),
                  DropdownMenuItem(
                    value: AdhanSound.madinah,
                    child: Text('أذان المسجد النبوي الشريف'),
                  ),
                  DropdownMenuItem(
                    value: AdhanSound.takbeer,
                    child: Text('تكبيرات الأذان (تنبيه موجز)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    onSettingsChanged(settings.copyWith(sound: val));
                  }
                },
              ),
              const SizedBox(height: AppSpace.md),
            ],

            // ── Volume Slider ───────────────────────────────────────────
            if (settings.defaultMode != PrayerNotificationMode.silent) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مستوى صوت الأذان والتنبيه',
                        style: textTheme.bodySmall.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      Text(
                        '${settings.volume.toInt()}%',
                        style: textTheme.label.copyWith(
                          fontWeight: FontWeight.bold,
                          color: palette.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
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
            ],

            // ── Comprehensive Testing Bench (Audio + Instant + 5s Outside App) ──
            PrayerNotificationTester(
              settings: settings,
              adhanService: adhanService,
            ),

            const SizedBox(height: AppSpace.lg),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: AppSpace.md),

            // ── Per-Prayer Customization Section ────────────────────────
            Text(
              'تخصيص التنبيه لكل صلاة',
              style: textTheme.label.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'يمكنك اختيار نمط مختلف لكل فريضة (مثل أذان للفجر وتنبيه صامت للظهر)',
              style: textTheme.caption.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: AppSpace.md),

            ...AdhanSettingsService.prayerNames.map((name) {
              if (name.contains('الشروق')) return const SizedBox.shrink();
              final currentPrayerMode = settings.modeForPrayer(name);

              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        name,
                        style: textTheme.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                      const Spacer(),
                      DropdownButton<PrayerNotificationMode>(
                        value: currentPrayerMode,
                        underline: const SizedBox.shrink(),
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: palette.primary,
                        ),
                        dropdownColor: palette.surfaceRaised,
                        style: textTheme.caption.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (newMode) {
                          if (newMode == null) return;
                          HapticFeedback.selectionClick();
                          final updatedModes =
                              Map<String, PrayerNotificationMode>.from(
                            settings.prayerModes,
                          );
                          updatedModes[name] = newMode;
                          onSettingsChanged(
                            settings.copyWith(prayerModes: updatedModes),
                          );
                        },
                        items: const [
                          DropdownMenuItem(
                            value: PrayerNotificationMode.adhan,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('أذان كامل'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: PrayerNotificationMode.takbeer,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('تنبيه موجز'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: PrayerNotificationMode.tone,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('نغمة هادئة'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: PrayerNotificationMode.silent,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('إشعار صامت'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: PrayerNotificationMode.off,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('إيقاف التنبيه'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildModePill({
    required BuildContext context,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required PrayerNotificationMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = settings.defaultMode == mode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.mdRadius,
        onTap: () {
          HapticFeedback.selectionClick();
          onSettingsChanged(
            settings.copyWith(
              defaultMode: mode,
              silentNotifications: mode == PrayerNotificationMode.silent,
            ),
          );
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? palette.primarySoft : palette.surfaceRaised,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: isSelected ? palette.primary : palette.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? palette.primary : palette.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppIcon.sm,
                  color: isSelected ? palette.onPrimary : palette.textMuted,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? palette.primary : palette.text,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      subtitle,
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: palette.primary,
                  size: AppIcon.sm,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
