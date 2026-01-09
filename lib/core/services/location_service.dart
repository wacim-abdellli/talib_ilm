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

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.city,
  });
}

class LocationService {
  static const _defaultCity = AppStrings.locationDefaultCity;
  static const _defaultLat = 21.3891;
  static const _defaultLon = 39.8579;

  static const _keyCity = 'last_city';
  static const _keyLat = 'last_lat';
  static const _keyLon = 'last_lon';
  static const _keyManualEnabled = 'manual_location_enabled';
  static const _keyManualCity = 'manual_city';
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
        best = await _resolvePosition(lastKnown, best.city);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final resolved = await _resolvePosition(position, best.city);
      await _saveLastKnown(
        prefs,
        city: resolved.city,
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
    return LocationResult(latitude: lat, longitude: lon, city: city);
  }

  LocationResult? _loadManual(SharedPreferences prefs) {
    final enabled = prefs.getBool(_keyManualEnabled) ?? false;
    if (!enabled) return null;
    final lat = prefs.getDouble(_keyManualLat);
    final lon = prefs.getDouble(_keyManualLon);
    if (lat == null || lon == null) return null;
    final city =
        prefs.getString(_keyManualCity) ?? AppStrings.locationManualDefault;
    return LocationResult(latitude: lat, longitude: lon, city: city);
  }

  Future<void> _saveLastKnown(
    SharedPreferences prefs, {
    required String city,
    required double latitude,
    required double longitude,
  }) async {
    await prefs.setString(_keyCity, city);
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
    await prefs.setDouble(_keyManualLat, location.latitude);
    await prefs.setDouble(_keyManualLon, location.longitude);
  }

  Future<void> clearManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyManualEnabled, false);
    await prefs.remove(_keyManualCity);
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

  Future<LocationResult?> _tryIpLocation() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://ipapi.co/json/'),
      );
      final response = await request.close().timeout(
            const Duration(seconds: 4),
          );
      if (response.statusCode != HttpStatus.ok) {
        client.close();
        return null;
      }
      final payload = await response.transform(utf8.decoder).join();
      client.close();
      final data = jsonDecode(payload);
      if (data is! Map<String, dynamic>) return null;

      final latRaw = data['latitude'] ?? data['lat'];
      final lonRaw = data['longitude'] ?? data['lon'];
      final cityRaw = data['city'];
      if (latRaw == null || lonRaw == null) return null;

      final latitude = (latRaw as num).toDouble();
      final longitude = (lonRaw as num).toDouble();
      final city = (cityRaw is String && cityRaw.trim().isNotEmpty)
          ? cityRaw.trim()
          : AppStrings.locationCurrent;

      return LocationResult(
        latitude: latitude,
        longitude: longitude,
        city: city,
      );
    } catch (_) {
      return null;
    }
  }

  Future<LocationResult> _resolvePosition(
    Position position,
    String fallbackCity,
  ) async {
    var city = fallbackCity;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      city = _pickCity(placemarks) ?? fallbackCity;
    } catch (_) {
      city = fallbackCity;
    }

    if (city == _defaultCity && (position.latitude != _defaultLat)) {
      city = AppStrings.locationCurrent;
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
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
