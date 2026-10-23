import 'dart:async';
import 'package:flutter/foundation.dart';

/// Available audio stream types in the application.
enum AudioStreamType {
  quran,
  radio,
  mutun,
  adhan,
}

/// Centralized audio coexistence and priority manager.
///
/// Enforces mutual exclusivity among media streams (Quran, Radio, Mutun)
/// and grants Adhan top priority by pausing all active media playback.
class AudioCoordinator {
  const AudioCoordinator._();

  static AudioStreamType? _currentActiveStream;
  static AudioStreamType? get currentActiveStream => _currentActiveStream;

  // Handlers registered by individual services to pause their playback
  static Future<void> Function()? onPauseQuran;
  static Future<void> Function()? onPauseRadio;
  static Future<void> Function()? onPauseMutun;
  static Future<void> Function()? onPauseAdhan;

  /// Request audio focus for [requestedType].
  /// Pauses all conflicting audio sources according to priority rules.
  static Future<void> acquireFocus(AudioStreamType requestedType) async {
    if (_currentActiveStream == requestedType) return;

    if (requestedType == AudioStreamType.adhan) {
      // Adhan has supreme priority: pause all other media sources
      await _pauseMediaStreams();
    } else {
      // Media stream (Quran, Radio, Mutun): pause other media streams and Adhan if sounding
      final futures = <Future<void>>[];

      if (requestedType != AudioStreamType.quran && onPauseQuran != null) {
        futures.add(onPauseQuran!().catchError((_) {}));
      }
      if (requestedType != AudioStreamType.radio && onPauseRadio != null) {
        futures.add(onPauseRadio!().catchError((_) {}));
      }
      if (requestedType != AudioStreamType.mutun && onPauseMutun != null) {
        futures.add(onPauseMutun!().catchError((_) {}));
      }
      if (onPauseAdhan != null) {
        futures.add(onPauseAdhan!().catchError((_) {}));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    }

    _currentActiveStream = requestedType;
  }

  /// Release focus when [type] completes or stops.
  static void releaseFocus(AudioStreamType type) {
    if (_currentActiveStream == type) {
      _currentActiveStream = null;
    }
  }

  static Future<void> _pauseMediaStreams() async {
    final futures = <Future<void>>[];
    if (onPauseQuran != null) futures.add(onPauseQuran!().catchError((_) {}));
    if (onPauseRadio != null) futures.add(onPauseRadio!().catchError((_) {}));
    if (onPauseMutun != null) futures.add(onPauseMutun!().catchError((_) {}));
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  @visibleForTesting
  static void reset() {
    _currentActiveStream = null;
    onPauseQuran = null;
    onPauseRadio = null;
    onPauseMutun = null;
    onPauseAdhan = null;
  }
}
