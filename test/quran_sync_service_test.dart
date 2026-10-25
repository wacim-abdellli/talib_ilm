import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/services/quran_page_service.dart';
import 'package:talib_ilm/features/quran/data/services/quran_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    QuranSyncService.resetForTesting();
    QuranSyncService.retryDelay = Duration.zero;
  });

  tearDown(() {
    QuranSyncService.resetForTesting();
  });

  group('QuranSyncService Input Bounds Validation (R84)', () {
    test('isValidChunkIndex accurately bounds 1..31', () {
      expect(QuranSyncService.isValidChunkIndex(1), isTrue);
      expect(QuranSyncService.isValidChunkIndex(31), isTrue);
      expect(QuranSyncService.isValidChunkIndex(0), isFalse);
      expect(QuranSyncService.isValidChunkIndex(32), isFalse);
      expect(QuranSyncService.isValidChunkIndex(-1), isFalse);
    });

    test('isValidPageNumber accurately bounds 1..604', () {
      expect(QuranSyncService.isValidPageNumber(1), isTrue);
      expect(QuranSyncService.isValidPageNumber(604), isTrue);
      expect(QuranSyncService.isValidPageNumber(0), isFalse);
      expect(QuranSyncService.isValidPageNumber(605), isFalse);
    });

    test('Invalid chunk requests return early with zero network calls', () async {
      int networkCallCount = 0;
      final mockClient = MockClient((request) async {
        networkCallCount++;
        return http.Response('{}', 200);
      });
      QuranSyncService.setHttpClient(mockClient);

      expect(await QuranSyncService.instance.isChunkDownloaded(0), isFalse);
      expect(await QuranSyncService.instance.isChunkDownloaded(32), isFalse);

      await QuranSyncService.instance.downloadChunk(0);
      await QuranSyncService.instance.downloadChunk(32);

      expect(networkCallCount, equals(0),
          reason: 'Zero network calls must be dispatched for out-of-bounds chunks');
    });
  });

  group('QuranSyncService HTTP Seam & Database Hook Flow (R84)', () {
    test('Fetches missing pages, saves via database hook, and marks chunk synced', () async {
      final savedPages = <int, QuranPageData>{};
      final existingDbPages = <int>{1}; // Page 1 already in DB

      QuranSyncService.setDatabaseHooks(
        getPage: (pageNum) async {
          if (existingDbPages.contains(pageNum)) {
            return QuranPageData(
              pageNumber: 1,
              verses: [],
            );
          }
          return null;
        },
        savePage: (pageNum, data) async {
          savedPages[pageNum] = data;
        },
      );

      final requestedUrls = <String>[];
      final mockClient = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        expect(request.headers['Accept'], equals('application/json'));

        final pageMatch = RegExp(r'/by_page/(\d+)').firstMatch(request.url.path);
        final pageNum = int.parse(pageMatch!.group(1)!);

        return http.Response(
          jsonEncode({
            'verses': [
              {
                'id': pageNum * 10,
                'verse_number': 1,
                'verse_key': '1:1',
                'text_uthmani': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      QuranSyncService.setHttpClient(mockClient);

      // Track progress emissions
      final progressEvents = <double>[];
      final subscription = QuranSyncService.instance.progressStream.listen((p) {
        progressEvents.add(p);
      });

      // Download chunk 1 (Pages 1..20)
      await QuranSyncService.instance.downloadChunk(1);
      await subscription.cancel();

      // Page 1 was already in DB, so pages 2..20 (19 pages) should have been fetched
      expect(requestedUrls.length, equals(19));
      expect(savedPages.length, equals(19));
      expect(savedPages.containsKey(2), isTrue);
      expect(savedPages.containsKey(20), isTrue);

      // SharedPreferences should record chunk 1 completed
      expect(await QuranSyncService.instance.isChunkDownloaded(1), isTrue);

      // Progress stream should have emitted progression
      expect(progressEvents.isNotEmpty, isTrue);
      expect(progressEvents.last, equals(1.0));
    });

    test('Already synced chunk skips download immediately', () async {
      SharedPreferences.setMockInitialValues({'quran_chunk_synced_2': true});

      int networkCalls = 0;
      final mockClient = MockClient((request) async {
        networkCalls++;
        return http.Response('{}', 200);
      });
      QuranSyncService.setHttpClient(mockClient);

      await QuranSyncService.instance.downloadChunk(2);
      expect(networkCalls, equals(0), reason: 'Already synced chunk must skip network calls');
    });
  });

  group('QuranSyncService Streaming Byte Ceilings & Cancellation (R84)', () {
    test('Oversized page response cancels stream early and fails page fetch', () async {
      bool streamCancelled = false;
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final controller = StreamController<List<int>>();
        controller.onCancel = () {
          streamCancelled = true;
        };

        // Emit chunks exceeding maxQuranPageResponseBytes (128 KB)
        final chunk = List<int>.filled(64 * 1024, 65); // 64 KB chunk
        Future<void>.microtask(() async {
          controller.add(chunk);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk); // 192 KB total > 128 KB limit
        });

        return http.StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      QuranSyncService.setHttpClient(mockClient);

      QuranSyncService.setDatabaseHooks(
        getPage: (_) async => null,
        savePage: (_, data) async {},
      );

      // Expect downloadChunk to fail when oversized response aborts
      expect(
        () async => await QuranSyncService.instance.downloadChunk(1),
        throwsA(isA<Exception>()),
      );

      // Verify stream was cancelled
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(streamCancelled, isTrue, reason: 'Stream must be cancelled early when exceeding 128 KB');
      expect(await QuranSyncService.instance.isChunkDownloaded(1), isFalse);
    });
  });

  group('QuranSyncService Concurrency Deduplication & Join (R84)', () {
    test('Concurrent identical chunk downloads join same in-flight Future', () async {
      final savedPages = <int>{};
      final completer = Completer<http.Response>();
      int requestCount = 0;

      QuranSyncService.setDatabaseHooks(
        getPage: (_) async => null,
        savePage: (pageNum, data) async {
          savedPages.add(pageNum);
        },
      );

      final mockClient = MockClient((request) async {
        requestCount++;
        return completer.future;
      });
      QuranSyncService.setHttpClient(mockClient);

      // Launch 3 concurrent calls for Chunk 31 (Pages 601..604)
      final future1 = QuranSyncService.instance.downloadChunk(31);
      final future2 = QuranSyncService.instance.downloadChunk(31);
      final future3 = QuranSyncService.instance.downloadChunk(31);

      await Future<void>.delayed(Duration.zero);
      // Only 1 page request dispatched initially
      expect(requestCount, equals(1));

      completer.complete(
        http.Response(
          jsonEncode({
            'verses': [
              {
                'id': 6230,
                'verse_number': 1,
                'verse_key': '114:1',
                'text_uthmani': 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      // All 3 callers await the same completion
      await Future.wait([future1, future2, future3]);

      // All callers completed and chunk marked downloaded
      expect(await QuranSyncService.instance.isChunkDownloaded(31), isTrue);
    });

    test('Failed chunk download cleans up in-flight state allowing retry', () async {
      var shouldFail = true;
      int networkCalls = 0;

      QuranSyncService.setDatabaseHooks(
        getPage: (_) async => null,
        savePage: (_, data) async {},
      );

      final mockClient = MockClient((request) async {
        networkCalls++;
        if (shouldFail) {
          throw http.ClientException('Simulated network outage');
        }
        return http.Response(
          jsonEncode({
            'verses': [
              {
                'id': 1,
                'verse_number': 1,
                'verse_key': '1:1',
                'text_uthmani': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      QuranSyncService.setHttpClient(mockClient);

      // Attempt 1 fails
      await expectLater(
        QuranSyncService.instance.downloadChunk(1),
        throwsA(isA<http.ClientException>()),
      );
      expect(await QuranSyncService.instance.isChunkDownloaded(1), isFalse);

      // Attempt 2 succeeds after network recovers
      shouldFail = false;
      await QuranSyncService.instance.downloadChunk(1);
      expect(await QuranSyncService.instance.isChunkDownloaded(1), isTrue);
      expect(networkCalls, greaterThan(1));
    });
  });
}
