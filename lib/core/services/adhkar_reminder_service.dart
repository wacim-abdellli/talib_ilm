import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

enum AdhkarReminderType { morning, evening, sleep }

class AdhkarReminderSettings {
  final bool morningEnabled;
  final int morningHour;
  final int morningMinute;

  final bool eveningEnabled;
  final int eveningHour;
  final int eveningMinute;

  final bool sleepEnabled;
  final int sleepHour;
  final int sleepMinute;

  const AdhkarReminderSettings({
    this.morningEnabled = true,
    this.morningHour = 6,
    this.morningMinute = 30,
    this.eveningEnabled = true,
    this.eveningHour = 17,
    this.eveningMinute = 0,
    this.sleepEnabled = true,
    this.sleepHour = 22,
    this.sleepMinute = 0,
  });

  AdhkarReminderSettings copyWith({
    bool? morningEnabled,
    int? morningHour,
    int? morningMinute,
    bool? eveningEnabled,
    int? eveningHour,
    int? eveningMinute,
    bool? sleepEnabled,
    int? sleepHour,
    int? sleepMinute,
  }) {
    return AdhkarReminderSettings(
      morningEnabled: morningEnabled ?? this.morningEnabled,
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
      eveningEnabled: eveningEnabled ?? this.eveningEnabled,
      eveningHour: eveningHour ?? this.eveningHour,
      eveningMinute: eveningMinute ?? this.eveningMinute,
      sleepEnabled: sleepEnabled ?? this.sleepEnabled,
      sleepHour: sleepHour ?? this.sleepHour,
      sleepMinute: sleepMinute ?? this.sleepMinute,
    );
  }

  TimeOfDay get morningTime =>
      TimeOfDay(hour: morningHour, minute: morningMinute);
  TimeOfDay get eveningTime =>
      TimeOfDay(hour: eveningHour, minute: eveningMinute);
  TimeOfDay get sleepTime => TimeOfDay(hour: sleepHour, minute: sleepMinute);
}

class AdhkarReminderService {
  static const _keyMorningEnabled = 'adhkar_rem_morning_enabled';
  static const _keyMorningHour = 'adhkar_rem_morning_hour';
  static const _keyMorningMinute = 'adhkar_rem_morning_min';

  static const _keyEveningEnabled = 'adhkar_rem_evening_enabled';
  static const _keyEveningHour = 'adhkar_rem_evening_hour';
  static const _keyEveningMinute = 'adhkar_rem_evening_min';

  static const _keySleepEnabled = 'adhkar_rem_sleep_enabled';
  static const _keySleepHour = 'adhkar_rem_sleep_hour';
  static const _keySleepMinute = 'adhkar_rem_sleep_min';
  static const _scheduleStatePrefix = 'adhkar_schedule_event_';

  static const int idMorning = 301;
  static const int idEvening = 302;
  static const int idSleep = 303;

  final NotificationService _notificationService;
  final DateTime Function() _now;

  AdhkarReminderService({
    NotificationService? notificationService,
    DateTime Function()? now,
  }) : _notificationService = notificationService ?? NotificationService(),
       _now = now ?? DateTime.now;

  @visibleForTesting
  static String scheduleStateKey({
    required DateTime date,
    required AdhkarReminderType reminder,
  }) => '$_scheduleStatePrefix${_formatDate(date)}_${reminder.name}';

  static Future<bool?> wasReminderScheduled({
    required DateTime date,
    required AdhkarReminderType reminder,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(scheduleStateKey(date: date, reminder: reminder));
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _recordScheduleState({
    required AdhkarReminderType reminder,
    required bool scheduled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _now();
    final firstDateToKeep = DateTime(today.year, today.month, today.day - 1);
    final lastDateToKeep = DateTime(today.year, today.month, today.day + 7);
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_scheduleStatePrefix)) continue;
      if (key.length < _scheduleStatePrefix.length + 10) {
        await prefs.remove(key);
        continue;
      }
      final dateText = key.substring(
        _scheduleStatePrefix.length,
        _scheduleStatePrefix.length + 10,
      );
      final date = DateTime.tryParse(dateText);
      if (date == null ||
          date.isBefore(firstDateToKeep) ||
          date.isAfter(lastDateToKeep)) {
        await prefs.remove(key);
      }
    }
    for (var dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final date = DateTime(today.year, today.month, today.day + dayOffset);
      final occurrenceTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
      final hasAlarmForOccurrence =
          scheduled && (dayOffset > 0 || !occurrenceTime.isBefore(today));
      await prefs.setBool(
        scheduleStateKey(date: date, reminder: reminder),
        hasAlarmForOccurrence,
      );
    }
  }

