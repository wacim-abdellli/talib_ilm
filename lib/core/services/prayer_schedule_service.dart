import 'package:shared_preferences/shared_preferences.dart';

import '../../features/prayer/data/models/prayer_models.dart';
import 'adhan_settings_service.dart';
import 'notification_service.dart';
import 'prayer_time_service.dart';

class PrayerScheduleService {
  static const _keyDate = 'prayer_schedule_date';
  static const _keyLocation = 'prayer_schedule_location';
  static const _keySettings = 'prayer_schedule_settings';

  final PrayerTimeService _prayerTimeService;
  final NotificationService _notificationService;
  final AdhanSettingsService _adhanSettingsService;

  PrayerScheduleService({
    PrayerTimeService? prayerTimeService,
    NotificationService? notificationService,
    AdhanSettingsService? adhanSettingsService,
  })  : _prayerTimeService = prayerTimeService ?? PrayerTimeService(),
        _notificationService = notificationService ?? NotificationService(),
        _adhanSettingsService =
            adhanSettingsService ?? AdhanSettingsService();

  Future<void> refreshSchedulesIfNeeded({
    PrayerTimesDay? day,
    bool force = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = day ?? await _prayerTimeService.getPrayerTimesDay();
    final tomorrow = await _prayerTimeService.getPrayerTimesDay(
      date: DateTime.now().add(const Duration(days: 1)),
    );
    final settings = await _adhanSettingsService.getSettings();

    final dateKey = _formatDate(today.date);
    final locationKey = today.city;
    final settingsKey = _settingsKey(settings);

    final lastDate = prefs.getString(_keyDate);
    final lastLocation = prefs.getString(_keyLocation);
    final lastSettings = prefs.getString(_keySettings);

    if (!force &&
        lastDate == dateKey &&
        lastLocation == locationKey &&
        lastSettings == settingsKey) {
      return;
    }

    await _notificationService.init();
    await _notificationService.requestPermissions();
    await _notificationService.cancelAll();

    // Schedule Today's upcoming prayers (base ID 100)
    await _scheduleDay(today, settings, baseId: 100);

    // Schedule Tomorrow's prayers (base ID 200)
    await _scheduleDay(tomorrow, settings, baseId: 200);

    await prefs.setString(_keyDate, dateKey);
    await prefs.setString(_keyLocation, locationKey);
    await prefs.setString(_keySettings, settingsKey);
  }

  Future<void> _scheduleDay(
    PrayerTimesDay day,
    AdhanSettings settings, {
    required int baseId,
  }) async {
    final now = DateTime.now();
    final entries = day.prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    var id = baseId;
    for (final entry in entries) {
      final prayerName = entry.key;
      final prayerTime = entry.value;

      // Skip Sunrise (الشروق) for adhan / call to prayer
      if (prayerName.contains('الشروق')) {
        id += 1;
        continue;
      }

      final mode = settings.modeForPrayer(prayerName);
      if (mode != PrayerNotificationMode.off && prayerTime.isAfter(now)) {
        await _notificationService.schedulePrayerNotification(
          id: id,
          prayerName: prayerName,
          scheduledTime: prayerTime,
          mode: mode,
          sound: settings.sound,
        );
      }
      id += 1;
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _settingsKey(AdhanSettings settings) {
    final modes = AdhanSettingsService.prayerNames
        .map((name) => settings.modeForPrayer(name).index.toString())
        .join();
    return '${settings.enabled}|${settings.sound.index}|'
        '${settings.defaultMode.index}|$modes|${settings.silentNotifications}';
  }
}
