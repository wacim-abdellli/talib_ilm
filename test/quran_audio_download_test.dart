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
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
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
}
