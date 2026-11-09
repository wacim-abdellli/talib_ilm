import 'dart:async';
import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/services/dhikr_moment_service.dart';

class DhikrMomentSettingsSheet {
  static Future<void> show(BuildContext context) async {
    final settings = await DhikrMomentService.load();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DhikrMomentSettingsForm(initialSettings: settings),
    );
  }
}

class _DhikrMomentSettingsForm extends StatefulWidget {
  final DhikrMomentSettings initialSettings;

  const _DhikrMomentSettingsForm({required this.initialSettings});

  @override
  State<_DhikrMomentSettingsForm> createState() =>
      _DhikrMomentSettingsFormState();
}

class _DhikrMomentSettingsFormState extends State<_DhikrMomentSettingsForm>
    with WidgetsBindingObserver {
  late DhikrMomentSettings _settings = widget.initialSettings;
  bool _overlayPermission = false;
  bool _checkingPermission = true;
  bool _waitingForSettings = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshOverlayPermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_waitingForSettings) {
        unawaited(_completeOverlayPermissionRequest());
      } else if (DhikrMomentService.supportsFloatingOverlay) {
        unawaited(_refreshOverlayPermission());
      }
    }
  }

  Future<void> _refreshOverlayPermission() async {
    final allowed = await DhikrMomentService.hasOverlayPermission();
    if (!mounted) return;
    final wasEnabled = _settings.enabled;
    setState(() {
      _overlayPermission = allowed;
      _checkingPermission = false;
      if (!allowed && DhikrMomentService.supportsFloatingOverlay) {
        _settings = _settings.copyWith(enabled: false);
      }
    });
    if (!allowed && wasEnabled && DhikrMomentService.supportsFloatingOverlay) {
      try {
        await DhikrMomentService.save(_settings);
      } catch (_) {}
    }
  }

  Future<void> _onEnabledChanged(bool enabled) async {
    if (_saving || _waitingForSettings) return;
    if (enabled &&
        DhikrMomentService.supportsFloatingOverlay &&
        !_overlayPermission) {
      setState(() => _waitingForSettings = true);
      final opened = await DhikrMomentService.requestOverlayPermission();
      if (!opened && mounted && _waitingForSettings) {
        setState(() => _waitingForSettings = false);
        _showMessage('تعذر فتح إعداد إذن الظهور فوق التطبيقات.');
      }
      return;
    }
    await _saveEnabled(enabled);
  }

  Future<void> _completeOverlayPermissionRequest() async {
    final allowed = await DhikrMomentService.hasOverlayPermission();
    if (!mounted) return;
    setState(() {
      _waitingForSettings = false;
      _overlayPermission = allowed;
    });
    if (allowed) {
      await _saveEnabled(true);
    } else {
      if (_settings.enabled) await _saveEnabled(false);
      _showMessage(
        'لم يُمنح إذن الظهور فوق التطبيقات؛ بقيت لحظة الذكر متوقفة.',
      );
    }
  }

  Future<void> _saveEnabled(bool enabled) async {
    final updated = _settings.copyWith(enabled: enabled);
    setState(() {
      _settings = updated;
      _saving = true;
    });
    var ready = false;
    try {
      ready = await DhikrMomentService.save(updated);
    } catch (_) {
      ready = false;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!ready) _settings = _settings.copyWith(enabled: !enabled);
    });
    if (!ready) {
      try {
        await DhikrMomentService.save(updated.copyWith(enabled: false));
      } catch (_) {}
      if (!mounted) return;
      _showMessage(
        enabled
            ? 'تعذر تفعيل لحظة الذكر. تحقق من الإذن والوقت المحدد.'
            : 'تعذر إيقاف لحظة الذكر. حاول مرة أخرى.',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickWindowTime(bool isStart) async {
    final minutes = isStart ? _settings.startMinutes : _settings.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null || !mounted) return;
    final value = picked.hour * 60 + picked.minute;
    setState(() {
      _settings = isStart
          ? _settings.copyWith(startMinutes: value)
          : _settings.copyWith(endMinutes: value);
    });
  }

  Future<void> _saveSettings() async {
    if (_settings.endMinutes <= _settings.startMinutes) {
      _showMessage('اختر وقت انتهاء بعد وقت البدء.');
      return;
    }
    setState(() => _saving = true);
    var ready = false;
    try {
      ready = await DhikrMomentService.save(_settings);
    } catch (_) {
      ready = false;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    if (!ready && mounted) {
      _showMessage(
        'حُفظت الإعدادات، لكن تعذر تفعيل التذكيرات. تحقق من الأذونات.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewFor(_settings.content);
    final colors = Theme.of(context).colorScheme;
    final helperText = _checkingPermission
        ? 'جارٍ التحقق من الإذن...'
        : DhikrMomentService.supportsFloatingOverlay
        ? _waitingForSettings
              ? 'افتح إذن الظهور فوق التطبيقات ثم عُد إلى هنا'
              : !_overlayPermission
              ? 'يتطلب عرض البطاقة إذن الظهور فوق التطبيقات على Android'
              : 'اختر ما تحب أن يذكّرك به يومك'
        : 'على iPhone تصل كتذكيرات مجدولة، ولا تظهر فوق التطبيقات.';

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Icon(Icons.spa_rounded, color: colors.primary),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لحظة ذكر',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          helperText,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value:
                        _settings.enabled &&
                        (!DhikrMomentService.supportsFloatingOverlay ||
                            _overlayPermission),
                    onChanged:
                        _checkingPermission || _saving || _waitingForSettings
                        ? null
                        : _onEnabledChanged,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPreview(context, colors, preview),
                      const SizedBox(height: AppSpace.lg),
                      Text(
                        'ماذا تريد أن يظهر؟',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        'اختر نوعاً واحداً أو اترك المحتوى متنوعاً تلقائياً.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      _buildContentOptions(context),
                      const SizedBox(height: AppSpace.lg),
                      Text(
                        'متى تحب أن تراها؟',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        'حتى ${_settings.timesPerDay} ${_settings.timesPerDay == 1 ? 'مرة' : 'مرات'} خلال الفترة التي تختارها',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Slider(
                          value: _settings.timesPerDay.toDouble(),
                          min: 1,
                          max: DhikrMomentService.maxAppearancesPerDay
                              .toDouble(),
                          divisions:
                              DhikrMomentService.maxAppearancesPerDay - 1,
                          label: '${_settings.timesPerDay}',
                          onChanged: (value) => setState(
                            () => _settings = _settings.copyWith(
                              timesPerDay: value.round(),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickWindowTime(true),
                              icon: const Icon(Icons.wb_sunny_outlined),
                              label: Text(
                                'من ${_formatMomentTime(_settings.startMinutes)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickWindowTime(false),
                              icon: const Icon(Icons.nights_stay_outlined),
                              label: Text(
                                'إلى ${_formatMomentTime(_settings.endMinutes)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!DhikrMomentService.supportsFloatingOverlay) ...[
                        const SizedBox(height: AppSpace.md),
                        Text(
                          'ستصل التذكيرات حسب أوقاتك المختارة وإعدادات إشعارات iPhone.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              FilledButton.icon(
                onPressed: _saving || _waitingForSettings
                    ? null
                    : _saveSettings,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: AppIcon.sm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('حفظ لحظة الذكر'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    ColorScheme colors,
    (String, String) preview,
  ) => Container(
    padding: const EdgeInsets.all(AppSpace.lg),
    decoration: BoxDecoration(
      color: colors.primary,
      borderRadius: AppRadius.lgRadius,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _settings.content == DhikrMomentContent.mixed
              ? 'لَحْظَةٌ لِقَلْبِكَ'
              : 'مِثَالٌ عَلَى الْبِطَاقَة',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.onPrimary.withValues(alpha: .78),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          preview.$1,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.onPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          preview.$2,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onPrimary.withValues(alpha: .82),
          ),
        ),
      ],
    ),
  );

  Widget _buildContentOptions(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpace.sm) / 2;
        return Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final option in DhikrMomentContent.values)
              SizedBox(
                width: itemWidth,
                child: _ContentOptionTile(
                  icon: _iconFor(option),
                  label: _labelFor(option),
                  selected: _settings.content == option,
                  onTap: () => setState(
                    () => _settings = _settings.copyWith(content: option),
                  ),
                  colors: colors,
                ),
              ),
          ],
        );
      },
    );
  }

  static (String, String) _previewFor(
    DhikrMomentContent content,
  ) => switch (content) {
    DhikrMomentContent.names => ('الرَّحْمَنُ', 'واسع الرحمة بخلقه'),
    DhikrMomentContent.adhkar => (
      'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      'تنزيهٌ لله وحمدٌ له',
    ),
    DhikrMomentContent.duas => ('رَبِّ زِدْنِي عِلْمًا', 'دعاءٌ قرآني قصير'),
    DhikrMomentContent.quran => ('إِنَّ مَعَ الْعُسْرِ يُسْرًا', 'الشرح • ٦'),
    DhikrMomentContent.hadith => (
      'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
      'صحيح البخاري • ١',
    ),
    DhikrMomentContent.mixed => (
      'تذكيرٌ يتجدد خلال يومك',
      'ذكر • دعاء • آية • حديث',
    ),
  };

  static IconData _iconFor(DhikrMomentContent content) => switch (content) {
    DhikrMomentContent.names => Icons.auto_awesome_rounded,
    DhikrMomentContent.adhkar => Icons.favorite_rounded,
    DhikrMomentContent.duas => Icons.volunteer_activism_rounded,
    DhikrMomentContent.quran => Icons.menu_book_rounded,
    DhikrMomentContent.hadith => Icons.format_quote_rounded,
    DhikrMomentContent.mixed => Icons.shuffle_rounded,
  };

  static String _labelFor(DhikrMomentContent content) => switch (content) {
    DhikrMomentContent.mixed => 'متنوع تلقائياً',
    DhikrMomentContent.adhkar => 'الأذكار',
    DhikrMomentContent.names => 'أسماء الله',
    DhikrMomentContent.duas => 'أدعية',
    DhikrMomentContent.quran => 'آيات قرآنية',
    DhikrMomentContent.hadith => 'من السنة',
  };

  static String _formatMomentTime(int minutes) {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    final period = hour < 12 ? 'ص' : 'م';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class _ContentOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colors;

  const _ContentOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? colors.primaryContainer : colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.mdRadius,
      side: BorderSide(
        color: selected ? colors.primary : colors.outline,
        width: selected ? 1.5 : 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.lg,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppIcon.sm,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: AppIcon.sm,
                  color: colors.primary,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
