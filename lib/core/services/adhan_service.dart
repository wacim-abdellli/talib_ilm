import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/constants/app_assets.dart';
import '../../features/quran/data/services/quran_audio_service.dart';
import '../../features/radio/data/services/quran_radio_service.dart';
import 'adhan_settings_service.dart';

export 'package:just_audio/just_audio.dart' show PlayerState;

class AdhanService {
  static final AdhanService _instance = AdhanService._internal();
  factory AdhanService({AudioPlayer? player}) {
    if (player != null) {
      return AdhanService._withPlayer(player);
    }
    return _instance;
  }
  AdhanService._internal() : _player = AudioPlayer();
  AdhanService._withPlayer(this._player);

  final AudioPlayer _player;

  bool get isPlaying => _player.playing;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get isPlayingStream => _player.playingStream;

  /// Play adhan, takbeer, or voice announcement with volume control.
  /// AudioSource is loaded directly without a MediaItem tag to guarantee it
  /// never appears as a music/media player notification.
  Future<void> play({
    AdhanSound sound = AdhanSound.qatami,
    PrayerNotificationMode mode = PrayerNotificationMode.adhan,
    double volume = 80.0,
    String? prayerName,
  }) async {
    try {
      // Pause Quran recitation and radio to prevent audio collision
      try {
        QuranAudioService().pause();
        QuranRadioService().pause();
      } catch (_) {}

      // Ensure Full Adhan mode strictly plays a full muezzin sound
      final effectiveSound =
          (mode == PrayerNotificationMode.adhan && sound == AdhanSound.takbeer)
              ? AdhanSound.qatami
              : sound;

      final assetPath =
          _assetFor(sound: effectiveSound, mode: mode, prayerName: prayerName);

      // Create pure AudioSource without MediaItem tag so just_audio_background
      // never publishes a MediaSession or transport controls.
      final source = AudioSource.asset(assetPath);

      final normalizedVolume = (volume / 100).clamp(0.0, 1.0);

      await _player.stop();
      await _player.setAudioSource(source);
      await _player.setVolume(normalizedVolume);
      await _player.play();
    } catch (e) {
      debugPrint('AdhanService.play error: $e');
    }
  }

  /// Sets audio player volume dynamically in real time
  Future<void> setVolume(double volume) async {
    final normalized = (volume / 100).clamp(0.0, 1.0);
    try {
      await _player.setVolume(normalized);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('AdhanService.stop error: $e');
    }
  }

  /// Test play with volume and optional prayer name and mode
  Future<void> test({
    AdhanSound sound = AdhanSound.qatami,
    PrayerNotificationMode mode = PrayerNotificationMode.adhan,
    double volume = 80.0,
    String? prayerName,
  }) async {
    await play(
      sound: sound,
      mode: mode,
      volume: volume,
      prayerName: prayerName,
    );
  }

  Future<void> preload() async {
    // Media sources are prepared on demand with MediaItem tags
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }

  String _assetFor({
    required AdhanSound sound,
    required PrayerNotificationMode mode,
    String? prayerName,
  }) {
    if (mode == PrayerNotificationMode.announcement) {
      return AppAssets.adhanAnnouncementFor(prayerName);
    }
    if (mode == PrayerNotificationMode.takbeer) {
      return AppAssets.adhanTakbeer;
    }

    // For Full Adhan mode, strictly ensure a full muezzin asset is used
    final effectiveSound =
        (sound == AdhanSound.takbeer) ? AdhanSound.qatami : sound;

    switch (effectiveSound) {
      case AdhanSound.makkah:
        return AppAssets.adhanMakkah;
      case AdhanSound.madinah:
        return AppAssets.adhanMadinah;
      case AdhanSound.alafasy:
        return AppAssets.adhanAlafasy;
      case AdhanSound.abdulbasit:
        return AppAssets.adhanAbdulbasit;
      case AdhanSound.qatami:
        return AppAssets.adhanQatami;
      case AdhanSound.aqsa:
        return AppAssets.adhanAqsa;
      case AdhanSound.takbeer:
        return AppAssets.adhanQatami;
    }
  }
}
