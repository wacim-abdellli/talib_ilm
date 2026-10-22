import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// Information regarding the White Days (Ayyam al-Bid: 13, 14, 15) for a Hijri month.
class WhiteDaysInfo {
  final int hijriYear;
  final int hijriMonth;
  final String monthName;
  final DateTime day13;
  final DateTime day14;
  final DateTime day15;
  final bool isRamadan;
  final bool isDhuAlHijjah;

  const WhiteDaysInfo({
    required this.hijriYear,
    required this.hijriMonth,
    required this.monthName,
    required this.day13,
    required this.day14,
    required this.day15,
    required this.isRamadan,
    required this.isDhuAlHijjah,
  });

  /// True if [date] falls on 13, 14, or 15 of this Hijri month
  bool isWhiteDay(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final d13 = DateTime(day13.year, day13.month, day13.day);
    final d14 = DateTime(day14.year, day14.month, day14.day);
    final d15 = DateTime(day15.year, day15.month, day15.day);
    return d == d13 || d == d14 || d == d15;
  }

  /// Returns 13, 14, or 15 if [date] matches, or null otherwise
  int? getWhiteDayNumber(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    if (d == DateTime(day13.year, day13.month, day13.day)) return 13;
    if (d == DateTime(day14.year, day14.month, day14.day)) return 14;
    if (d == DateTime(day15.year, day15.month, day15.day)) return 15;
    return null;
  }
}

/// Information regarding Monday and Thursday Sunnah fasting.
class NextSunnahFastInfo {
  final bool isTodaySunnah;
  final bool isTomorrowSunnah;
  final String? todayName;
  final String nextDayName;
  final int daysToNext;

  const NextSunnahFastInfo({
    required this.isTodaySunnah,
    required this.isTomorrowSunnah,
    this.todayName,
    required this.nextDayName,
    required this.daysToNext,
  });
}

/// Service managing Sunnah fasting dates, interactive tracker persistence, and notifications.
class FastingReminderService {
  static const String _keyReminderEnabled = 'sunnah_fasting_reminder_enabled';
  static const String _keyTrackerPrefix = 'sunnah_fasting_completed_';

  static const int idWhiteDay1 = 501;
  static const int idWhiteDay2 = 502;
  static const int idWhiteDay3 = 503;
  static const int idMondayEve = 504;
  static const int idThursdayEve = 505;

  final NotificationService _notificationService;

  FastingReminderService({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  /// Gets White Days data based on current or upcoming Hijri month.
  static WhiteDaysInfo getWhiteDaysInfo([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    try {
      HijriCalendar.setLocal('ar');
    } catch (_) {}
    final h = HijriCalendar.fromDate(ref);

    // If today is past the 15th, calculate for the next Hijri month's White Days
    DateTime? d13, d14, d15;
    final cur = DateTime(ref.year, ref.month, ref.day);

    if (h.hDay <= 15) {
      d13 = cur.add(Duration(days: 13 - h.hDay));
      d14 = cur.add(Duration(days: 14 - h.hDay));
      d15 = cur.add(Duration(days: 15 - h.hDay));
    } else {
      final targetMonth = h.hMonth == 12 ? 1 : h.hMonth + 1;
      for (var i = 1; i <= 35; i++) {
        final candidate = cur.add(Duration(days: i));
        final hCand = HijriCalendar.fromDate(candidate);
        if (hCand.hMonth == targetMonth && hCand.hDay == 13) {
          d13 = candidate;
          d14 = candidate.add(const Duration(days: 1));
          d15 = candidate.add(const Duration(days: 2));
          break;
        }
      }
    }

    d13 ??= cur;
    d14 ??= cur.add(const Duration(days: 1));
    d15 ??= cur.add(const Duration(days: 2));

    final targetH = HijriCalendar.fromDate(d13);
    return WhiteDaysInfo(
      hijriYear: targetH.hYear,
      hijriMonth: targetH.hMonth,
      monthName: targetH.longMonthName,
      day13: d13,
      day14: d14,
      day15: d15,
      isRamadan: targetH.hMonth == 9,
      isDhuAlHijjah: targetH.hMonth == 12,
    );
  }

  /// Checks Monday & Thursday status.
  static NextSunnahFastInfo getNextSunnahFast([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final weekday = ref.weekday;
    final isTodayMonday = (weekday == DateTime.monday);
    final isTodayThursday = (weekday == DateTime.thursday);
    final isTomorrowMonday = (weekday == DateTime.sunday);
    final isTomorrowThursday = (weekday == DateTime.wednesday);

    int daysToNext;
    String nextDayName;

    if (isTodayMonday || isTodayThursday) {
      daysToNext = 0;
      nextDayName = isTodayMonday ? 'اليوم الإثنين' : 'اليوم الخميس';
    } else if (weekday < DateTime.thursday && weekday > DateTime.monday) {
      daysToNext = DateTime.thursday - weekday;
      nextDayName = 'الخميس';
    } else {
      daysToNext = (DateTime.monday + 7 - weekday) % 7;
      if (daysToNext == 0) daysToNext = 7;
      nextDayName = 'الإثنين';
    }

    return NextSunnahFastInfo(
      isTodaySunnah: isTodayMonday || isTodayThursday,
      isTomorrowSunnah: isTomorrowMonday || isTomorrowThursday,
      todayName: isTodayMonday ? 'الإثنين' : (isTodayThursday ? 'الخميس' : null),
      nextDayName: nextDayName,
      daysToNext: daysToNext,
    );
  }

  /// Whether fasting reminder notifications are enabled (defaults to true).
  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReminderEnabled) ?? true;
  }

  /// Sets fasting reminder toggle and reschedules notifications.
  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderEnabled, enabled);
    await syncSchedules(enabled);
  }

