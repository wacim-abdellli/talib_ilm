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

    test('AUD-101: Failed edition replacement preserves existing offline file and download state', () async {
      final initialData = {
        'code': 200,
        'status': 'OK',
        'data': {
          'surahs': [
            {
              'number': 1,
              'name': 'سُورَةُ ٱلْفَاتِحَةِ - النسخة الأصلية',
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

      final replacementData = {
        'code': 200,
        'status': 'OK',
        'data': {
          'surahs': [
            {
              'number': 1,
              'name': 'سُورَةُ ٱلْفَاتِحَةِ - النسخة البديلة',
              'englishName': 'Al-Faatiha Updated',
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

      // 1. Seed existing valid offline edition
      final finalFile = File('${tempDir.path}/warsh.json');
      final tmpFile = File('${tempDir.path}/warsh.json.tmp');
      final backupFile = File('${tempDir.path}/warsh.json.bak');
      final initialJsonString = jsonEncode(initialData);
      await finalFile.writeAsString(initialJsonString);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('downloaded_editions', ['warsh']);
      expect(await EditionService.isEditionDownloaded('warsh'), isTrue);

      // 2. Prepare mock client returning valid replacement payload
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(replacementData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      EditionService.setHttpClient(mockClient);

      // 3. Inject simulated file installation failure (e.g. disk full during install)
      EditionService.testFileInstaller = (src, dst) async {
        throw const FileSystemException('Simulated disk full or I/O failure during rename');
      };

      // 4. Run downloadEdition attempting replacement
      final events = <DownloadProgress>[];
      await for (final progress in EditionService.downloadEdition('warsh')) {
        events.add(progress);
      }

      // 5. Verify error was reported
      expect(events.isNotEmpty, isTrue);
      expect(events.last.isError, isTrue);

      // 6. Verify CRITICAL INVARIANT: Existing offline edition was NOT lost!
      expect(
        await finalFile.exists(),
        isTrue,
        reason: 'AUD-101: Original offline edition file must survive failed replacement!',
      );
      final preservedContent = await finalFile.readAsString();
      expect(
        preservedContent,
        equals(initialJsonString),
        reason: 'Preserved edition content must remain byte-for-byte identical to original',
      );
      expect(
        await EditionService.isEditionDownloaded('warsh'),
        isTrue,
        reason: 'Edition must still be marked as downloaded in preferences',
      );

      // Verify temporary files are cleaned up and no leftover backup exists
      expect(await tmpFile.exists(), isFalse, reason: 'Temporary file must be deleted on failure');
      expect(await backupFile.exists(), isFalse, reason: 'Backup file must be restored/removed');
    });

    test('AUD-101: Successful edition replacement safely installs new edition and cleans up backup', () async {
      final initialData = {
        'code': 200,
        'status': 'OK',
        'data': {
          'surahs': [
            {
              'number': 1,
              'name': 'سُورَةُ ٱلْفَاتِحَةِ - الإصدار القديم',
              'englishName': 'Al-Faatiha Old',
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

      final updatedData = {
        'code': 200,
        'status': 'OK',
        'data': {
          'surahs': [
            {
              'number': 1,
              'name': 'سُورَةُ ٱلْفَاتِحَةِ - الإصدار الجديد',
              'englishName': 'Al-Faatiha New',
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

      final finalFile = File('${tempDir.path}/warsh.json');
      final tmpFile = File('${tempDir.path}/warsh.json.tmp');
      final backupFile = File('${tempDir.path}/warsh.json.bak');
      await finalFile.writeAsString(jsonEncode(initialData));

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(updatedData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      EditionService.setHttpClient(mockClient);

      final events = <DownloadProgress>[];
      await for (final progress in EditionService.downloadEdition('warsh')) {
        events.add(progress);
      }

      expect(events.isNotEmpty, isTrue);
      expect(events.last.isError, isFalse);
      expect(events.last.progress, equals(1.0));

      // Verify new content is written and old files are cleaned up
      expect(await finalFile.exists(), isTrue);
      expect(await finalFile.readAsString(), equals(jsonEncode(updatedData)));
      expect(await tmpFile.exists(), isFalse);
      expect(await backupFile.exists(), isFalse);
      expect(await EditionService.isEditionDownloaded('warsh'), isTrue);
    });

    test('AUD-101 Crash Recovery: loadSurahFromEdition recovers orphan backup if primary file is missing', () async {
      final seedData = {
        'code': 200,
        'status': 'OK',
        'data': {
          'surahs': [
            {
              'number': 1,
              'name': 'سُورَةُ ٱلْفَاتِحَةِ - نسخة مسترجعة',
              'englishName': 'Al-Faatiha Recovered',
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

      final finalFile = File('${tempDir.path}/warsh.json');
      final backupFile = File('${tempDir.path}/warsh.json.bak');

      // Simulate power loss / termination midway through replacement:
      // Primary file does not exist, but backup file exists
      await backupFile.writeAsString(jsonEncode(seedData));
      expect(await finalFile.exists(), isFalse);
      expect(await backupFile.exists(), isTrue);

      // Attempt to load surah from edition
      final surah = await EditionService.loadSurahFromEdition('warsh', 1);

      expect(surah, isNotNull);
      expect(surah!.name, contains('نسخة مسترجعة'));

      // Verify that primary file was restored from backup
      expect(await finalFile.exists(), isTrue);
      expect(await backupFile.exists(), isFalse);
    });

    test('AUD-101 Rollback Resilience: rollback failure is explicitly surfaced and backup remains accessible', () async {
      final seedData = {
        'code': 200,
        'status': 'OK',
        'data': {
          'surahs': [
            {
              'number': 1,
              'name': 'سُورَةُ ٱلْفَاتِحَةِ - النسخة الموثوقة',
              'englishName': 'Al-Faatiha Protected',
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

      final replacementData = {
        'code': 200,
        'status': 'OK',
        'data': {
          'surahs': [
            {
              'number': 1,
              'name': 'سُورَةُ ٱلْفَاتِحَةِ - نسخة جديدة فاشلة',
              'englishName': 'Al-Faatiha Broken',
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

      final finalFile = File('${tempDir.path}/warsh.json');
      final backupFile = File('${tempDir.path}/warsh.json.bak');
      await finalFile.writeAsString(jsonEncode(seedData));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('downloaded_editions', ['warsh']);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(replacementData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      EditionService.setHttpClient(mockClient);

      // 1. Simulate install failure
      EditionService.testFileInstaller = (src, dst) async {
        throw const FileSystemException('Simulated install failure');
      };

      // 2. Simulate rollback restoration failure
      EditionService.testFileRestorer = (bak, dst) async {
        throw const FileSystemException('Simulated rollback restoration failure');
      };

      final events = <DownloadProgress>[];
      await for (final progress in EditionService.downloadEdition('warsh')) {
        events.add(progress);
      }

      expect(events.isNotEmpty, isTrue);
      expect(events.last.isError, isTrue);

      // Verify that rollback failure was NOT silently swallowed
      expect(
        events.last.status,
        contains('Rollback error'),
        reason: 'Rollback failure must be explicitly surfaced in error status, not silently caught',
      );

      // Verify backup file was NOT deleted or lost
      expect(await backupFile.exists(), isTrue, reason: 'Backup file must remain preserved');

      // Verify emergency fallback: loadSurahFromEdition can still read the preserved edition from backup!
      final surah = await EditionService.loadSurahFromEdition('warsh', 1);
      expect(surah, isNotNull, reason: 'Reader must fall back to readable backup if primary is un-restorable');
      expect(surah!.name, contains('النسخة الموثوقة'));
    });
  });
}
