import '../../features/prayer/data/models/prayer_models.dart';

enum PrayerCity {
  makkah,
  madinah,
  riyadh,
}

enum PrayerCalculationMethod {
  fixed,
}

class PrayerService {
  final PrayerCity city;
  final PrayerCalculationMethod method;
  final DateTime Function() now;

  PrayerService({
    this.city = PrayerCity.makkah,
    this.method = PrayerCalculationMethod.fixed,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<NextPrayer> getNextPrayer() async {
    final current = now();
    final schedule = _buildSchedule(
      date: DateTime(current.year, current.month, current.day),
      city: city,
      method: method,
    );

    final sorted = schedule.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in sorted) {
      if (!entry.value.isBefore(current)) {
        final minutes = entry.value.difference(current).inMinutes;
        return NextPrayer(
          prayer: entry.key,
          time: entry.value,
          minutesRemaining: minutes,
        );
      }
    }

    final tomorrow = DateTime(current.year, current.month, current.day + 1);
    final nextDaySchedule = _buildSchedule(
      date: tomorrow,
      city: city,
      method: method,
    );
    final nextEntry = nextDaySchedule.entries
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final first = nextEntry.first;
    final minutes = first.value.difference(current).inMinutes;
    return NextPrayer(
      prayer: first.key,
      time: first.value,
      minutesRemaining: minutes,
    );
  }

  Map<Prayer, DateTime> _buildSchedule({
    required DateTime date,
    required PrayerCity city,
    required PrayerCalculationMethod method,
  }) {
    final times = _fixedTimesForCity(city);
    return {
      Prayer.fajr: _at(date, times.fajr),
      Prayer.dhuhr: _at(date, times.dhuhr),
      Prayer.asr: _at(date, times.asr),
      Prayer.maghrib: _at(date, times.maghrib),
      Prayer.isha: _at(date, times.isha),
    };
  }

  _PrayerTimes _fixedTimesForCity(PrayerCity city) {
    switch (city) {
      case PrayerCity.makkah:
        return const _PrayerTimes(
          fajr: '05:15',
          dhuhr: '12:20',
          asr: '15:35',
          maghrib: '18:05',
          isha: '19:20',
        );
      case PrayerCity.madinah:
        return const _PrayerTimes(
          fajr: '05:20',
          dhuhr: '12:25',
          asr: '15:40',
          maghrib: '18:10',
          isha: '19:25',
        );
      case PrayerCity.riyadh:
        return const _PrayerTimes(
          fajr: '05:05',
          dhuhr: '12:10',
          asr: '15:25',
          maghrib: '17:55',
          isha: '19:10',
        );
    }
  }

  DateTime _at(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

class _PrayerTimes {
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  const _PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
}
