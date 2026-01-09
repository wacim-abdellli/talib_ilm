import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';

enum AdhanSound {
  makkah,
  madinah,
}

class AdhanSettings {
  final bool enabled;
  final AdhanSound sound;
  final bool silentNotifications;
  final Map<String, bool> prayerToggles;

  const AdhanSettings({
    required this.enabled,
    required this.sound,
    required this.silentNotifications,
    required this.prayerToggles,
  });

  AdhanSettings copyWith({
    bool? enabled,
    AdhanSound? sound,
    bool? silentNotifications,
    Map<String, bool>? prayerToggles,
  }) {
    return AdhanSettings(
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      silentNotifications: silentNotifications ?? this.silentNotifications,
      prayerToggles: prayerToggles ?? this.prayerToggles,
    );
  }

  bool isPrayerEnabled(String name) {
    return prayerToggles[name] ?? true;
  }
}

class AdhanSettingsService {
  static const _keyEnabled = 'adhan_enabled';
  static const _keySound = 'adhan_sound';
  static const _keySilent = 'adhan_silent';
  static const _keyPrayerPrefix = 'adhan_prayer_';

  static const List<String> prayerNames = AppStrings.prayerOrder;

  Future<AdhanSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    final soundIndex = prefs.getInt(_keySound) ?? 0;
    final silent = prefs.getBool(_keySilent) ?? false;

    final maxIndex = AdhanSound.values.length - 1;
    final safeIndex = soundIndex.clamp(0, maxIndex).toInt();
    final sound = AdhanSound.values[safeIndex];

    final toggles = <String, bool>{};
    for (final name in prayerNames) {
      toggles[name] = prefs.getBool('$_keyPrayerPrefix$name') ?? true;
    }

    return AdhanSettings(
      enabled: enabled,
      sound: sound,
      silentNotifications: silent,
      prayerToggles: toggles,
    );
  }

  Future<void> saveSettings(AdhanSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, settings.enabled);
    await prefs.setInt(_keySound, settings.sound.index);
    await prefs.setBool(_keySilent, settings.silentNotifications);
    for (final entry in settings.prayerToggles.entries) {
      await prefs.setBool('$_keyPrayerPrefix${entry.key}', entry.value);
    }
  }
}
