import 'package:flutter/material.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/services/adhan_service.dart';
import '../../../core/services/adhan_settings_service.dart';

class PrayerSettingsSheet extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const PrayerSettingsSheet({super.key, this.onSettingsChanged});

  @override
  State<PrayerSettingsSheet> createState() => _PrayerSettingsSheetState();
}

class _PrayerSettingsSheetState extends State<PrayerSettingsSheet> {
  final AdhanSettingsService _settingsService = AdhanSettingsService();
  final AdhanService _adhanService = AdhanService();

  AdhanSettings? _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _adhanService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _settingsService.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(AdhanSettings settings) async {
    await _settingsService.saveSettings(settings);
    widget.onSettingsChanged?.call();
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _settings == null) {
      return const SizedBox(height: 240);
    }

    final settings = _settings!;
    final enabledCount = settings.prayerToggles.values
        .where((value) => value)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إعدادات الأذان', style: AppText.heading),
          const SizedBox(height: 6),
          Text(
            'مفعّل $enabledCount من ${AdhanSettingsService.prayerNames.length}',
            style: AppText.caption,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تفعيل الأذان', style: AppText.body),
            value: settings.enabled,
            onChanged: (value) {
              _save(settings.copyWith(enabled: value));
            },
          ),
          const SizedBox(height: 8),
          Text('تفعيل لكل صلاة', style: AppText.bodyMuted),
          const SizedBox(height: 8),
          ...AdhanSettingsService.prayerNames.map((name) {
            final enabled = settings.isPrayerEnabled(name);
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name, style: AppText.body),
              value: enabled,
              onChanged: (value) {
                final updated = Map<String, bool>.from(settings.prayerToggles);
                updated[name] = value;
                _save(settings.copyWith(prayerToggles: updated));
              },
            );
          }),
          const SizedBox(height: 8),
          Text('اختيار الأذان', style: AppText.bodyMuted),
          const SizedBox(height: 8),
          RadioGroup<AdhanSound>(
            groupValue: settings.sound,
            onChanged: (value) {
              if (!settings.enabled || value == null) return;
              _save(settings.copyWith(sound: value));
            },
            child: Column(
              children: const [
                RadioListTile<AdhanSound>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('مكة', style: AppText.body),
                  value: AdhanSound.makkah,
                ),
                RadioListTile<AdhanSound>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('المدينة', style: AppText.body),
                  value: AdhanSound.madinah,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('إشعارات صامتة فقط', style: AppText.body),
            value: settings.silentNotifications,
            onChanged: (value) {
              _save(settings.copyWith(silentNotifications: value));
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                await _adhanService.test(settings.sound);
              },
              child: const Text('تشغيل الأذان للتجربة'),
            ),
          ),
        ],
      ),
    );
  }
}
