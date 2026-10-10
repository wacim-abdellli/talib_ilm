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

    // Load method (auto-detected by country if not manually set)
    final savedMethodStr = prefs.getString(_keyCalcMethod);

    try {
      final location = await _locationService.getLocation();
      final method = _resolveMethod(
        savedMethodStr,
        countryCode: location.countryCode,
        latitude: location.latitude,
      );

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
      final method = _resolveMethod(savedMethodStr, countryCode: null, latitude: _defaultLat);
      return _buildDay(
        current,
        city: AppStrings.locationDefaultCity,
        latitude: _defaultLat,
        longitude: 39.8579,
        date: date,
        method: method,
        adjustments: adjustments,
      );
    }
  }

  static const _defaultLat = 21.3891;

  CalculationMethod _resolveMethod(
    String? savedMethod, {
    String? countryCode,
    double? latitude,
  }) {
    if (savedMethod != null) {
      switch (savedMethod) {
        case 'mwl':
          return CalculationMethod.muslim_world_league;
        case 'umm_al_qura':
          return CalculationMethod.umm_al_qura;
        case 'dubai':
          return CalculationMethod.dubai;
        case 'turkey':
          return CalculationMethod.turkey;
        case 'qatar':
          return CalculationMethod.qatar;
        case 'kuwait':
          return CalculationMethod.kuwait;
        case 'karachi':
          return CalculationMethod.karachi;
        case 'singapore':
          return CalculationMethod.singapore;
        case 'egyptian':
          return CalculationMethod.egyptian;
        default:
          break;
      }
    }

    // Auto-select standard calculation method based on country
    final code = (countryCode ?? '').toUpperCase().trim();
    switch (code) {
      case 'SA': // Saudi Arabia
      case 'YE': // Yemen
        return CalculationMethod.umm_al_qura;
      case 'EG': // Egypt
      case 'SD': // Sudan
      case 'LY': // Libya
      case 'SY': // Syria
      case 'LB': // Lebanon
      case 'JO': // Jordan
      case 'PS': // Palestine
        return CalculationMethod.egyptian;
      case 'AE': // UAE
        return CalculationMethod.dubai;
      case 'QA': // Qatar
        return CalculationMethod.qatar;
      case 'KW': // Kuwait
        return CalculationMethod.kuwait;
      case 'TR': // Turkey
        return CalculationMethod.turkey;
      case 'US': // USA
      case 'CA': // Canada
        return CalculationMethod.north_america;
      case 'PK': // Pakistan
      case 'IN': // India
      case 'BD': // Bangladesh
      case 'AF': // Afghanistan
        return CalculationMethod.karachi;
      case 'SG': // Singapore
      case 'MY': // Malaysia
      case 'ID': // Indonesia
        return CalculationMethod.singapore;
      case 'DZ': // Algeria
      case 'MA': // Morocco
      case 'TN': // Tunisia
      case 'FR': // France
      case 'GB': // UK
      case 'DE': // Germany
      case 'ES': // Spain
      case 'IT': // Italy
      default:
        // Muslim World League (18° Fajr, 17° Isha) is the official standard in Algeria & international
        return CalculationMethod.muslim_world_league;
    }
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

    DateTime nextPrayerTime;
    String nextPrayer;

    final sortedEntries = prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final upcoming = sortedEntries.where((e) => e.value.isAfter(reference)).toList();
    if (upcoming.isNotEmpty) {
      nextPrayer = upcoming.first.key;
      nextPrayerTime = upcoming.first.value;
    } else {
      // All of today's prayers have passed (after Isha); next prayer is tomorrow's Fajr
      nextPrayer = AppStrings.prayerFajr;
      final tomorrow = current.add(const Duration(days: 1));
      final tomorrowComponents = DateComponents.from(tomorrow);
      final tomorrowTimes = PrayerTimes(coordinates, tomorrowComponents, params);
      nextPrayerTime = tomorrowTimes.fajr;
    }

    return PrayerTimesDay(
      city: city,
      date: DateTime(current.year, current.month, current.day),
      prayers: prayers,
      nextPrayer: nextPrayer,
      nextPrayerTime: nextPrayerTime,
    );
  }
}
