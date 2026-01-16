import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import 'location_service.dart';

class PrayerTimeService {
  final LocationService _locationService;
  final DateTime Function() now;

  static const _keyCalcMethod = 'adhan_calc_method';
  static const _keyAdjPrefix = 'adhan_adj_';

  PrayerTimeService({
    LocationService? locationService,
    DateTime Function()? now,
  }) : _locationService = locationService ?? LocationService(),
       now = now ?? DateTime.now;

  Future<PrayerTimesDay> getPrayerTimesDay({DateTime? date}) async {
    final current = (date ?? now()).toLocal();
    final prefs = await SharedPreferences.getInstance();

    // Load adjustments
    final adjustments = <String, int>{};
    for (final name in AppStrings.prayerOrder) {
      adjustments[name] = prefs.getInt('$_keyAdjPrefix$name') ?? 0;
    }

    // Load method
    final methodStr = prefs.getString(_keyCalcMethod) ?? 'egyptian';
    CalculationMethod method;
    switch (methodStr) {
      case 'mwl':
        method = CalculationMethod.muslim_world_league;
        break;
      case 'umm_al_qura':
        method = CalculationMethod.umm_al_qura;
        break;
      case 'egyptian':
      default:
        method = CalculationMethod.egyptian;
        break;
    }

    try {
      final location = await _locationService.getLocation();
      return _buildDay(
        current,
        city: location.city,
        latitude: location.latitude,
        longitude: location.longitude,
        date: date,
        method: method,
        adjustments: adjustments,
      );
    } catch (_) {
      return _buildDay(
        current,
        city: AppStrings.locationDefaultCity,
        latitude: 21.3891,
        longitude: 39.8579,
        date: date,
        method: method, // Use selected method even for default location
        adjustments: adjustments,
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
    CalculationMethod method = CalculationMethod.egyptian,
    Map<String, int> adjustments = const {},
  }) {
    final safeLat = latitude.clamp(-90.0, 90.0);
    final safeLon = longitude.clamp(-180.0, 180.0);
    final coordinates = Coordinates(safeLat, safeLon);
    final params = method.getParameters()..madhab = Madhab.shafi;

    // Apply Adjustments to params?
    // Adhan package allows adjusting params.adjustments
    // adjustments using PrayerAdjustments
    // But adhan dart params.adjustments is PrayerAdjustments object
    // with fajr, sunrise, dhuhr, asr, maghrib, isha (int minutes)

    final adjFajr = adjustments[AppStrings.prayerFajr] ?? 0;
    final adjDhuhr = adjustments[AppStrings.prayerDhuhr] ?? 0;
    final adjAsr = adjustments[AppStrings.prayerAsr] ?? 0;
    final adjMaghrib = adjustments[AppStrings.prayerMaghrib] ?? 0;
    final adjIsha = adjustments[AppStrings.prayerIsha] ?? 0;

    params.adjustments.fajr = adjFajr;
    params.adjustments.dhuhr = adjDhuhr;
    params.adjustments.asr = adjAsr;
    params.adjustments.maghrib = adjMaghrib;
    params.adjustments.isha = adjIsha;

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
