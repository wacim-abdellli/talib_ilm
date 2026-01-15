import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
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
      return const SizedBox(height: AppUi.sheetPlaceholderHeight);
    }

    final settings = _settings!;
    final enabledCount = settings.prayerToggles.values
        .where((value) => value)
        .length;

    return Padding(
      padding: AppUi.screenPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.adhanSettingsTitle, style: AppText.heading),
          const SizedBox(height: AppUi.gapXSPlus),
          Text(
            AppStrings.adhanEnabledCount(
              enabledCount,
              AdhanSettingsService.prayerNames.length,
            ),
            style: AppText.caption,
          ),
          const SizedBox(height: AppUi.gapMD),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.adhanEnableToggle, style: AppText.body),
            value: settings.enabled,
            onChanged: (value) {
              _save(settings.copyWith(enabled: value));
            },
          ),
          const SizedBox(height: AppUi.gapSM),
          Text(AppStrings.adhanPerPrayer, style: AppText.bodyMuted),
          const SizedBox(height: AppUi.gapSM),
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
          const SizedBox(height: AppUi.gapSM),
          Text(AppStrings.adhanSelect, style: AppText.bodyMuted),
          const SizedBox(height: AppUi.gapSM),
          RadioGroup<AdhanSound>(
            groupValue: settings.sound,
            onChanged: (value) {
              if (!settings.enabled || value == null) return;
              _save(settings.copyWith(sound: value));
            },
            child: Column(
              children: [
                RadioListTile<AdhanSound>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.adhanMakkah, style: AppText.body),
                  value: AdhanSound.makkah,
                ),
                RadioListTile<AdhanSound>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.adhanMadinah, style: AppText.body),
                  value: AdhanSound.madinah,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUi.gapSM),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.adhanSilentOnly, style: AppText.body),
            value: settings.silentNotifications,
            onChanged: (value) {
              _save(settings.copyWith(silentNotifications: value));
            },
          ),
          const SizedBox(height: AppUi.gapMD),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                await _adhanService.test(settings.sound);
              },
              child: const Text(AppStrings.adhanTest),
            ),
          ),
        ],
      ),
    );
  }
}
