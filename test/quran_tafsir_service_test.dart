import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/constants/app_policy.dart';
import 'package:talib_ilm/features/quran/data/services/quran_tafsir_service.dart';

class TestStreamingHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;
  TestStreamingHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    QuranTafsirService.clearMemoryCache();
    QuranTafsirService.resetHttpClient();
  });

  tearDown(() {
    QuranTafsirService.clearMemoryCache();
    QuranTafsirService.resetHttpClient();
  });

  group('QuranTafsirService Input Validation (R80)', () {
    test('isValidVerse accurately rejects out-of-bounds surah or ayah numbers', () {
      expect(QuranTafsirService.isValidVerse(0, 1), isFalse);
      expect(QuranTafsirService.isValidVerse(115, 1), isFalse);
      expect(QuranTafsirService.isValidVerse(-5, 1), isFalse);
      expect(QuranTafsirService.isValidVerse(1, 0), isFalse);
      expect(QuranTafsirService.isValidVerse(1, -1), isFalse);
      expect(QuranTafsirService.isValidVerse(1, 7), isTrue); // Al-Fatiha has 7 verses
      expect(QuranTafsirService.isValidVerse(1, 8), isFalse); // Al-Fatiha does not have 8 verses
      expect(QuranTafsirService.isValidVerse(114, 6), isTrue); // An-Nas has 6 verses
      expect(QuranTafsirService.isValidVerse(114, 7), isFalse);
    });

    test('getTafsir and fetchWordMeanings reject invalid verses without network or storage calls', () async {
      bool networkCalled = false;
      QuranTafsirService.setHttpClient(TestStreamingHttpClient((request) async {
        networkCalled = true;
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 200);
      }));

      final tafsir = await QuranTafsirService.getTafsir(surahNumber: 0, ayahNumber: 1);
      expect(tafsir, equals('آية غير صالحة'));

      final words = await QuranTafsirService.fetchWordMeanings(115, 1);
      expect(words, isEmpty);

      final cached = QuranTafsirService.getCachedWordMeanings(999, 1);
      expect(cached, isNull);

      expect(networkCalled, isFalse, reason: 'Must never fire HTTP requests for invalid verse bounds');
    });
  });

  group('QuranTafsirService HTTP Seam & Streaming Byte Limits (R80)', () {
    test('Seam: setHttpClient routes CDN requests to test handler', () async {
      final testClient = TestStreamingHttpClient((request) async {
        const jsonStr = '{"text": "الحمد لله رب العالمين: أي الشكر التام لله وحده"}';
        final bytes = utf8.encode(jsonStr);
        return http.StreamedResponse(
          Stream.value(bytes),
          200,
          contentLength: bytes.length,
        );
      });

      QuranTafsirService.setHttpClient(testClient);
      final text = await QuranTafsirService.getTafsir(surahNumber: 1, ayahNumber: 2);
      expect(text, contains('الحمد لله رب العالمين: أي الشكر التام لله وحده'));
    });

    test('Oversized Tafsir stream cancels subscription early and falls back gracefully', () async {
      int cancelCount = 0;
      final chunk100kb = Uint8List(100 * 1024);

      final testClient = TestStreamingHttpClient((request) async {
        final controller = StreamController<List<int>>(onCancel: () {
          cancelCount++;
        });

        Future<void>.microtask(() async {
          if (!controller.isClosed) controller.add(chunk100kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk100kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk100kb);
          if (!controller.isClosed) await controller.close();
        });

        return http.StreamedResponse(controller.stream, 200);
      });

      QuranTafsirService.setHttpClient(testClient);

      // Falls back to bundled translation or verse text on stream cancellation
      final text = await QuranTafsirService.getTafsir(surahNumber: 1, ayahNumber: 1);
      expect(text.isNotEmpty, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cancelCount, greaterThanOrEqualTo(1), reason: 'Stream subscription must be cancelled when exceeding 256KB');
    });

    test('Oversized Word-by-Word stream cancels subscription and returns empty list', () async {
      bool streamCancelled = false;
      final chunk80kb = Uint8List(80 * 1024);

      final testClient = TestStreamingHttpClient((request) async {
        final controller = StreamController<List<int>>(onCancel: () {
          streamCancelled = true;
        });

        Future<void>.microtask(() async {
          if (!controller.isClosed) controller.add(chunk80kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk80kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk80kb);
          if (!controller.isClosed) await controller.close();
        });

        return http.StreamedResponse(controller.stream, 200);
      });

      QuranTafsirService.setHttpClient(testClient);

      final words = await QuranTafsirService.fetchWordMeanings(1, 1);
      expect(words, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(streamCancelled, isTrue, reason: 'WordMeaning stream must be cancelled when exceeding 128KB');
    });
  });

  group('QuranTafsirService In-Flight Deduplication & Retry (R80)', () {
    test('Concurrent identical Tafsir requests share in-flight Future and make 1 network call', () async {
      int requestCount = 0;
      final testClient = TestStreamingHttpClient((request) async {
        requestCount++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        const jsonStr = '{"text": "تفسير متزامن مشترك"}';
        final bytes = utf8.encode(jsonStr);
        return http.StreamedResponse(Stream.value(bytes), 200, contentLength: bytes.length);
      });

      QuranTafsirService.setHttpClient(testClient);

      // Launch 3 simultaneous requests for 1:3
      final futures = await Future.wait([
        QuranTafsirService.getTafsir(surahNumber: 1, ayahNumber: 3),
        QuranTafsirService.getTafsir(surahNumber: 1, ayahNumber: 3),
        QuranTafsirService.getTafsir(surahNumber: 1, ayahNumber: 3),
      ]);

      expect(requestCount, equals(1), reason: 'Concurrent calls must deduplicate into 1 network request');
      for (final res in futures) {
        expect(res, contains('تفسير متزامن مشترك'));
      }
    });

    test('Concurrent identical Word-by-Word requests share in-flight Future', () async {
      int requestCount = 0;
      final testClient = TestStreamingHttpClient((request) async {
        requestCount++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        const jsonStr = '{"verse": {"words": [{"text_uthmani": "الرَّحِيمِ", "translation": {"text": "The Merciful"}}]}}';
        final bytes = utf8.encode(jsonStr);
        return http.StreamedResponse(Stream.value(bytes), 200, contentLength: bytes.length);
      });

      QuranTafsirService.setHttpClient(testClient);

      final futures = await Future.wait([
        QuranTafsirService.fetchWordMeanings(1, 3),
        QuranTafsirService.fetchWordMeanings(1, 3),
        QuranTafsirService.fetchWordMeanings(1, 3),
      ]);

      expect(requestCount, equals(1));
      for (final list in futures) {
        expect(list.length, equals(1));
        expect(list.first.word, equals('الرَّحِيمِ'));
      }
    });

    test('Failed request does not leave sticky in-flight state and allows retry', () async {
      int callCount = 0;
      final testClient = TestStreamingHttpClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.StreamedResponse(Stream.value(utf8.encode('error')), 500);
        } else {
          const jsonStr = '{"text": "تمت إعادة المحاولة بنجاح"}';
          final bytes = utf8.encode(jsonStr);
          return http.StreamedResponse(Stream.value(bytes), 200, contentLength: bytes.length);
        }
      });

      QuranTafsirService.setHttpClient(testClient);

      // First call fails over network and drops back to bundled fallback
      final firstRes = await QuranTafsirService.getTafsir(surahNumber: 1, ayahNumber: 4);
      expect(firstRes, isNot(contains('تمت إعادة المحاولة بنجاح')));
      expect(callCount, equals(2)); // Tried CDN (failed) + Quran.com fallback (failed)

      // Clear memory cache to simulate retry attempt
      QuranTafsirService.clearMemoryCache();

      // Second call retries network and succeeds
      final secondRes = await QuranTafsirService.getTafsir(surahNumber: 1, ayahNumber: 4);
      expect(secondRes, contains('تمت إعادة المحاولة بنجاح'));
    });
  });

  group('QuranTafsirService RAM Cache Budgets & FIFO Eviction (R80)', () {
    test('Tafsir memory cache caps at AppPolicy.maxTafsirMemoryEntries and evicts oldest', () async {
      final testClient = TestStreamingHttpClient((request) async {
        final b = utf8.encode('{"text": "شرح"}');
        return http.StreamedResponse(Stream.value(b), 200, contentLength: b.length);
      });
      QuranTafsirService.setHttpClient(testClient);

      // Load entries up to the limit
      final maxEntries = AppPolicy.maxTafsirMemoryEntries;
      for (int i = 1; i <= maxEntries + 5; i++) {
        // Use Surah 2 (Al-Baqarah has 286 ayahs)
        await QuranTafsirService.getTafsir(surahNumber: 2, ayahNumber: i);
      }

      expect(QuranTafsirService.memCacheSize, lessThanOrEqualTo(maxEntries));
      expect(QuranTafsirService.memCacheSize, equals(maxEntries));
    });

    test('WordMeanings memory cache caps at AppPolicy.maxWordMeaningMemoryEntries', () async {
      final testClient = TestStreamingHttpClient((request) async {
        final b = utf8.encode('{"verse": {"words": [{"text_uthmani": "ء", "translation": {"text": "letter"}}]}}');
        return http.StreamedResponse(Stream.value(b), 200, contentLength: b.length);
      });
      QuranTafsirService.setHttpClient(testClient);

      final maxEntries = AppPolicy.maxWordMeaningMemoryEntries;
      for (int i = 1; i <= maxEntries + 5; i++) {
        await QuranTafsirService.fetchWordMeanings(2, i);
      }

      expect(QuranTafsirService.wordsCacheSize, lessThanOrEqualTo(maxEntries));
      expect(QuranTafsirService.wordsCacheSize, equals(maxEntries));
    });
  });

  group('QuranTafsirService Persistence & Offline Fallback', () {
    test('loads cached word meanings from SharedPreferences and populates RAM cache', () async {
      final sampleWords = [
        {'w': 'بِسْمِ', 'm': 'In the name', 't': "bis'mi"},
        {'w': 'اللَّهِ', 'm': 'of Allah', 't': 'Allahi'},
      ];
      SharedPreferences.setMockInitialValues({
        'wbw_1_1': json.encode(sampleWords),
      });

      final words = await QuranTafsirService.fetchWordMeanings(1, 1);
      expect(words.length, 2);
      expect(words[0].word, 'بِسْمِ');
      expect(words[0].meaning, 'In the name');

      final cached = QuranTafsirService.getCachedWordMeanings(1, 1);
      expect(cached, isNotNull);
      expect(cached!.length, 2);
    });

    test('offline fallback returns authentic bundled translation when network is unreachable', () async {
      final testClient = TestStreamingHttpClient((request) async {
        throw Exception('No network');
      });
      QuranTafsirService.setHttpClient(testClient);

      final tafsir = await QuranTafsirService.getTafsir(surahNumber: 1, ayahNumber: 1);
      expect(tafsir, contains('In the name of Allah'));
    });
  });
}
