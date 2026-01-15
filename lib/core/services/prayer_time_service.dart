import 'package:adhan/adhan.dart';
import '../../app/constants/app_strings.dart';
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
    final current = (date ?? now()).toLocal();
    try {
      final location = await _locationService.getLocation();
      return _buildDay(
        current,
        city: location.city,
        latitude: location.latitude,
        longitude: location.longitude,
        date: date,
      );
    } catch (_) {
      return _buildDay(
        current,
        city: AppStrings.locationDefaultCity,
        latitude: 21.3891,
        longitude: 39.8579,
        date: date,
      );
    }
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

  PrayerTimesDay _buildDay(
    DateTime current, {
    required String city,
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final safeLat = latitude.clamp(-90.0, 90.0);
    final safeLon = longitude.clamp(-180.0, 180.0);
    final coordinates = Coordinates(safeLat, safeLon);
    final params = CalculationMethod.muslim_world_league.getParameters()
      ..madhab = Madhab.shafi;
    final dateComponents = DateComponents.from(current);
    final times = PrayerTimes(coordinates, dateComponents, params);

    final prayers = <String, DateTime>{
      AppStrings.prayerFajr: times.fajr,
      AppStrings.prayerDhuhr: times.dhuhr,
      AppStrings.prayerAsr: times.asr,
      AppStrings.prayerMaghrib: times.maghrib,
      AppStrings.prayerIsha: times.isha,
    };

    final reference = date == null
        ? current
        : DateTime(current.year, current.month, current.day);
    final nextPrayer = _nextPrayerName(prayers, reference);

    return PrayerTimesDay(
      city: city,
      date: DateTime(current.year, current.month, current.day),
      prayers: prayers,
      nextPrayer: nextPrayer,
    );
  }
}
