import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/prayer/data/models/prayer_models.dart';
import '../utils/async_lock.dart';
import 'adhan_settings_service.dart';
import 'adhkar_reminder_service.dart';
import 'home_widget_service.dart';
import 'notification_service.dart';
import 'prayer_time_service.dart';
export 'schedule_outcome.dart';

class PrayerScheduleService {
  static const _keyFingerprint = 'prayer_schedule_fingerprint';
  static const _keyDate = 'prayer_schedule_date';
  static const _keyLocation = 'prayer_schedule_location';
  static const _keySettings = 'prayer_schedule_settings';
  static const _keyTimestamp = 'prayer_schedule_timestamp';

  static AsyncLock _sharedLock = AsyncLock();

  final PrayerTimeService _prayerTimeService;
  final NotificationService _notificationService;
  final AdhanSettingsService _adhanSettingsService;
  final DateTime Function() _now;
  final AsyncLock _refreshLock;

  PrayerScheduleService({
    PrayerTimeService? prayerTimeService,
    NotificationService? notificationService,
    AdhanSettingsService? adhanSettingsService,
    DateTime Function()? now,
    AsyncLock? lock,
  })  : _prayerTimeService = prayerTimeService ?? PrayerTimeService(),
        _notificationService = notificationService ?? NotificationService(),
        _adhanSettingsService =
            adhanSettingsService ?? AdhanSettingsService(),
        _now = now ?? (prayerTimeService?.now ?? DateTime.now),
        _refreshLock = lock ?? _sharedLock;

  @visibleForTesting
  static void resetSharedStateForTesting() {
    _sharedLock = AsyncLock();
  }

