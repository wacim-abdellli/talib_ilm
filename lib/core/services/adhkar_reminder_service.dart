import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

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

  static const int idMorning = 301;
  static const int idEvening = 302;
  static const int idSleep = 303;

  final NotificationService _notificationService;

  AdhkarReminderService({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

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
      required int id,
      required String title,
      required String body,
      required int hour,
      required int minute,
      required String payload,
    }) async {
      try {
        if (enabled) {
          outcomes.add(
            await _notificationService.scheduleDailyAdhkarNotification(
              id: id,
              title: title,
              body: body,
              hour: hour,
              minute: minute,
              payload: payload,
            ),
          );
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
      }
    }

    // 1. Morning Adhkar
    await applyOne(
      enabled: settings.morningEnabled,
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
