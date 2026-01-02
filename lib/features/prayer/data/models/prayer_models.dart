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
        return 'الفجر';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
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
    case 'الفجر':
      return Prayer.fajr;
    case 'الظهر':
      return Prayer.dhuhr;
    case 'العصر':
      return Prayer.asr;
    case 'المغرب':
      return Prayer.maghrib;
    case 'العشاء':
      return Prayer.isha;
  }
  return null;
}
