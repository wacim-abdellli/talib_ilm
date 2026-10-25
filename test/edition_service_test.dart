import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/services/edition_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    EditionService.resetForTesting();
    tempDir = await Directory.systemTemp.createTemp('edition_service_test_');
    EditionService.testBaseDir = tempDir;
  });

  tearDown(() async {
    EditionService.resetForTesting();
    if (await tempDir.exists()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  group('EditionService Input Bounds & Path Sanitization (R85)', () {
    test('isValidEditionId accepts only known safe edition identifiers', () {
      expect(EditionService.isValidEditionId('hafs'), isTrue);
      expect(EditionService.isValidEditionId('warsh'), isTrue);
      expect(EditionService.isValidEditionId('tajweed'), isTrue);

      // Rejects path traversal and malformed names
      expect(EditionService.isValidEditionId('../etc/passwd'), isFalse);
      expect(EditionService.isValidEditionId('warsh/malicious'), isFalse);
      expect(EditionService.isValidEditionId('warsh\\malicious'), isFalse);
      expect(EditionService.isValidEditionId('unknown_edition'), isFalse);
      expect(EditionService.isValidEditionId(''), isFalse);
    });

    test('isValidSurahNumber accurately bounds 1..114', () {
      expect(EditionService.isValidSurahNumber(1), isTrue);
      expect(EditionService.isValidSurahNumber(114), isTrue);
      expect(EditionService.isValidSurahNumber(0), isFalse);
      expect(EditionService.isValidSurahNumber(115), isFalse);
    });
  });

  group('EditionService HTTP Seam, Streaming & Atomic Write (R85)', () {
    test('Downloads edition stream, atomically saves file, and updates preferences', () async {
      final mockData = {
        'code': 200,
        'status': 'OK',
        'data': {
          'surahs': [
            {
              'number': 1,
              'name': 'سُورَةُ ٱلْفَاتِحَةِ',
              'englishName': 'Al-Faatiha',
              'englishNameTranslation': 'The Opening',
              'revelationType': 'Meccan',
              'numberOfAyahs': 7,
              'ayahs': [
                {
                  'number': 1,
                  'text': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  'numberInSurah': 1,
                  'juz': 1,
                  'manzil': 1,
                  'page': 1,
                  'ruku': 1,
                  'hizbQuarter': 1,
                  'sajda': false,
                }
              ]
            }
          ]
        }
      };

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('api.alquran.cloud'));
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      EditionService.setHttpClient(mockClient);

      final events = <DownloadProgress>[];
      await for (final progress in EditionService.downloadEdition('warsh')) {
        events.add(progress);
      }

      // Check progress events
      expect(events.isNotEmpty, isTrue);
      expect(events.last.progress, equals(1.0));
      expect(events.last.isError, isFalse);

      // Verify file written to tempDir without leftover .tmp file
      final finalFile = File('${tempDir.path}/warsh.json');
      final tmpFile = File('${tempDir.path}/warsh.json.tmp');
      expect(await finalFile.exists(), isTrue);
      expect(await tmpFile.exists(), isFalse);

      // Verify preferences updated
      expect(await EditionService.isEditionDownloaded('warsh'), isTrue);

      // Verify loadSurahFromEdition parses the downloaded file
      final surah = await EditionService.loadSurahFromEdition('warsh', 1);
      expect(surah, isNotNull);
      expect(surah!.number, equals(1));
      expect(surah.name, contains('ٱلْفَاتِحَةِ'));

      // Verify deleteEdition deletes file and removes from preferences
      final deleted = await EditionService.deleteEdition('warsh');
      expect(deleted, isTrue);
      expect(await finalFile.exists(), isFalse);
      expect(await EditionService.isEditionDownloaded('warsh'), isFalse);
    });

    test('Oversized edition payload triggers stream cancellation and cleans up tmp file', () async {
      bool streamCancelled = false;
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final controller = StreamController<List<int>>();
        controller.onCancel = () {
          streamCancelled = true;
        };

        // Emit chunks exceeding maxQuranEditionBytes (6 MB)
        final chunk = List<int>.filled(2 * 1024 * 1024, 65); // 2 MB chunk
        Future<void>.microtask(() async {
          controller.add(chunk);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk); // 10 MB total > 6 MB limit
        });

        return http.StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      EditionService.setHttpClient(mockClient);

      final events = <DownloadProgress>[];
      await for (final progress in EditionService.downloadEdition('tajweed')) {
        events.add(progress);
      }

      expect(events.last.isError, isTrue);
      expect(streamCancelled, isTrue, reason: 'Stream must be cancelled early on oversized payload');

      // Ensure neither tmp nor final file remain
      final finalFile = File('${tempDir.path}/tajweed.json');
      final tmpFile = File('${tempDir.path}/tajweed.json.tmp');
      expect(await finalFile.exists(), isFalse);
      expect(await tmpFile.exists(), isFalse);
      expect(await EditionService.isEditionDownloaded('tajweed'), isFalse);
    });
  });
}
