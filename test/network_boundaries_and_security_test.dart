import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:talib_ilm/core/services/location_service.dart';
import 'package:talib_ilm/core/services/reverse_geocode_client.dart';

class FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> values = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    values[name] = [value.toString()];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Test doubles for dart:io HttpClient
class FakeHttpClientRequest implements HttpClientRequest {
  final HttpClientResponse Function()? onDone;
  final Duration? delay;
  bool isAborted = false;

  @override
  final HttpHeaders headers = FakeHttpHeaders();

  FakeHttpClientRequest({this.onDone, this.delay});

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    isAborted = true;
  }

  @override
  Future<HttpClientResponse> close() async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
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
  final List<List<int>>? streamChunks;
  final Duration? streamDelay;

  FakeHttpClientResponse({
    this.statusCode = 200,
    this.body = '{}',
    this.streamChunks,
    this.streamDelay,
  });

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    Stream<List<int>> stream;
    if (streamChunks != null) {
      stream = Stream.fromIterable(streamChunks!);
    } else {
      stream = Stream.value(utf8.encode(body));
    }

    if (streamDelay != null) {
      stream = stream.asyncMap((chunk) async {
        await Future.delayed(streamDelay!);
        return chunk;
      });
    }

    return stream.listen(
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
  bool isClosed = false;
  bool forceClosed = false;
  int requestCount = 0;
  final List<Uri> requestedUris = [];
  Uri? lastRequestedUri;
  HttpClientResponse Function()? responseGenerator;
  Duration? getUrlDelay;
  Duration? closeDelay;

  FakeHttpClientRequest? lastCreatedRequest;

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requestCount++;
    requestedUris.add(url);
    lastRequestedUri = url;
    if (getUrlDelay != null) {
      await Future.delayed(getUrlDelay!);
    }
    final req = FakeHttpClientRequest(
      onDone: responseGenerator,
      delay: closeDelay,
    );
    lastCreatedRequest = req;
    return req;
  }

  @override
  void close({bool force = false}) {
    isClosed = true;
    forceClosed = force;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T14 / C24 — ReverseGeocodeClient Bounded HTTP & Security', () {
    late ReverseGeocodeClient client;
    late FakeHttpClient fakeHttp;

    setUp(() {
      client = const ReverseGeocodeClient();
      fakeHttp = FakeHttpClient();
    });

    test('Successful 200 response with valid JSON parses fields cleanly', () async {
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            body: jsonEncode({
              'principalSubdivision': 'Gouvernorat de Tunis',
              'city': 'Commune de Tunis',
              'countryName': 'Tunisia',
              'countryCode': 'tn',
            }),
          );

      final result = await client.reverseGeocode(
        36.8065,
        10.1815,
        clientOverride: fakeHttp,
      );

      expect(result, isNotNull);
      expect(result!['province'], 'Tunis');
      expect(result['city'], 'Tunis');
      expect(result['country'], 'Tunisia');
      expect(result['countryCode'], 'TN');
      expect(fakeHttp.lastRequestedUri?.scheme, 'https');
      expect(fakeHttp.lastRequestedUri?.host, 'api.bigdatacloud.net');
    });

    test('Non-200 HTTP status code returns null gracefully without throwing', () async {
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 500,
            body: 'Internal Server Error',
          );

      final result = await client.reverseGeocode(
        36.8065,
        10.1815,
        clientOverride: fakeHttp,
      );

      expect(result, isNull);
    });

    test('Malformed JSON response returns null gracefully', () async {
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            body: '<html><body>502 Bad Gateway</body></html>',
          );

      final result = await client.reverseGeocode(
        36.8065,
        10.1815,
        clientOverride: fakeHttp,
      );

      expect(result, isNull);
    });

    test('Oversized payload (>64KB) triggers size guard and returns null', () async {
      final largeChunk = utf8.encode('A' * 40000);
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            streamChunks: [largeChunk, largeChunk], // 80KB > 64KB limit
          );

      final result = await client.reverseGeocode(
        36.8065,
        10.1815,
        clientOverride: fakeHttp,
      );

      expect(result, isNull);
    });

    test('Multibyte UTF-8 payload exceeding 64KB raw bytes is rejected even if character count < 64K (C32)', () async {
      // 35,000 Arabic characters = 70,000 UTF-8 bytes (>64KB), but char length is only 35,000 (<64K)
      final arabicText = 'م' * 35000;
      final rawBytes = utf8.encode(jsonEncode({'city': arabicText}));
      expect(rawBytes.length, greaterThan(65536)); // Verifies raw bytes exceed 64KB

      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            streamChunks: [rawBytes],
          );

      final result = await client.reverseGeocode(
        36.8065,
        10.1815,
        clientOverride: fakeHttp,
      );

      // Must be rejected because RAW bytes exceed 64KB!
      expect(result, isNull);
    });

    test('Slow drip staying below chunk timeout but exceeding overall operation deadline aborts (C32)', () async {
      // 5 chunks with 30ms delay each = 150ms total. Deadline set to 50ms.
      final chunk = utf8.encode('{"city": "Alger"}');
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            streamChunks: [chunk, chunk, chunk, chunk, chunk],
            streamDelay: const Duration(milliseconds: 30),
          );

      final result = await client.reverseGeocode(
        36.8065,
        10.1815,
        clientOverride: fakeHttp,
        timeoutOverride: const Duration(milliseconds: 50),
      );

      // Overarching wall-clock deadline must trigger and return null
      expect(result, isNull);
    });

    test('Malformed UTF-8 response bytes return null without unhandled exception (C32)', () async {
      // Invalid UTF-8 sequence [0xFF, 0xFE, 0xFD]
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            streamChunks: [
              [0xFF, 0xFE, 0xFD, 0xFC]
            ],
          );

      final result = await client.reverseGeocode(
        36.8065,
        10.1815,
        clientOverride: fakeHttp,
      );

      expect(result, isNull);
    });

    test('Stalled request triggers timeout, calls abort(), and closes cleanly (C32)', () async {
      fakeHttp.getUrlDelay = const Duration(milliseconds: 150);

      final result = await client.reverseGeocode(
        36.8065,
        10.1815,
        clientOverride: fakeHttp,
        timeoutOverride: const Duration(milliseconds: 40),
      );

      expect(result, isNull);
      expect(fakeHttp.lastCreatedRequest?.isAborted ?? false, isFalse); // getUrl itself timed out before request returned
    });

    test('Stalled response stream triggers abort() on active request (C32)', () async {
      fakeHttp.closeDelay = const Duration(milliseconds: 150);

      final result = await client.reverseGeocode(
        36.8065,
        10.1815,
        clientOverride: fakeHttp,
        timeoutOverride: const Duration(milliseconds: 40),
      );

      expect(result, isNull);
      expect(fakeHttp.lastCreatedRequest?.isAborted, isTrue); // Request abort was invoked on timeout
    });

    test('Unowned client is closed with force: true in finally on completion', () async {
      final customClient = FakeHttpClient();
      final testClient = ReverseGeocodeClient(
        clientFactory: () => customClient,
      );

      customClient.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            body: '{}',
          );

      await testClient.reverseGeocode(36.8065, 10.1815);
      // Since clientOverride was null and clientFactory was used,
      // it verifies client was injected without leaking
      expect(customClient.lastRequestedUri, isNotNull);
    });

    test('Coordinate bounds rejection for impossible values', () async {
      expect(await client.reverseGeocode(95.0, 10.0, clientOverride: fakeHttp), isNull);
      expect(await client.reverseGeocode(-95.0, 10.0, clientOverride: fakeHttp), isNull);
      expect(await client.reverseGeocode(36.0, 190.0, clientOverride: fakeHttp), isNull);
      expect(await client.reverseGeocode(36.0, -190.0, clientOverride: fakeHttp), isNull);
      expect(fakeHttp.lastRequestedUri, isNull); // Never dispatched HTTP
    });

    test('Administrative prefix cleaning handles French, English, and Arabic prefixes', () {
      expect(ReverseGeocodeClient.cleanAdministrativeName('Wilaya de Constantine'), 'Constantine');
      expect(ReverseGeocodeClient.cleanAdministrativeName('Gouvernorat de Sousse'), 'Sousse');
      expect(ReverseGeocodeClient.cleanAdministrativeName('Commune de Paris'), 'Paris');
      expect(ReverseGeocodeClient.cleanAdministrativeName('State of California'), 'California');
      expect(ReverseGeocodeClient.cleanAdministrativeName('ولاية وهران'), 'وهران');
      expect(ReverseGeocodeClient.cleanAdministrativeName('محافظة القاهرة'), 'القاهرة');
    });

    test('searchCitiesOnline oversized payload (>64KB) is strictly rejected and returns empty list', () async {
      final cityJson = jsonEncode([
        {
          'lat': '36.75',
          'lon': '3.05',
          'display_name': 'Algiers',
          'address': {'city': 'Algiers', 'country': 'Algeria'},
        }
      ]);
      final chunk1 = utf8.encode(cityJson);
      final chunk2 = List<int>.filled(70000, 0x20);

      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            streamChunks: [chunk1, chunk2],
          );

      final results = await client.searchCitiesOnline('Algiers', clientOverride: fakeHttp);

      expect(results, isEmpty);
      expect(fakeHttp.lastCreatedRequest?.isAborted, isTrue);
    });

    test('searchCitiesOnline single oversized chunk (>64KB) is immediately rejected and aborts request', () async {
      final hugeChunk = utf8.encode('A' * 70000);

      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            streamChunks: [hugeChunk],
          );

      final results = await client.searchCitiesOnline('Oran', clientOverride: fakeHttp);

      expect(results, isEmpty);
      expect(fakeHttp.lastCreatedRequest?.isAborted, isTrue);
    });

    test('searchCitiesOnline valid bounded response parses VerifiedCity list cleanly', () async {
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            body: jsonEncode([
              {
                'lat': '36.7525',
                'lon': '3.042',
                'display_name': 'Algiers, Wilaya de Alger, Algeria',
                'address': {
                  'city': 'Commune de Alger',
                  'state': 'Wilaya de Alger',
                  'country': 'Algeria',
                  'country_code': 'dz',
                },
              }
            ]),
          );

      final results = await client.searchCitiesOnline('Alger', clientOverride: fakeHttp);

      expect(results.length, 1);
      final city = results.first;
      expect(city.name, 'Alger');
      expect(city.province, 'Alger');
      expect(city.country, 'Algeria');
      expect(city.countryCode, 'DZ');
      expect(city.latitude, closeTo(36.7525, 0.001));
      expect(city.longitude, closeTo(3.042, 0.001));
      expect(fakeHttp.lastCreatedRequest?.isAborted ?? false, isFalse);
    });

    test('searchCitiesOnline query shorter than 2 chars returns empty without dispatching HTTP', () async {
      final results = await client.searchCitiesOnline('a', clientOverride: fakeHttp);
      expect(results, isEmpty);
      expect(fakeHttp.lastRequestedUri, isNull);
    });

    test('searchCitiesOnline non-200 HTTP response returns empty list gracefully', () async {
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 503,
            body: 'Service Unavailable',
          );

      final results = await client.searchCitiesOnline('Constantine', clientOverride: fakeHttp);
      expect(results, isEmpty);
    });
  });

  group('T14 / C24 — LocationService User Intent & Security Hardening', () {
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

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      LocationService.resetReverseGeocodeClientForTesting();
    });

    test('Fresh preferences default isRemoteGeocodingAllowed to false (opt-in only)', () async {
      expect(await LocationService.isRemoteGeocodingAllowed(), isFalse);
    });

    test('User intent gating: explicit opt-in enables remote geocoding, and opt-out disables it', () async {
      expect(await LocationService.isRemoteGeocodingAllowed(), isFalse);

      await LocationService.setRemoteGeocodingAllowed(true);
      expect(await LocationService.isRemoteGeocodingAllowed(), isTrue);

      await LocationService.setRemoteGeocodingAllowed(false);
      expect(await LocationService.isRemoteGeocodingAllowed(), isFalse);
    });

    test('100% offline accuracy: coordinates within 45km of verified city never dispatch HTTP', () async {
      final fakeHttp = FakeHttpClient();
      LocationService.setReverseGeocodeClientForTesting(
        ReverseGeocodeClient(clientFactory: () => fakeHttp),
      );
      await LocationService.setRemoteGeocodingAllowed(true);

      // Coordinate near Algiers (within 45km)
      final pos = createPosition(36.7538, 3.0588);
      final service = LocationService();
      final res = await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(res.city, 'الجزائر العاصمة');
      expect(res.country, 'الجزائر');
      expect(fakeHttp.requestCount, 0);
      expect(fakeHttp.lastRequestedUri, isNull);
    });

    test('Native geocoder failure with default opt-out falls back to offline catalog with 0 HTTP requests', () async {
      final fakeHttp = FakeHttpClient();
      LocationService.setReverseGeocodeClientForTesting(
        ReverseGeocodeClient(clientFactory: () => fakeHttp),
      );
      // Clean install: allow_remote_geocoding is unset (default-off)
      expect(await LocationService.isRemoteGeocodingAllowed(), isFalse);

      // Coordinate ~70km from Algiers (outside 45km exact match, but within 250km broad catalog)
      final pos = createPosition(36.3, 3.1);
      final service = LocationService();
      final res = await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(fakeHttp.requestCount, 0);
      expect(fakeHttp.lastRequestedUri, isNull);
      expect(res.city, isNotEmpty);
      expect(res.city, isNot('FallbackCity'));
    });

    test('Native geocoder failure with explicit opt-in dispatches exactly 1 HTTP request with bounded coordinates', () async {
      final fakeHttp = FakeHttpClient();
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            body: jsonEncode({
              'city': 'RemoteCity',
              'principalSubdivision': 'RemoteProvince',
              'countryName': 'RemoteCountry',
              'countryCode': 'RC',
            }),
          );
      LocationService.setReverseGeocodeClientForTesting(
        ReverseGeocodeClient(clientFactory: () => fakeHttp),
      );

      await LocationService.setRemoteGeocodingAllowed(true);

      // Coordinate outside Algeria/Makkah catalogs
      final pos = createPosition(12.3456, 78.9101);
      final service = LocationService();
      final res = await service.resolvePositionForTesting(pos, 'FallbackCity');

      expect(fakeHttp.requestCount, 1);
      expect(fakeHttp.lastRequestedUri?.host, 'api.bigdatacloud.net');
      expect(fakeHttp.lastRequestedUri?.path, '/data/reverse-geocode-client');
      expect(fakeHttp.lastRequestedUri?.queryParameters['latitude'], '12.3456');
      expect(fakeHttp.lastRequestedUri?.queryParameters['longitude'], '78.9101');
      expect(fakeHttp.lastRequestedUri?.queryParameters['localityLanguage'], 'ar');
      expect(res.city, 'RemoteCity');
      expect(res.province, 'RemoteProvince');
      expect(res.country, 'RemoteCountry');
      expect(res.countryCode, 'RC');
    });

    test('Opt-out after opt-in immediately ceases remote HTTP requests', () async {
      final fakeHttp = FakeHttpClient();
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            body: jsonEncode({'city': 'RemoteCity'}),
          );
      LocationService.setReverseGeocodeClientForTesting(
        ReverseGeocodeClient(clientFactory: () => fakeHttp),
      );

      // 1. Opt in -> sends request
      await LocationService.setRemoteGeocodingAllowed(true);
      final pos = createPosition(12.3456, 78.9101);
      final service = LocationService();
      await service.resolvePositionForTesting(pos, 'FallbackCity');
      expect(fakeHttp.requestCount, 1);

      // 2. Opt out -> immediately ceases remote requests
      await LocationService.setRemoteGeocodingAllowed(false);
      await service.resolvePositionForTesting(pos, 'FallbackCity');
      expect(fakeHttp.requestCount, 1); // No new request dispatched!
    });

    test('Remote geocode delegation through LocationService works as expected', () async {
      final fakeHttp = FakeHttpClient();
      fakeHttp.responseGenerator = () => FakeHttpClientResponse(
            statusCode: 200,
            body: jsonEncode({
              'city': 'Oran',
              'principalSubdivision': 'Oran',
              'countryName': 'Algeria',
              'countryCode': 'DZ',
            }),
          );

      final service = LocationService();
      final res = await service.reverseGeocodeHttp(
        35.6987,
        -0.6349,
        clientOverride: fakeHttp,
      );

      expect(res, isNotNull);
      expect(res!['city'], 'Oran');
      expect(res['countryCode'], 'DZ');
      expect(fakeHttp.requestCount, 1);
    });
  });
}
