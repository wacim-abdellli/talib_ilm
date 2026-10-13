import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';
import '../constants/verified_cities.dart';

enum LocationSource {
  gps,
  manual,
  savedGps,
  defaultCity,
}

class LocationResult {
  final double latitude;
  final double longitude;
  final String city;
  final String? country;
  final String? countryCode;
  final String? province;
  final LocationSource source;
  final String? calculationMethod;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.city,
    this.country,
    this.countryCode,
    this.province,
    this.source = LocationSource.defaultCity,
    this.calculationMethod,
  });

  bool get isAccurate =>
      source == LocationSource.gps ||
      source == LocationSource.manual ||
      source == LocationSource.savedGps;

  String get sourceLabel {
    switch (source) {
      case LocationSource.gps:
        return 'موقع GPS دقيق وتلقائي';
      case LocationSource.manual:
        return 'مدينة محددة يدوياً';
      case LocationSource.savedGps:
        return 'موقع GPS محفوظ';
      case LocationSource.defaultCity:
        return 'الموقع الافتراضي';
    }
  }
}

class LocationService {
  static const _defaultCity = AppStrings.locationDefaultCity;
  static const _defaultLat = 21.3891;
  static const _defaultLon = 39.8579;

  static Duration _sec(int s) => Duration(seconds: s); // ui-lint: allow service network timeout

  static const _keyCity = 'last_city';
  static const _keyProvince = 'last_province';
  static const _keyCountry = 'last_country';
  static const _keyCountryCode = 'last_country_code';
  static const _keyLat = 'last_lat';
  static const _keyLon = 'last_lon';
  static const _keyIsVerifiedGps = 'last_is_verified_gps';

  static const _keyManualEnabled = 'manual_location_enabled';
  static const _keyManualCity = 'manual_city';
  static const _keyManualProvince = 'manual_province';
  static const _keyManualCountry = 'manual_country';
  static const _keyManualCountryCode = 'manual_country_code';
  static const _keyManualLat = 'manual_lat';
  static const _keyManualLon = 'manual_lon';
  static const _keyManualCalcMethod = 'manual_calc_method';

