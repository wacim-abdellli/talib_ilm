import 'package:shared_preferences/shared_preferences.dart';

import '../../features/prayer/data/models/prayer_models.dart';
import 'adhan_settings_service.dart';
import 'notification_service.dart';
import '../../app/constants/app_strings.dart';
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
    final resolvedDay = day ?? await _prayerTimeService.getPrayerTimesDay();
    final settings = await _adhanSettingsService.getSettings();

    final dateKey = _formatDate(resolvedDay.date);
    final locationKey = resolvedDay.city;
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
    await _scheduleDay(resolvedDay, settings);

    await prefs.setString(_keyDate, dateKey);
    await prefs.setString(_keyLocation, locationKey);
    await prefs.setString(_keySettings, settingsKey);
  }

  Future<void> _scheduleDay(PrayerTimesDay day, AdhanSettings settings) async {
    final now = DateTime.now();
    final entries = day.prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final playSound = settings.enabled && !settings.silentNotifications;
    final sound = playSound ? settings.sound : null;

    var id = 100;
    for (final entry in entries) {
      if (!settings.isPrayerEnabled(entry.key)) {
        id += 1;
        continue;
      }

      if (entry.value.isAfter(now)) {
        await _notificationService.scheduleNotification(
          id: id,
          title: AppStrings.prayerNotificationTitle,
          body: AppStrings.prayerNotificationBody(entry.key),
          scheduledTime: entry.value,
          playSound: playSound,
          sound: sound,
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
    final toggles = AdhanSettingsService.prayerNames
        .map((name) => settings.isPrayerEnabled(name) ? '1' : '0')
        .join();
    return '${settings.enabled}|${settings.sound.index}|'
        '${settings.silentNotifications}|$toggles';
  }
}
