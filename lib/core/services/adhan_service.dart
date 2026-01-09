import 'package:just_audio/just_audio.dart';
import '../../app/constants/app_assets.dart';

import 'adhan_settings_service.dart';

class AdhanService {
  final AudioPlayer _player;

  AdhanService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  Future<void> play(AdhanSound sound) async {
    final asset = _assetFor(sound);
    await _player.stop();
    await _player.setAudioSource(AudioSource.asset(asset));
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> test(AdhanSound sound) async {
    await play(sound);
  }

  Future<void> dispose() async {
    await _player.dispose();
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
