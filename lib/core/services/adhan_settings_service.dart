import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';

enum AdhanSound { makkah, madinah }

class AdhanSettings {
  final bool enabled;
  final AdhanSound sound;
  final bool silentNotifications;
  final Map<String, bool> prayerToggles;
  final String calculationMethod;
  final double volume;
  final double notifyBeforeMinutes;
  final bool iqamaReminders;
  final Map<String, int> adjustments;

  const AdhanSettings({
    required this.enabled,
    required this.sound,
    required this.silentNotifications,
    required this.prayerToggles,
    required this.calculationMethod,
    required this.volume,
    required this.notifyBeforeMinutes,
    required this.iqamaReminders,
    required this.adjustments,
  });

  AdhanSettings copyWith({
    bool? enabled,
    AdhanSound? sound,
    bool? silentNotifications,
    Map<String, bool>? prayerToggles,
    String? calculationMethod,
    double? volume,
    double? notifyBeforeMinutes,
    bool? iqamaReminders,
    Map<String, int>? adjustments,
  }) {
    return AdhanSettings(
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      silentNotifications: silentNotifications ?? this.silentNotifications,
      prayerToggles: prayerToggles ?? this.prayerToggles,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      volume: volume ?? this.volume,
      notifyBeforeMinutes: notifyBeforeMinutes ?? this.notifyBeforeMinutes,
      iqamaReminders: iqamaReminders ?? this.iqamaReminders,
      adjustments: adjustments ?? this.adjustments,
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
  // New keys
  static const _keyCalcMethod = 'adhan_calc_method';
  static const _keyVolume = 'adhan_volume';
  static const _keyNotifyBefore = 'adhan_notify_before';
  static const _keyIqama = 'adhan_iqama';
  static const _keyAdjPrefix = 'adhan_adj_';

  static const List<String> prayerNames = AppStrings.prayerOrder;
  static const Map<String, String> calculationMethods = {
    'egyptian': 'الهيئة المصرية العامة للمساحة',
    'mwl': 'رابطة العالم الإسلامي',
    'umm_al_qura': 'جامعة أم القرى',
  };

  Future<AdhanSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    final soundIndex = prefs.getInt(_keySound) ?? 0;
    final silent = prefs.getBool(_keySilent) ?? false;
    final calcMethod = prefs.getString(_keyCalcMethod) ?? 'egyptian';
    final volume = prefs.getDouble(_keyVolume) ?? 80.0;
    final notifyBefore = prefs.getDouble(_keyNotifyBefore) ?? 15.0;
    final iqama = prefs.getBool(_keyIqama) ?? false;

    final maxIndex = AdhanSound.values.length - 1;
    final safeIndex = soundIndex.clamp(0, maxIndex).toInt();
    final sound = AdhanSound.values[safeIndex];

    final toggles = <String, bool>{};
    final adjustments = <String, int>{};
    for (final name in prayerNames) {
      toggles[name] = prefs.getBool('$_keyPrayerPrefix$name') ?? true;
      adjustments[name] = prefs.getInt('$_keyAdjPrefix$name') ?? 0;
    }

    return AdhanSettings(
      enabled: enabled,
      sound: sound,
      silentNotifications: silent,
      prayerToggles: toggles,
      calculationMethod: calcMethod,
      volume: volume,
      notifyBeforeMinutes: notifyBefore,
      iqamaReminders: iqama,
      adjustments: adjustments,
    );
  }

  Future<void> saveSettings(AdhanSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, settings.enabled);
    await prefs.setInt(_keySound, settings.sound.index);
    await prefs.setBool(_keySilent, settings.silentNotifications);
    await prefs.setString(_keyCalcMethod, settings.calculationMethod);
    await prefs.setDouble(_keyVolume, settings.volume);
    await prefs.setDouble(_keyNotifyBefore, settings.notifyBeforeMinutes);
    await prefs.setBool(_keyIqama, settings.iqamaReminders);

    for (final entry in settings.prayerToggles.entries) {
      await prefs.setBool('$_keyPrayerPrefix${entry.key}', entry.value);
    }
    for (final entry in settings.adjustments.entries) {
      await prefs.setInt('$_keyAdjPrefix${entry.key}', entry.value);
    }
  }
}
