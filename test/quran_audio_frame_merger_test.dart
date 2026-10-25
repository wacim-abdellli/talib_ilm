import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_downloader.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_frame_merger.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quran_audio_test_');
    QuranAudioDownloader.testBaseDir = tempDir;
  });

  tearDown(() async {
    QuranAudioDownloader.testBaseDir = null;
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('QuranAudioFrameMerger Tests', () {
    test('stripId3Tags leaves pure audio data unchanged', () {
      final pureAudio = Uint8List.fromList([0xFF, 0xFB, 0x90, 0x64, 0x01, 0x02, 0x03]);
      final result = QuranAudioFrameMerger.stripId3Tags(pureAudio);
      expect(result, pureAudio);
    });

    test('stripId3Tags removes ID3v2 header from beginning', () {
      // ID3v2.3 header: 'ID3', version 3.0, flags 0, synchsafe size 10 (total 10 header + 10 tag = 20 bytes)
      final header = Uint8List.fromList([
        0x49, 0x44, 0x33, // 'ID3'
        0x03, 0x00, // version 2.3
        0x00, // flags
        0x00, 0x00, 0x00, 0x0A, // size = 10 synchsafe
        // 10 bytes of ID3 payload
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      ]);
      final audioPayload = Uint8List.fromList([0xFF, 0xFB, 0x90, 0x64, 11, 12, 13]);
      final fullBytes = Uint8List.fromList([...header, ...audioPayload]);

      final stripped = QuranAudioFrameMerger.stripId3Tags(fullBytes);
      expect(stripped, audioPayload);
    });

    test('stripId3Tags removes ID3v1 trailer from end', () {
      final audioPayload = Uint8List.fromList([0xFF, 0xFB, 0x90, 0x64, 21, 22, 23]);
      // ID3v1: 128 bytes starting with 'TAG'
      final id3v1 = Uint8List(128);
      id3v1[0] = 0x54; // 'T'
      id3v1[1] = 0x41; // 'A'
      id3v1[2] = 0x47; // 'G'

      final fullBytes = Uint8List.fromList([...audioPayload, ...id3v1]);
      final stripped = QuranAudioFrameMerger.stripId3Tags(fullBytes);
      expect(stripped, audioPayload);
    });

    test('stripId3Tags removes encoder Xing and Info header frames', () {
      // Mock Info frame: starts with MP3 sync, contains 'Info' at offset 36, followed by sync at 100
      final infoFrame = Uint8List(100);
      infoFrame[0] = 0xFF;
      infoFrame[1] = 0xFA;
      infoFrame[36] = 0x49; // 'I'
      infoFrame[37] = 0x6E; // 'n'
      infoFrame[38] = 0x66; // 'f'
      infoFrame[39] = 0x6F; // 'o'

      final audioFrame = Uint8List.fromList([0xFF, 0xFB, 0x90, 0x64, 99, 100, 101]);
      final fullBytes = Uint8List.fromList([...infoFrame, ...audioFrame]);

      final stripped = QuranAudioFrameMerger.stripId3Tags(fullBytes);
      expect(stripped, audioFrame);
    });

    test('isFullSurahFileHealthy detects legacy poisoned files containing Info tag', () async {
      final healthyFile = File('${tempDir.path}/healthy.mp3');
      final healthyBytes = Uint8List(2000);
      healthyBytes.fillRange(0, 2000, 0xAA);
      healthyBytes[0] = 0xFF;
      healthyBytes[1] = 0xFB;
      await healthyFile.writeAsBytes(healthyBytes);

      expect(QuranAudioFrameMerger.isFullSurahFileHealthy(healthyFile, 1), isTrue);

      final poisonedFile = File('${tempDir.path}/poisoned.mp3');
      final poisonedBytes = Uint8List(2000);
      poisonedBytes[0] = 0xFF;
      poisonedBytes[1] = 0xFA;
      poisonedBytes[36] = 0x49; // 'I'
      poisonedBytes[37] = 0x6E; // 'n'
      poisonedBytes[38] = 0x66; // 'f'
      poisonedBytes[39] = 0x6F; // 'o'
      await poisonedFile.writeAsBytes(poisonedBytes);

      expect(QuranAudioFrameMerger.isFullSurahFileHealthy(poisonedFile, 1), isFalse);
    });

    test('assembleFullSurahAudio concatenates verses into single full_surah.mp3', () async {
      final reciter = QuranAudioService.reciters.first;
      // Surah Al-Fatihah (7 verses)
      final surahDir = await QuranAudioDownloader.getSurahDir(1, reciter.id);

      // Create 7 mock valid audio files (> 32 bytes, non-markup)
      for (int a = 1; a <= 7; a++) {
        final aStr = a.toString().padLeft(3, '0');
        final file = File('${surahDir.path}/001$aStr.mp3');
        final content = Uint8List(200);
        content.fillRange(0, 200, a);
        content[0] = 0xFF;
        content[1] = 0xFB; // valid MP3 sync header
        await file.writeAsBytes(content);
      }

      final isDownloaded = await QuranAudioDownloader.isSurahDownloaded(1, reciter: reciter);
      expect(isDownloaded, isTrue);

      final fullFile = await QuranAudioFrameMerger.assembleFullSurahAudio(1, reciter: reciter);
      expect(fullFile, isNotNull);
      expect(fullFile!.existsSync(), isTrue);
      expect(fullFile.path.endsWith('full_surah.mp3'), isTrue);
      // Total size should be 7 * 200 = 1400 bytes
      expect(fullFile.lengthSync(), 1400);

      // Subsequent call should return existing cached file directly
      final cached = await QuranAudioFrameMerger.getFullSurahAudioFile(1, reciter: reciter);
      expect(cached?.path, fullFile.path);
    });
  });

  group('QuranAudioService Full Surah Mode & Streams', () {
    test('isFullSurahModeNotifier tracks full surah state', () {
      final service = QuranAudioService();
      expect(service.isFullSurahMode, isFalse);
      service.isFullSurahModeNotifier.value = true;
      expect(service.isFullSurahMode, isTrue);
      service.isFullSurahModeNotifier.value = false;
      expect(service.isFullSurahMode, isFalse);
    });

    test('reciters list exposes 10 default reciters with minshawi', () {
      expect(QuranAudioService.reciters.length, 10);
      expect(QuranAudioService.reciters.any((r) => r.id == 'minshawi'), isTrue);
    });
  });
}
