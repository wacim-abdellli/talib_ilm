import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranAudioService Tests', () {
    final service = QuranAudioService();

    test('reciters list contains 5 official reciters', () {
      expect(QuranAudioService.reciters.length, 5);
      expect(service.selectedReciter.id, 'alafasy');
    });

    test('getAudioUrl formats surah and ayah with 3 digits padding', () {
      final url = service.getAudioUrl(1, 1);
      expect(url, 'https://everyayah.com/data/Alafasy_128kbps/001001.mp3');

      final urlBaqarah = service.getAudioUrl(2, 255);
      expect(urlBaqarah, 'https://everyayah.com/data/Alafasy_128kbps/002255.mp3');
    });

    test('reciter selection updates URL', () {
      final husary = QuranAudioService.reciters.firstWhere((r) => r.id == 'husary');
      service.setSelectedReciter(husary);
      expect(service.selectedReciter.id, 'husary');
      expect(service.getAudioUrl(1, 1), contains('Husary_128kbps/001001.mp3'));

      // Restore default
      service.setSelectedReciter(QuranAudioService.reciters[0]);
    });

    test('playback speed can be updated via notifier', () async {
      await service.setPlaybackSpeed(1.25);
      expect(service.speedNotifier.value, 1.25);

      await service.setPlaybackSpeed(1.0);
      expect(service.speedNotifier.value, 1.0);
    });

    test('repeat mode updates correctly', () {
      service.setRepeatMode(AudioRepeatMode.singleAyah);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.singleAyah);

      service.setRepeatMode(AudioRepeatMode.surah);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.surah);

      service.setRepeatMode(AudioRepeatMode.none);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.none);
    });

    test('classifyError distinguishes network failure from missing file', () {
      final netErr = QuranAudioService.classifyError('SocketException: Failed host lookup');
      expect(netErr.type, AudioPlaybackErrorType.network);
      expect(netErr.message, contains('يرجى التحقق من الاتصال بالإنترنت'));

      final notFoundErr = QuranAudioService.classifyError('HTTP 404: Not Found');
      expect(notFoundErr.type, AudioPlaybackErrorType.sourceNotFound);
      expect(notFoundErr.message, contains('ملف التلاوة غير متوفر'));

      final unknownErr = QuranAudioService.classifyError('CodecException: Invalid sample format');
      expect(unknownErr.type, AudioPlaybackErrorType.unknown);
      expect(unknownErr.message, contains('تعذر تشغيل التلاوة'));
    });

    test('errorNotifier clears on stop and returns player to idle state', () async {
      service.errorNotifier.value = const AudioPlaybackError(
        type: AudioPlaybackErrorType.network,
        message: 'تعذر تشغيل التلاوة. يرجى التحقق من الاتصال بالإنترنت',
      );
      service.activeSurahNotifier.value = 1;
      service.activeAyahNotifier.value = 1;

      expect(service.errorNotifier.value, isNotNull);

      await service.stop();

      expect(service.errorNotifier.value, isNull);
      expect(service.activeSurahNotifier.value, isNull);
      expect(service.activeAyahNotifier.value, isNull);
      expect(service.isPlayingNotifier.value, isFalse);
    });
  });
}
