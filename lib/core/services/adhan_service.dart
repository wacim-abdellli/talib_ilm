import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../app/constants/app_assets.dart';
import '../../features/quran/data/services/quran_audio_service.dart';
import '../../features/radio/data/services/quran_radio_service.dart';
import 'adhan_settings_service.dart';

export 'package:just_audio/just_audio.dart' show PlayerState;

class AdhanService {
  final AudioPlayer _player;

  AdhanService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  bool get isPlaying => _player.playing;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Play adhan or takbeer with volume control and MediaItem tag for background audio
  Future<void> play(AdhanSound sound, {double volume = 80.0}) async {
    try {
      // Pause Quran recitation and radio to prevent audio collision
      try {
        QuranAudioService().pause();
        QuranRadioService().pause();
      } catch (_) {}

      final assetPath = _assetFor(sound);
      final title = _titleFor(sound);

      // Create AudioSource with required MediaItem tag for just_audio_background
      final source = AudioSource.asset(
        assetPath,
        tag: MediaItem(
          id: 'adhan_${sound.name}',
          album: 'أذان الصلاة',
          title: title,
          artist: 'المؤذن',
        ),
      );

      final normalizedVolume = (volume / 100).clamp(0.0, 1.0);

      await _player.stop();
      await _player.setAudioSource(source);
      await _player.setVolume(normalizedVolume);
      await _player.play();
    } catch (e) {
      debugPrint('AdhanService.play error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('AdhanService.stop error: $e');
    }
  }

  /// Test play with volume
  Future<void> test(AdhanSound sound, {double volume = 80.0}) async {
    await play(sound, volume: volume);
  }

  Future<void> preload() async {
    // Media sources are prepared on demand with MediaItem tags
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }

  String _assetFor(AdhanSound sound) {
    switch (sound) {
      case AdhanSound.makkah:
        return AppAssets.adhanMakkah;
      case AdhanSound.madinah:
        return AppAssets.adhanMadinah;
      case AdhanSound.takbeer:
        return AppAssets.adhanTakbeer;
    }
  }

  String _titleFor(AdhanSound sound) {
    switch (sound) {
      case AdhanSound.makkah:
        return 'أذان مكة المكرمة';
      case AdhanSound.madinah:
        return 'أذان المسجد النبوي الشريف';
      case AdhanSound.takbeer:
        return 'تكبيرات الأذان';
    }
  }
}
