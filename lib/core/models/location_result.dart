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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationResult &&
          runtimeType == other.runtimeType &&
          city == other.city &&
          (latitude - other.latitude).abs() < 0.005 &&
          (longitude - other.longitude).abs() < 0.005 &&
          source == other.source &&
          calculationMethod == other.calculationMethod;

  @override
  int get hashCode => Object.hash(
        city,
        (latitude * 100).round(),
        (longitude * 100).round(),
        source,
        calculationMethod,
      );
}
