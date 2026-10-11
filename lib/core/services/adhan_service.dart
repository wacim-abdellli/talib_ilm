import 'package:just_audio/just_audio.dart';
import '../../app/constants/app_assets.dart';
import 'adhan_settings_service.dart';

export 'package:just_audio/just_audio.dart' show PlayerState;

class AdhanService {
  final AudioPlayer _player;
  AudioSource? _preloadedMakkah;
  AudioSource? _preloadedMadinah;
  bool _isPreloaded = false;

  AdhanService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  /// Preload adhan audio sources for instant playback
  Future<void> preload() async {
    if (_isPreloaded) return;
    try {
      _preloadedMakkah = AudioSource.asset(AppAssets.adhanMakkah);
      _preloadedMadinah = AudioSource.asset(AppAssets.adhanMadinah);
      _isPreloaded = true;
    } catch (e) {
      // Fallback: load on-demand
      _isPreloaded = false;
    }
  }

  bool get isPlaying => _player.playing;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Play adhan with volume control
  Future<void> play(AdhanSound sound, {double volume = 80.0}) async {
    try {
      await preload();
      final source = _sourceFor(sound);

      // Set volume (0.0 to 1.0)
      final normalizedVolume = (volume / 100).clamp(0.0, 1.0);

      await _player.stop();
      await _player.setAudioSource(source);
      await _player.setVolume(normalizedVolume);
      await _player.play();
    } catch (e) {
      // Fall back to direct asset play
      final asset = _assetFor(sound);
      await _player.stop();
      await _player.setAudioSource(AudioSource.asset(asset));
      await _player.setVolume((volume / 100).clamp(0.0, 1.0));
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  /// Test play with volume
  Future<void> test(AdhanSound sound, {double volume = 80.0}) async {
    await play(sound, volume: volume);
  }

  Future<void> dispose() async {
    _isPreloaded = false;
    _preloadedMakkah = null;
    _preloadedMadinah = null;
    await _player.dispose();
  }

  AudioSource _sourceFor(AdhanSound sound) {
    if (!_isPreloaded) {
      return AudioSource.asset(_assetFor(sound));
    }
    return sound == AdhanSound.makkah ? _preloadedMakkah! : _preloadedMadinah!;
  }

  String _assetFor(AdhanSound sound) {
    switch (sound) {
      case AdhanSound.makkah:
        return AppAssets.adhanMakkah;
      case AdhanSound.madinah:
        return AppAssets.adhanMadinah;
    }
  }
}
