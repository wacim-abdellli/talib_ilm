import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:talib_ilm/features/quran/data/services/quran_audio_downloader.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final testReciter = QuranReciter.defaultReciters.first; // alafasy

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quran_audio_harden_test_');
    QuranAudioDownloader.testBaseDir = tempDir;
    QuranAudioDownloader().resetStateForTesting();
  });

  tearDown(() async {
    QuranAudioDownloader.resetHttpClient();
    QuranAudioDownloader().resetStateForTesting();
    QuranAudioDownloader.testBaseDir = null;
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('QuranAudioService Input Validation & URL Bounds (R86)', () {
    test('isValidSurah accurately validates 1..114 boundaries', () {
      expect(QuranAudioService.isValidSurah(1), isTrue);
      expect(QuranAudioService.isValidSurah(114), isTrue);
      expect(QuranAudioService.isValidSurah(0), isFalse);
      expect(QuranAudioService.isValidSurah(115), isFalse);
      expect(QuranAudioService.isValidSurah(-1), isFalse);
    });

    test('isValidVerse bounds ayahs to canonical counts per chapter', () {
      expect(QuranAudioService.isValidVerse(1, 1), isTrue);
      expect(QuranAudioService.isValidVerse(1, 7), isTrue);
      expect(QuranAudioService.isValidVerse(1, 8), isFalse);

      expect(QuranAudioService.isValidVerse(2, 286), isTrue);
      expect(QuranAudioService.isValidVerse(2, 287), isFalse);
      expect(QuranAudioService.isValidVerse(114, 6), isTrue);
      expect(QuranAudioService.isValidVerse(114, 7), isFalse);
    });

    test('getAudioUrl rejects out-of-bounds surah or ayah with ArgumentError', () {
      final service = QuranAudioService();
      expect(() => service.getAudioUrl(0, 1), throwsArgumentError);
      expect(() => service.getAudioUrl(115, 1), throwsArgumentError);
      expect(() => service.getAudioUrl(1, 8), throwsArgumentError);
      expect(() => service.getAudioUrl(1, 0), throwsArgumentError);

      final validUrl = service.getAudioUrl(1, 1);
      expect(validUrl, 'https://everyayah.com/data/Alafasy_128kbps/001001.mp3');
    });

    test('playVerse and playContinuous reject invalid inputs safely without mutating state', () async {
      final service = QuranAudioService();
      await service.stop();

      await service.playVerse(0, 1);
      expect(service.activeSurahNotifier.value, isNull);

      await service.playVerse(1, 99);
      expect(service.activeSurahNotifier.value, isNull);

      await service.playContinuous(surah: 115, startAyah: 1);
      expect(service.activeSurahNotifier.value, isNull);
    });
  });

  group('QuranAudioDownloader Hardening & Network Seams (R86)', () {
    test('rejects out-of-bounds surah without network dispatch', () async {
      int networkDispatches = 0;
      final mockClient = _MockHttpClient((req) async {
        networkDispatches++;
        return http.StreamedResponse(const Stream.empty(), 200);
      });

      QuranAudioDownloader.setHttpClient(mockClient);

      await QuranAudioDownloader().downloadSurah(
        surah: 115,
        reciter: testReciter,
      );

      final key = '${testReciter.id}_115';
      final prog = QuranAudioDownloader().downloadProgressNotifier.value[key];
      expect(prog, isNotNull);
      expect(prog!.status, SurahDownloadStatus.failed);
      expect(prog.errorMessage, contains('رقم السورة غير صالح'));
      expect(networkDispatches, 0);
    });

    test('rejects text/html content-type and deletes temp file', () async {
      final mockClient = _MockHttpClient((req) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('<html><body>Error</body></html>')),
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      QuranAudioDownloader.setHttpClient(mockClient);

      await QuranAudioDownloader().downloadSurah(
        surah: 114,
        reciter: testReciter,
      );

      final key = '${testReciter.id}_114';
      final prog = QuranAudioDownloader().downloadProgressNotifier.value[key];
      expect(prog, isNotNull);
      expect(prog!.status, SurahDownloadStatus.failed);
      expect(prog.errorMessage, contains('HTML/Text'));

      // Verify no stray temp files left behind
      final surahDir = await QuranAudioStorage.getSurahDir(114, testReciter.id);
      final tmps = surahDir.listSync().where((f) => f.path.endsWith('.tmp'));
      expect(tmps.isEmpty, isTrue);
    });

    test('cancels stream early when payload exceeds maxAyahAudioBytes ceiling', () async {
      bool streamCancelled = false;
      final controller = StreamController<List<int>>();

      // Emit chunk then listen to cancel
      controller.onListen = () {
        // Send a 1 MB chunk first
        controller.add(Uint8List(1024 * 1024));
        // Then send oversized chunk exceeding 25 MB limit
        controller.add(Uint8List(26 * 1024 * 1024));
      };
      controller.onCancel = () {
        streamCancelled = true;
      };

      final mockClient = _MockHttpClient((req) async {
        return http.StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'audio/mpeg'},
        );
      });

      QuranAudioDownloader.setHttpClient(mockClient);

      await QuranAudioDownloader().downloadSurah(
        surah: 114,
        reciter: testReciter,
      );

      final key = '${testReciter.id}_114';
      final prog = QuranAudioDownloader().downloadProgressNotifier.value[key];
      expect(prog, isNotNull);
      expect(prog!.status, SurahDownloadStatus.failed);
      expect(prog.errorMessage, contains('يتجاوز الحد المسموح به'));
      expect(streamCancelled, isTrue);

      // Verify no stray temp files
      final surahDir = await QuranAudioStorage.getSurahDir(114, testReciter.id);
      final tmps = surahDir.listSync().where((f) => f.path.endsWith('.tmp'));
      expect(tmps.isEmpty, isTrue);
    });

    test('successful download writes atomically and updates progress to completed', () async {
      // Build valid dummy MP3 frame (at least 32 bytes, not starting with HTML/JSON)
      final validMp3Bytes = Uint8List(128);
      validMp3Bytes[0] = 0xFF; // MP3 sync word
      validMp3Bytes[1] = 0xFB;

      final mockClient = _MockHttpClient((req) async {
        return http.StreamedResponse(
          Stream.value(validMp3Bytes),
          200,
          contentLength: validMp3Bytes.length,
          headers: {'content-type': 'audio/mpeg'},
        );
      });

      QuranAudioDownloader.setHttpClient(mockClient);

      // Surah Al-Kawthar (108) has 3 verses
      await QuranAudioDownloader().downloadSurah(
        surah: 108,
        reciter: testReciter,
      );

      final key = '${testReciter.id}_108';
      final prog = QuranAudioDownloader().downloadProgressNotifier.value[key];
      expect(prog, isNotNull);
      expect(prog!.status, SurahDownloadStatus.completed);
      expect(prog.downloadedAyahs, 3);
      expect(prog.totalAyahs, 3);

      final isDownloaded = await QuranAudioStorage.isSurahDownloaded(
        108,
        reciter: testReciter,
      );
      expect(isDownloaded, isTrue);

      // Clean deletion
      await QuranAudioStorage.deleteSurahAudio(108, reciter: testReciter);
      final isStillDownloaded = await QuranAudioStorage.isSurahDownloaded(
        108,
        reciter: testReciter,
      );
      expect(isStillDownloaded, isFalse);
    });

    test('Muhammad Al-Luhaidan and expanded reciters are available with surah-based capabilities', () async {
      final reciters = QuranReciter.defaultReciters;
      expect(reciters.length, greaterThanOrEqualTo(30));

      final luhaidan = reciters.firstWhere((r) => r.id == 'luhaidan');
      expect(luhaidan.name, 'محمد اللحيدان');
      expect(luhaidan.isSurahBased, isTrue);
      expect(luhaidan.surahBaseUrl, contains('muhammad-luhaidan'));

      // Value equality
      final luhaidanClone = const QuranReciter(
        id: 'luhaidan',
        name: 'محمد اللحيدان',
      );
      expect(luhaidan, equals(luhaidanClone));

      // Audio URL construction
      final service = QuranAudioService();
      final url = service.getAudioUrl(1, 1, reciter: luhaidan);
      expect(url, equals('https://cdn.mp3quran.net/audio/muhammad-luhaidan/r1/001.mp3'));

      // Direct surah-based mock download
      final dummyMp3Bytes = Uint8List.fromList(List<int>.filled(2048, 0xFF));
      QuranAudioDownloader.setHttpClient(
        _MockHttpClient((request) async {
          return http.StreamedResponse(
            Stream.value(dummyMp3Bytes),
            200,
            contentLength: dummyMp3Bytes.length,
            headers: {'content-type': 'audio/mpeg'},
          );
        }),
      );

      final downloader = QuranAudioDownloader();
      await downloader.downloadSurah(surah: 1, reciter: luhaidan);

      final isDownloaded = await QuranAudioStorage.isSurahDownloaded(1, reciter: luhaidan);
      expect(isDownloaded, isTrue);

      final bytes = await QuranAudioStorage.getSurahDownloadedBytes(1, reciter: luhaidan);
      expect(bytes, equals(dummyMp3Bytes.length));

      // Clean deletion
      await QuranAudioStorage.deleteSurahAudio(1, reciter: luhaidan);
      final isStillDownloaded = await QuranAudioStorage.isSurahDownloaded(1, reciter: luhaidan);
      expect(isStillDownloaded, isFalse);
    });
  });
}

class _MockHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest) _handler;
  _MockHttpClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _handler(request);
}