  /// Synchronizes and schedules the 7-day rolling window of prayer notifications.
  /// Serialized through a shared [AsyncLock] across all instances in the isolate
  /// to eliminate duplicate or competing schedule execution.
  Future<ScheduleBatchResult> refreshSchedulesIfNeeded({
    PrayerTimesDay? day,
    bool force = false,
  }) async {
    return await _refreshLock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final today = day ?? await _prayerTimeService.getPrayerTimesDay();
      final settings = await _adhanSettingsService.getSettings();
      final now = _now();

      final fingerprint = _buildFingerprint(
        today: today,
        settings: settings,
        now: now,
      );

      final lastFingerprint = prefs.getString(_keyFingerprint);
      final lastDate = prefs.getString(_keyDate);
      final lastLocation = prefs.getString(_keyLocation);
      final lastSettings = prefs.getString(_keySettings);
      final lastRefreshTimeMs = prefs.getInt(_keyTimestamp) ?? 0;
      final hoursSinceLastRefresh =
          (now.millisecondsSinceEpoch - lastRefreshTimeMs) / (1000 * 60 * 60);

      // Check whether previous scheduling succeeded and is fresh (< 12 hours).
      // Fingerprint includes date, location, timezone/DST offset, calculationMethod, madhab, adjustments, and settings.
      final isUpToDate = lastFingerprint != null
          ? (lastFingerprint == fingerprint)
          : (lastDate == _formatDate(today.date) &&
              lastLocation == today.city &&
              lastSettings == _settingsKey(settings));

      if (!force && isUpToDate && hoursSinceLastRefresh < 12) {
        return const ScheduleBatchResult();
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

      var totalAttempted = 0;
      var exactScheduled = 0;
      var inexactFallback = 0;
      var skippedPast = 0;
      var failed = 0;
      final errors = <String>[];

      // Schedule 7 rolling days using civil calendar date arithmetic
      // (DateTime(year, month, day + dayOffset) correctly handles DST transition days)
      for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
        final targetDate = DateTime(now.year, now.month, now.day + dayOffset);
        final dayPrayerTimes = (dayOffset == 0 && day != null)
            ? day
            : await _prayerTimeService.getPrayerTimesDay(date: targetDate);

        final dayOutcomes = await _scheduleDay(
          dayPrayerTimes,
          settings,
          dayOffset: dayOffset,
        );

        for (final outcome in dayOutcomes) {
          totalAttempted++;
          switch (outcome.status) {
            case ScheduleOutcomeStatus.exact:
              exactScheduled++;
              break;
            case ScheduleOutcomeStatus.inexactFallback:
              inexactFallback++;
              break;
            case ScheduleOutcomeStatus.skippedPast:
              skippedPast++;
              break;
            case ScheduleOutcomeStatus.permissionDenied:
            case ScheduleOutcomeStatus.failed:
              failed++;
              if (outcome.errorMessage != null) {
                errors.add(outcome.errorMessage!);
              }
              break;
          }
        }
      }

      // Ensure daily Adhkar reminders are also scheduled and preserved
      try {
        final adhkarService =
            AdhkarReminderService(notificationService: _notificationService);
        final adhkarSettings = await adhkarService.getSettings();
        await adhkarService.applySchedules(adhkarSettings);
      } catch (e) {
        debugPrint('PrayerScheduleService: Adhkar scheduling warning: $e');
      }

      final batchResult = ScheduleBatchResult(
        totalAttempted: totalAttempted,
        exactScheduled: exactScheduled,
        inexactFallbackScheduled: inexactFallback,
        skippedPast: skippedPast,
        failed: failed,
        errors: errors,
      );

      // C11 Data Safety: Only persist success fingerprint if the batch completed without failure!
      if (batchResult.isSuccess) {
        await prefs.setString(_keyFingerprint, fingerprint);
        await prefs.setString(_keyDate, _formatDate(today.date));
        await prefs.setString(_keyLocation, today.city);
        await prefs.setString(_keySettings, _settingsKey(settings));
        await prefs.setInt(_keyTimestamp, now.millisecondsSinceEpoch);
      } else {
        debugPrint(
          'PrayerScheduleService: Batch had $failed failures. Omitting success fingerprint so next refresh retries.',
        );
      }

      try {
        await HomeWidgetService.updateAllWidgets(prayerDay: today);
      } catch (_) {}

      return batchResult;
    });
  }

  Future<List<ScheduleOutcome>> _scheduleDay(
    PrayerTimesDay day,
    AdhanSettings settings, {
    required int dayOffset,
  }) async {
    final outcomes = <ScheduleOutcome>[];
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
        final outcome = await _notificationService.scheduleSurahAlKahfNotification(
          id: kahfId,
          scheduledTime: kahfTime,
        );
        outcomes.add(outcome);
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
            final outcome = await _notificationService.schedulePrePrayerNotification(
              id: basePrePrayerId + index,
              prayerName: effectivePrayerName,
              scheduledTime: prePrayerTime,
              minutesBefore: notifyBefore,
              isJumua: isJumua,
            );
            outcomes.add(outcome);
          }
        }

        // 2. Prayer / Adhan notification at prayer time
        if (prayerTime.isAfter(now)) {
          final outcome = await _notificationService.schedulePrayerNotification(
            id: baseAdhanId + index,
            prayerName: effectivePrayerName,
            scheduledTime: prayerTime,
            mode: mode,
            sound: settings.sound,
            isJumua: isJumua,
          );
          outcomes.add(outcome);
        }

        // 3. Iqama reminder (e.g. 25 min for Friday Khutbah + prayer, 20 min for Fajr, 15 min for others)
        if (settings.iqamaReminders) {
          final iqamaMinutes = isJumua
              ? 25
              : (prayerName.contains('الفجر') ? 20 : 15);
          final iqamaTime = prayerTime.add(Duration(minutes: iqamaMinutes));
          if (iqamaTime.isAfter(now)) {
            final outcome = await _notificationService.scheduleIqamaNotification(
              id: baseIqamaId + index,
              prayerName: effectivePrayerName,
              scheduledTime: iqamaTime,
              isJumua: isJumua,
            );
            outcomes.add(outcome);
          }
        }
      }
      index += 1;
    }
    return outcomes;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _buildFingerprint({
    required PrayerTimesDay today,
    required AdhanSettings settings,
    required DateTime now,
  }) {
    final dateKey = _formatDate(today.date);
    final locKey =
        '${today.city}|${today.prayers.values.map((d) => d.millisecondsSinceEpoch).join(",")}';
    final tzKey = '${now.timeZoneName}|${now.timeZoneOffset.inMinutes}';
    final calcKey =
        '${settings.calculationMethod}|${settings.madhab}|${settings.adjustments.entries.map((e) => "${e.key}:${e.value}").join(",")}';
    final setKey = _settingsKey(settings);
    return '$dateKey|$locKey|$tzKey|$calcKey|$setKey';
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
