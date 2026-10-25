import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:talib_ilm/app/theme/app_policy.dart';
import 'package:talib_ilm/features/quran/data/services/tajweed_verse_service.dart';

/// Test HTTP client that routes requests to custom handlers.
class TestStreamingHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;
  TestStreamingHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

void main() {
  setUp(() {
    TajweedVerseService.clearMemoryCache();
    TajweedVerseService.resetHttpClient();
  });

  tearDown(() {
    TajweedVerseService.clearMemoryCache();
    TajweedVerseService.resetHttpClient();
  });

  group('TajweedVerseService Input Validation (R81)', () {
    test('isValidSurah accurately bounds 1..114', () {
      expect(TajweedVerseService.isValidSurah(1), isTrue);
      expect(TajweedVerseService.isValidSurah(114), isTrue);
      expect(TajweedVerseService.isValidSurah(0), isFalse);
      expect(TajweedVerseService.isValidSurah(-5), isFalse);
      expect(TajweedVerseService.isValidSurah(115), isFalse);
    });

    test('isValidVerse accurately bounds canonical ayahs per chapter', () {
      // Al-Fatihah: 7 ayahs
      expect(TajweedVerseService.isValidVerse(1, 1), isTrue);
      expect(TajweedVerseService.isValidVerse(1, 7), isTrue);
      expect(TajweedVerseService.isValidVerse(1, 0), isFalse);
      expect(TajweedVerseService.isValidVerse(1, 8), isFalse);

      // Al-Baqarah: 286 ayahs
      expect(TajweedVerseService.isValidVerse(2, 286), isTrue);
      expect(TajweedVerseService.isValidVerse(2, 287), isFalse);

      // An-Nas: 6 ayahs
      expect(TajweedVerseService.isValidVerse(114, 6), isTrue);
      expect(TajweedVerseService.isValidVerse(114, 7), isFalse);

      // Invalid Surah
      expect(TajweedVerseService.isValidVerse(0, 1), isFalse);
      expect(TajweedVerseService.isValidVerse(115, 1), isFalse);
    });

    test('getAyahMarkup and getSurahMarkups reject invalid inputs without network calls', () async {
      bool networkCalled = false;
      final testClient = TestStreamingHttpClient((request) async {
        networkCalled = true;
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 200);
      });
      TajweedVerseService.setHttpClient(testClient);

      final ayahResult1 = await TajweedVerseService.getAyahMarkup(0, 1);
      final ayahResult2 = await TajweedVerseService.getAyahMarkup(1, 8);
      final surahResult = await TajweedVerseService.getSurahMarkups(115);

      expect(ayahResult1, isNull);
      expect(ayahResult2, isNull);
      expect(surahResult, isEmpty);
      expect(networkCalled, isFalse, reason: 'Invalid inputs must never trigger HTTP calls');
    });
  });

  group('TajweedVerseService HTTP Seam & Streaming Byte Limits (R81)', () {
    test('Seam: setHttpClient routes requests and parses verses correctly', () async {
      final sampleJson = json.encode({
        'verses': [
          {
            'verse_number': 1,
            'text_uthmani_tajweed': 'بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ',
          },
          {
            'verse_number': 2,
            'text_uthmani_tajweed': 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
          },
        ],
      });

      final testClient = TestStreamingHttpClient((request) async {
        expect(request.url.toString(), contains('api.quran.com'));
        expect(request.url.toString(), contains('/by_chapter/1'));
        final bytes = utf8.encode(sampleJson);
        return http.StreamedResponse(
          Stream.value(bytes),
          200,
          contentLength: bytes.length,
        );
      });

      TajweedVerseService.setHttpClient(testClient);

      final surahMap = await TajweedVerseService.getSurahMarkups(1);
      expect(surahMap.length, 2);
      expect(surahMap[1], contains('ham_wasl'));
      expect(surahMap[2], contains('ٱلْحَمْدُ'));

      // Ayah markup query hits cache
      final ayah1 = await TajweedVerseService.getAyahMarkup(1, 1);
      expect(ayah1, surahMap[1]);
    });

    test('Oversized chapter stream cancels subscription early and does not cache corrupted data', () async {
      int cancelCount = 0;
      final chunk200kb = Uint8List(200 * 1024);

      final testClient = TestStreamingHttpClient((request) async {
        final controller = StreamController<List<int>>(onCancel: () {
          cancelCount++;
        });

        Future<void>.microtask(() async {
          // Send 3 chunks of 200KB = 600KB > AppPolicy.maxTajweedChapterResponseBytes (512 KB)
          if (!controller.isClosed) controller.add(chunk200kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk200kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk200kb);
          if (!controller.isClosed) await controller.close();
        });

        return http.StreamedResponse(controller.stream, 200);
      });

      TajweedVerseService.setHttpClient(testClient);

      final map = await TajweedVerseService.getSurahMarkups(2);
      expect(map, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cancelCount, greaterThanOrEqualTo(1), reason: 'Stream must be cancelled when exceeding 512KB');
    });
  });

  group('TajweedVerseService Sticky Failure Prevention & Retry Recovery (R81)', () {
    test('Transient network failure does NOT poison cache with empty map, allowing retry', () async {
      int callCount = 0;

      final sampleJson = json.encode({
        'verses': [
          {
            'verse_number': 1,
            'text_uthmani_tajweed': 'الٓمٓ',
          },
        ],
      });

      final testClient = TestStreamingHttpClient((request) async {
        callCount++;
        if (callCount == 1) {
          // First attempt fails with 500 server error
          return http.StreamedResponse(Stream.value(utf8.encode('Server error')), 500);
        } else {
          // Second attempt succeeds
          final bytes = utf8.encode(sampleJson);
          return http.StreamedResponse(Stream.value(bytes), 200);
        }
      });

      TajweedVerseService.setHttpClient(testClient);

      // Attempt 1: Fails due to server error, returns empty map
      final firstResult = await TajweedVerseService.getSurahMarkups(2);
      expect(firstResult, isEmpty);
      expect(callCount, 1);

      // Attempt 2: Network recovered. Must NOT return sticky empty cache; must retry and succeed!
      final secondResult = await TajweedVerseService.getSurahMarkups(2);
      expect(secondResult.isNotEmpty, isTrue);
      expect(secondResult[1], 'الٓمٓ');
      expect(callCount, 2, reason: 'Must have retried network call instead of using empty sticky cache');

      // Attempt 3: Successful result IS cached, so third call makes no network request
      final thirdResult = await TajweedVerseService.getSurahMarkups(2);
      expect(thirdResult[1], 'الٓمٓ');
      expect(callCount, 2, reason: 'Successful non-empty result must be cached in memory');
    });
  });

  group('TajweedVerseService In-Flight Deduplication & Concurrency (R81)', () {
    test('Concurrent identical chapter requests share single network call', () async {
      int networkCalls = 0;
      final completer = Completer<List<int>>();

      final testClient = TestStreamingHttpClient((request) async {
        networkCalls++;
        final bytes = await completer.future;
        return http.StreamedResponse(Stream.value(bytes), 200);
      });

      TajweedVerseService.setHttpClient(testClient);

      // Launch 3 parallel requests for Surah 112 (Al-Ikhlas)
      final future1 = TajweedVerseService.getSurahMarkups(112);
      final future2 = TajweedVerseService.getSurahMarkups(112);
      final future3 = TajweedVerseService.getAyahMarkup(112, 1);

      // Network call has started exactly once
      expect(networkCalls, 1);

      final sampleJson = json.encode({
        'verses': [
          {
            'verse_number': 1,
            'text_uthmani_tajweed': 'قُلْ هُوَ اللَّهُ أَحَدٌ',
          },
        ],
      });
      completer.complete(utf8.encode(sampleJson));

      final results = await Future.wait([future1, future2]);
      final ayah1 = await future3;

      expect(results[0][1], 'قُلْ هُوَ اللَّهُ أَحَدٌ');
      expect(results[1][1], 'قُلْ هُوَ اللَّهُ أَحَدٌ');
      expect(ayah1, 'قُلْ هُوَ اللَّهُ أَحَدٌ');
      expect(networkCalls, 1, reason: 'Concurrent calls must deduplicate into a single HTTP request');
    });

    test('Failed in-flight request cleans up pending state cleanly', () async {
      int networkCalls = 0;

      final testClient = TestStreamingHttpClient((request) async {
        networkCalls++;
        throw http.ClientException('Connection aborted');
      });

      TajweedVerseService.setHttpClient(testClient);

      final result1 = await TajweedVerseService.getSurahMarkups(108);
      expect(result1, isEmpty);
      expect(networkCalls, 1);

      // Next attempt can be initiated without stuck pending future
      final result2 = await TajweedVerseService.getSurahMarkups(108);
      expect(result2, isEmpty);
      expect(networkCalls, 2, reason: 'Pending in-flight state must be cleared in finally');
    });
  });

  group('TajweedVerseService RAM FIFO Eviction (R81)', () {
    test('Surah cache respects AppPolicy.maxTajweedSurahMemoryEntries and evicts oldest', () async {
      final testClient = TestStreamingHttpClient((request) async {
        final surahMatch = RegExp(r'/by_chapter/(\d+)').firstMatch(request.url.path);
        final surah = int.tryParse(surahMatch?.group(1) ?? '1') ?? 1;
        final jsonStr = json.encode({
          'verses': [
            {'verse_number': 1, 'text_uthmani_tajweed': 'Surah $surah Ayah 1'},
          ],
        });
        return http.StreamedResponse(Stream.value(utf8.encode(jsonStr)), 200);
      });

      TajweedVerseService.setHttpClient(testClient);

      // Populate up to maxTajweedSurahMemoryEntries (30) + 2 extra
      const totalToPopulate = AppPolicy.maxTajweedSurahMemoryEntries + 2;
      for (int i = 1; i <= totalToPopulate; i++) {
        await TajweedVerseService.getSurahMarkups(i);
      }

      // Oldest entries (1 and 2) should have been evicted from FIFO
      // When requesting Surah 1 again, it must refetch via network
      int refetchCalls = 0;
      final refetchClient = TestStreamingHttpClient((request) async {
        refetchCalls++;
        final jsonStr = json.encode({
          'verses': [
            {'verse_number': 1, 'text_uthmani_tajweed': 'Surah 1 Refetched'},
          ],
        });
        return http.StreamedResponse(Stream.value(utf8.encode(jsonStr)), 200);
      });

      TajweedVerseService.setHttpClient(refetchClient);
      final refetched = await TajweedVerseService.getSurahMarkups(1);
      expect(refetched[1], 'Surah 1 Refetched');
      expect(refetchCalls, 1, reason: 'Surah 1 should have been evicted when exceeding capacity 30');
    });
  });
}
