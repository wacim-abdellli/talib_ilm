import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/prayer/data/models/prayer_models.dart';
import '../utils/async_lock.dart';
import 'adhan_settings_service.dart';
import 'adhkar_reminder_service.dart';
import 'home_widget_service.dart';
import 'iqama_timing_policy.dart';
import 'notification_service.dart';
import 'prayer_time_service.dart';
export 'schedule_outcome.dart';

enum PrayerScheduleEvent { adhan, prePrayer, iqama }

class PrayerScheduleService {
  static const _keyFingerprint = 'prayer_schedule_fingerprint';
  static const _keyDate = 'prayer_schedule_date';
  static const _keyLocation = 'prayer_schedule_location';
  static const _keySettings = 'prayer_schedule_settings';
  static const _keyTimestamp = 'prayer_schedule_timestamp';
  static const _keyAdhkarFingerprint = 'adhkar_schedule_fingerprint';
  static const _keyAdhkarTimestamp = 'adhkar_schedule_timestamp';
  static const _eventStatePrefix = 'prayer_schedule_event_';

  static AsyncLock _sharedLock = AsyncLock();

  /// Returns the last OS scheduling result for one prayer occurrence.
  /// A null result means no schedule result is known, so foreground delivery
  /// must provide the recovery path.
  static Future<bool?> wasEventScheduled({
    required DateTime date,
    required String prayerName,
    required PrayerScheduleEvent event,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(
      eventStateKey(date: date, prayerName: prayerName, event: event),
    );
  }

  @visibleForTesting
  static String eventStateKey({
    required DateTime date,
    required String prayerName,
    required PrayerScheduleEvent event,
  }) => '$_eventStatePrefix${_formatDateKey(date)}_${event.name}_$prayerName';

  static bool shouldUseForegroundFallback(bool? wasScheduled) =>
      wasScheduled != true;

  static String _formatDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Future<void> _recordEventSchedule({
    required DateTime date,
    required String prayerName,
    required PrayerScheduleEvent event,
    required bool scheduled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      eventStateKey(date: date, prayerName: prayerName, event: event),
      scheduled,
    );
  }

  static bool _hasPlatformAlarm(ScheduleOutcome outcome) =>
      outcome.status == ScheduleOutcomeStatus.exact ||
      outcome.status == ScheduleOutcomeStatus.inexactFallback;

  Future<void> _pruneOldEventStates(
    SharedPreferences prefs,
    DateTime today,
  ) async {
    final firstDateToKeep = DateTime(today.year, today.month, today.day - 1);
    final lastDateToKeep = DateTime(today.year, today.month, today.day + 7);
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_eventStatePrefix)) continue;
      if (key.length < _eventStatePrefix.length + 10) {
        await prefs.remove(key);
        continue;
      }
      final dateText = key.substring(
        _eventStatePrefix.length,
        _eventStatePrefix.length + 10,
      );
      final date = DateTime.tryParse(dateText);
      if (date == null ||
          date.isBefore(firstDateToKeep) ||
          date.isAfter(lastDateToKeep)) {
        await prefs.remove(key);
      }
    }
  }

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
  }) : _prayerTimeService = prayerTimeService ?? PrayerTimeService(),
       _notificationService = notificationService ?? NotificationService(),
       _adhanSettingsService = adhanSettingsService ?? AdhanSettingsService(),
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
      final notificationPermissionGranted = await _notificationService
          .arePermissionsGranted();
      final exactAlarmsAllowed = await _notificationService
          .canScheduleExactNotifications();

      final fingerprint = _buildFingerprint(
        today: today,
        settings: settings,
        now: now,
        notificationPermissionGranted: notificationPermissionGranted,
        exactAlarmsAllowed: exactAlarmsAllowed,
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

      final prayerScheduleIsFresh = isUpToDate && hoursSinceLastRefresh < 12;

      final adhkarService = AdhkarReminderService(
        notificationService: _notificationService,
        now: _now,
      );
      final adhkarSettings = await adhkarService.getSettings();
      final adhkarFingerprint = _buildAdhkarFingerprint(
        adhkarSettings,
        notificationPermissionGranted: notificationPermissionGranted,
        exactAlarmsAllowed: exactAlarmsAllowed,
      );
      final lastAdhkarFingerprint = prefs.getString(_keyAdhkarFingerprint);
      final lastAdhkarRefreshTimeMs = prefs.getInt(_keyAdhkarTimestamp) ?? 0;
      final hoursSinceAdhkarRefresh =
          (now.millisecondsSinceEpoch - lastAdhkarRefreshTimeMs) /
          (1000 * 60 * 60);
      final adhkarScheduleIsFresh =
          lastAdhkarFingerprint == adhkarFingerprint &&
          hoursSinceAdhkarRefresh < 12;
      final refreshPrayerSchedule = force || !prayerScheduleIsFresh;
      final refreshAdhkarSchedule = force || !adhkarScheduleIsFresh;

      if (!refreshPrayerSchedule && !refreshAdhkarSchedule) {
        return const ScheduleBatchResult();
      }

      var totalAttempted = 0;
      var exactScheduled = 0;
      var inexactFallback = 0;
      var skippedPast = 0;
      var failed = 0;
      var prayerFailures = 0;
      var adhkarFailures = 0;
      final errors = <String>[];

      void recordOutcome(ScheduleOutcome outcome, {required bool adhkar}) {
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
            if (adhkar) {
              adhkarFailures++;
            } else {
              prayerFailures++;
            }
            if (outcome.errorMessage != null) {
              errors.add(outcome.errorMessage!);
            }
            break;
        }
      }

      if (refreshPrayerSchedule) {
        await _pruneOldEventStates(prefs, today.date);

        // Preserve notification IDs for any prayer currently sounding / active
        // within an active window of [-60s, +360s].
        final sortedTodayPrayers = today.prayers.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        final preserveIds = <int>{};
        var prayerIdx = 0;
        for (final entry in sortedTodayPrayers) {
          if (!entry.key.contains('الشروق')) {
            final prayerMode = settings.modeForPrayer(entry.key);
            final diff = now.difference(entry.value).inSeconds;
            if (settings.enabled &&
                prayerMode != PrayerNotificationMode.off &&
                diff >= -60 &&
                diff <= 360) {
              preserveIds.add(
                1000 + prayerIdx,
              ); // Scheduled notification ID (day 0)
              preserveIds.add(
                100 + prayerIdx,
              ); // Legacy scheduled notification ID
              preserveIds.add(700 + prayerIdx); // Instant alert ID
              preserveIds.add(750 + prayerIdx); // Instant pre-prayer ID
            }
            final prePrayerTime = entry.value.subtract(
              Duration(minutes: settings.notifyBeforeMinutes.toInt()),
            );
            final preDiff = now.difference(prePrayerTime).inSeconds;
            if (settings.enabled &&
                prayerMode != PrayerNotificationMode.off &&
                settings.notifyBeforeMinutes > 0 &&
                preDiff >= -60 &&
                preDiff <= 60) {
              preserveIds.add(2000 + prayerIdx);
              preserveIds.add(750 + prayerIdx);
            }
            final isJumua =
                today.date.weekday == DateTime.friday &&
                entry.key.contains('الظهر');
            final iqamaTime = entry.value.add(
              Duration(
                minutes: IqamaTimingPolicy.minutesAfterAdhan(
                  entry.key,
                  isJumua: isJumua,
                ),
              ),
            );
            final iqamaDiff = now.difference(iqamaTime).inSeconds;
            if (settings.enabled &&
                settings.iqamaReminders &&
                prayerMode != PrayerNotificationMode.off &&
                iqamaDiff >= -60 &&
                iqamaDiff <= 60) {
              preserveIds.add(3000 + prayerIdx);
            }
          }
          prayerIdx++;
        }

        await _notificationService.init();
        await _notificationService.cancelPrayerNotificationsOnly(
          preserveIds: preserveIds,
        );

        // Schedule 7 rolling days using civil calendar date arithmetic
        // (DateTime(year, month, day + dayOffset) handles DST transition days).
        for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
          final targetDate = DateTime(now.year, now.month, now.day + dayOffset);
          final dayPrayerTimes = (dayOffset == 0 && day != null)
              ? day
              : await _prayerTimeService.getPrayerTimesDay(date: targetDate);

          final dayOutcomes = await _scheduleDay(
            dayPrayerTimes,
            settings,
            dayOffset: dayOffset,
            notificationsEnabled: notificationPermissionGranted,
          );

          for (final outcome in dayOutcomes) {
            recordOutcome(outcome, adhkar: false);
          }
        }
      }

      if (refreshAdhkarSchedule) {
        await _notificationService.init();
        final outcomes = await adhkarService.applySchedules(adhkarSettings);
        for (final outcome in outcomes) {
          recordOutcome(outcome, adhkar: true);
        }
      }

      final batchResult = ScheduleBatchResult(
        totalAttempted: totalAttempted,
        exactScheduled: exactScheduled,
        inexactFallbackScheduled: inexactFallback,
        skippedPast: skippedPast,
        failed: failed,
        errors: errors,
      );

      // Keep prayer and Adhkar freshness independent: an Adhkar failure must
      // retry Adhkar without needlessly canceling/recreating the seven-day
      // prayer alarm window on every app resume.
      if (refreshPrayerSchedule && prayerFailures == 0) {
        await prefs.setString(_keyFingerprint, fingerprint);
        await prefs.setString(_keyDate, _formatDate(today.date));
        await prefs.setString(_keyLocation, today.city);
        await prefs.setString(_keySettings, _settingsKey(settings));
        await prefs.setInt(_keyTimestamp, now.millisecondsSinceEpoch);
      } else if (prayerFailures > 0) {
        debugPrint(
          'PrayerScheduleService: Prayer schedule had $prayerFailures failures. Omitting success fingerprint so next refresh retries.',
        );
      }

      if (refreshAdhkarSchedule && adhkarFailures == 0) {
        await prefs.setString(_keyAdhkarFingerprint, adhkarFingerprint);
        await prefs.setInt(_keyAdhkarTimestamp, now.millisecondsSinceEpoch);
      } else if (adhkarFailures > 0) {
        debugPrint(
          'PrayerScheduleService: Adhkar schedule had $adhkarFailures failures. Omitting its success fingerprint so next refresh retries.',
        );
      }

      if (refreshPrayerSchedule) {
        try {
          await HomeWidgetService.updateAllWidgets(prayerDay: today);
        } catch (_) {}
      }

      return batchResult;
    });
  }

  Future<List<ScheduleOutcome>> _scheduleDay(
    PrayerTimesDay day,
    AdhanSettings settings, {
    required int dayOffset,
    required bool notificationsEnabled,
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
        final outcome = await _notificationService
            .scheduleSurahAlKahfNotification(
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

      final isJumua =
          isFriday && (prayerName.contains('الظهر') || prayerName == 'الظهر');
      final effectivePrayerName = isJumua ? 'صلاة الجمعة' : prayerName;

      final mode = settings.modeForPrayer(prayerName);
      final prePrayerTime = prayerTime.subtract(
        Duration(minutes: settings.notifyBeforeMinutes.toInt()),
      );
      final prayerAgeSeconds = now.difference(prayerTime).inSeconds;
      final prePrayerAgeSeconds = now.difference(prePrayerTime).inSeconds;
      final prayerIsInActiveWindow =
          prayerAgeSeconds >= -60 && prayerAgeSeconds <= 360;
      final prePrayerIsInActiveWindow =
          prePrayerAgeSeconds >= -60 && prePrayerAgeSeconds <= 60;

      if (settings.enabled && mode != PrayerNotificationMode.off) {
        // 1. Advance notification (e.g. 15 minutes before)
        final notifyBefore = settings.notifyBeforeMinutes.toInt();
        if (notifyBefore > 0) {
          if (prePrayerTime.isAfter(now)) {
            await _recordEventSchedule(
              date: day.date,
              prayerName: prayerName,
              event: PrayerScheduleEvent.prePrayer,
              scheduled: false,
            );
            final outcome = await _notificationService
                .schedulePrePrayerNotification(
                  id: basePrePrayerId + index,
                  prayerName: effectivePrayerName,
                  scheduledTime: prePrayerTime,
                  minutesBefore: notifyBefore,
                  isJumua: isJumua,
                );
            outcomes.add(outcome);
            await _recordEventSchedule(
              date: day.date,
              prayerName: prayerName,
              event: PrayerScheduleEvent.prePrayer,
              scheduled: notificationsEnabled && _hasPlatformAlarm(outcome),
            );
          } else if (!prePrayerIsInActiveWindow || !notificationsEnabled) {
            await _recordEventSchedule(
              date: day.date,
              prayerName: prayerName,
              event: PrayerScheduleEvent.prePrayer,
              scheduled: false,
            );
          }
        }

        // 2. Prayer / Adhan notification at prayer time
        if (prayerTime.isAfter(now)) {
          await _recordEventSchedule(
            date: day.date,
            prayerName: prayerName,
            event: PrayerScheduleEvent.adhan,
            scheduled: false,
          );
          final outcome = await _notificationService.schedulePrayerNotification(
            id: baseAdhanId + index,
            prayerName: effectivePrayerName,
            scheduledTime: prayerTime,
            mode: mode,
            sound: settings.sound,
            isJumua: isJumua,
          );
          outcomes.add(outcome);
          await _recordEventSchedule(
            date: day.date,
            prayerName: prayerName,
            event: PrayerScheduleEvent.adhan,
            scheduled: notificationsEnabled && _hasPlatformAlarm(outcome),
          );
        } else if (!prayerIsInActiveWindow || !notificationsEnabled) {
          await _recordEventSchedule(
            date: day.date,
            prayerName: prayerName,
            event: PrayerScheduleEvent.adhan,
            scheduled: false,
          );
        }

        // 3. Iqama reminder (e.g. 25 min for Friday Khutbah + prayer, 20 min for Fajr, 15 min for others)
        if (settings.iqamaReminders) {
          final iqamaMinutes = IqamaTimingPolicy.minutesAfterAdhan(
            prayerName,
            isJumua: isJumua,
          );
          final iqamaTime = prayerTime.add(Duration(minutes: iqamaMinutes));
          final iqamaDiff = now.difference(iqamaTime).inSeconds;
          final iqamaIsInActiveWindow = iqamaDiff >= -60 && iqamaDiff <= 60;
          if (iqamaTime.isAfter(now)) {
            await _recordEventSchedule(
              date: day.date,
              prayerName: prayerName,
              event: PrayerScheduleEvent.iqama,
              scheduled: false,
            );
            final outcome = await _notificationService
                .scheduleIqamaNotification(
                  id: baseIqamaId + index,
                  prayerName: effectivePrayerName,
                  scheduledTime: iqamaTime,
                  isJumua: isJumua,
                );
            outcomes.add(outcome);
            await _recordEventSchedule(
              date: day.date,
              prayerName: prayerName,
              event: PrayerScheduleEvent.iqama,
              scheduled: notificationsEnabled && _hasPlatformAlarm(outcome),
            );
          } else if (!iqamaIsInActiveWindow || !notificationsEnabled) {
            await _recordEventSchedule(
              date: day.date,
              prayerName: prayerName,
              event: PrayerScheduleEvent.iqama,
              scheduled: false,
            );
          }
        } else {
          await _recordEventSchedule(
            date: day.date,
            prayerName: prayerName,
            event: PrayerScheduleEvent.iqama,
            scheduled: false,
          );
        }
      } else {
        await _recordEventSchedule(
          date: day.date,
          prayerName: prayerName,
          event: PrayerScheduleEvent.adhan,
          scheduled: false,
        );
        await _recordEventSchedule(
          date: day.date,
          prayerName: prayerName,
          event: PrayerScheduleEvent.prePrayer,
          scheduled: false,
        );
        await _recordEventSchedule(
          date: day.date,
          prayerName: prayerName,
          event: PrayerScheduleEvent.iqama,
          scheduled: false,
        );
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
    required bool notificationPermissionGranted,
    required bool? exactAlarmsAllowed,
  }) {
    final dateKey = _formatDate(today.date);
    final locKey =
        '${today.city}|${today.prayers.values.map((d) => d.millisecondsSinceEpoch).join(",")}';
    final tzKey = '${now.timeZoneName}|${now.timeZoneOffset.inMinutes}';
    final calcKey =
        '${settings.calculationMethod}|${settings.madhab}|${settings.adjustments.entries.map((e) => "${e.key}:${e.value}").join(",")}';
    final setKey = _settingsKey(settings);
    final permissionKey =
        'notifications:$notificationPermissionGranted|exact:$exactAlarmsAllowed';
    // Version the schedule policy so the first launch after R19 rebuilds the
    // rolling window and persists per-occurrence delivery ownership.
    return 'r19|$dateKey|$locKey|$tzKey|$calcKey|$setKey|$permissionKey';
  }

  String _buildAdhkarFingerprint(
    AdhkarReminderSettings settings, {
    required bool notificationPermissionGranted,
    required bool? exactAlarmsAllowed,
  }) {
    return '${settings.morningEnabled}:${settings.morningHour}:${settings.morningMinute}|'
        '${settings.eveningEnabled}:${settings.eveningHour}:${settings.eveningMinute}|'
        '${settings.sleepEnabled}:${settings.sleepHour}:${settings.sleepMinute}|'
        'notifications:$notificationPermissionGranted|exact:$exactAlarmsAllowed';
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
