import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:talib_ilm/features/quran/data/quran_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    QuranApiService.resetForTesting();
  });

  tearDown(() {
    QuranApiService.resetForTesting();
  });

  group('QuranApiService Input Bounds Validation (R83)', () {
    test('isValidSurahNumber accurately bounds 1..114', () {
      expect(QuranApiService.isValidSurahNumber(1), isTrue);
      expect(QuranApiService.isValidSurahNumber(114), isTrue);
      expect(QuranApiService.isValidSurahNumber(0), isFalse);
      expect(QuranApiService.isValidSurahNumber(115), isFalse);
      expect(QuranApiService.isValidSurahNumber(-5), isFalse);
    });

    test('isValidPageNumber accurately bounds 1..604', () {
      expect(QuranApiService.isValidPageNumber(1), isTrue);
      expect(QuranApiService.isValidPageNumber(604), isTrue);
      expect(QuranApiService.isValidPageNumber(0), isFalse);
      expect(QuranApiService.isValidPageNumber(605), isFalse);
      expect(QuranApiService.isValidPageNumber(-1), isFalse);
    });

    test('isValidJuzNumber accurately bounds 1..30', () {
      expect(QuranApiService.isValidJuzNumber(1), isTrue);
      expect(QuranApiService.isValidJuzNumber(30), isTrue);
      expect(QuranApiService.isValidJuzNumber(0), isFalse);
      expect(QuranApiService.isValidJuzNumber(31), isFalse);
      expect(QuranApiService.isValidJuzNumber(-10), isFalse);
    });

    test('isValidAyah accurately bounds canonical ayahs per surah', () {
      // Al-Fatiha has 7 verses
      expect(QuranApiService.isValidAyah(1, 1), isTrue);
      expect(QuranApiService.isValidAyah(1, 7), isTrue);
      expect(QuranApiService.isValidAyah(1, 0), isFalse);
      expect(QuranApiService.isValidAyah(1, 8), isFalse);

      // Al-Baqarah has 286 verses
      expect(QuranApiService.isValidAyah(2, 286), isTrue);
      expect(QuranApiService.isValidAyah(2, 287), isFalse);

      // Invalid surah numbers
      expect(QuranApiService.isValidAyah(0, 1), isFalse);
      expect(QuranApiService.isValidAyah(115, 1), isFalse);
    });

    test('Invalid requests return immediately with zero network calls', () async {
      int networkCallCount = 0;
      final mockClient = MockClient((request) async {
        networkCallCount++;
        return http.Response('{}', 200);
      });
      QuranApiService.setHttpClient(mockClient);

      // Invalid surah numbers
      final surahLow = await QuranApiService.getSurah(0);
      final surahHigh = await QuranApiService.getSurah(115);
      expect(surahLow, isNull);
      expect(surahHigh, isNull);

      // Invalid page numbers
      final pageLow = await QuranApiService.getPage(0);
      final pageHigh = await QuranApiService.getPage(605);
      expect(pageLow, isEmpty);
      expect(pageHigh, isEmpty);

      // Invalid juz numbers
      final juzLow = await QuranApiService.getJuz(0);
      final juzHigh = await QuranApiService.getJuz(31);
      expect(juzLow, isNull);
      expect(juzHigh, isNull);

      // Invalid ayah references
      final ayahBadFmt = await QuranApiService.getAyah('invalid');
      final ayahBadSurah = await QuranApiService.getAyah('0:1');
      final ayahOutOfRange = await QuranApiService.getAyah('1:8');
      expect(ayahBadFmt, isNull);
      expect(ayahBadSurah, isNull);
      expect(ayahOutOfRange, isNull);

      // Empty or whitespace search
      final emptySearch = await QuranApiService.searchQuran('');
      final whitespaceSearch = await QuranApiService.searchQuran('   ');
      expect(emptySearch, isEmpty);
      expect(whitespaceSearch, isEmpty);

      expect(networkCallCount, equals(0),
          reason: 'Zero network calls must be dispatched for invalid inputs');
    });
  });

  group('QuranApiService HTTP Seam & Normal Flow (R83)', () {
    test('getAllSurahs fetches and parses chapters from quran.com API', () async {
      final mockChaptersJson = jsonEncode({
        'chapters': [
          {
            'id': 1,
            'name_arabic': 'الفاتحة',
            'name_simple': 'Al-Fatihah',
            'translated_name': {'name': 'The Opener'},
            'verses_count': 7,
            'revelation_place': 'makkah',
          },
          {
            'id': 2,
            'name_arabic': 'البقرة',
            'name_simple': 'Al-Baqarah',
            'translated_name': {'name': 'The Cow'},
            'verses_count': 286,
            'revelation_place': 'madinah',
          },
        ]
      });

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'https://api.quran.com/api/v4/chapters');
        return http.Response(mockChaptersJson, 200, headers: {'content-type': 'application/json'});
      });
      QuranApiService.setHttpClient(mockClient);

      final surahs = await QuranApiService.getAllSurahs();
      expect(surahs.length, equals(2));
      expect(surahs[0].number, equals(1));
      expect(surahs[0].name, equals('الفاتحة'));
      expect(surahs[1].number, equals(2));
      expect(surahs[1].name, equals('البقرة'));
    });

    test('getSurah fetches verses from alquran.cloud and parses correctly', () async {
      final mockSurahJson = jsonEncode({
        'code': 200,
        'status': 'OK',
        'data': {
          'number': 114,
          'name': 'سُورَةُ النَّاسِ',
          'englishName': 'An-Naas',
          'englishNameTranslation': 'Mankind',
          'revelationType': 'Meccan',
          'numberOfAyahs': 6,
          'ayahs': [
            {
              'number': 6231,
              'text': 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
              'numberInSurah': 1,
              'juz': 30,
              'manzil': 7,
              'page': 604,
              'ruku': 556,
              'hizbQuarter': 240,
              'sajda': false,
            },
          ]
        }
      });

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('/surah/114/quran-uthmani'));
        return http.Response(mockSurahJson, 200, headers: {'content-type': 'application/json'});
      });
      QuranApiService.setHttpClient(mockClient);

      final surah = await QuranApiService.getSurah(114);
      expect(surah, isNotNull);
      expect(surah!.number, equals(114));
      expect(surah.name, equals('سُورَةُ النَّاسِ'));
      expect(surah.ayahs.length, equals(1));
      expect(surah.ayahs[0].numberInSurah, equals(1));
    });

    test('getPage fetches ayahs for requested page number', () async {
      final mockPageJson = jsonEncode({
        'code': 200,
        'status': 'OK',
        'data': {
          'number': 604,
          'ayahs': [
            {
              'number': 6231,
              'text': 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
              'numberInSurah': 1,
              'juz': 30,
              'page': 604,
              'hizbQuarter': 240,
              'sajda': false,
            }
          ]
        }
      });

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('/page/604/quran-uthmani'));
        return http.Response(mockPageJson, 200, headers: {'content-type': 'application/json'});
      });
      QuranApiService.setHttpClient(mockClient);

      final ayahs = await QuranApiService.getPage(604);
      expect(ayahs.length, equals(1));
      expect(ayahs[0].page, equals(604));
    });

    test('searchQuran queries and parses keyword matches', () async {
      final mockSearchJson = jsonEncode({
        'code': 200,
        'status': 'OK',
        'data': {
          'count': 1,
          'matches': [
            {
              'number': 1,
              'text': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              'edition': {'identifier': 'quran-uthmani'},
              'surah': {
                'number': 1,
                'name': 'سورة الفاتحة',
                'englishName': 'Al-Fatihah',
              },
              'numberInSurah': 1,
            }
          ]
        }
      });

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('/search/'));
        return http.Response(mockSearchJson, 200, headers: {'content-type': 'application/json'});
      });
      QuranApiService.setHttpClient(mockClient);

      final results = await QuranApiService.searchQuran('الله');
      expect(results.length, equals(1));
      expect(results[0].text, contains('اللَّهِ'));
    });
  });

  group('QuranApiService Streaming Byte Ceilings & Cancellation (R83)', () {
    test('Oversized surah metadata response cancels stream and falls back safely', () async {
      bool streamCancelled = false;
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final controller = StreamController<List<int>>();
        controller.onCancel = () {
          streamCancelled = true;
        };

        // Emit chunks that exceed maxQuranSurahsCatalogBytes (64 KB)
        final chunk = List<int>.filled(32 * 1024, 65); // 32 KB chunk
        Future<void>.microtask(() async {
          controller.add(chunk);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk); // 96 KB total > 64 KB limit
        });

        return http.StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      QuranApiService.setHttpClient(mockClient);

      // Should cancel stream and fall back gracefully to offline fallback catalog
      final surahs = await QuranApiService.getAllSurahs();
      expect(streamCancelled, isTrue, reason: 'Stream must be cancelled early when exceeding byte limit');
      expect(surahs.isNotEmpty, isTrue, reason: 'Fallback catalog must be returned');
      expect(surahs.length, equals(114));
    });

    test('Oversized page response cancels stream early and returns empty list', () async {
      bool streamCancelled = false;
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final controller = StreamController<List<int>>();
        controller.onCancel = () {
          streamCancelled = true;
        };

        // Emit chunks exceeding maxQuranPageResponseBytes (128 KB)
        final chunk = List<int>.filled(64 * 1024, 66); // 64 KB chunk
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
      QuranApiService.setHttpClient(mockClient);

      final ayahs = await QuranApiService.getPage(100);
      expect(streamCancelled, isTrue);
      expect(ayahs, isEmpty);
    });
  });

  group('QuranApiService In-Flight Deduplication & Retry Recovery (R83)', () {
    test('Concurrent getAllSurahs requests share single network call', () async {
      int requestCount = 0;
      final completer = Completer<http.Response>();

      final mockClient = MockClient((request) async {
        requestCount++;
        return completer.future;
      });
      QuranApiService.setHttpClient(mockClient);

      // Launch 3 simultaneous requests
      final future1 = QuranApiService.getAllSurahs();
      final future2 = QuranApiService.getAllSurahs();
      final future3 = QuranApiService.getAllSurahs();

      await Future<void>.delayed(Duration.zero);
      expect(requestCount, equals(1), reason: 'Concurrent requests must share identical in-flight Future');

      completer.complete(
        http.Response(
          jsonEncode({
            'chapters': [
              {
                'id': 1,
                'name_arabic': 'الفاتحة',
                'name_simple': 'Al-Fatihah',
                'translated_name': {'name': 'The Opener'},
                'verses_count': 7,
                'revelation_place': 'makkah',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final results = await Future.wait([future1, future2, future3]);
      expect(results[0].length, equals(1));
      expect(results[1].length, equals(1));
      expect(results[2].length, equals(1));
      expect(requestCount, equals(1));
    });

    test('Network failure cleans up in-flight state allowing subsequent retry', () async {
      var shouldFail = true;
      int networkCalls = 0;
      final mockClient = MockClient((request) async {
        networkCalls++;
        if (shouldFail) {
          throw http.ClientException('Simulated network dropout');
        }
        return http.Response(
          jsonEncode({
            'code': 200,
            'status': 'OK',
            'data': {
              'number': 114,
              'name': 'سُورَةُ النَّاسِ',
              'englishName': 'An-Naas',
              'englishNameTranslation': 'Mankind',
              'revelationType': 'Meccan',
              'numberOfAyahs': 6,
              'ayahs': [],
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      QuranApiService.setHttpClient(mockClient);

      // First call fails completely across all retries/sources
      final firstAttempt = await QuranApiService.getSurah(114);
      expect(firstAttempt, isNull);

      // Network recovers, second call succeeds
      shouldFail = false;
      final secondAttempt = await QuranApiService.getSurah(114);
      expect(secondAttempt, isNotNull);
      expect(secondAttempt!.number, equals(114));
      expect(networkCalls, greaterThan(1));
    });
  });
}
