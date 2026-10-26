/// App defaults for the estimated time between Adhan and Iqama.
///
/// These offsets keep countdowns and reminders consistent inside the app. They
/// are not mosque-specific Iqama timetables; local congregation times vary.
class IqamaTimingPolicy {
  IqamaTimingPolicy._();

  static int minutesAfterAdhan(String prayerName, {bool isJumua = false}) {
    if (isJumua) return 25;
    final prayer = prayerName.toLowerCase().trim();
    if (prayer.contains('فجر') || prayer.contains('fajr')) return 25;
    if (prayer.contains('ظهر') || prayer.contains('dhuhr')) return 20;
    if (prayer.contains('عصر') || prayer.contains('asr')) return 20;
    if (prayer.contains('مغرب') || prayer.contains('maghrib')) return 10;
    if (prayer.contains('عشاء') || prayer.contains('isha')) return 15;
    return 15;
  }
}
