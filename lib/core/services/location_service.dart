import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String city;
  final String? country;
  final String? countryCode;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.city,
    this.country,
    this.countryCode,
  });
}

class LocationService {
  static const _defaultCity = AppStrings.locationDefaultCity;
  static const _defaultLat = 21.3891;
  static const _defaultLon = 39.8579;

  static const _keyCity = 'last_city';
  static const _keyCountry = 'last_country';
  static const _keyCountryCode = 'last_country_code';
  static const _keyLat = 'last_lat';
  static const _keyLon = 'last_lon';
  static const _keyManualEnabled = 'manual_location_enabled';
  static const _keyManualCity = 'manual_city';
  static const _keyManualCountry = 'manual_country';
  static const _keyManualCountryCode = 'manual_country_code';
  static const _keyManualLat = 'manual_lat';
  static const _keyManualLon = 'manual_lon';
  static bool _localeReady = false;

  Future<LocationResult> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final manual = _loadManual(prefs);
    if (manual != null) return manual;

    final fallback = _loadFallback(prefs);
    var best = fallback;

    try {
      final ip = await _tryIpLocation();
      if (ip != null) {
        best = ip;
        await _saveLastKnown(
          prefs,
          city: ip.city,
          country: ip.country,
          countryCode: ip.countryCode,
          latitude: ip.latitude,
          longitude: ip.longitude,
        );
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        return best;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return best;
      }

      await _ensureLocale();

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        best = await _resolvePosition(
          lastKnown,
          best.city,
          fallbackCountry: best.country,
          fallbackCountryCode: best.countryCode,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final resolved = await _resolvePosition(
        position,
        best.city,
        fallbackCountry: best.country,
        fallbackCountryCode: best.countryCode,
      );
      await _saveLastKnown(
        prefs,
        city: resolved.city,
        country: resolved.country,
        countryCode: resolved.countryCode,
        latitude: resolved.latitude,
        longitude: resolved.longitude,
      );

      return resolved;
    } catch (_) {
      return best;
    }
  }

  LocationResult _loadFallback(SharedPreferences prefs) {
    final lat = prefs.getDouble(_keyLat) ?? _defaultLat;
    final lon = prefs.getDouble(_keyLon) ?? _defaultLon;
    final city = prefs.getString(_keyCity) ?? _defaultCity;
    final country = prefs.getString(_keyCountry);
    final countryCode = prefs.getString(_keyCountryCode);
    return LocationResult(
      latitude: lat,
      longitude: lon,
      city: city,
      country: country,
      countryCode: countryCode,
    );
  }

  LocationResult? _loadManual(SharedPreferences prefs) {
    final enabled = prefs.getBool(_keyManualEnabled) ?? false;
    if (!enabled) return null;
    final lat = prefs.getDouble(_keyManualLat);
    final lon = prefs.getDouble(_keyManualLon);
    if (lat == null || lon == null) return null;
    final city =
        prefs.getString(_keyManualCity) ?? AppStrings.locationManualDefault;
    final country = prefs.getString(_keyManualCountry);
    final countryCode = prefs.getString(_keyManualCountryCode);
    return LocationResult(
      latitude: lat,
      longitude: lon,
      city: city,
      country: country,
      countryCode: countryCode,
    );
  }

  Future<void> _saveLastKnown(
    SharedPreferences prefs, {
    required String city,
    String? country,
    String? countryCode,
    required double latitude,
    required double longitude,
  }) async {
    await prefs.setString(_keyCity, city);
    if (country != null) await prefs.setString(_keyCountry, country);
    if (countryCode != null) await prefs.setString(_keyCountryCode, countryCode);
    await prefs.setDouble(_keyLat, latitude);
    await prefs.setDouble(_keyLon, longitude);
  }

