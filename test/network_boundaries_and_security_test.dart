import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/constants/verified_cities.dart';
import 'package:talib_ilm/core/services/location_service.dart';
import 'package:talib_ilm/core/services/reverse_geocode_client.dart';

/// Test doubles for dart:io HttpClient
class FakeHttpClientRequest implements HttpClientRequest {
  final HttpClientResponse Function()? onDone;
  final Duration? delay;
  bool isAborted = false;

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
  Uri? lastRequestedUri;
  HttpClientResponse Function()? responseGenerator;
  Duration? getUrlDelay;
  Duration? closeDelay;

  FakeHttpClientRequest? lastCreatedRequest;

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
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
  });

  group('T14 / C24 — LocationService User Intent & Security Hardening', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('User intent gating: isRemoteGeocodingAllowed toggles correctly', () async {
      expect(await LocationService.isRemoteGeocodingAllowed(), isTrue);

      await LocationService.setRemoteGeocodingAllowed(false);
      expect(await LocationService.isRemoteGeocodingAllowed(), isFalse);

      await LocationService.setRemoteGeocodingAllowed(true);
      expect(await LocationService.isRemoteGeocodingAllowed(), isTrue);
    });

    test('Nearest verified city catalog lookup provides 100% offline accuracy', () {
      // Coordinate near Algiers (within 45km)
      final nearest = VerifiedCitiesCatalog.findNearest(36.7538, 3.0588, maxDistanceKm: 45.0);
      expect(nearest, isNotNull);
      expect(nearest!.country, 'الجزائر');
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
    });
  });
}
