import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/constants/app_strings.dart';
import 'adhan_service.dart';
import 'adhan_settings_service.dart';
import 'notification_service.dart';
import 'prayer_time_service.dart';

class ActivePrayerAlert {
  final String prayerName;
  final DateTime prayerTime;
  final PrayerNotificationMode mode;
  final AdhanSound sound;

  const ActivePrayerAlert({
    required this.prayerName,
    required this.prayerTime,
    required this.mode,
    required this.sound,
  });
}

/// App-wide foreground prayer monitoring service.
///
/// Ensures that when the user has the app open (or opens the app during prayer time),
/// the Adhan audio plays reliably, the instant system heads-up notification is posted,
/// and an in-app dignified prayer alert banner is displayed with mute/stop controls.
class ForegroundPrayerService {
  static final ForegroundPrayerService _instance =
      ForegroundPrayerService._internal();
  factory ForegroundPrayerService() => _instance;
  ForegroundPrayerService._internal();

  Timer? _timer;
  StreamSubscription<PlayerState>? _playerSub;
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final AdhanSettingsService _adhanSettingsService = AdhanSettingsService();
  final AdhanService _adhanService = AdhanService();
  final NotificationService _notificationService = NotificationService();

  final ValueNotifier<ActivePrayerAlert?> activeAlert =
      ValueNotifier<ActivePrayerAlert?>(null);
  final Set<String> _alertedKeys = <String>{};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('adhan_alerted_keys') ?? [];
    _alertedKeys.addAll(saved);

    // Auto-dismiss alert when audio finishes playing
    _playerSub?.cancel();
    _playerSub = _adhanService.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (activeAlert.value != null) {
          activeAlert.value = null;
        }
      }
    });
  }

  void start() {
    unawaited(init());
    _timer?.cancel();
    _check();
    _timer = Timer.periodic(
      const Duration(seconds: 10), // ui-lint: allow service interval
      (_) => _check(),
    );
  }

  void stop() {
    _timer?.cancel();
    _playerSub?.cancel();
  }

  Future<void> dismissAlert() async {
    await _adhanService.stop();
    activeAlert.value = null;
  }

  Future<void> _check() async {
    try {
      final now = DateTime.now();
      final settings = await _adhanSettingsService.getSettings();
      if (!settings.enabled) return;

      final day = await _prayerTimeService.getPrayerTimesDay();
      final todayStr =
          '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';

      // Keep only keys from today
      _alertedKeys.removeWhere((k) => !k.startsWith(todayStr));

      for (final entry in day.prayers.entries) {
        final name = entry.key;
        final time = entry.value;

        // Skip Sunrise (الشروق) for adhan
        if (name.contains('الشروق')) continue;

        final mode = settings.modeForPrayer(name);
        if (mode == PrayerNotificationMode.off) continue;

        // Check if now is within [prayerTime, prayerTime + 90 seconds]
        final diff = now.difference(time);
        if (diff.inSeconds >= 0 && diff.inSeconds <= 90) {
          final alertKey = '${todayStr}_$name';
          if (!_alertedKeys.contains(alertKey)) {
            _alertedKeys.add(alertKey);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('adhan_alerted_keys', _alertedKeys.toList());

            // 1. Play Adhan audio directly in-app
            if (mode == PrayerNotificationMode.adhan ||
                mode == PrayerNotificationMode.takbeer ||
                mode == PrayerNotificationMode.announcement) {
              await _adhanService.play(
                sound: settings.sound,
                mode: mode,
                volume: settings.volume,
                prayerName: name,
              );
            }

            // 2. Trigger instant system notification with heads-up alarm banner
            final orderIndex = AppStrings.prayerOrder.indexOf(name);
            final notifId = 700 + (orderIndex >= 0 ? orderIndex : 0);
            await _notificationService.showInstantPrayerAlert(
              id: notifId,
              prayerName: name,
              mode: mode,
              sound: settings.sound,
            );

            // 3. Post in-app alert banner
            activeAlert.value = ActivePrayerAlert(
              prayerName: name,
              prayerTime: time,
              mode: mode,
              sound: settings.sound,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('ForegroundPrayerService._check error: $e');
    }
  }
}
