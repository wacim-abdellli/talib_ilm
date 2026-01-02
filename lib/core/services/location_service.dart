import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _defaultCity = 'مكة المكرمة';
  static const _defaultLat = 21.3891;
  static const _defaultLon = 39.8579;

  static const _keyCity = 'last_city';
  static const _keyLat = 'last_lat';
  static const _keyLon = 'last_lon';

  Future<LocationResult> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final fallback = _loadFallback(prefs);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return fallback;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return fallback;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      String city = fallback.city;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        city = _pickCity(placemarks) ?? fallback.city;
      } catch (_) {
        city = fallback.city;
      }
      await _saveLastKnown(
        prefs,
        city: city,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
      );
    } catch (_) {
      return fallback;
    }
  }

  LocationResult _loadFallback(SharedPreferences prefs) {
    final lat = prefs.getDouble(_keyLat) ?? _defaultLat;
    final lon = prefs.getDouble(_keyLon) ?? _defaultLon;
    final city = prefs.getString(_keyCity) ?? _defaultCity;
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
