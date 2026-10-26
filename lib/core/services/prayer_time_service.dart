import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import 'location_service.dart';

class PrayerTimeService {
  final LocationService _locationService;
  final DateTime Function() now;

  static const _keyCalcMethod = 'adhan_calc_method';
  static const _keyMadhab = 'adhan_madhab';
  static const _keyAdjPrefix = 'adhan_adj_';

  static PrayerTimesDay? _cachedToday;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);
  static bool _cachedIsFallback = false;
  static bool _listenerAttached = false;

  static double? _lastLatitude;
  static double? _lastLongitude;
  static String? _lastCity;
  static String? _lastCountryCode;
  static CalculationMethod? _lastMethod;
  static String? _lastSavedMethodStr;
  static String? _lastMadhab;
  static Map<String, int> _lastAdjustments = const {};

  static void clearCache() {
    _cachedToday = null;
    _cacheTimestamp = null;
    _cachedIsFallback = false;
    _lastLatitude = null;
    _lastLongitude = null;
    _lastCity = null;
    _lastCountryCode = null;
    _lastMethod = null;
    _lastSavedMethodStr = null;
    _lastMadhab = null;
    _lastAdjustments = const {};
  }

  PrayerTimeService({
    LocationService? locationService,
    DateTime Function()? now,
  }) : _locationService = locationService ?? LocationService(),
       now = now ?? DateTime.now {
    if (!_listenerAttached) {
      _listenerAttached = true;
      LocationService.onLocationChanged.addListener(clearCache);
    }
  }

  /// Returns cached prayer times if available for today,
  /// otherwise returns an instant fallback (Makkah calculation) with 0ms delay.
  /// This ensures UI callers never block on GPS/network during initial frame build.
  PrayerTimesDay getCachedOrFallbackPrayerTimesDay() {
    final current = now().toLocal();
    if (_cachedToday != null &&
        _cachedToday!.date.day == current.day &&
        _cachedToday!.date.month == current.month &&
        _cachedToday!.date.year == current.year) {
      return _cachedToday!;
    }
    return _buildDay(
      current,
      city: AppStrings.locationDefaultCity,
      latitude: _defaultLat,
      longitude: 39.8579,
    );
  }

  Future<PrayerTimesDay> getPrayerTimesDay({
    DateTime? date,
    bool forceRefresh = false,
  }) async {
    final current = (date ?? now()).toLocal();
    final isToday = date == null;

    if (!forceRefresh &&
        isToday &&
        _cachedToday != null &&
        _cacheTimestamp != null &&
        !_cachedIsFallback) {
      if (DateTime.now().difference(_cacheTimestamp!) < _cacheDuration &&
          _cachedToday!.date.day == current.day &&
          _cachedToday!.date.month == current.month &&
          _cachedToday!.date.year == current.year) {
        return _cachedToday!;
      }
    }

    if (date != null &&
        _lastLatitude != null &&
        _lastLongitude != null &&
        _lastCity != null) {
      return _buildDay(
        current,
        city: _lastCity!,
        latitude: _lastLatitude!,
        longitude: _lastLongitude!,
        countryCode: _lastCountryCode,
        savedMethod: _lastSavedMethodStr,
        savedMadhab: _lastMadhab,
        date: date,
        method: _lastMethod ?? CalculationMethod.muslim_world_league,
        adjustments: _lastAdjustments,
      );
    }

    final prefs = await SharedPreferences.getInstance();

    // Load adjustments
    final adjustments = <String, int>{};
    for (final name in AppStrings.prayerOrder) {
      adjustments[name] = prefs.getInt('$_keyAdjPrefix$name') ?? 0;
    }

    // Load method and madhab
    final savedMethodStr = prefs.getString(_keyCalcMethod);
    final savedMadhab = prefs.getString(_keyMadhab) ?? 'shafi';

    try {
      final location = await _locationService.getLocation();
      final method = _resolveMethod(
        savedMethodStr ?? location.calculationMethod,
        countryCode: location.countryCode,
        latitude: location.latitude,
      );

      _lastLatitude = location.latitude;
      _lastLongitude = location.longitude;
      _lastCity = location.city;
      _lastCountryCode = location.countryCode;
      _lastMethod = method;
      _lastSavedMethodStr = savedMethodStr;
      _lastMadhab = savedMadhab;
      _lastAdjustments = adjustments;

      final result = _buildDay(
        current,
        city: location.city,
        latitude: location.latitude,
        longitude: location.longitude,
        countryCode: location.countryCode,
        savedMethod: savedMethodStr,
        savedMadhab: savedMadhab,
        date: date,
        method: method,
        adjustments: adjustments,
      );

      if (isToday) {
        _cachedToday = result;
        _cacheTimestamp = DateTime.now();
        _cachedIsFallback = false;
      }
      return result;
    } catch (_) {
      final method = _resolveMethod(savedMethodStr, countryCode: null, latitude: _defaultLat);
      final result = _buildDay(
        current,
        city: AppStrings.locationDefaultCity,
        latitude: _defaultLat,
        longitude: 39.8579,
        countryCode: null,
        savedMethod: savedMethodStr,
        savedMadhab: savedMadhab,
        date: date,
        method: method,
        adjustments: adjustments,
      );

      if (isToday) {
        _cachedToday = result;
        _cacheTimestamp = DateTime.now();
        _cachedIsFallback = true;
      }
      return result;
    }
  }

  static const _defaultLat = 21.3891;

  CalculationMethod _resolveMethod(
    String? savedMethod, {
    String? countryCode,
    double? latitude,
  }) {
    if (savedMethod != null && savedMethod != 'auto') {
      switch (savedMethod) {
        case 'algeria':
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
      case 'DZ': // Algeria (وزارة الشؤون الدينية والأوقاف)
      case 'MA': // Morocco (وزارة الأوقاف والشؤون الإسلامية)
      case 'TN': // Tunisia (وزارة الشؤون الدينية)
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
    String? countryCode,
    String? savedMethod,
    String? savedMadhab,
    DateTime? date,
    CalculationMethod method = CalculationMethod.muslim_world_league,
    Map<String, int> adjustments = const {},
  }) {
    final safeLat = latitude.clamp(-90.0, 90.0);
    final safeLon = longitude.clamp(-180.0, 180.0);
    final coordinates = Coordinates(safeLat, safeLon);
    final params = method.getParameters();
    params.madhab = (savedMadhab == 'hanafi') ? Madhab.hanafi : Madhab.shafi;
    if (safeLat.abs() > 48.0) {
      params.highLatitudeRule = HighLatitudeRule.twilight_angle;
    }

    // Calibrate official Ministry of Religious Affairs standard for Algeria & North Africa:
    // Official ministry timetables (Algeria, Morocco, Tunisia) calculate Isha at complete 18.0° twilight.
    // Default MWL in adhan library uses 17.0°, resulting in an astronomical ~5-minute early disparity.
    final country = (countryCode ?? '').toUpperCase().trim();
    if (country == 'DZ' || country == 'MA' || country == 'TN' || savedMethod == 'algeria') {
      params.fajrAngle = 18.0;
      params.ishaAngle = 18.0;
    }

    // Apply Adjustments to params
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

    // Native offline astronomical calculations via adhan
    final sunnahTimes = SunnahTimes(times);
    final middleOfTheNight = sunnahTimes.middleOfTheNight;
    final lastThirdOfTheNight = sunnahTimes.lastThirdOfTheNight;
    final dhuha = times.sunrise.add(const Duration(minutes: 15));
    final qiblaDirection = Qibla(coordinates).direction;

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
      final tomorrow = DateTime(current.year, current.month, current.day + 1);
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
      sunrise: times.sunrise,
      sunset: times.maghrib,
      middleOfTheNight: middleOfTheNight,
      lastThirdOfTheNight: lastThirdOfTheNight,
      dhuha: dhuha,
      qiblaDirection: qiblaDirection,
    );
  }
}
