import 'package:talib_ilm/app/constants/app_strings.dart';

enum Prayer {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
}

extension PrayerLabels on Prayer {
  String get labelAr {
    switch (this) {
      case Prayer.fajr:
        return AppStrings.prayerFajr;
      case Prayer.dhuhr:
        return AppStrings.prayerDhuhr;
      case Prayer.asr:
        return AppStrings.prayerAsr;
      case Prayer.maghrib:
        return AppStrings.prayerMaghrib;
      case Prayer.isha:
        return AppStrings.prayerIsha;
    }
  }
}

class NextPrayer {
  final Prayer prayer;
  final DateTime time;
  final int minutesRemaining;

  const NextPrayer({
    required this.prayer,
    required this.time,
    required this.minutesRemaining,
  });
}

class PrayerTimesDay {
  final String city;
  final DateTime date;
  final Map<String, DateTime> prayers;
  final String nextPrayer;

  const PrayerTimesDay({
    required this.city,
    required this.date,
    required this.prayers,
    required this.nextPrayer,
  });
}

Prayer? prayerFromLabel(String label) {
  switch (label) {
    case AppStrings.prayerFajr:
      return Prayer.fajr;
    case AppStrings.prayerDhuhr:
      return Prayer.dhuhr;
    case AppStrings.prayerAsr:
      return Prayer.asr;
    case AppStrings.prayerMaghrib:
      return Prayer.maghrib;
    case AppStrings.prayerIsha:
      return Prayer.isha;
  }
  return null;
}

/// Formats a [DateTime] into a 12-hour Arabic prayer time string
/// using standard Western Arabic numerals (e.g. "10:09 ص", "1:29 م")
/// instead of Arabic-Indic ("Indian") numerals.
String formatPrayerTime12h(DateTime time) {
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minuteStr = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'م' : 'ص';
  return '$hour12:$minuteStr $period';
}
