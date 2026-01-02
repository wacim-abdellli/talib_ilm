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
    final day = await _prayerTimeService.getPrayerTimesDay();
    final nextTime = day.prayers[day.nextPrayer];
    final resolvedTime = nextTime ?? day.prayers.values.first;
    final minutes = resolvedTime.difference(now()).inMinutes;

    return NextPrayer(
      prayer: prayerFromLabel(day.nextPrayer) ?? Prayer.fajr,
      time: resolvedTime,
      minutesRemaining: minutes < 0 ? 0 : minutes,
    );
  }
}
