part of 'location_service.dart';

extension _LocationServiceResolutionHandlers on LocationService {
  Future<LocationResult> _resolvePositionImpl(
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

    // 2. Check user consent for remote reverse-geocoding before ANY platform or external call
    final allowRemote = await LocationService.isRemoteGeocodingAllowed();

    if (allowRemote) {
      // User explicitly opted in: attempt platform geocoder, fallback to BigDataCloud
      try {
        final placemarks = await LocationService._platformGeocoder(
          position.latitude,
          position.longitude,
        ).timeout(AppPolicy.networkFast);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          country = p.country?.trim() ?? country;
          countryCode = p.isoCountryCode?.trim().toUpperCase() ?? countryCode;
          if (p.administrativeArea != null &&
              p.administrativeArea!.trim().isNotEmpty) {
            province = LocationService._cleanAdministrativeName(
              p.administrativeArea!.trim(),
            );
          }

          final picked = _pickCleanCity(placemarks);
          if (picked != null) city = picked;
        }
      } catch (_) {}

      // Fallback: HTTP reverse geocoding if platform geocoder threw or found no clean city
      if (city == fallbackCity) {
        final arabicGeo = await reverseGeocodeHttp(
          position.latitude,
          position.longitude,
        );
        if (arabicGeo != null) {
          if (arabicGeo['city'] != null) city = arabicGeo['city']!;
          if (arabicGeo['province'] != null) province = arabicGeo['province'];
          if (arabicGeo['country'] != null) country = arabicGeo['country'];
          if (arabicGeo['countryCode'] != null) {
            countryCode = arabicGeo['countryCode'];
          }
        }
      }
    } else {
      // User has not opted in (clean install default): strictly ZERO network/platform geocoder calls.
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

    if (city == LocationService._defaultCity &&
        (position.latitude != LocationService._defaultLat)) {
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
}
