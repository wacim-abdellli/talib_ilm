import 'package:shared_preferences/shared_preferences.dart';

import 'schedule_outcome.dart';

enum PrayerScheduleEvent { adhan, prePrayer, iqama }

/// Manages persisted OS schedule event states and pruning for prayer notifications.
class PrayerScheduleStateStore {
  static const String _eventStatePrefix = 'prayer_schedule_event_';

  const PrayerScheduleStateStore._();

  /// Returns the last OS scheduling result for one prayer occurrence.
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

  static String eventStateKey({
    required DateTime date,
    required String prayerName,
    required PrayerScheduleEvent event,
  }) => '$_eventStatePrefix${formatDateKey(date)}_${event.name}_$prayerName';

  static bool shouldUseForegroundFallback(bool? wasScheduled) =>
      wasScheduled != true;

  static String formatDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Future<void> recordEventSchedule({
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

  static bool hasPlatformAlarm(ScheduleOutcome outcome) =>
      outcome.status == ScheduleOutcomeStatus.exact ||
      outcome.status == ScheduleOutcomeStatus.inexactFallback;

  static Future<void> pruneOldEventStates(
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
}
