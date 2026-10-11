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
  ipEstimate,
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
        return 'موقع GPS دقيق ومؤكد';
      case LocationSource.manual:
        return 'مدينة محددة يدوياً';
      case LocationSource.savedGps:
        return 'موقع GPS محفوظ';
      case LocationSource.ipEstimate:
        return 'موقع تقديري (شبكة الإنترنت)';
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

  /// Retrieves the best location in prioritized order:
  /// 1. Manual user choice (verified city or coordinates)
  /// 2. Hardware GPS (real physical satellites)
  /// 3. Cached verified GPS position
  /// 4. IP estimate (last resort only)
  Future<LocationResult> getLocation() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Manual location takes absolute priority if enabled by user
    final manual = _loadManual(prefs);
    if (manual != null) return manual;

    final fallback = _loadFallback(prefs);

    // 2. Try physical Hardware GPS first
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        if (isServiceEnabled) {
          await _ensureLocale();

          // Try quick last known position for instant cache
          final lastKnown = await Geolocator.getLastKnownPosition();
          LocationResult? quickBest;
          if (lastKnown != null) {
            quickBest = await _resolvePosition(
              lastKnown,
              fallback.city,
              fallbackCountry: fallback.country,
              fallbackCountryCode: fallback.countryCode,
              source: LocationSource.savedGps,
            );
          }

          // Fetch fresh high-accuracy position (up to 8s timeout)
          try {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: _sec(8),
              ),
            );

            final resolved = await _resolvePosition(
              position,
              quickBest?.city ?? fallback.city,
              fallbackCountry: quickBest?.country ?? fallback.country,
              fallbackCountryCode: quickBest?.countryCode ?? fallback.countryCode,
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

            return resolved;
          } catch (_) {
            if (quickBest != null) return quickBest;
          }
        }
      }
    } catch (_) {}

    // 3. If GPS is unavailable/denied, check if we already have a saved verified GPS location
    if (fallback.source == LocationSource.savedGps) {
      return fallback;
    }

    // 4. Last resort: Try IP geolocation (marked as estimate, never overrides verified GPS)
    try {
      final ip = await _tryIpLocation();
      if (ip != null) {
        await _saveLastKnown(
          prefs,
          city: ip.city,
          province: ip.province,
          country: ip.country,
          countryCode: ip.countryCode,
          latitude: ip.latitude,
          longitude: ip.longitude,
          isVerifiedGps: false,
        );
        return ip;
      }
    } catch (_) {}

    return fallback;
  }

  /// Explicitly triggers high-accuracy GPS detection with full error reporting
  Future<LocationResult> refreshGpsLocation() async {
    final prefs = await SharedPreferences.getInstance();

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('تم رفض إذن الوصول إلى الموقع. يرجى منحه من إعدادات الهاتف.');
    }

    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      try {
        await Geolocator.openLocationSettings();
      } catch (_) {}
      throw Exception('خدمة الموقع (GPS) غير مفعلة على هاتفك. يرجى تفعيلها لتحديد موقعك.');
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

  Future<LocationResult?> _tryIpLocation() async {
    // 1. Try ipwho.is
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://ipwho.is/'));
      final response = await request.close().timeout(_sec(4));
      if (response.statusCode == HttpStatus.ok) {
        final payload = await response.transform(utf8.decoder).join();
        client.close();
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic> && data['success'] != false) {
          final latRaw = data['latitude'];
          final lonRaw = data['longitude'];
          final regionRaw = data['region'];
          final countryRaw = data['country'];
          final codeRaw = data['country_code'];
          if (latRaw != null && lonRaw != null) {
            final lat = (latRaw as num).toDouble();
            final lon = (lonRaw as num).toDouble();

            // Check if coordinates correspond to a verified city within 40km
            final nearest = VerifiedCitiesCatalog.findNearest(lat, lon, maxDistanceKm: 40.0);
            if (nearest != null) {
              return LocationResult(
                latitude: lat,
                longitude: lon,
                city: nearest.name,
                province: nearest.province,
                country: nearest.country,
                countryCode: nearest.countryCode,
                source: LocationSource.ipEstimate,
                calculationMethod: nearest.calculationMethod,
              );
            }

            var city = '';
            var province = (regionRaw is String && regionRaw.trim().isNotEmpty)
                ? _cleanAdministrativeName(regionRaw.trim())
                : null;
            var country = countryRaw is String ? countryRaw.trim() : null;
            var code = codeRaw is String ? codeRaw.toUpperCase().trim() : null;

            final arabicGeo = await _reverseGeocodeHttp(lat, lon);
            if (arabicGeo != null) {
              if (arabicGeo['city'] != null) city = arabicGeo['city']!;
              if (arabicGeo['province'] != null) province = arabicGeo['province'];
              if (arabicGeo['country'] != null) country = arabicGeo['country'];
              if (arabicGeo['countryCode'] != null) code = arabicGeo['countryCode'];
            }

            final displayCity = city.isNotEmpty
                ? city
                : (province ?? country ?? AppStrings.locationCurrent);

            return LocationResult(
              latitude: lat,
              longitude: lon,
              city: displayCity,
              province: province,
              country: country,
              countryCode: code,
              source: LocationSource.ipEstimate,
            );
          }
        }
      } else {
        client.close();
      }
    } catch (_) {}

    // 2. Fallback: ip-api.com
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('http://ip-api.com/json/?fields=status,country,countryCode,regionName,city,lat,lon'),
      );
      final response = await request.close().timeout(_sec(3));
      if (response.statusCode == HttpStatus.ok) {
        final payload = await response.transform(utf8.decoder).join();
        client.close();
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final lat = (data['lat'] as num).toDouble();
          final lon = (data['lon'] as num).toDouble();

          final nearest = VerifiedCitiesCatalog.findNearest(lat, lon, maxDistanceKm: 40.0);
          if (nearest != null) {
            return LocationResult(
              latitude: lat,
              longitude: lon,
              city: nearest.name,
              province: nearest.province,
              country: nearest.country,
              countryCode: nearest.countryCode,
              source: LocationSource.ipEstimate,
              calculationMethod: nearest.calculationMethod,
            );
          }

          var city = (data['city'] as String?)?.trim() ?? '';
          var province = (data['regionName'] as String?)?.trim();
          var country = data['country'] as String?;
          var code = (data['countryCode'] as String?)?.toUpperCase();

          final arabicGeo = await _reverseGeocodeHttp(lat, lon);
          if (arabicGeo != null) {
            if (arabicGeo['city'] != null) city = arabicGeo['city']!;
            if (arabicGeo['province'] != null) province = arabicGeo['province'];
            if (arabicGeo['country'] != null) country = arabicGeo['country'];
            if (arabicGeo['countryCode'] != null) code = arabicGeo['countryCode'];
          }

          final displayCity = city.isNotEmpty
              ? city
              : (province ?? country ?? AppStrings.locationCurrent);

          return LocationResult(
            latitude: lat,
            longitude: lon,
            city: displayCity,
            province: province,
            country: country,
            countryCode: code,
            source: LocationSource.ipEstimate,
          );
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
    // (within 25km of an official Wilaya/City center)
    final nearest = VerifiedCitiesCatalog.findNearest(
      position.latitude,
      position.longitude,
      maxDistanceKm: 25.0,
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
      // If administrativeArea exists (e.g. Wilaya / Governorate), it is often the most recognizable
      final admin = place.administrativeArea?.trim();
      final locality = place.locality?.trim();
      final sub = place.subAdministrativeArea?.trim();

      // If locality and admin are both present and distinct, format nicely
      if (locality != null && locality.isNotEmpty) {
        final cleanLocality = _cleanAdministrativeName(locality);
        if (admin != null && admin.isNotEmpty) {
          final cleanAdmin = _cleanAdministrativeName(admin);
          if (cleanAdmin != cleanLocality) {
            // E.g. "الجزائر (الدار البيضاء)" or "المهدية"
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
