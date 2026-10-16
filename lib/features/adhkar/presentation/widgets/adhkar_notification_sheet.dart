import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhkar_reminder_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';

class AdhkarNotificationSheet extends StatefulWidget {
  const AdhkarNotificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.85,
      builder: (sheetContext) => const AdhkarNotificationSheet(),
    );
  }

  @override
  State<AdhkarNotificationSheet> createState() =>
      _AdhkarNotificationSheetState();
}

class _AdhkarNotificationSheetState extends State<AdhkarNotificationSheet> {
  final AdhkarReminderService _service = AdhkarReminderService();
  AdhkarReminderSettings _settings = const AdhkarReminderSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.getSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings(AdhkarReminderSettings newSettings) async {
    setState(() => _settings = newSettings);
    await _service.saveSettings(newSettings);
    HapticFeedback.selectionClick();
  }

  Future<void> _pickTime({
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    HapticFeedback.lightImpact();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      onSelected(picked);
      if (mounted) {
        AppSnackbar.success(
          context,
          'تم تحديث موعد التنبيه إلى ${_formatTime(picked)}',
          duration: AppMotion.toastShort,
          hasNavBar: true,
        );
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.goldSoft,
                  border: Border.all(color: palette.gold.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: AppIcon.sm,
                    color: palette.gold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تنبيهات الأذكار اليومية',
                      style: textTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                    ),
                    Text(
                      'تذكير بأذكار الصباح والمساء والنوم في أوقاتها المسنونة',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpace.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // ── 1. Morning Adhkar Card ──
            _ReminderCard(
              title: 'أذكار الصباح',
              subtitle: 'الموعد المقترح: بعد صلاة الفجر',
              icon: Icons.wb_sunny_rounded,
              iconColor: palette.adhkarCategory('morning').fg,
              iconBgColor: palette.adhkarCategory('morning').bg,
              isEnabled: _settings.morningEnabled,
              timeLabel: _formatTime(_settings.morningTime),
              onToggle: (enabled) {
                _updateSettings(_settings.copyWith(morningEnabled: enabled));
              },
              onPickTime: () {
                _pickTime(
                  initialTime: _settings.morningTime,
                  onSelected: (t) {
                    _updateSettings(_settings.copyWith(
                      morningHour: t.hour,
                      morningMinute: t.minute,
                      morningEnabled: true,
                    ));
                  },
                );
              },
            ),
            const SizedBox(height: AppSpace.sm),

            // ── 2. Evening Adhkar Card ──
            _ReminderCard(
              title: 'أذكار المساء',
              subtitle: 'الموعد المقترح: بعد صلاة العصر إلى الغروب',
              icon: Icons.wb_twilight_rounded,
              iconColor: palette.adhkarCategory('evening').fg,
              iconBgColor: palette.adhkarCategory('evening').bg,
              isEnabled: _settings.eveningEnabled,
              timeLabel: _formatTime(_settings.eveningTime),
              onToggle: (enabled) {
                _updateSettings(_settings.copyWith(eveningEnabled: enabled));
              },
              onPickTime: () {
                _pickTime(
                  initialTime: _settings.eveningTime,
                  onSelected: (t) {
                    _updateSettings(_settings.copyWith(
                      eveningHour: t.hour,
                      eveningMinute: t.minute,
                      eveningEnabled: true,
                    ));
                  },
                );
              },
            ),
            const SizedBox(height: AppSpace.sm),

            // ── 3. Sleep Adhkar Card ──
            _ReminderCard(
              title: 'أذكار النوم',
              subtitle: 'الموعد المقترح: عند الإيواء إلى الفراش ليلاً',
              icon: Icons.bedtime_rounded,
              iconColor: palette.adhkarCategory('sleeping').fg,
              iconBgColor: palette.adhkarCategory('sleeping').bg,
              isEnabled: _settings.sleepEnabled,
              timeLabel: _formatTime(_settings.sleepTime),
              onToggle: (enabled) {
                _updateSettings(_settings.copyWith(sleepEnabled: enabled));
              },
              onPickTime: () {
                _pickTime(
                  initialTime: _settings.sleepTime,
                  onSelected: (t) {
                    _updateSettings(_settings.copyWith(
                      sleepHour: t.hour,
                      sleepMinute: t.minute,
                      sleepEnabled: true,
                    ));
                  },
                );
              },
            ),
            const SizedBox(height: AppSpace.lg),

            // ── Action Button ──
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'تم الحفظ والتفعيل',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.md,
                icon: Icons.check_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isEnabled;
  final String timeLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  const _ReminderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.isEnabled,
    required this.timeLabel,
    required this.onToggle,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      color: isEnabled ? palette.surface : palette.surfaceMuted,
      border: Border.all(
        color: palette.border,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? iconBgColor : palette.surface,
              border: Border.all(
                color: isEnabled
                    ? iconColor.withValues(alpha: 0.3)
                    : palette.border,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: AppIcon.xs,
                color: isEnabled ? iconColor : palette.textMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? palette.text : palette.textMuted,
                  ),
                ),
                Text(
                  subtitle,
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Time Picker Chip
          InkWell(
            onTap: isEnabled ? onPickTime : null,
            borderRadius: AppRadius.smRadius,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xxs,
              ),
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: isEnabled ? palette.surfaceRaised : palette.surface,
                  borderRadius: AppRadius.smRadius,
                  border: Border.all(
                    color: isEnabled ? palette.gold : palette.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: AppIcon.xs,
                      color: isEnabled ? palette.gold : palette.textMuted,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    Text(
                      timeLabel,
                      style: textTheme.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? palette.gold : palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Toggle Switch
          Switch(
            value: isEnabled,
            activeThumbColor: palette.primary,
            activeTrackColor: palette.primarySoft,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