  static bool _localeReady = false;
  static LocationResult? _memoryCache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 15);

  /// Retrieves the location strictly prioritizing phone hardware GPS automatically:
  /// 1. In-memory fast cache (zero allocation)
  /// 2. Manual user override (if user explicitly selected a city/coordinates)
  /// 3. Cached verified GPS fix from previous satellite acquisition (instant 0ms startup)
  /// 4. Phone hardware GPS satellites (with background refresh)
  /// 5. Default fallback (Makkah)
  Future<LocationResult> getLocation({bool autoPrompt = true}) async {
    // 0. Instant in-memory cache
    if (_memoryCache != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _memoryCache!;
      }
    }

    final prefs = await SharedPreferences.getInstance();

    // Clean up any stale unverified IP estimates from previous app sessions
    final isGpsVerified = prefs.getBool(_keyIsVerifiedGps) ?? false;
    final isManual = prefs.getBool(_keyManualEnabled) ?? false;
    final savedCity = prefs.getString(_keyCity);
    if (!isGpsVerified && !isManual && (savedCity == 'شربان' || savedCity == 'المهدية' || savedCity == 'Chorbane')) {
      await prefs.remove(_keyCity);
      await prefs.remove(_keyProvince);
      await prefs.remove(_keyLat);
      await prefs.remove(_keyLon);
    }

    // 1. Manual user choice takes priority if enabled
    final manual = _loadManual(prefs);
    if (manual != null) {
      _memoryCache = manual;
      _cacheTime = DateTime.now();
      return manual;
    }

    // 2. Previously verified GPS fix available: return instantly for zero-latency startup
    final saved = _loadFallback(prefs);
    if (saved.source == LocationSource.savedGps) {
      _memoryCache = saved;
      _cacheTime = DateTime.now();
      // Background non-blocking refresh of fresh satellites
      unawaited(_backgroundGpsRefresh(prefs));
      return saved;
    }

    // 3. Hardware GPS: automatically requested & acquired if no verified fix exists yet
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && autoPrompt) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        if (isServiceEnabled) {
          await _ensureLocale();

          // 3a. Quick last known hardware position
          final lastKnown = await Geolocator.getLastKnownPosition();
          LocationResult? quickBest;
          if (lastKnown != null) {
            quickBest = await _resolvePosition(
              lastKnown,
              _defaultCity,
              source: LocationSource.savedGps,
            );
          }

          // 3b. High accuracy fresh position from satellite GPS
          try {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: _sec(6),
              ),
            );

            final resolved = await _resolvePosition(
              position,
              quickBest?.city ?? _defaultCity,
              source: LocationSource.gps,
            );

            await _saveLastKnown(
              prefs,
              city: resolved.city,
              province: resolved.province,
              country: resolved.country,
              countryCode: resolved.countryCode,
              latitude: resolved.latitude,
              longitude: resolved.longitude,
              isVerifiedGps: true,
            );

            _memoryCache = resolved;
            _cacheTime = DateTime.now();
            return resolved;
          } catch (_) {
            if (quickBest != null) {
              _memoryCache = quickBest;
              _cacheTime = DateTime.now();
              return quickBest;
            }
          }
        }
      }
    } catch (_) {}

    // 4. Default fallback (Makkah Al-Mukarramah) until GPS is granted
    _memoryCache = saved;
    _cacheTime = DateTime.now();
    return saved;
  }

  Future<void> _backgroundGpsRefresh(SharedPreferences prefs) async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: _sec(5),
        ),
      );
      final resolved = await _resolvePosition(
        position,
        _defaultCity,
        source: LocationSource.gps,
      );
      await _saveLastKnown(
        prefs,
        city: resolved.city,
        province: resolved.province,
        country: resolved.country,
        countryCode: resolved.countryCode,
        latitude: resolved.latitude,
        longitude: resolved.longitude,
        isVerifiedGps: true,
      );
      _memoryCache = resolved;
      _cacheTime = DateTime.now();
    } catch (_) {}
  }

  /// Explicitly triggers high-accuracy GPS detection with native system prompts
  Future<LocationResult> refreshGpsLocation({bool autoOpenSettings = false}) async {
    final prefs = await SharedPreferences.getInstance();

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (autoOpenSettings) {
        try {
          await Geolocator.openAppSettings();
        } catch (_) {}
      }
      throw Exception('لم يتم منح إذن الوصول إلى الموقع (GPS).');
    }

    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if (autoOpenSettings) {
        try {
          await Geolocator.openLocationSettings();
        } catch (_) {}
      }
      throw Exception('خدمة الموقع (GPS) مغلقة على هاتفك.');
    }

    await _ensureLocale();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: _sec(10),
      ),
    );

    final resolved = await _resolvePosition(
      position,
      AppStrings.locationDefaultCity,
      source: LocationSource.gps,
    );

    await _saveLastKnown(
      prefs,
      city: resolved.city,
      province: resolved.province,
      country: resolved.country,
      countryCode: resolved.countryCode,
      latitude: resolved.latitude,
      longitude: resolved.longitude,
      isVerifiedGps: true,
    );

    // Turn off manual override when user explicitly chooses GPS
    await prefs.setBool(_keyManualEnabled, false);

    return resolved;
  }

  LocationResult _loadFallback(SharedPreferences prefs) {
    final lat = prefs.getDouble(_keyLat) ?? _defaultLat;
    final lon = prefs.getDouble(_keyLon) ?? _defaultLon;
    final city = prefs.getString(_keyCity) ?? _defaultCity;
    final province = prefs.getString(_keyProvince);
    final country = prefs.getString(_keyCountry);
    final countryCode = prefs.getString(_keyCountryCode);
    final isGps = prefs.getBool(_keyIsVerifiedGps) ?? false;

    return LocationResult(
      latitude: lat,
      longitude: lon,
      city: city,
      province: province,
      country: country,
      countryCode: countryCode,
      source: isGps ? LocationSource.savedGps : LocationSource.defaultCity,
    );
  }

  LocationResult? _loadManual(SharedPreferences prefs) {
    final enabled = prefs.getBool(_keyManualEnabled) ?? false;
    if (!enabled) return null;
    final lat = prefs.getDouble(_keyManualLat);
    final lon = prefs.getDouble(_keyManualLon);
    if (lat == null || lon == null) return null;
    final city = prefs.getString(_keyManualCity) ?? AppStrings.locationManualDefault;
    final province = prefs.getString(_keyManualProvince);
    final country = prefs.getString(_keyManualCountry);
    final countryCode = prefs.getString(_keyManualCountryCode);
    final calcMethod = prefs.getString(_keyManualCalcMethod);

    return LocationResult(
      latitude: lat,
      longitude: lon,
      city: city,
      province: province,
      country: country,
      countryCode: countryCode,
      source: LocationSource.manual,
      calculationMethod: calcMethod,
    );
  }

  Future<void> _saveLastKnown(
    SharedPreferences prefs, {
    required String city,
    String? province,
    String? country,
    String? countryCode,
    required double latitude,
    required double longitude,
    required bool isVerifiedGps,
  }) async {
    await prefs.setString(_keyCity, city);
    if (province != null) {
      await prefs.setString(_keyProvince, province);
    } else {
      await prefs.remove(_keyProvince);
    }
    if (country != null) await prefs.setString(_keyCountry, country);
    if (countryCode != null) await prefs.setString(_keyCountryCode, countryCode);
    await prefs.setDouble(_keyLat, latitude);
    await prefs.setDouble(_keyLon, longitude);
    await prefs.setBool(_keyIsVerifiedGps, isVerifiedGps);
  }

  Future<LocationResult?> getManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadManual(prefs);
  }

  Future<void> setManualLocation(LocationResult location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyManualEnabled, true);
    await prefs.setString(_keyManualCity, location.city);
    if (location.province != null) {
      await prefs.setString(_keyManualProvince, location.province!);
    } else {
      await prefs.remove(_keyManualProvince);
    }
    if (location.country != null) {
      await prefs.setString(_keyManualCountry, location.country!);
    }
    if (location.countryCode != null) {
      await prefs.setString(_keyManualCountryCode, location.countryCode!);
    }
    if (location.calculationMethod != null) {
      await prefs.setString(_keyManualCalcMethod, location.calculationMethod!);
    }
    await prefs.setDouble(_keyManualLat, location.latitude);
    await prefs.setDouble(_keyManualLon, location.longitude);
  }

  /// Sets a verified city selected from the catalog
  Future<void> setVerifiedCity(VerifiedCity city) async {
    final location = LocationResult(
      latitude: city.latitude,
      longitude: city.longitude,
      city: city.name,
      province: city.province,
      country: city.country,
      countryCode: city.countryCode,
      source: LocationSource.manual,
      calculationMethod: city.calculationMethod,
    );
    await setManualLocation(location);

    // Also update saved calc method in preferences for prayer calculations
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adhan_calc_method', city.calculationMethod);
  }

  Future<void> clearManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyManualEnabled, false);
    await prefs.remove(_keyManualCity);
    await prefs.remove(_keyManualProvince);
    await prefs.remove(_keyManualCountry);
    await prefs.remove(_keyManualCountryCode);
    await prefs.remove(_keyManualCalcMethod);
    await prefs.remove(_keyManualLat);
    await prefs.remove(_keyManualLon);
  }

  Future<void> _ensureLocale() async {
    if (_localeReady) return;
    try {
      await setLocaleIdentifier('ar');
    } catch (_) {}
    _localeReady = true;
  }

  Future<Map<String, String>?> _reverseGeocodeHttp(double latitude, double longitude) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$latitude&longitude=$longitude&localityLanguage=ar',
      );
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(_sec(4));
      if (response.statusCode == HttpStatus.ok) {
        final payload = await response.transform(utf8.decoder).join();
        client.close();
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic>) {
          final res = <String, String>{};
          final subdivision = data['principalSubdivision'];
          final locality = data['city'] ?? data['locality'];

          // Prefer clean province or major subdivision over obscure cadastral hamlets
          if (subdivision is String && subdivision.trim().isNotEmpty) {
            res['province'] = _cleanAdministrativeName(subdivision.trim());
          }
          if (locality is String && locality.trim().isNotEmpty) {
            res['city'] = _cleanAdministrativeName(locality.trim());
          }
          if (data['countryName'] is String && (data['countryName'] as String).trim().isNotEmpty) {
            res['country'] = (data['countryName'] as String).trim();
          }
          if (data['countryCode'] is String && (data['countryCode'] as String).trim().isNotEmpty) {
            res['countryCode'] = (data['countryCode'] as String).trim().toUpperCase();
          }
          return res;
        }
      } else {
        client.close();
      }
    } catch (_) {}
    return null;
  }

  Future<LocationResult> _resolvePosition(
    Position position,
    String fallbackCity, {
    String? fallbackCountry,
    String? fallbackCountryCode,
    LocationSource source = LocationSource.gps,
  }) async {
    // 1. Cross-reference exact GPS coordinates with VerifiedCitiesCatalog
    // Within 45km of an official Wilaya/City center to cover the entire governorate/wilaya!
    final nearest = VerifiedCitiesCatalog.findNearest(
      position.latitude,
      position.longitude,
      maxDistanceKm: 45.0,
    );

    if (nearest != null) {
      return LocationResult(
        // Retain exact GPS coordinates for mathematical prayer accuracy!
        latitude: position.latitude,
        longitude: position.longitude,
        city: nearest.name,
        province: nearest.province,
        country: nearest.country,
        countryCode: nearest.countryCode,
        source: source,
        calculationMethod: nearest.calculationMethod,
      );
    }

    var city = fallbackCity;
    String? province;
    String? country = fallbackCountry;
    String? countryCode = fallbackCountryCode;

    // 2. Try native device geocoder
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        country = p.country?.trim() ?? country;
        countryCode = p.isoCountryCode?.trim().toUpperCase() ?? countryCode;
        if (p.administrativeArea != null && p.administrativeArea!.trim().isNotEmpty) {
          province = _cleanAdministrativeName(p.administrativeArea!.trim());
        }

        final picked = _pickCleanCity(placemarks);
        if (picked != null) city = picked;
      }
    } catch (_) {
      // 3. Fallback: HTTP reverse geocoding
      final arabicGeo = await _reverseGeocodeHttp(position.latitude, position.longitude);
      if (arabicGeo != null) {
        if (arabicGeo['city'] != null) city = arabicGeo['city']!;
        if (arabicGeo['province'] != null) province = arabicGeo['province'];
        if (arabicGeo['country'] != null) country = arabicGeo['country'];
        if (arabicGeo['countryCode'] != null) countryCode = arabicGeo['countryCode'];
      }
    }

    if (city == _defaultCity && (position.latitude != _defaultLat)) {
      city = province ?? country ?? AppStrings.locationCurrent;
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      province: province,
      country: country,
      countryCode: countryCode,
      source: source,
    );
  }

  String? _pickCleanCity(List<Placemark> placemarks) {
    for (final place in placemarks) {
      final admin = place.administrativeArea?.trim();
      final locality = place.locality?.trim();
      final sub = place.subAdministrativeArea?.trim();

      if (locality != null && locality.isNotEmpty) {
        final cleanLocality = _cleanAdministrativeName(locality);
        if (admin != null && admin.isNotEmpty) {
          final cleanAdmin = _cleanAdministrativeName(admin);
          if (cleanAdmin != cleanLocality) {
            return cleanAdmin;
          }
        }
        return cleanLocality;
      }

      if (sub != null && sub.isNotEmpty) return _cleanAdministrativeName(sub);
      if (admin != null && admin.isNotEmpty) return _cleanAdministrativeName(admin);
    }
    return null;
  }

  static String _cleanAdministrativeName(String raw) {
    var s = raw.trim();
    // Remove French / English prefixes
    s = s.replaceAll(RegExp(r'^(Commune de|Gouvernorat de|Province de|Wilaya de|State of|Province of)\s+', caseSensitive: false), '');
    // Clean Arabic prefixes if redundant
    if (s.startsWith('ولاية ')) s = s.substring(6).trim();
    if (s.startsWith('محافظة ')) s = s.substring(7).trim();
    return s.trim();
  }
}
