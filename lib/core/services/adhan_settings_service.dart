import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';

enum AdhanSound {
  qatami,
  makkah,
  madinah,
  alafasy,
  abdulbasit,
  aqsa,
  takbeer,
}

/// Rich notification options for prayer times
enum PrayerNotificationMode {
  adhan,        // أذان كامل بصوت المؤذن المختار
  takbeer,      // تكبيرات الأذان فقط
  announcement, // نداء وقت الصلاة (حان الآن وقت صلاة...)
  tone,         // نغمة تنبيه هادئة
  silent,       // إشعار مرئي فقط بدون صوت
  off,          // إيقاف التنبيه
}

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
  final PrayerNotificationMode defaultMode;
  final Map<String, PrayerNotificationMode> prayerModes;

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
    this.defaultMode = PrayerNotificationMode.adhan,
    this.prayerModes = const {},
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
    PrayerNotificationMode? defaultMode,
    Map<String, PrayerNotificationMode>? prayerModes,
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
      defaultMode: defaultMode ?? this.defaultMode,
      prayerModes: prayerModes ?? this.prayerModes,
    );
  }

  /// Resolves the specific notification mode for a given prayer.
  PrayerNotificationMode modeForPrayer(String name) {
    if (!enabled) return PrayerNotificationMode.off;
    final specific = prayerModes[name];
    if (specific != null) return specific;
    final isToggled = prayerToggles[name] ?? true;
    if (!isToggled) return PrayerNotificationMode.off;
    if (silentNotifications) return PrayerNotificationMode.silent;
    return defaultMode;
  }

  /// Whether a prayer notification is actively enabled (non-silent or silent)
  bool isPrayerEnabled(String name) {
    return modeForPrayer(name) != PrayerNotificationMode.off;
  }
}

class AdhanSettingsService {
  static const _keyEnabled = 'adhan_enabled';
  static const _keySound = 'adhan_sound';
  static const _keySilent = 'adhan_silent';
  static const _keyPrayerPrefix = 'adhan_prayer_';
  // Advanced notification keys
  static const _keyDefaultMode = 'adhan_default_mode';
  static const _keyPrayerModePrefix = 'adhan_prayer_mode_';
  static const _keyCalcMethod = 'adhan_calc_method';
  static const _keyVolume = 'adhan_volume';
  static const _keyNotifyBefore = 'adhan_notify_before';
  static const _keyIqama = 'adhan_iqama';
  static const _keyAdjPrefix = 'adhan_adj_';

  static const List<String> prayerNames = AppStrings.prayerOrder;
  static const Map<String, String> calculationMethods = {
    'auto': 'تلقائي (حسب الدولة الحالية)',
    'algeria': 'وزارة الشؤون الدينية (الجزائر والمغرب العربي)',
    'mwl': 'رابطة العالم الإسلامي (دولي - 18°/17°)',
    'umm_al_qura': 'جامعة أم القرى (مكة المكرمة)',
    'egyptian': 'الهيئة المصرية العامة للمساحة',
  };

  Future<AdhanSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? true;
    final soundIndex = prefs.getInt(_keySound);
    final AdhanSound sound;
    if (soundIndex != null && soundIndex >= 0 && soundIndex < AdhanSound.values.length) {
      sound = AdhanSound.values[soundIndex];
    } else {
      sound = AdhanSound.qatami;
    }

    final silent = prefs.getBool(_keySilent) ?? false;
    final calcMethod = prefs.getString(_keyCalcMethod) ?? 'auto';
    final volume = prefs.getDouble(_keyVolume) ?? 80.0;
    final notifyBefore = prefs.getDouble(_keyNotifyBefore) ?? 15.0;
    final iqama = prefs.getBool(_keyIqama) ?? false;

    final defaultModeIndex = prefs.getInt(_keyDefaultMode);
    final PrayerNotificationMode defaultMode;
    if (defaultModeIndex != null && defaultModeIndex >= 0 && defaultModeIndex < PrayerNotificationMode.values.length) {
      defaultMode = PrayerNotificationMode.values[defaultModeIndex];
    } else {
      defaultMode = silent ? PrayerNotificationMode.silent : PrayerNotificationMode.adhan;
    }

    final toggles = <String, bool>{};
    final adjustments = <String, int>{};
    final prayerModes = <String, PrayerNotificationMode>{};

    for (final name in prayerNames) {
      final isToggled = prefs.getBool('$_keyPrayerPrefix$name') ?? true;
      toggles[name] = isToggled;
      adjustments[name] = prefs.getInt('$_keyAdjPrefix$name') ?? 0;

      final modeIdx = prefs.getInt('$_keyPrayerModePrefix$name');
      if (modeIdx != null && modeIdx >= 0 && modeIdx < PrayerNotificationMode.values.length) {
        prayerModes[name] = PrayerNotificationMode.values[modeIdx];
      } else {
        prayerModes[name] = isToggled ? defaultMode : PrayerNotificationMode.off;
      }
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
      defaultMode: defaultMode,
      prayerModes: prayerModes,
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
    await prefs.setInt(_keyDefaultMode, settings.defaultMode.index);

    for (final entry in settings.prayerToggles.entries) {
      await prefs.setBool('$_keyPrayerPrefix${entry.key}', entry.value);
    }
    for (final entry in settings.adjustments.entries) {
      await prefs.setInt('$_keyAdjPrefix${entry.key}', entry.value);
    }
    for (final entry in settings.prayerModes.entries) {
      await prefs.setInt('$_keyPrayerModePrefix${entry.key}', entry.value.index);
    }
  }
}
