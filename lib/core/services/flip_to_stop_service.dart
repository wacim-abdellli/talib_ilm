import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adhan_service.dart';
import 'foreground_prayer_service.dart';
import 'notification_service.dart';
import '../../features/quran/data/services/quran_audio_service.dart';
import '../../features/radio/data/services/quran_radio_service.dart';

/// Modern Flip-to-Stop service:
/// Listens to device orientation via accelerometer.
/// When user flips phone face-down (Z < -7.0 m/s²), it silences active Adhan,
/// cancels prayer notifications, or pauses Holy Quran audio / Quran radio.
class FlipToStopService {
  static final FlipToStopService _instance = FlipToStopService._internal();
  factory FlipToStopService() => _instance;
  FlipToStopService._internal();

  static const String _prefKey = 'flip_to_stop_enabled';

  StreamSubscription<AccelerometerEvent>? _sensorSub;
  bool _isEnabled = true;
  bool _wasFaceDown = false;
  DateTime _lastTriggerTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isEnabled => _isEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_prefKey) ?? true;
    _startListening();
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    if (enabled) {
      _startListening();
    } else {
      _sensorSub?.cancel();
      _sensorSub = null;
    }
  }

  void _startListening() {
    _sensorSub?.cancel();
    if (!_isEnabled) return;

    try {
      _sensorSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(_onAccelerometerEvent, onError: (_) {});
    } catch (_) {
      // Sensor not available on this platform (e.g. desktop/web/simulator)
    }
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_isEnabled) return;

    // Face down: Z is strongly negative (gravity pointing away from screen, ~ -9.8 m/s²)
    // X and Y are relatively flat (phone placed face-down on surface or held face down)
    final isFaceDown = event.z < -7.0 && event.x.abs() < 5.0 && event.y.abs() < 5.0;

    if (isFaceDown && !_wasFaceDown) {
      final now = DateTime.now();
      // Debounce at least 1.5 seconds between trigger events
      if (now.difference(_lastTriggerTime).inMilliseconds > 1500) {
        _lastTriggerTime = now;
        _handleFlipToStop();
      }
    }

    _wasFaceDown = isFaceDown;
  }

  void _handleFlipToStop() {
    bool stoppedSomething = false;

    // 1. Silence Adhan & dismiss in-app prayer alerts
    try {
      final foregroundPrayer = ForegroundPrayerService();
      if (foregroundPrayer.activeAlert.value != null) {
        foregroundPrayer.dismissAlert();
        stoppedSomething = true;
      }
      final adhanService = AdhanService();
      if (adhanService.isPlaying) {
        adhanService.stop();
        stoppedSomething = true;
      }
      NotificationService().cancelPrayerNotificationsOnly();
    } catch (_) {}

    // 2. Pause Quran recitation audio
    try {
      final quranAudio = QuranAudioService();
      if (quranAudio.isPlaying) {
        quranAudio.pause();
        stoppedSomething = true;
      }
    } catch (_) {}

    // 3. Pause Quran radio
    try {
      final radio = QuranRadioService();
      if (radio.isPlaying) {
        radio.pause();
        stoppedSomething = true;
      }
    } catch (_) {}

    if (stoppedSomething) {
      HapticFeedback.mediumImpact();
    }
  }

  void dispose() {
    _sensorSub?.cancel();
    _sensorSub = null;
  }
}