  Future<LocationResult?> getManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadManual(prefs);
  }

  Future<void> setManualLocation(LocationResult location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyManualEnabled, true);
    await prefs.setString(_keyManualCity, location.city);
    if (location.country != null) {
      await prefs.setString(_keyManualCountry, location.country!);
    }
    if (location.countryCode != null) {
      await prefs.setString(_keyManualCountryCode, location.countryCode!);
    }
    await prefs.setDouble(_keyManualLat, location.latitude);
    await prefs.setDouble(_keyManualLon, location.longitude);
  }

  Future<void> clearManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyManualEnabled, false);
    await prefs.remove(_keyManualCity);
    await prefs.remove(_keyManualCountry);
    await prefs.remove(_keyManualCountryCode);
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
      final response = await request.close().timeout(const Duration(seconds: 3));
      if (response.statusCode == HttpStatus.ok) {
        final payload = await response.transform(utf8.decoder).join();
        client.close();
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic>) {
          final res = <String, String>{};
          final c = data['city'] ?? data['locality'] ?? data['principalSubdivision'];
          if (c is String && c.trim().isNotEmpty) {
            res['city'] = c.trim();
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
    // 1. Try ipwho.is (fast, unthrottled, detailed JSON)
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://ipwho.is/'));
      final response = await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode == HttpStatus.ok) {
        final payload = await response.transform(utf8.decoder).join();
        client.close();
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic> && data['success'] != false) {
          final latRaw = data['latitude'];
          final lonRaw = data['longitude'];
          final cityRaw = data['city'];
          final countryRaw = data['country'];
          final codeRaw = data['country_code'];
          if (latRaw != null && lonRaw != null) {
            final lat = (latRaw as num).toDouble();
            final lon = (lonRaw as num).toDouble();
            var city = (cityRaw is String && cityRaw.trim().isNotEmpty) ? cityRaw.trim() : '';
            var country = countryRaw is String ? countryRaw.trim() : null;
            var code = codeRaw is String ? codeRaw.toUpperCase().trim() : null;

            // Resolve Arabic city name via BigDataCloud
            final arabicGeo = await _reverseGeocodeHttp(lat, lon);
            if (arabicGeo != null) {
              if (arabicGeo['city'] != null) city = arabicGeo['city']!;
              if (arabicGeo['country'] != null) country = arabicGeo['country'];
              if (arabicGeo['countryCode'] != null) code = arabicGeo['countryCode'];
            }

            return LocationResult(
              latitude: lat,
              longitude: lon,
              city: city.isNotEmpty ? city : (country ?? AppStrings.locationCurrent),
              country: country,
              countryCode: code,
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
      final request = await client.getUrl(Uri.parse('http://ip-api.com/json/?fields=status,country,countryCode,city,lat,lon'));
      final response = await request.close().timeout(const Duration(seconds: 3));
      if (response.statusCode == HttpStatus.ok) {
        final payload = await response.transform(utf8.decoder).join();
        client.close();
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final lat = (data['lat'] as num).toDouble();
          final lon = (data['lon'] as num).toDouble();
          var city = (data['city'] as String?)?.trim() ?? '';
          var country = data['country'] as String?;
          var code = (data['countryCode'] as String?)?.toUpperCase();

          // Resolve Arabic city name via BigDataCloud
          final arabicGeo = await _reverseGeocodeHttp(lat, lon);
          if (arabicGeo != null) {
            if (arabicGeo['city'] != null) city = arabicGeo['city']!;
            if (arabicGeo['country'] != null) country = arabicGeo['country'];
            if (arabicGeo['countryCode'] != null) code = arabicGeo['countryCode'];
          }

          return LocationResult(
            latitude: lat,
            longitude: lon,
            city: city.isNotEmpty ? city : (country ?? AppStrings.locationCurrent),
            country: country,
            countryCode: code,
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
  }) async {
    var city = fallbackCity;
    String? country = fallbackCountry;
    String? countryCode = fallbackCountryCode;

    // 1. Try native geocoder
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final picked = _pickCity(placemarks);
      if (picked != null) city = picked;
      if (placemarks.isNotEmpty) {
        country = placemarks.first.country?.trim() ?? country;
        countryCode = placemarks.first.isoCountryCode?.trim().toUpperCase() ?? countryCode;
      }
    } catch (_) {
      // 2. Fallback: HTTP reverse geocode in Arabic (fixes Android OEM Geocoder bugs)
      final arabicGeo = await _reverseGeocodeHttp(position.latitude, position.longitude);
      if (arabicGeo != null) {
        if (arabicGeo['city'] != null) city = arabicGeo['city']!;
        if (arabicGeo['country'] != null) country = arabicGeo['country'];
        if (arabicGeo['countryCode'] != null) countryCode = arabicGeo['countryCode'];
      }
    }

    if (city == _defaultCity && (position.latitude != _defaultLat)) {
      city = country ?? AppStrings.locationCurrent;
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      country: country,
      countryCode: countryCode,
    );
  }

  String? _pickCity(List<Placemark> placemarks) {
    for (final place in placemarks) {
      final city = place.locality?.trim();
      if (city != null && city.isNotEmpty) return city;
      final sub = place.subAdministrativeArea?.trim();
      if (sub != null && sub.isNotEmpty) return sub;
      final admin = place.administrativeArea?.trim();
      if (admin != null && admin.isNotEmpty) return admin;
    }
    return null;
  }
}
