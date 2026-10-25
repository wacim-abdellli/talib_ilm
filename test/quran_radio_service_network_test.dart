import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:talib_ilm/app/theme/app_policy.dart';
import 'package:talib_ilm/features/radio/data/models/quran_radio_model.dart';
import 'package:talib_ilm/features/radio/data/services/quran_radio_service.dart';

/// Test HTTP client that routes requests to custom handlers.
class TestStreamingHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;
  TestStreamingHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranRadioService service;

  final defaultBundledStation = QuranRadioStation(
    id: 1,
    name: 'إذاعة القرآن الكريم بمصر',
    rawName: 'إذاعة القرآن الكريم بمصر',
    url: 'https://stream.radiojar.com/8s5u8tpdtwzuv',
    category: 'إذاعات عامة',
  );

  setUp(() async {
    service = QuranRadioService();
    QuranRadioService.resetHttpClient();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    service.resetForTesting(stations: [defaultBundledStation]);
  });

  tearDown(() {
    QuranRadioService.resetHttpClient();
    service.resetForTesting();
  });

  group('QuranRadioService HTTP Seam & Online Refresh (R82)', () {
    test('Seam: setHttpClient routes requests and merges valid new stations', () async {
      final sampleJson = json.encode({
        'radios': [
          {
            'id': 201,
            'name': 'إذاعة الشيخ عبد الباسط عبد الصمد',
            'url': 'https://backup.qurango.net/radio/abdulbasit_abdulsamad_mojawwad',
          },
        ],
      });

      final testClient = TestStreamingHttpClient((request) async {
        expect(request.url.toString(), contains('mp3quran.net/api/v3/radios'));
        final bytes = utf8.encode(sampleJson);
        return http.StreamedResponse(
          Stream.value(bytes),
          200,
          contentLength: bytes.length,
        );
      });

      QuranRadioService.setHttpClient(testClient);

      await service.refreshOnlineStations();

      expect(service.stations.length, 2);
      expect(service.stations.any((s) => s.id == 201), isTrue);
      expect(service.stations.firstWhere((s) => s.id == 201).url, startsWith('https://'));
    });
  });

  group('QuranRadioService Security & Protocol Hardening (R82)', () {
    test('Rejects non-HTTPS cleartext URLs and malformed station addresses', () async {
      final sampleJson = json.encode({
        'radios': [
          {
            'id': 301,
            'name': 'Cleartext Radio',
            'url': 'http://insecure-radio.example.com/stream', // Cleartext HTTP - must be rejected
          },
          {
            'id': 302,
            'name': 'Malformed Scheme Radio',
            'url': 'javascript:alert(1)', // Malformed scheme - must be rejected
          },
          {
            'id': 303,
            'name': 'Empty URL Radio',
            'url': '', // Empty - must be rejected
          },
          {
            'id': 304,
            'name': 'Valid Secure Radio',
            'url': 'https://secure-radio.example.com/stream.mp3', // Valid HTTPS
          },
        ],
      });

      final testClient = TestStreamingHttpClient((request) async {
        final bytes = utf8.encode(sampleJson);
        return http.StreamedResponse(Stream.value(bytes), 200, contentLength: bytes.length);
      });

      QuranRadioService.setHttpClient(testClient);

      await service.refreshOnlineStations();

      // Only the valid secure HTTPS radio should be added
      expect(service.stations.length, 2);
      expect(service.stations.any((s) => s.id == 301), isFalse);
      expect(service.stations.any((s) => s.id == 302), isFalse);
      expect(service.stations.any((s) => s.id == 303), isFalse);
      expect(service.stations.any((s) => s.id == 304), isTrue);
    });
  });

  group('QuranRadioService Streaming Byte Limits & Cancellation (R82)', () {
    test('Oversized radio stream cancels subscription early and leaves bundled stations intact', () async {
      int cancelCount = 0;
      final chunk100kb = Uint8List(100 * 1024);

      final testClient = TestStreamingHttpClient((request) async {
        final controller = StreamController<List<int>>(onCancel: () {
          cancelCount++;
        });

        Future<void>.microtask(() async {
          // Emit 3 chunks of 100KB = 300KB > AppPolicy.maxRadioCatalogBytes (256 KB)
          if (!controller.isClosed) controller.add(chunk100kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk100kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk100kb);
          if (!controller.isClosed) await controller.close();
        });

        return http.StreamedResponse(controller.stream, 200);
      });

      QuranRadioService.setHttpClient(testClient);

      await service.refreshOnlineStations();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cancelCount, greaterThanOrEqualTo(1), reason: 'Stream must be cancelled when exceeding 256KB');
      expect(service.stations.length, 1, reason: 'Bundled stations must remain intact on stream abort');
      expect(service.stations.first.id, defaultBundledStation.id);
    });
  });

  group('QuranRadioService Concurrency & Deduplication (R82)', () {
    test('Concurrent refreshOnlineStations calls share a single network Future', () async {
      int networkCalls = 0;
      final completer = Completer<List<int>>();

      final testClient = TestStreamingHttpClient((request) async {
        networkCalls++;
        final bytes = await completer.future;
        return http.StreamedResponse(Stream.value(bytes), 200);
      });

      QuranRadioService.setHttpClient(testClient);

      // Launch 3 simultaneous refreshes
      final f1 = service.refreshOnlineStations();
      final f2 = service.refreshOnlineStations();
      final f3 = service.refreshOnlineStations();

      expect(networkCalls, 1, reason: 'Duplicate in-flight refreshes must share 1 network request');

      final sampleJson = json.encode({
        'radios': [
          {
            'id': 501,
            'name': 'إذاعة الشارقة',
            'url': 'https://secure.sharjah.ae/radio',
          },
        ],
      });
      completer.complete(utf8.encode(sampleJson));

      await Future.wait([f1, f2, f3]);

      expect(networkCalls, 1);
      expect(service.stations.any((s) => s.id == 501), isTrue);
      expect(service.inFlightRefreshForTesting, isNull, reason: 'In-flight reference must be cleared in finally');
    });

    test('Network error leaves bundled stations intact and allows subsequent retry', () async {
      int networkCalls = 0;

      final testClient = TestStreamingHttpClient((request) async {
        networkCalls++;
        if (networkCalls == 1) {
          throw http.ClientException('Network dropout');
        }
        final sampleJson = json.encode({
          'radios': [
            {
              'id': 601,
              'name': 'إذاعة تلاوات خاشعة',
              'url': 'https://qurango.net/radio/khashia',
            },
          ],
        });
        return http.StreamedResponse(Stream.value(utf8.encode(sampleJson)), 200);
      });

      QuranRadioService.setHttpClient(testClient);

      // First attempt fails
      await service.refreshOnlineStations();
      expect(service.stations.length, 1);
      expect(networkCalls, 1);

      // Second attempt retries and succeeds
      await service.refreshOnlineStations();
      expect(service.stations.length, 2);
      expect(service.stations.any((s) => s.id == 601), isTrue);
      expect(networkCalls, 2);
    });
  });

  group('QuranRadioService Capacity Bounds (R82)', () {
    test('Caps stations at AppPolicy.maxRadioStations', () async {
      // Generate 200 stations, exceeding AppPolicy.maxRadioStations (150)
      final generatedRadios = List.generate(
        200,
        (i) => {
          'id': 1000 + i,
          'name': 'Station $i',
          'url': 'https://secure.radio.test/stream_$i.mp3',
        },
      );
      final sampleJson = json.encode({'radios': generatedRadios});

      final testClient = TestStreamingHttpClient((request) async {
        final bytes = utf8.encode(sampleJson);
        return http.StreamedResponse(Stream.value(bytes), 200, contentLength: bytes.length);
      });

      QuranRadioService.setHttpClient(testClient);

      await service.refreshOnlineStations();

      expect(service.stations.length, AppPolicy.maxRadioStations);
    });
  });
}
