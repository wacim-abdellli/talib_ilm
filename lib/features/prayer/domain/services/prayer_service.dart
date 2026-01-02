import '../../data/models/prayer_models.dart';
import '../../../../core/services/prayer_time_service.dart';

class PrayerService {
  final PrayerTimeService _prayerTimeService;
  final DateTime Function() now;

  PrayerService({
    PrayerTimeService? prayerTimeService,
    DateTime Function()? now,
  })  : _prayerTimeService = prayerTimeService ?? PrayerTimeService(),
        now = now ?? DateTime.now;

  Future<NextPrayer> getNextPrayer() async {
    final current = now().toLocal();
    final day = await _prayerTimeService.getPrayerTimesDay();
    final nextEntry = _findNextPrayer(day.prayers, current);

    MapEntry<String, DateTime> resolvedEntry;
    if (nextEntry == null) {
      final tomorrow = current.add(const Duration(days: 1));
      final tomorrowDay =
          await _prayerTimeService.getPrayerTimesDay(date: tomorrow);
      final entries = tomorrowDay.prayers.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      resolvedEntry = entries.first;
    } else {
      resolvedEntry = nextEntry;
    }

    final minutes = resolvedEntry.value.difference(current).inMinutes;

    return NextPrayer(
      prayer: prayerFromLabel(resolvedEntry.key) ?? Prayer.fajr,
      time: resolvedEntry.value,
      minutesRemaining: minutes < 0 ? 0 : minutes,
    );
  }

  MapEntry<String, DateTime>? _findNextPrayer(
    Map<String, DateTime> prayers,
    DateTime current,
  ) {
    final entries = prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in entries) {
      if (!entry.value.isBefore(current)) {
        return entry;
      }
    }

    return null;
  }
}