  Future<AdhkarReminderSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AdhkarReminderSettings(
      morningEnabled: prefs.getBool(_keyMorningEnabled) ?? true,
      morningHour: prefs.getInt(_keyMorningHour) ?? 6,
      morningMinute: prefs.getInt(_keyMorningMinute) ?? 30,
      eveningEnabled: prefs.getBool(_keyEveningEnabled) ?? true,
      eveningHour: prefs.getInt(_keyEveningHour) ?? 17,
      eveningMinute: prefs.getInt(_keyEveningMinute) ?? 0,
      sleepEnabled: prefs.getBool(_keySleepEnabled) ?? true,
      sleepHour: prefs.getInt(_keySleepHour) ?? 22,
      sleepMinute: prefs.getInt(_keySleepMinute) ?? 0,
    );
  }

  Future<void> saveSettings(AdhkarReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMorningEnabled, settings.morningEnabled);
    await prefs.setInt(_keyMorningHour, settings.morningHour);
    await prefs.setInt(_keyMorningMinute, settings.morningMinute);

    await prefs.setBool(_keyEveningEnabled, settings.eveningEnabled);
    await prefs.setInt(_keyEveningHour, settings.eveningHour);
    await prefs.setInt(_keyEveningMinute, settings.eveningMinute);

    await prefs.setBool(_keySleepEnabled, settings.sleepEnabled);
    await prefs.setInt(_keySleepHour, settings.sleepHour);
    await prefs.setInt(_keySleepMinute, settings.sleepMinute);

    await applySchedules(settings);
  }

  Future<List<ScheduleOutcome>> applySchedules(
    AdhkarReminderSettings settings,
  ) async {
    final outcomes = <ScheduleOutcome>[];

    Future<void> applyOne({
      required bool enabled,
      required AdhkarReminderType reminder,
      required int id,
      required String title,
      required String body,
      required int hour,
      required int minute,
      required String payload,
    }) async {
      var scheduled = false;
      try {
        if (enabled) {
          final outcome = await _notificationService
              .scheduleDailyAdhkarNotification(
                id: id,
                title: title,
                body: body,
                hour: hour,
                minute: minute,
                payload: payload,
              );
          outcomes.add(outcome);
          scheduled =
              outcome.status == ScheduleOutcomeStatus.exact ||
              outcome.status == ScheduleOutcomeStatus.inexactFallback;
        } else {
          final canceled = await _notificationService.tryCancelNotification(id);
          if (!canceled) {
            outcomes.add(
              ScheduleOutcome(
                status: ScheduleOutcomeStatus.failed,
                notificationId: id,
                errorMessage: 'Failed to cancel disabled Adhkar reminder $id',
              ),
            );
          }
        }
      } catch (error) {
        outcomes.add(
          ScheduleOutcome(
            status: ScheduleOutcomeStatus.failed,
            notificationId: id,
            errorMessage: error.toString(),
          ),
        );
      } finally {
        await _recordScheduleState(
          reminder: reminder,
          scheduled: enabled && scheduled,
          hour: hour,
          minute: minute,
        );
      }
    }

    // 1. Morning Adhkar
    await applyOne(
      enabled: settings.morningEnabled,
      reminder: AdhkarReminderType.morning,
      id: idMorning,
      title: 'أذكار الصباح',
      body: 'أصبحنا وأصبح الملك لله.. ابدأ يومك بحفظ الله وذكره',
      hour: settings.morningHour,
      minute: settings.morningMinute,
      payload: 'morning',
    );

    // 2. Evening Adhkar
    await applyOne(
      enabled: settings.eveningEnabled,
      reminder: AdhkarReminderType.evening,
      id: idEvening,
      title: 'أذكار المساء',
      body: 'أمسينا وأمسى الملك لله.. حصّن نفسك بحفظ الله وذكره',
      hour: settings.eveningHour,
      minute: settings.eveningMinute,
      payload: 'evening',
    );

    // 3. Sleep Adhkar
    await applyOne(
      enabled: settings.sleepEnabled,
      reminder: AdhkarReminderType.sleep,
      id: idSleep,
      title: 'أذكار النوم',
      body: 'باسمك ربي وضعت جنبي وبك أرفعه.. لا تنسَ أذكار النوم وسورة الملك',
      hour: settings.sleepHour,
      minute: settings.sleepMinute,
      payload: 'sleeping',
    );

    return outcomes;
  }
}
