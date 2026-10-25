import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_downloader.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('talib_audio_test_');
    QuranAudioDownloader.testBaseDir = tempDir;
  });

  tearDown(() async {
    QuranAudioDownloader.testBaseDir = null;
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('SurahDownloadProgress State Tests', () {
    test('calculates correct progress fraction and state flags', () {
      const p1 = SurahDownloadProgress(
        surah: 1,
        reciterId: 'alafasy',
        downloadedAyahs: 3,
        totalAyahs: 7,
        downloadedBytes: 300000,
        status: SurahDownloadStatus.downloading,
      );

      expect(p1.progressFraction, closeTo(3 / 7, 0.001));
      expect(p1.isDownloading, isTrue);
      expect(p1.isCompleted, isFalse);
      expect(p1.isPaused, isFalse);

      const p2 = SurahDownloadProgress(
        surah: 1,
        reciterId: 'alafasy',
        downloadedAyahs: 7,
        totalAyahs: 7,
        downloadedBytes: 700000,
        status: SurahDownloadStatus.completed,
      );

      expect(p2.progressFraction, equals(1.0));
      expect(p2.isCompleted, isTrue);
      expect(p2.isDownloading, isFalse);
    });

    test('estimateSurahSizeMb adjusts with bitrate and verse count', () {
      final alafasy = QuranAudioService.reciters.firstWhere((r) => r.id == 'alafasy'); // 128 kbps
      final ghamadi = QuranAudioService.reciters.firstWhere((r) => r.id == 'ghamadi'); // 40 kbps

      final alafasyFatihah = QuranAudioDownloader.estimateSurahSizeMb(1, reciter: alafasy);
      final ghamadiFatihah = QuranAudioDownloader.estimateSurahSizeMb(1, reciter: ghamadi);

      expect(alafasyFatihah, greaterThan(ghamadiFatihah));
      expect(alafasyFatihah, greaterThan(0.5));
    });

    test('formatBytes converts bytes into Arabic storage labels', () {
      expect(QuranAudioDownloader.formatBytes(0), equals('0 ب'));
      expect(QuranAudioDownloader.formatBytes(512), equals('512.0 ب'));
      expect(QuranAudioDownloader.formatBytes(1024 * 1024), equals('1.0 م.ب'));
    });
  });

  group('QuranAudioDownloader Operations Tests', () {
    test('downloadSurah downloads all ayahs and sets status completed', () async {
      final downloader = QuranAudioDownloader();

      // Mock client that returns 100 bytes of dummy mp3 data for each request
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          List.filled(100, 42),
          200,
          headers: {'content-type': 'audio/mpeg'},
        );
      });

      // Download Surah Al-Fatihah (7 ayahs)
      await downloader.downloadSurah(
        surah: 1,
        client: mockClient,
      );

      final isDownloaded = await QuranAudioDownloader.isSurahDownloaded(1);
      expect(isDownloaded, isTrue);

      final bytes = await QuranAudioDownloader.getSurahDownloadedBytes(1);
      expect(bytes, equals(700)); // 7 ayahs * 100 bytes

      final totalStorage = await QuranAudioDownloader.getTotalStorageUsed();
      expect(totalStorage, equals(700));
    });

    test('deleteSurahAudio removes only targeted surah and updates storage', () async {
      final downloader = QuranAudioDownloader();

      final mockClient = MockClient((request) async {
        return http.Response.bytes(List.filled(50, 1), 200);
      });

      // Download Surah 108 (Al-Kawthar, 3 ayahs) and 112 (Al-Ikhlas, 4 ayahs)
      await downloader.downloadSurah(surah: 108, client: mockClient);
      await downloader.downloadSurah(surah: 112, client: mockClient);

      expect(await QuranAudioDownloader.isSurahDownloaded(108), isTrue);
      expect(await QuranAudioDownloader.isSurahDownloaded(112), isTrue);

      // Delete 108
      await QuranAudioDownloader.deleteSurahAudio(108);

      expect(await QuranAudioDownloader.isSurahDownloaded(108), isFalse);
      expect(await QuranAudioDownloader.isSurahDownloaded(112), isTrue);
    });

    test('deleteAllDownloadedAudio removes all files', () async {
      final downloader = QuranAudioDownloader();
      final mockClient = MockClient((request) async {
        return http.Response.bytes(List.filled(50, 1), 200);
      });

      await downloader.downloadSurah(surah: 108, client: mockClient);
      expect(await QuranAudioDownloader.getTotalStorageUsed(), greaterThan(0));

      await QuranAudioDownloader.deleteAllDownloadedAudio();
      expect(await QuranAudioDownloader.getTotalStorageUsed(), equals(0));
    });

    test('cancelDownload stops download, cleans up temp files, and leaves status idle without raw exception', () async {
      final downloader = QuranAudioDownloader();
      final reciter = QuranAudioService().selectedReciter;
      final key = '${reciter.id}_108';

      // Mock client that simulates active cancellation during stream
      final mockClient = MockClient((request) async {
        // Trigger cancellation on ayah 2
        if (request.url.path.contains('108002')) {
          downloader.cancelDownload(108);
          throw http.ClientException('Connection closed while receiving data', request.url);
        }
        return http.Response.bytes(List.filled(50, 1), 200);
      });

      await downloader.downloadSurah(surah: 108, client: mockClient);

      // Verify progress was reset to idle and not failed
      final progress = downloader.downloadProgressNotifier.value[key];
      expect(progress?.status, isNot(equals(SurahDownloadStatus.failed)));
      expect(progress?.errorMessage, isNull);

      // Verify no leftover .tmp files
      final dir = await QuranAudioDownloader.getSurahDir(108, reciter.id);
      if (dir.existsSync()) {
        final tmpFiles = dir.listSync().where((f) => f.path.endsWith('.tmp'));
        expect(tmpFiles, isEmpty);
      }
    });

    test('network failure generates clean localized Arabic error message instead of raw ClientException', () async {
      final downloader = QuranAudioDownloader();
      final reciter = QuranAudioService().selectedReciter;
      final key = '${reciter.id}_112';

      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection closed while receiving data', request.url);
      });

      await downloader.downloadSurah(surah: 112, client: mockClient);

      final progress = downloader.downloadProgressNotifier.value[key];
      expect(progress?.status, equals(SurahDownloadStatus.failed));
      expect(progress?.errorMessage, equals('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت'));
      expect(progress?.errorMessage?.contains('ClientException'), isFalse);
    });

    test('pauseDownload sets status paused and allows subsequent resume to complete', () async {
      final downloader = QuranAudioDownloader();
      final reciter = QuranAudioService().selectedReciter;
      final key = '${reciter.id}_110';

      // Mock client that pauses on ayah 2
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('110002')) {
          downloader.pauseDownload(110);
        }
        return http.Response.bytes(List.filled(50, 1), 200);
      });

      await downloader.downloadSurah(surah: 110, client: mockClient);

      final pausedProgress = downloader.downloadProgressNotifier.value[key];
      expect(pausedProgress?.status, equals(SurahDownloadStatus.paused));
      expect(pausedProgress?.isPaused, isTrue);

      // Resume with normal client
      final resumeClient = MockClient((request) async {
        return http.Response.bytes(List.filled(50, 1), 200);
      });

      await downloader.downloadSurah(surah: 110, client: resumeClient);

      final completedProgress = downloader.downloadProgressNotifier.value[key];
      expect(completedProgress?.status, equals(SurahDownloadStatus.completed));
      expect(await QuranAudioDownloader.isSurahDownloaded(110), isTrue);
    });
  });

  group('Audio Source Resolution (Offline Local File vs Online Stream)', () {
    test('getAudioSource selects local UriAudioSource if file exists on disk', () async {
      final audioService = QuranAudioService();
      final reciter = audioService.selectedReciter;

      // Create a dummy local file for Surah 1 Ayah 1
      final localPath = await QuranAudioDownloader.getLocalAyahPath(1, 1, reciter: reciter);
      final file = File(localPath);
      await file.create(recursive: true);
      await file.writeAsBytes(List.filled(256, 9));

      final source = await audioService.getAudioSource(1, 1, reciter: reciter);

      // Verify that a UriAudioSource pointing to file: URI is created
      expect(source, isA<UriAudioSource>());
      final uriSource = source as UriAudioSource;
      expect(uriSource.uri.isScheme('file'), isTrue);
      expect(uriSource.uri.toFilePath().replaceAll('\\', '/'), equals(file.path.replaceAll('\\', '/')));
    });

    test('getAudioSource falls back to remote https stream when local file does not exist', () async {
      final audioService = QuranAudioService();
      final reciter = audioService.selectedReciter;

      // Surah 114 Ayah 1 has no local file
      final source = await audioService.getAudioSource(114, 1, reciter: reciter);

      expect(source, isA<UriAudioSource>());
      final uriSource = source as UriAudioSource;
      expect(uriSource.uri.isScheme('https'), isTrue);
      expect(uriSource.uri.toString(), contains('everyayah.com'));
      expect(uriSource.uri.toString(), contains('114001.mp3'));
    });
  });

  group('QuranAudioDownloader Robustness & Error Remediation (T07)', () {
    test('joins duplicate concurrent calls without redundant work (C14)', () async {
      final downloader = QuranAudioDownloader();
      downloader.resetStateForTesting();

      int networkRequests = 0;
      final mockClient = MockClient((request) async {
        networkRequests++;
        return http.Response.bytes(
          List.filled(64, 42),
          200,
          headers: {'content-type': 'audio/mpeg'},
        );
      });

      // Launch 2 simultaneous downloads of Surah 112 (4 ayahs)
      await Future.wait([
        downloader.downloadSurah(surah: 112, client: mockClient),
        downloader.downloadSurah(surah: 112, client: mockClient),
      ]);

      // Exactly 4 requests should have been dispatched (not 8)
      expect(networkRequests, equals(4));
      expect(await QuranAudioDownloader.isSurahDownloaded(112), isTrue);
    });

    test('rejects 200 OK with text/html content-type and leaves status failed without corrupted mp3 (C15)', () async {
      final downloader = QuranAudioDownloader();
      downloader.resetStateForTesting();
      final reciter = QuranAudioService().selectedReciter;
      final key = '${reciter.id}_114';

      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><head><title>Login</title></head><body>Redirecting</body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      await downloader.downloadSurah(surah: 114, client: mockClient);

      final progress = downloader.downloadProgressNotifier.value[key];
      expect(progress?.status, equals(SurahDownloadStatus.failed));
      expect(progress?.errorMessage, contains('غير صالحة'));

      // Ensure no corrupt mp3 was promoted
      final isDownloaded = await QuranAudioDownloader.isSurahDownloaded(114);
      expect(isDownloaded, isFalse);

      final surahDir = await QuranAudioDownloader.getSurahDir(114, reciter.id);
      final mp3Files = surahDir.existsSync()
          ? surahDir.listSync().where((f) => f.path.endsWith('.mp3'))
          : <FileSystemEntity>[];
      expect(mp3Files, isEmpty);
    });

    test('rejects zero-byte response body and does not promote empty file (C15)', () async {
      final downloader = QuranAudioDownloader();
      downloader.resetStateForTesting();
      final reciter = QuranAudioService().selectedReciter;
      final key = '${reciter.id}_113';

      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          <int>[],
          200,
          headers: {'content-type': 'audio/mpeg'},
        );
      });

      await downloader.downloadSurah(surah: 113, client: mockClient);

      final progress = downloader.downloadProgressNotifier.value[key];
      expect(progress?.status, equals(SurahDownloadStatus.failed));
      expect(progress?.errorMessage, contains('فارغ'));
      expect(await QuranAudioDownloader.isSurahDownloaded(113), isFalse);
    });

    test('rejects truncated response when Content-Length does not match streamed bytes (C15)', () async {
      final downloader = QuranAudioDownloader();
      downloader.resetStateForTesting();
      final reciter = QuranAudioService().selectedReciter;
      final key = '${reciter.id}_113';

      final mockClient = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.value(List.filled(50, 99)),
          200,
          contentLength: 1000,
          headers: {'content-type': 'audio/mpeg'},
        );
      });

      await downloader.downloadSurah(surah: 113, client: mockClient);

      final progress = downloader.downloadProgressNotifier.value[key];
      expect(progress?.status, equals(SurahDownloadStatus.failed));
      expect(progress?.errorMessage, contains('مبتور'));
      expect(await QuranAudioDownloader.isSurahDownloaded(113), isFalse);
    });

    test('isSurahDownloaded rejects corrupted files (< 32 bytes or HTML markup) and cleans them on resume (C15)', () async {
      final downloader = QuranAudioDownloader();
      downloader.resetStateForTesting();
      final reciter = QuranAudioService().selectedReciter;

      // Corrupt Surah 114 Ayah 1 by writing an HTML error page
      final surahDir = await QuranAudioDownloader.getSurahDir(114, reciter.id);
      final corruptFile = File('${surahDir.path}/114001.mp3');
      await corruptFile.create(recursive: true);
      await corruptFile.writeAsString('<!DOCTYPE html><html><body>Error</body></html>');

      // isSurahDownloaded must reject this
      expect(await QuranAudioDownloader.isSurahDownloaded(114), isFalse);

      // Now run download with valid client; it should clean and replace the corrupt file
      final validClient = MockClient((request) async {
        return http.Response.bytes(
          List.filled(80, 20),
          200,
          headers: {'content-type': 'audio/mpeg'},
        );
      });

      await downloader.downloadSurah(surah: 114, client: validClient);

      expect(await QuranAudioDownloader.isSurahDownloaded(114), isTrue);
      // Validated file must no longer contain the html markup
      final firstByte = (await File('${surahDir.path}/114001.mp3').readAsBytes())[0];
      expect(firstByte, equals(20));
    });

    test('caller-injected client is not closed by downloader (C16)', () async {
      final downloader = QuranAudioDownloader();
      downloader.resetStateForTesting();

      final client = MockClient((request) async {
        return http.Response.bytes(
          List.filled(64, 15),
          200,
          headers: {'content-type': 'audio/mpeg'},
        );
      });

      await downloader.downloadSurah(surah: 112, client: client);

      // Injected client should still be able to make requests after download finishes
      final probeResponse = await client.get(Uri.parse('https://example.com'));
      expect(probeResponse.statusCode, equals(200));
    });
  });
}
