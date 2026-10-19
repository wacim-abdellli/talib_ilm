import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/constants/app_strings.dart';
import 'adhan_service.dart';
import 'adhan_settings_service.dart';
import 'home_widget_service.dart';
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

  Timer? _initialTimer;
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
    _initialTimer?.cancel();
    _timer?.cancel();
    _initialTimer = Timer(const Duration(seconds: 1), _check); // ui-lint: allow service interval
    _timer = Timer.periodic(
      const Duration(seconds: 30), // ui-lint: allow service interval
      (_) => _check(),
    );
  }

  void stop() {
    _initialTimer?.cancel();
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

        final isJumua = day.date.weekday == DateTime.friday &&
            (name.contains('الظهر') || name == 'الظهر');
        final effectiveName = isJumua ? 'صلاة الجمعة' : name;

        // 1. Advance reminder check in foreground (e.g. 15 minutes before)
        final notifyBefore = settings.notifyBeforeMinutes.toInt();
        if (notifyBefore > 0) {
          final preTime = time.subtract(Duration(minutes: notifyBefore));
          final preDiff = now.difference(preTime);
          if (preDiff.inSeconds >= 0 && preDiff.inSeconds <= 60) {
            final preAlertKey = '${todayStr}_pre_$name';
            if (!_alertedKeys.contains(preAlertKey)) {
              _alertedKeys.add(preAlertKey);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setStringList(
                  'adhan_alerted_keys', _alertedKeys.toList());

              final orderIndex = AppStrings.prayerOrder.indexOf(name);
              final preNotifId = 750 + (orderIndex >= 0 ? orderIndex : 0);
              await _notificationService.showInstantPrePrayerNotification(
                id: preNotifId,
                prayerName: effectiveName,
                minutesBefore: notifyBefore,
                isJumua: isJumua,
              );
            }
          }
        }

        // 2. Check if now is within [prayerTime, prayerTime + 90 seconds]
        final diff = now.difference(time);
        if (diff.inSeconds >= 0 && diff.inSeconds <= 90) {
          final alertKey = '${todayStr}_$name';
          if (!_alertedKeys.contains(alertKey)) {
            _alertedKeys.add(alertKey);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('adhan_alerted_keys', _alertedKeys.toList());

            final effectiveSound = settings.effectiveMuezzinSound;

            // 1. Play audio via AdhanService foreground media session if not already playing
            if (mode != PrayerNotificationMode.silent &&
                mode != PrayerNotificationMode.off) {
              if (!_adhanService.isPlaying) {
                unawaited(_adhanService.play(
                  sound: effectiveSound,
                  mode: mode,
                  volume: settings.volume,
                  prayerName: effectiveName,
                ));
              }
            }

            // 2. Trigger instant system notification with heads-up alarm presentation
            final orderIndex = AppStrings.prayerOrder.indexOf(name);
            final notifId = 700 + (orderIndex >= 0 ? orderIndex : 0);
            await _notificationService.showInstantPrayerAlert(
              id: notifId,
              prayerName: effectiveName,
              mode: mode,
              sound: effectiveSound,
            );

            // 3. Post in-app alert banner with stop controls
            activeAlert.value = ActivePrayerAlert(
              prayerName: effectiveName,
              prayerTime: time,
              mode: mode,
              sound: effectiveSound,
            );

            unawaited(HomeWidgetService.updatePrayerWidget(prayerDay: day));
          }
        }
      }
    } catch (e) {
      debugPrint('ForegroundPrayerService._check error: $e');
    }
  }
}
