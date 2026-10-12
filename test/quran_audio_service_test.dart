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
  });
}
