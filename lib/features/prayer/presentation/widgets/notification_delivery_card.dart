import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/prayer_schedule_service.dart';
import '../../../../shared/widgets/app_card.dart';

/// Shows the Android notification and exact-alarm state, with repair actions
/// so people can restore device-level delivery settings themselves.
class NotificationDeliveryCard extends StatefulWidget {
  final AdhanSettings settings;

  const NotificationDeliveryCard({super.key, required this.settings});

  @override
  State<NotificationDeliveryCard> createState() =>
      _NotificationDeliveryCardState();
}

class _NotificationDeliveryCardState extends State<NotificationDeliveryCard>
    with WidgetsBindingObserver {
  final NotificationService _notifications = NotificationService();
  NotificationDeliveryHealth? _health;
  bool _loading = true;
  bool _working = false;
  String? _message;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshHealth();
  }

  @override
  void didUpdateWidget(covariant NotificationDeliveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) _refreshHealth();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshHealth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshHealth() async {
    if (!_isAndroid) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final health = await _notifications.getDeliveryHealth(widget.settings);
      if (!mounted) return;
      setState(() {
        _health = health;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _health = null;
        _loading = false;
        _message = 'تعذر قراءة حالة التنبيهات: $error';
      });
    }
  }

  Future<void> _repairAndReschedule() async {
    if (_working) return;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      await _notifications.requestPermissions();
      final result = await PrayerScheduleService().refreshSchedulesIfNeeded(
        force: true,
      );
      if (mounted) {
        setState(() {
          _message = result.failed == 0
              ? 'تم تحديث جدولة التنبيهات. راجع أذونات التطبيق والقنوات أدناه.'
              : 'تمت المحاولة مع ${result.failed} أخطاء في الجدولة.';
        });
      }
      await _refreshHealth();
    } catch (error) {
      if (mounted) setState(() => _message = 'تعذر تحديث الجدولة: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final actionStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(AppSize.tap, AppSize.tap),
      tapTargetSize: MaterialTapTargetSize.padded,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: palette.primary,
                size: AppIcon.md,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'حالة وصول التنبيهات',
                  style: text.bodyBold.copyWith(color: palette.text),
                ),
              ),
              IconButton(
                tooltip: 'تحديث حالة التنبيهات',
                onPressed: _loading ? null : _refreshHealth,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          if (!_isAndroid)
            Text(
              'تفاصيل أذونات التنبيه الدقيق وقنوات Android متاحة على أجهزة Android فقط.',
              style: text.caption.copyWith(color: palette.textMuted),
            )
          else if (_loading)
            const LinearProgressIndicator()
          else if (_health != null) ...[
            _HealthRow(
              label: 'إذن الإشعارات',
              value: _health!.notificationsAllowed == true
                  ? 'مسموح'
                  : 'غير مسموح',
              good: _health!.notificationsAllowed == true,
            ),
            _HealthRow(
              label: 'التنبيه في الوقت الدقيق',
              value: _health!.exactAlarmsAllowed == true
                  ? 'مسموح'
                  : _health!.exactAlarmsAllowed == false
                  ? 'قد يتأخر'
                  : 'غير متاح',
              good: _health!.exactAlarmsAllowed == true,
            ),
            _HealthRow(
              label: 'قنوات الصلاة والأذكار',
              value: _channelSummary(_health!),
              good: !_health!.hasChannelProblems,
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          Text(
            'قد يظل وضع الصامت أو عدم الإزعاج أو إعدادات القنوات وتوفير البطارية قادراً على كتم التنبيه أو تأخيره.',
            style: text.caption.copyWith(color: palette.textMuted),
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(_message!, style: text.caption.copyWith(color: palette.text)),
          ],
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              OutlinedButton.icon(
                style: actionStyle,
                onPressed: _working || !_isAndroid
                    ? null
                    : _repairAndReschedule,
                icon: _working
                    ? const SizedBox(
                        width: AppIcon.xs,
                        height: AppIcon.xs,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.build_circle_outlined),
                label: const Text('إصلاح الأذونات والجدولة'),
              ),
              OutlinedButton.icon(
                style: actionStyle,
                onPressed: _working || !_isAndroid ? null : _openSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('إعدادات التطبيق'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _channelSummary(NotificationDeliveryHealth health) {
    final issueChannels = {
      ...health.missingChannelIds,
      ...health.blockedChannelIds,
      ...health.lowImportanceChannelIds,
      ...health.silentChannelIds,
    };
    return issueChannels.isEmpty
        ? 'مهيأة'
        : '${issueChannels.length} قناة تحتاج مراجعة';
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final bool good;

  const _HealthRow({
    required this.label,
    required this.value,
    required this.good,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tap),
      child: Row(
        children: [
          Icon(
            good ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: good ? palette.success : palette.error,
            size: AppIcon.sm,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              label,
              style: context.text.caption.copyWith(color: palette.text),
            ),
          ),
          Text(
            value,
            style: context.text.caption.copyWith(
              color: good ? palette.success : palette.error,
            ),
          ),
        ],
      ),
    );
  }
}
