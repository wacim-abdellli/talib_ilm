import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_service.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../core/services/flip_to_stop_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'iqama_interval_settings.dart';
import 'prayer_notification_mode_pill.dart';

class PrayerAdhanSection extends StatefulWidget {
  final AdhanSettings settings;
  final bool isDark;
  final AdhanService adhanService;
  final ValueChanged<AdhanSettings> onSettingsChanged;
  final VoidCallback? onOpenVoicesTab;

  const PrayerAdhanSection({
    super.key,
    required this.settings,
    required this.isDark,
    required this.adhanService,
    required this.onSettingsChanged,
    this.onOpenVoicesTab,
  });

  @override
  State<PrayerAdhanSection> createState() => _PrayerAdhanSectionState();
}

class _PrayerAdhanSectionState extends State<PrayerAdhanSection> {
  PrayerNotificationMode? _previewingMode;

  String _muezzinNameFor(AdhanSound sound) {
    switch (sound) {
      case AdhanSound.qatami:
        return 'الشيخ ناصر القطامي';
      case AdhanSound.makkah:
        return 'الحرم المكي الشريف (علي ملا)';
      case AdhanSound.madinah:
        return 'المسجد النبوي (عصام بخاري)';
      case AdhanSound.alafasy:
        return 'الشيخ مشاري العفاسي';
      case AdhanSound.abdulbasit:
        return 'الشيخ عبد الباسط عبد الصمد';
      case AdhanSound.aqsa:
        return 'المسجد الأقصى (ناجي قزاز)';
      case AdhanSound.takbeer:
        return 'تكبيرات الأذان فقط';
    }
  }

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
    final onSettingsChanged = widget.onSettingsChanged;
    final palette = context.palette;
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.md),

        // ── 1. Master Enable Card ─────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSize.tap),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: settings.enabled
                            ? palette.primarySoft
                            : palette.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        settings.enabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        color: settings.enabled
                            ? palette.primary
                            : palette.textMuted,
                        size: AppIcon.sm,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
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
                            'إطلاق الأذان والتنبيهات عند دخول وقت كل صلاة',
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
            ],
          ),
        ),

        if (settings.enabled) ...[
          const SizedBox(height: AppSpace.md),

          // ── 2. Current Voice Summary Card ──────────────────────────
          if (settings.defaultMode == PrayerNotificationMode.adhan)
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: palette.primary,
                      size: AppIcon.sm,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المؤذن المختار للأذان',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                        Text(
                          _muezzinNameFor(settings.effectiveMuezzinSound),
                          style: textTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: palette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onOpenVoicesTab != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: palette.primarySoft,
                        foregroundColor: palette.primary,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xs,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.pillRadius,
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: AppIcon.xs),
                      label: const Text('تغيير المؤذن'),
                      onPressed: widget.onOpenVoicesTab,
                    ),
                ],
              ),
            ),

          const SizedBox(height: AppSpace.md),

          // ── 3. Default Notification Mode Selection ──────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'نمط التنبيه الافتراضي',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'اختر النمط الأساسي لتنبيهات الصلاة:',
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                ),
                const SizedBox(height: AppSpace.md),
                _buildModePill(
                  palette: palette,
                  textTheme: textTheme,
                  mode: PrayerNotificationMode.adhan,
                  title: 'أذان كامل',
                  subtitle: 'سماع صوت الأذان كاملاً عند دخول وقت الصلاة',
                  icon: Icons.mosque_rounded,
                ),
                const SizedBox(height: AppSpace.xs),
                _buildModePill(
                  palette: palette,
                  textTheme: textTheme,
                  mode: PrayerNotificationMode.takbeer,
                  title: 'تكبيرات فقط',
                  subtitle: 'تكبيرات الأذان فقط (الله أكبر، الله أكبر)',
                  icon: Icons.campaign_rounded,
                ),
                const SizedBox(height: AppSpace.xs),
                _buildModePill(
                  palette: palette,
                  textTheme: textTheme,
                  mode: PrayerNotificationMode.announcement,
                  title: 'نداء وقت الصلاة',
                  subtitle: 'نداء صوتي وقور: "حان الآن وقت صلاة..."',
                  icon: Icons.record_voice_over_rounded,
                ),
                const SizedBox(height: AppSpace.xs),
                _buildModePill(
                  palette: palette,
                  textTheme: textTheme,
                  mode: PrayerNotificationMode.tone,
                  title: 'نغمة تنبيه هادئة',
                  subtitle: 'نغمة الهاتف القياسية القصيرة دون أذان',
                  icon: Icons.notifications_active_rounded,
                ),
                const SizedBox(height: AppSpace.xs),
                _buildModePill(
                  palette: palette,
                  textTheme: textTheme,
                  mode: PrayerNotificationMode.silent,
                  title: 'إشعار صامت مرئي',
                  subtitle: 'ظهور إشعار الصلاة على الشاشة بدون صوت',
                  icon: Icons.notifications_none_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.md),

          // ── 4. Per-Prayer Customization ─────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'تخصيص التنبيه لكل صلاة',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'يمكنك اختيار نمط مستقل لكل صلاة (مثل أذان للفجر وتنبيه صامت للظهر)',
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                ),
                const SizedBox(height: AppSpace.md),
                ...AdhanSettingsService.prayerNames.map((name) {
                  if (name.contains('الشروق')) return const SizedBox.shrink();
                  final currentMode = settings.modeForPrayer(name);

                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpace.xs,
                    ),
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
                            value: currentMode,
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
                                child: Text('أذان كامل'),
                              ),
                              DropdownMenuItem(
                                value: PrayerNotificationMode.takbeer,
                                child: Text('تكبيرات فقط'),
                              ),
                              DropdownMenuItem(
                                value: PrayerNotificationMode.announcement,
                                child: Text('نداء الصلاة'),
                              ),
                              DropdownMenuItem(
                                value: PrayerNotificationMode.tone,
                                child: Text('نغمة هادئة'),
                              ),
                              DropdownMenuItem(
                                value: PrayerNotificationMode.silent,
                                child: Text('إشعار صامت'),
                              ),
                              DropdownMenuItem(
                                value: PrayerNotificationMode.off,
                                child: Text('إيقاف التنبيه'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.md),

          // ── 5. Advanced Notification Reminders ──────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'خيارات التنبيه المتقدمة',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpace.md),

                // Notify before slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'التنبيه قبل دخول الوقت',
                        style: textTheme.bodyBold.copyWith(
                          color: palette.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      '${settings.notifyBeforeMinutes.toInt()} دقيقة',
                      style: textTheme.labelBold.copyWith(
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: palette.primary,
                    inactiveTrackColor: palette.border,
                    thumbColor: palette.primary,
                    overlayColor: palette.primarySoft,
                  ),
                  child: Slider(
                    value: settings.notifyBeforeMinutes,
                    min: 5,
                    max: 30,
                    divisions: 5,
                    onChanged: (val) {
                      onSettingsChanged(
                        settings.copyWith(notifyBeforeMinutes: val),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpace.md),
                Divider(color: palette.border, height: 1),
                const SizedBox(height: AppSpace.md),

                // Iqama toggle
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSize.tap),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تذكير الإقامة',
                              style: textTheme.bodyBold.copyWith(
                                color: palette.text,
                              ),
                            ),
                            Text(
                              'إشعار تذكيري عند موعد الإقامة الذي تضبطه لكل صلاة',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.iqamaReminders,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          onSettingsChanged(
                            settings.copyWith(iqamaReminders: val),
                          );
                        },
                        activeThumbColor: palette.primary,
                        activeTrackColor: palette.primarySoft,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.sm),
                IqamaIntervalSettings(
                  settings: settings,
                  onSettingsChanged: onSettingsChanged,
                ),

                const SizedBox(height: AppSpace.md),
                Divider(color: palette.border, height: 1),
                const SizedBox(height: AppSpace.md),

                // Flip to stop toggle
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSize.tap),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'قلب الهاتف لكتم الصوت والأذان',
                              style: textTheme.bodyBold.copyWith(
                                color: palette.text,
                              ),
                            ),
                            Text(
                              'عند وضع الهاتف مقلوباً (الشاشة لأسفل) يتم إيقاف الأذان فوراً',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: FlipToStopService().isEnabled,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            FlipToStopService().setEnabled(val);
                          });
                        },
                        activeThumbColor: palette.primary,
                        activeTrackColor: palette.primarySoft,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModePill({
    required AppPalette palette,
    required AppTextTheme textTheme,
    required PrayerNotificationMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return PrayerNotificationModePill(
      palette: palette,
      textTheme: textTheme,
      settings: widget.settings,
      adhanService: widget.adhanService,
      mode: mode,
      title: title,
      subtitle: subtitle,
      icon: icon,
      previewingMode: _previewingMode,
      onSettingsChanged: widget.onSettingsChanged,
      onTogglePreview: _togglePreviewMode,
    );
  }
}
