import 'package:shared_preferences/shared_preferences.dart';

import '../../features/prayer/data/models/prayer_models.dart';
import 'adhan_settings_service.dart';
import 'adhkar_reminder_service.dart';
import 'home_widget_service.dart';
import 'notification_service.dart';
import 'prayer_time_service.dart';

class PrayerScheduleService {
  static const _keyDate = 'prayer_schedule_date';
  static const _keyLocation = 'prayer_schedule_location';
  static const _keySettings = 'prayer_schedule_settings';

  final PrayerTimeService _prayerTimeService;
  final NotificationService _notificationService;
  final AdhanSettingsService _adhanSettingsService;
  final DateTime Function() _now;

  PrayerScheduleService({
    PrayerTimeService? prayerTimeService,
    NotificationService? notificationService,
    AdhanSettingsService? adhanSettingsService,
    DateTime Function()? now,
  })  : _prayerTimeService = prayerTimeService ?? PrayerTimeService(),
        _notificationService = notificationService ?? NotificationService(),
        _adhanSettingsService =
            adhanSettingsService ?? AdhanSettingsService(),
        _now = now ?? (prayerTimeService?.now ?? DateTime.now);

  Future<void> refreshSchedulesIfNeeded({
    PrayerTimesDay? day,
    bool force = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = day ?? await _prayerTimeService.getPrayerTimesDay();
    final settings = await _adhanSettingsService.getSettings();

    final dateKey = _formatDate(today.date);
    final locationKey = today.city;
    final settingsKey = _settingsKey(settings);

    final lastDate = prefs.getString(_keyDate);
    final lastLocation = prefs.getString(_keyLocation);
    final lastSettings = prefs.getString(_keySettings);
    final lastRefreshTimeMs = prefs.getInt('prayer_schedule_timestamp') ?? 0;
    final now = _now();
    final hoursSinceLastRefresh =
        (now.millisecondsSinceEpoch - lastRefreshTimeMs) / (1000 * 60 * 60);

    // If not forced, same day, same location, same settings, and refreshed within 12 hours:
    // the 7-day rolling window is fully saturated, so return early to avoid redundant work.
    if (!force &&
        lastDate == dateKey &&
        lastLocation == locationKey &&
        lastSettings == settingsKey &&
        hoursSinceLastRefresh < 12) {
      return;
    }

    // Preserve notification IDs for any prayer currently sounding / active
    // within an active window of [-60s, +360s]
    final sortedTodayPrayers = today.prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final preserveIds = <int>{};
    var prayerIdx = 0;
    for (final entry in sortedTodayPrayers) {
      if (!entry.key.contains('الشروق')) {
        final diff = now.difference(entry.value).inSeconds;
        if (diff >= -60 && diff <= 360) {
          preserveIds.add(1000 + prayerIdx); // Scheduled notification ID (day 0)
          preserveIds.add(100 + prayerIdx);  // Legacy scheduled notification ID
          preserveIds.add(700 + prayerIdx);  // Instant alert ID
          preserveIds.add(750 + prayerIdx);  // Instant pre-prayer ID
        }
      }
      prayerIdx++;
    }

    await _notificationService.init();
    await _notificationService.cancelPrayerNotificationsOnly(
      preserveIds: preserveIds,
    );

    // Schedule 7 rolling days (Day 0 = Today, Day 1 = Tomorrow, ..., Day 6 = 6 days ahead)
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final dayPrayerTimes = (dayOffset == 0 && day != null)
          ? day
          : await _prayerTimeService.getPrayerTimesDay(date: targetDate);

      await _scheduleDay(
        dayPrayerTimes,
        settings,
        dayOffset: dayOffset,
      );
    }

    // Ensure daily Adhkar reminders are also scheduled and preserved
    try {
      final adhkarService =
          AdhkarReminderService(notificationService: _notificationService);
      final adhkarSettings = await adhkarService.getSettings();
      await adhkarService.applySchedules(adhkarSettings);
    } catch (_) {
      // Non-fatal if adhkar scheduling fails
    }

    await prefs.setString(_keyDate, dateKey);
    await prefs.setString(_keyLocation, locationKey);
    await prefs.setString(_keySettings, settingsKey);
    await prefs.setInt('prayer_schedule_timestamp', now.millisecondsSinceEpoch);

    try {
      await HomeWidgetService.updateAllWidgets(prayerDay: today);
    } catch (_) {}
  }

  Future<void> _scheduleDay(
    PrayerTimesDay day,
    AdhanSettings settings, {
    required int dayOffset,
  }) async {
    final now = _now();
    final isFriday = day.date.weekday == DateTime.friday;
    final entries = day.prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final baseAdhanId = 1000 + (dayOffset * 100);
    final basePrePrayerId = 2000 + (dayOffset * 100);
    final baseIqamaId = 3000 + (dayOffset * 100);
    final kahfId = 4000 + (dayOffset * 100);

    // Friday Special: Surat Al-Kahf reminder at 09:00 AM
    if (isFriday) {
      final kahfTime = DateTime(
        day.date.year,
        day.date.month,
        day.date.day,
        9,
        0,
      );
      if (kahfTime.isAfter(now)) {
        await _notificationService.scheduleSurahAlKahfNotification(
          id: kahfId,
          scheduledTime: kahfTime,
        );
      }
    }

    var index = 0;
    for (final entry in entries) {
      final prayerName = entry.key;
      final prayerTime = entry.value;

      // Skip Sunrise (الشروق) for adhan / call to prayer
      if (prayerName.contains('الشروق')) {
        index += 1;
        continue;
      }

      final isJumua = isFriday &&
          (prayerName.contains('الظهر') || prayerName == 'الظهر');
      final effectivePrayerName = isJumua ? 'صلاة الجمعة' : prayerName;

      final mode = settings.modeForPrayer(prayerName);
      if (mode != PrayerNotificationMode.off) {
        // 1. Advance notification (e.g. 15 minutes before)
        final notifyBefore = settings.notifyBeforeMinutes.toInt();
        if (notifyBefore > 0) {
          final prePrayerTime =
              prayerTime.subtract(Duration(minutes: notifyBefore));
          if (prePrayerTime.isAfter(now)) {
            await _notificationService.schedulePrePrayerNotification(
              id: basePrePrayerId + index,
              prayerName: effectivePrayerName,
              scheduledTime: prePrayerTime,
              minutesBefore: notifyBefore,
              isJumua: isJumua,
            );
          }
        }

        // 2. Prayer / Adhan notification at prayer time
        if (prayerTime.isAfter(now)) {
          await _notificationService.schedulePrayerNotification(
            id: baseAdhanId + index,
            prayerName: effectivePrayerName,
            scheduledTime: prayerTime,
            mode: mode,
            sound: settings.sound,
            isJumua: isJumua,
          );
        }

        // 3. Iqama reminder (e.g. 25 min for Friday Khutbah + prayer, 20 min for Fajr, 15 min for others)
        if (settings.iqamaReminders) {
          final iqamaMinutes = isJumua
              ? 25
              : (prayerName.contains('الفجر') ? 20 : 15);
          final iqamaTime = prayerTime.add(Duration(minutes: iqamaMinutes));
          if (iqamaTime.isAfter(now)) {
            await _notificationService.scheduleIqamaNotification(
              id: baseIqamaId + index,
              prayerName: effectivePrayerName,
              scheduledTime: iqamaTime,
              isJumua: isJumua,
            );
          }
        }
      }
      index += 1;
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
        '${settings.defaultMode.index}|$modes|${settings.silentNotifications}|'
        '${settings.notifyBeforeMinutes}|${settings.iqamaReminders}';
  }
}
