import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../app/constants/app_assets.dart';
import 'adhan_settings_service.dart';
import 'audio_coordinator.dart';

export 'package:just_audio/just_audio.dart' show PlayerState;

class AdhanService {
  static final AdhanService _instance = AdhanService._internal();
  factory AdhanService({AudioPlayer? player}) {
    if (player != null) {
      return AdhanService._withPlayer(player);
    }
    return _instance;
  }
  AdhanService._internal() : _player = AudioPlayer() {
    AudioCoordinator.onPauseAdhan = stop;
    _watchForCompletion();
  }
  AdhanService._withPlayer(this._player) {
    AudioCoordinator.onPauseAdhan = stop;
    _watchForCompletion();
  }

  AudioPlayer _player;
  StreamSubscription<PlayerState>? _completionSubscription;

  void _watchForCompletion() {
    final previous = _completionSubscription;
    if (previous != null) unawaited(previous.cancel());
    _completionSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // just_audio_background leaves its media session active at completed.
        // Stopping moves it to idle, which removes Android's media-player card.
        unawaited(stop());
      }
    });
  }

  void _ensurePlayerActive() {
    try {
      final _ = _player.processingState;
    } catch (_) {
      _player = AudioPlayer();
      _watchForCompletion();
    }
  }

  bool get isPlaying {
    _ensurePlayerActive();
    return _player.playing;
  }

  Stream<PlayerState> get playerStateStream {
    _ensurePlayerActive();
    return _player.playerStateStream;
  }

  Stream<bool> get isPlayingStream {
    _ensurePlayerActive();
    return _player.playingStream;
  }

  /// Play adhan, takbeer, or voice announcement with volume control.
  /// just_audio_background requires a MediaItem tag on every source. The
  /// completion watcher stops the session so its media card is dismissed.
  Future<void> play({
    AdhanSound sound = AdhanSound.qatami,
    PrayerNotificationMode mode = PrayerNotificationMode.adhan,
    double volume = 80.0,
    String? prayerName,
  }) async {
    try {
      _ensurePlayerActive();

      // Acquire supreme Adhan audio focus: automatically pauses Quran recitation, radio, and mutun
      await AudioCoordinator.acquireFocus(AudioStreamType.adhan);

      // Ensure Full Adhan mode strictly plays a full muezzin sound
      final effectiveSound =
          (mode == PrayerNotificationMode.adhan && sound == AdhanSound.takbeer)
          ? AdhanSound.qatami
          : sound;

      final assetPath = _assetFor(
        sound: effectiveSound,
        mode: mode,
        prayerName: prayerName,
      );

      final source = AudioSource.asset(
        assetPath,
        tag: MediaItem(
          id: assetPath,
          album: 'أذان الصلاة',
          title: prayerName != null ? 'أذان صلاة $prayerName' : 'أذان الصلاة',
          artist: 'طالب العلم',
          artUri: Uri.parse(
            'android.resource://com.example.talib_ilm/mipmap/ic_launcher',
          ),
        ),
      );

      final normalizedVolume = (volume / 100).clamp(0.0, 1.0);

      try {
        await _player.stop();
      } catch (_) {}

      await _player.setAudioSource(source);
      await _player.setVolume(normalizedVolume);
      await _player.play();
    } catch (e) {
      debugPrint('AdhanService.play error: $e');
    }
  }

  /// Sets audio player volume dynamically in real time
  Future<void> setVolume(double volume) async {
    _ensurePlayerActive();
    final normalized = (volume / 100).clamp(0.0, 1.0);
    try {
      await _player.setVolume(normalized);
    } catch (_) {}
  }

  Future<void> stop() async {
    _ensurePlayerActive();
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('AdhanService.stop error: $e');
    } finally {
      AudioCoordinator.releaseFocus(AudioStreamType.adhan);
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
    _ensurePlayerActive();
    // Media sources are prepared on demand with MediaItem tags
  }

  Future<void> dispose() async {
    try {
      await _completionSubscription?.cancel();
      _completionSubscription = null;
      await _player.stop();
      await _player.dispose();
    } catch (_) {}
    // Re-initialize so singleton is never left in a broken disposed state
    _player = AudioPlayer();
    _watchForCompletion();
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
    final effectiveSound = (sound == AdhanSound.takbeer)
        ? AdhanSound.qatami
        : sound;

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
