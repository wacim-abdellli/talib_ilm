import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/location_service.dart';
import 'package:talib_ilm/core/services/reverse_geocode_client.dart';

class FakeHttpClientRequest implements HttpClientRequest {
  bool isAborted = false;
  final HttpClientResponse Function()? onDone;

  FakeHttpClientRequest({this.onDone});

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    isAborted = true;
  }

  @override
  Future<HttpClientResponse> close() async {
    if (onDone != null) {
      return onDone!();
    }
    return FakeHttpClientResponse(statusCode: 200, body: '{}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;

  FakeHttpClientResponse({this.statusCode = 200, this.body = '{}'});

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpClient implements HttpClient {
  int requestCount = 0;
  Uri? lastRequestedUri;
  HttpClientResponse Function()? responseGenerator;

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requestCount++;
    lastRequestedUri = url;
    return FakeHttpClientRequest(onDone: responseGenerator);
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Position createPosition(double lat, double lon) => Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

  late FakeHttpClient fakeHttp;
  int geocoderCallCount = 0;
  double? lastGeocoderLat;
  double? lastGeocoderLon;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeHttp = FakeHttpClient();
    geocoderCallCount = 0;
    lastGeocoderLat = null;
    lastGeocoderLon = null;

    LocationService.setReverseGeocodeClientForTesting(
      ReverseGeocodeClient(clientFactory: () => fakeHttp),
    );

    LocationService.setPlatformGeocoderForTesting((lat, lon) async {
      geocoderCallCount++;
      lastGeocoderLat = lat;
      lastGeocoderLon = lon;
      return [
        Placemark(
          locality: 'PlatformCity',
          administrativeArea: 'PlatformProvince',
          country: 'PlatformCountry',
          isoCountryCode: 'PC',
        ),
      ];
    });
  });

  tearDown(() {
    LocationService.resetReverseGeocodeClientForTesting();
    LocationService.resetPlatformGeocoderForTesting();
  });

  group('R62 — Location Privacy Boundaries at Every Provider Boundary', () {
    test('1. Fresh install defaults: isRemoteGeocodingAllowed is strictly false', () async {
      expect(await LocationService.isRemoteGeocodingAllowed(), isFalse);
    });

    test('2. Opt-out: coordinates outside catalog trigger ZERO platform geocoder AND ZERO HTTP calls', () async {
      expect(await LocationService.isRemoteGeocodingAllowed(), isFalse);

      // Coordinate in India outside Algeria/Makkah catalog
      final pos = createPosition(12.3456, 78.9101);
      final service = LocationService();
      final res = await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(geocoderCallCount, 0, reason: 'Platform geocoder must NOT be called when remote geocoding is disabled');
      expect(fakeHttp.requestCount, 0, reason: 'HTTP geocoder must NOT be called when remote geocoding is disabled');
      expect(res.city, isNotEmpty);
      expect(res.city, isNot('PlatformCity'));
    });

    test('3. Opt-out: coordinates near catalog (<= 250km) resolve from local broader catalog with ZERO network calls', () async {
      expect(await LocationService.isRemoteGeocodingAllowed(), isFalse);

      // Coordinate ~70km from Algiers (outside 45km exact match, but within 250km broad catalog)
      final pos = createPosition(36.3, 3.1);
      final service = LocationService();
      final res = await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(geocoderCallCount, 0);
      expect(fakeHttp.requestCount, 0);
      expect(res.city, isNotEmpty);
      expect(res.city, isNot('FallbackCity'));
      expect(res.city, isNot('PlatformCity'));
    });

    test('4. 100% offline accuracy: coordinates <= 45km from catalog resolve immediately without any external call even if opt-in enabled', () async {
      await LocationService.setRemoteGeocodingAllowed(true);
      expect(await LocationService.isRemoteGeocodingAllowed(), isTrue);

      // Exact coordinate of Algiers
      final pos = createPosition(36.7538, 3.0588);
      final service = LocationService();
      final res = await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(res.city, 'الجزائر العاصمة');
      expect(res.country, 'الجزائر');
      expect(geocoderCallCount, 0, reason: 'Catalog exact match must not call geocoder');
      expect(fakeHttp.requestCount, 0, reason: 'Catalog exact match must not call HTTP');
    });

    test('5. Explicit opt-in: dispatches platform geocoder with exact coordinates', () async {
      await LocationService.setRemoteGeocodingAllowed(true);
      expect(await LocationService.isRemoteGeocodingAllowed(), isTrue);

      final pos = createPosition(12.3456, 78.9101);
      final service = LocationService();
      final res = await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(geocoderCallCount, 1);
      expect(lastGeocoderLat, 12.3456);
      expect(lastGeocoderLon, 78.9101);
      expect(fakeHttp.requestCount, 0, reason: 'HTTP should not be called when platform geocoder succeeds');
      expect(res.city, 'PlatformProvince');
      expect(res.country, 'PlatformCountry');
      expect(res.countryCode, 'PC');
    });

    test('6. Explicit opt-in with platform geocoder throwing falls back to BigDataCloud HTTP', () async {
      await LocationService.setRemoteGeocodingAllowed(true);

      LocationService.setPlatformGeocoderForTesting((lat, lon) async {
        geocoderCallCount++;
        throw Exception('Platform geocoder unavailable on device');
      });

      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            body: jsonEncode({
              'city': 'BigDataCity',
              'principalSubdivision': 'BigDataProvince',
              'countryName': 'BigDataCountry',
              'countryCode': 'BD',
            }),
          );

      final pos = createPosition(12.3456, 78.9101);
      final service = LocationService();
      final res = await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(geocoderCallCount, 1);
      expect(fakeHttp.requestCount, 1);
      expect(fakeHttp.lastRequestedUri?.host, 'api.bigdatacloud.net');
      expect(fakeHttp.lastRequestedUri?.queryParameters['latitude'], '12.3456');
      expect(fakeHttp.lastRequestedUri?.queryParameters['longitude'], '78.9101');
      expect(res.city, 'BigDataCity');
      expect(res.country, 'BigDataCountry');
    });

    test('7. Explicit opt-in with empty platform placemarks falls back to BigDataCloud HTTP', () async {
      await LocationService.setRemoteGeocodingAllowed(true);

      LocationService.setPlatformGeocoderForTesting((lat, lon) async {
        geocoderCallCount++;
        return <Placemark>[]; // Empty list
      });

      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            body: jsonEncode({
              'city': 'BigDataCityFallback',
              'countryName': 'BigDataCountryFallback',
            }),
          );

      final pos = createPosition(12.3456, 78.9101);
      final service = LocationService();
      final res = await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(geocoderCallCount, 1);
      expect(fakeHttp.requestCount, 1);
      expect(res.city, 'BigDataCityFallback');
    });

    test('8. Opt-out immediately after opt-in halts all platform geocoder and HTTP calls', () async {
      await LocationService.setRemoteGeocodingAllowed(true);
      expect(await LocationService.isRemoteGeocodingAllowed(), isTrue);

      await LocationService.setRemoteGeocodingAllowed(false);
      expect(await LocationService.isRemoteGeocodingAllowed(), isFalse);

      final pos = createPosition(12.3456, 78.9101);
      final service = LocationService();
      await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(geocoderCallCount, 0);
      expect(fakeHttp.requestCount, 0);
    });

    test('9. Manual city override takes complete priority and makes zero geocoder or HTTP calls', () async {
      await LocationService.setRemoteGeocodingAllowed(true);

      final service = LocationService();
      await service.setManualLocation(LocationResult(
        latitude: 24.7136,
        longitude: 46.6753,
        city: 'الرياض',
        country: 'المملكة العربية السعودية',
        source: LocationSource.manual,
      ));

      final loc = await service.getLocation(autoPrompt: false);

      expect(loc.city, 'الرياض');
      expect(loc.source, LocationSource.manual);
      expect(geocoderCallCount, 0);
      expect(fakeHttp.requestCount, 0);
    });

    test('10. Invalid coordinates outside [-90, 90] / [-180, 180] rejected by reverse geocode client without network call', () async {
      final client = ReverseGeocodeClient(clientFactory: () => fakeHttp);
      final result1 = await client.reverseGeocode(-95.0, 50.0);
      final result2 = await client.reverseGeocode(50.0, 185.0);

      expect(result1, isNull);
      expect(result2, isNull);
      expect(fakeHttp.requestCount, 0);
    });

    test('11. Complete provider failure when opted-in falls back gracefully to fallback city without throwing', () async {
      await LocationService.setRemoteGeocodingAllowed(true);

      LocationService.setPlatformGeocoderForTesting((lat, lon) async {
        geocoderCallCount++;
        throw TimeoutException('Platform geocoder timed out');
      });

      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 500,
            body: 'Internal Server Error',
          );

      final pos = createPosition(12.3456, 78.9101);
      final service = LocationService();
      final res = await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(geocoderCallCount, 1);
      expect(fakeHttp.requestCount, 1);
      expect(res.city, isNotEmpty);
      expect(res.latitude, 12.3456);
      expect(res.longitude, 78.9101);
    });
  });
}