  /// Gets tracker completion status for a specific White Day of a given Hijri month.
  static Future<bool> isDayCompleted(int year, int month, int day) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyTrackerPrefix${year}_${month}_$day') ?? false;
  }

  /// Toggles tracker completion status for a specific White Day.
  static Future<bool> toggleDayCompleted(int year, int month, int day, bool currentVal) async {
    final prefs = await SharedPreferences.getInstance();
    final newVal = !currentVal;
    await prefs.setBool('$_keyTrackerPrefix${year}_${month}_$day', newVal);
    return newVal;
  }

  /// Syncs all upcoming fasting notifications (White Days and Mon/Thu).
  Future<void> syncSchedules([bool? forceState]) async {
    final enabled = forceState ?? await isReminderEnabled();
    if (!enabled) {
      await _cancelAll();
      return;
    }

    final now = DateTime.now();
    final info = getWhiteDaysInfo(now);

    // Schedule White Days notifications at 20:30 the evening before each White Day
    // Day 13 eve (night of 12th)
    final eve13 = DateTime(info.day13.year, info.day13.month, info.day13.day - 1, 20, 30);
    if (eve13.isAfter(now)) {
      await _notificationService.scheduleFastingReminder(
        id: idWhiteDay1,
        title: 'تذكير: غداً صيام أول الأيام البيض (13)',
        body: '«صيام ثلاثة أيام من كل شهر صيام الدهر» — استعد لصيام الغد',
        scheduledDate: eve13,
        payload: 'fasting_white_days',
      );
    }

    // Day 14 eve (night of 13th)
    final eve14 = DateTime(info.day14.year, info.day14.month, info.day14.day - 1, 20, 30);
    if (eve14.isAfter(now)) {
      await _notificationService.scheduleFastingReminder(
        id: idWhiteDay2,
        title: 'تذكير: غداً صيام ثاني الأيام البيض (14)',
        body: 'تقبل الله طاعتكم — واصل صيام الأيام البيض المسنونة',
        scheduledDate: eve14,
        payload: 'fasting_white_days',
      );
    }

    // Day 15 eve (night of 14th)
    final eve15 = DateTime(info.day15.year, info.day15.month, info.day15.day - 1, 20, 30);
    if (eve15.isAfter(now)) {
      await _notificationService.scheduleFastingReminder(
        id: idWhiteDay3,
        title: 'تذكير: غداً صيام ثالث الأيام البيض (15)',
        body: 'اليوم الأخير من الأيام البيض لشهر ${info.monthName} — نيل أجر صيام الشهر',
        scheduledDate: eve15,
        payload: 'fasting_white_days',
      );
    }

    // Schedule Monday eve (Sunday 20:30)
    final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    final nextSunday = DateTime(now.year, now.month, now.day + (daysUntilSunday == 0 && now.hour >= 21 ? 7 : daysUntilSunday), 20, 30);
    if (nextSunday.isAfter(now)) {
      await _notificationService.scheduleFastingReminder(
        id: idMondayEve,
        title: 'تذكير: غداً الإثنين سنة الصيام',
        body: '«تُعرَض الأعمالُ يومَ الاثنين والخميس، فأحب أن يُعرَض عملي وأنا صائم»',
        scheduledDate: nextSunday,
        payload: 'fasting_monday',
      );
    }

    // Schedule Thursday eve (Wednesday 20:30)
    final daysUntilWed = (DateTime.wednesday - now.weekday + 7) % 7;
    final nextWed = DateTime(now.year, now.month, now.day + (daysUntilWed == 0 && now.hour >= 21 ? 7 : daysUntilWed), 20, 30);
    if (nextWed.isAfter(now)) {
      await _notificationService.scheduleFastingReminder(
        id: idThursdayEve,
        title: 'تذكير: غداً الخميس سنة الصيام',
        body: '«تُعرَض الأعمالُ يومَ الاثنين والخميس، فأحب أن يُعرَض عملي وأنا صائم»',
        scheduledDate: nextWed,
        payload: 'fasting_thursday',
      );
    }
  }

  Future<void> _cancelAll() async {
    await _notificationService.cancelNotification(idWhiteDay1);
    await _notificationService.cancelNotification(idWhiteDay2);
    await _notificationService.cancelNotification(idWhiteDay3);
    await _notificationService.cancelNotification(idMondayEve);
    await _notificationService.cancelNotification(idThursdayEve);
  }
}
