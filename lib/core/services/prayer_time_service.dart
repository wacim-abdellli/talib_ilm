import 'package:adhan/adhan.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import 'location_service.dart';

class PrayerTimeService {
  final LocationService _locationService;
  final DateTime Function() now;

  PrayerTimeService({
    LocationService? locationService,
    DateTime Function()? now,
  })  : _locationService = locationService ?? LocationService(),
        now = now ?? DateTime.now;

  Future<PrayerTimesDay> getPrayerTimesDay({DateTime? date}) async {
    final current = date ?? now();
    final location = await _locationService.getLocation();

    final coordinates = Coordinates(location.latitude, location.longitude);
    final params = CalculationMethod.muslim_world_league.getParameters()
      ..madhab = Madhab.shafi;

    final dateComponents = DateComponents.from(current);
    final times = PrayerTimes(coordinates, dateComponents, params);

    final prayers = <String, DateTime>{
      'الفجر': times.fajr,
      'الظهر': times.dhuhr,
      'العصر': times.asr,
      'المغرب': times.maghrib,
      'العشاء': times.isha,
    };

    final nextPrayer = _nextPrayerName(prayers, current);

    return PrayerTimesDay(
      city: location.city,
      date: DateTime(current.year, current.month, current.day),
      prayers: prayers,
      nextPrayer: nextPrayer,
    );
  }

  String _nextPrayerName(Map<String, DateTime> prayers, DateTime now) {
    final entries = prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in entries) {
      if (!entry.value.isBefore(now)) {
        return entry.key;
      }
    }

    return entries.first.key;
  }
}
