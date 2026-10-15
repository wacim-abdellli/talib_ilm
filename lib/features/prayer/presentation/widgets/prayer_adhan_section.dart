import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_service.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'prayer_muezzin_selector.dart';

class PrayerAdhanSection extends StatefulWidget {
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
  State<PrayerAdhanSection> createState() => _PrayerAdhanSectionState();
}

class _PrayerAdhanSectionState extends State<PrayerAdhanSection> {
  PrayerNotificationMode? _previewingMode;

  Future<void> _togglePreviewMode(PrayerNotificationMode mode) async {
    HapticFeedback.lightImpact();
    if (_previewingMode == mode && widget.adhanService.isPlaying) {
      await widget.adhanService.stop();
      if (mounted) setState(() => _previewingMode = null);
      return;
    }

    if (mounted) setState(() => _previewingMode = mode);
    await widget.adhanService.test(
      sound: widget.settings.sound,
      mode: mode,
      volume: widget.settings.volume,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final adhanService = widget.adhanService;
    final onSettingsChanged = widget.onSettingsChanged;
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
              title: 'تكبيرات فقط',
              subtitle: 'تكبيرات الأذان فقط (الله أكبر، الله أكبر) دون الأذان كاملاً',
              icon: Icons.campaign_rounded,
            ),
            const SizedBox(height: AppSpace.xs),
            _buildModePill(
              context: context,
              palette: palette,
              textTheme: textTheme,
              mode: PrayerNotificationMode.announcement,
              title: 'نداء وقت الصلاة',
              subtitle: 'نداء صوتي وقور: "حان الآن وقت صلاة الفجر / الظهر / ..."',
              icon: Icons.record_voice_over_rounded,
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

            // ── Muezzin Selector (When Adhan active) ─────────────────────
            if (settings.defaultMode == PrayerNotificationMode.adhan) ...[
              PrayerMuezzinSelector(
                settings: settings,
                adhanService: adhanService,
                onSettingsChanged: onSettingsChanged,
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
                              adhanService.setVolume(val);
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
                                Text('تكبيرات فقط'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: PrayerNotificationMode.announcement,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('نداء الصلاة'),
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
    final isSelected = widget.settings.defaultMode == mode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.mdRadius,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onSettingsChanged(
            widget.settings.copyWith(
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
              if (mode == PrayerNotificationMode.takbeer ||
                  mode == PrayerNotificationMode.announcement) ...[
                const SizedBox(width: AppSpace.xs),
                StreamBuilder<PlayerState>(
                  stream: widget.adhanService.playerStateStream,
                  builder: (context, _) {
                    final isAudioActive =
                        widget.adhanService.isPlaying && _previewingMode == mode;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _togglePreviewMode(mode),
                        borderRadius: AppRadius.smRadius,
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: isAudioActive
                                ? palette.primary
                                : palette.surface,
                            borderRadius: AppRadius.smRadius,
                            border: Border.all(
                              color: palette.primary,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAudioActive
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                size: AppIcon.xs,
                                color: isAudioActive
                                    ? palette.onPrimary
                                    : palette.primary,
                              ),
                              const SizedBox(width: AppSpace.xxs),
                              Text(
                                isAudioActive ? 'إيقاف' : 'استمع',
                                style: textTheme.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isAudioActive
                                      ? palette.onPrimary
                                      : palette.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (isSelected) ...[
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.check_circle_rounded,
                  color: palette.primary,
                  size: AppIcon.sm,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
