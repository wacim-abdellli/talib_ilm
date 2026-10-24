import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';
import '../constants/app_policy.dart';
import '../constants/verified_cities.dart';
import '../models/location_result.dart';
import 'reverse_geocode_client.dart';
export '../models/location_result.dart';

class LocationService {
  static const _defaultCity = AppStrings.locationDefaultCity;
  static const _defaultLat = 21.3891;
  static const _defaultLon = 39.8579;

  static const _keyAllowRemoteGeocoding = 'allow_remote_geocoding';

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
  static bool _isGpsRefreshing = false;
  static DateTime? _lastGpsRefreshTime;

  /// Fast access to the in-memory cached location if present
  static LocationResult? get cachedLocation => _memoryCache;
  static DateTime? get cacheTime => _cacheTime;

  /// Global real-time notifier whenever location is acquired or changed
  static final ValueNotifier<LocationResult?> onLocationChanged =
      ValueNotifier<LocationResult?>(null);

  static void _notifyLocationChanged(LocationResult resolved) {
    _memoryCache = resolved;
    _cacheTime = DateTime.now();
    final current = onLocationChanged.value;
    if (current != null && current == resolved) {
      return;
    }
    onLocationChanged.value = resolved;
  }

  /// Clears in-memory location cache so subsequent lookups re-fetch fresh data
  static void clearCache() {
    _memoryCache = null;
    _cacheTime = null;
    _lastGpsRefreshTime = null;
  }

  /// Retrieves the location strictly prioritizing phone hardware GPS automatically:
  /// 1. In-memory fast cache (zero allocation)
  /// 2. Manual user override (if user explicitly selected a city/coordinates)
  /// 3. Cached verified GPS fix from previous satellite acquisition (instant 0ms startup)
  /// 4. Phone hardware GPS satellites (with background refresh)
  /// 5. Default fallback (Makkah)
  Future<LocationResult> getLocation({bool autoPrompt = true}) async {
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
                timeLimit: AppPolicy.locationQuick,
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

            _notifyLocationChanged(resolved);
            return resolved;
          } catch (_) {
            if (quickBest != null) {
              _notifyLocationChanged(quickBest);
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
    if (_isGpsRefreshing) return;
    if (_lastGpsRefreshTime != null &&
        DateTime.now().difference(_lastGpsRefreshTime!) < const Duration(minutes: 15)) {
      return;
    }
    _isGpsRefreshing = true;
    _lastGpsRefreshTime = DateTime.now();
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: AppPolicy.locationBackground,
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
      _notifyLocationChanged(resolved);
    } catch (_) {
    } finally {
      _isGpsRefreshing = false;
    }
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
        timeLimit: AppPolicy.networkRetry,
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

    _notifyLocationChanged(resolved);

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

    _notifyLocationChanged(location);
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

    clearCache();
    final fresh = await getLocation(autoPrompt: false);
    _notifyLocationChanged(fresh);
  }

  Future<void> _ensureLocale() async {
    if (_localeReady) return;
    try {
      await setLocaleIdentifier('ar');
    } catch (_) {}
    _localeReady = true;
  }

  /// Controls whether remote coordinate reverse-geocoding (api.bigdatacloud.net) is permitted.
  /// Defaults to false (opt-in only) to strictly protect user location privacy.
  static Future<bool> isRemoteGeocodingAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAllowRemoteGeocoding) ?? false;
  }

  /// Sets user intent for remote coordinate reverse-geocoding.
  static Future<void> setRemoteGeocodingAllowed(bool allowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAllowRemoteGeocoding, allowed);
  }

  static ReverseGeocodeClient _reverseGeocodeClient = const ReverseGeocodeClient();

  @visibleForTesting
  static void setReverseGeocodeClientForTesting(ReverseGeocodeClient client) {
    _reverseGeocodeClient = client;
  }

  @visibleForTesting
  static void resetReverseGeocodeClientForTesting() {
    _reverseGeocodeClient = const ReverseGeocodeClient();
  }

  /// Reverse geocodes coordinates via BigDataCloud API with strict resource, timeout, and payload bounds.
  @visibleForTesting
  Future<Map<String, String>?> reverseGeocodeHttp(
    double latitude,
    double longitude, {
    HttpClient? clientOverride,
  }) =>
      _reverseGeocodeClient.reverseGeocode(
        latitude,
        longitude,
        clientOverride: clientOverride,
      );

  @visibleForTesting
  Future<LocationResult> resolvePositionForTesting(
    Position position,
    String fallbackCity, {
    String? fallbackCountry,
    String? fallbackCountryCode,
    LocationSource source = LocationSource.gps,
  }) =>
      _resolvePosition(
        position,
        fallbackCity,
        fallbackCountry: fallbackCountry,
        fallbackCountryCode: fallbackCountryCode,
        source: source,
      );

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
      ).timeout(AppPolicy.networkFast);
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
      // 3. Fallback: HTTP reverse geocoding (gated by user intent / preference)
      final allowRemote = await isRemoteGeocodingAllowed();
      if (allowRemote) {
        final arabicGeo = await reverseGeocodeHttp(position.latitude, position.longitude);
        if (arabicGeo != null) {
          if (arabicGeo['city'] != null) city = arabicGeo['city']!;
          if (arabicGeo['province'] != null) province = arabicGeo['province'];
          if (arabicGeo['country'] != null) country = arabicGeo['country'];
          if (arabicGeo['countryCode'] != null) countryCode = arabicGeo['countryCode'];
        }
      } else {
        // Offline broader catalog fallback without remote coordinate transmission
        final nearestBroad = VerifiedCitiesCatalog.findNearest(
          position.latitude,
          position.longitude,
          maxDistanceKm: 250.0,
        );
        if (nearestBroad != null) {
          city = nearestBroad.name;
          province = nearestBroad.province;
          country = nearestBroad.country;
          countryCode = nearestBroad.countryCode;
        }
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

  String? _pickCleanCity(List<Placemark> placemarks) =>
      _reverseGeocodeClient.pickCleanCity(placemarks);

  static String _cleanAdministrativeName(String raw) =>
      ReverseGeocodeClient.cleanAdministrativeName(raw);
}
