import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/constants/app_strings.dart';
import '../constants/app_policy.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_widget_state_evaluator.dart';
import 'adhan_service.dart';
import 'adhan_settings_service.dart';
import 'adhkar_reminder_service.dart';
import 'home_widget_service.dart';
import 'iqama_timing_policy.dart';
import 'notification_service.dart';
import 'prayer_schedule_service.dart';
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
  Timer? _widgetTimer;
  StreamSubscription<PlayerState>? _playerSub;
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final AdhanSettingsService _adhanSettingsService = AdhanSettingsService();
  final AdhanService _adhanService = AdhanService();
  final NotificationService _notificationService = NotificationService();

  final ValueNotifier<ActivePrayerAlert?> activeAlert =
      ValueNotifier<ActivePrayerAlert?>(null);
  final Set<String> _alertedKeys = <String>{};
  final Set<String> _inFlightAlertKeys = <String>{};
  bool _initialized = false;

  bool get isPolling => _timer != null && _timer!.isActive;

  Future<void> init() async {
    if (!_initialized) {
      _initialized = true;
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('adhan_alerted_keys') ?? [];
      _alertedKeys.addAll(saved);
    }

    _attachPlayerSubscription();
  }

  void _attachPlayerSubscription() {
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
    _attachPlayerSubscription();
    _initialTimer?.cancel();
    _timer?.cancel();
    _widgetTimer?.cancel();
    _initialTimer = Timer(AppPolicy.oneSecond, _check);
    _timer = Timer.periodic(AppPolicy.pollingStandard, (_) => _check());
    _widgetTimer = Timer.periodic(
      AppPolicy.pollingActive,
      (_) => _checkAndUpdateWidgetsIfNeeded(),
    );
    _checkAndUpdateWidgetsIfNeeded();
  }

  /// Pauses foreground periodic UI polling when app is minimized/paused/hidden.
  /// Preserves active alerts and audio completion subscriptions.
  void pausePolling() {
    _initialTimer?.cancel();
    _initialTimer = null;
    _timer?.cancel();
    _timer = null;
    _widgetTimer?.cancel();
    _widgetTimer = null;
    _lastWidgetPhaseKey = null;
  }

  void stop() {
    pausePolling();
    _playerSub?.cancel();
    _playerSub = null;
    activeAlert.value = null;
  }

  @visibleForTesting
  void resetForTesting() {
    stop();
    _alertedKeys.clear();
    _inFlightAlertKeys.clear();
    _initialized = false;
    _lastWidgetPhaseKey = null;
    activeAlert.value = null;
  }

  @visibleForTesting
  Set<String> get alertedKeysForTesting => Set.unmodifiable(_alertedKeys);

  @visibleForTesting
  Future<void> checkForTesting() => _check();

  void _trimAlertedKeys() {
    if (_alertedKeys.length > 50) {
      final list = _alertedKeys.toList();
      _alertedKeys.clear();
      _alertedKeys.addAll(list.sublist(list.length - 50));
    }
  }

  Future<void> _markAlerted(String key) async {
    _alertedKeys.add(key);
    _trimAlertedKeys();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('adhan_alerted_keys', _alertedKeys.toList());
  }

  String? _lastWidgetPhaseKey;

  void _checkAndUpdateWidgetsIfNeeded() {
    final now = DateTime.now();
    _prayerTimeService
        .getPrayerTimesDay()
        .then((day) async {
          final iqamaOverrides = (await _adhanSettingsService.getSettings())
              .iqamaMinutesAfterAdhan;
          final eval = PrayerWidgetStateEvaluator.evaluate(
            now: now,
            all: day.prayers,
            iqamaOverrides: iqamaOverrides,
          );
          final key =
              '${eval.activePrayerName}_${eval.phase.name}_${now.hour}:${now.minute}';
          if (key != _lastWidgetPhaseKey) {
            _lastWidgetPhaseKey = key;
            unawaited(
              HomeWidgetService.updateAllWidgets(
                prayerDay: day,
                referenceTime: now,
              ),
            );
          }
        })
        .catchError((_) {});
  }

  Future<void> dismissAlert() async {
    await _adhanService.stop();
    activeAlert.value = null;
  }

  Future<void> _check() async {
    try {
      final now = DateTime.now();
      final settings = await _adhanSettingsService.getSettings();
      try {
        await _checkAdhkarReminders(now);
      } catch (e) {
        debugPrint('Foreground Adhkar check failed: $e');
      }
      if (!settings.enabled) {
        if (activeAlert.value != null || _adhanService.isPlaying) {
          await dismissAlert();
        }
        return;
      }

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

        final isJumua =
            day.date.weekday == DateTime.friday &&
            (name.contains('الظهر') || name == 'الظهر');
        final effectiveName = isJumua ? 'صلاة الجمعة' : name;

        // 1. Advance reminder check in foreground (e.g. 15 minutes before)
        final notifyBefore = settings.notifyBeforeMinutes.toInt();
        if (notifyBefore > 0) {
          final preTime = time.subtract(Duration(minutes: notifyBefore));
          final preDiff = now.difference(preTime);
          if (preDiff.inSeconds >= -60 && preDiff.inSeconds <= 60) {
            final preAlertKey = '${todayStr}_pre_$name';
            if (!_alertedKeys.contains(preAlertKey) &&
                _inFlightAlertKeys.add(preAlertKey)) {
              try {
                final scheduled = await _eventWasScheduled(
                  date: day.date,
                  prayerName: name,
                  event: PrayerScheduleEvent.prePrayer,
                );
                if (PrayerScheduleService.shouldUseForegroundFallback(
                  scheduled,
                )) {
                  final orderIndex = AppStrings.prayerOrder.indexOf(name);
                  final preNotifId = 750 + (orderIndex >= 0 ? orderIndex : 0);
                  try {
                    await _notificationService.showInstantPrePrayerNotification(
                      id: preNotifId,
                      prayerName: effectiveName,
                      minutesBefore: notifyBefore,
                      isJumua: isJumua,
                    );
                  } catch (e) {
                    debugPrint('Foreground pre-prayer notification failed: $e');
                  }
                }
                await _markAlerted(preAlertKey);
              } finally {
                _inFlightAlertKeys.remove(preAlertKey);
              }
            }
          }
        }

        // Recover Iqama delivery only when the OS did not confirm ownership.
        // Iqama offsets match the schedule service and Friday Dhuhr is Jumua.
        if (settings.iqamaReminders) {
          final iqamaMinutes = IqamaTimingPolicy.minutesAfterAdhan(
            name,
            isJumua: isJumua,
            configuredMinutes: settings.iqamaMinutesAfterAdhan,
          );
          final iqamaTime = time.add(Duration(minutes: iqamaMinutes));
          final iqamaDiff = now.difference(iqamaTime).inSeconds;
          if (iqamaDiff >= -60 && iqamaDiff <= 60) {
            final iqamaAlertKey = '${todayStr}_iqama_$name';
            if (!_alertedKeys.contains(iqamaAlertKey) &&
                _inFlightAlertKeys.add(iqamaAlertKey)) {
              try {
                final scheduled = await _eventWasScheduled(
                  date: day.date,
                  prayerName: name,
                  event: PrayerScheduleEvent.iqama,
                );
                if (PrayerScheduleService.shouldUseForegroundFallback(
                  scheduled,
                )) {
                  final orderIndex = _prayerScheduleIndex(day, name);
                  await _notificationService.showInstantIqamaNotification(
                    id: 3000 + (orderIndex >= 0 ? orderIndex : 0),
                    prayerName: effectiveName,
                    isJumua: isJumua,
                  );
                }
                await _markAlerted(iqamaAlertKey);
              } catch (e) {
                debugPrint('Foreground Iqama notification failed: $e');
              } finally {
                _inFlightAlertKeys.remove(iqamaAlertKey);
              }
            }
          }
        }

        // 2. Check if now is within [prayerTime, prayerTime + 90 seconds]
        final diff = now.difference(time);
        if (diff.inSeconds >= 0 && diff.inSeconds <= 90) {
          final alertKey = '${todayStr}_$name';
          if (!_alertedKeys.contains(alertKey) &&
              _inFlightAlertKeys.add(alertKey)) {
            try {
              final scheduled = await _eventWasScheduled(
                date: day.date,
                prayerName: name,
                event: PrayerScheduleEvent.adhan,
              );
              final effectiveSound = settings.effectiveMuezzinSound;
              final shouldFallback =
                  PrayerScheduleService.shouldUseForegroundFallback(scheduled);

              if (shouldFallback) {
                // Recover locally only when this occurrence has no confirmed
                // platform alarm.
                final orderIndex = AppStrings.prayerOrder.indexOf(name);
                final notifId = 700 + (orderIndex >= 0 ? orderIndex : 0);
                final useNotificationTone = mode == PrayerNotificationMode.tone;

                if (mode != PrayerNotificationMode.silent &&
                    !useNotificationTone &&
                    !_adhanService.isPlaying) {
                  unawaited(
                    _adhanService.play(
                      sound: effectiveSound,
                      mode: mode,
                      volume: settings.volume,
                      prayerName: effectiveName,
                    ),
                  );
                }

                // For media playback, keep the visible OS alert silent so it
                // cannot start a second copy of the Adhan. Tone mode uses the
                // OS notification tone as its configured audio source.
                try {
                  await _notificationService.showInstantPrayerAlert(
                    id: notifId,
                    prayerName: effectiveName,
                    mode: useNotificationTone
                        ? mode
                        : PrayerNotificationMode.silent,
                    sound: effectiveSound,
                  );
                } catch (e) {
                  debugPrint('Foreground prayer notification failed: $e');
                }
              }

              // 3. Post in-app alert banner with stop controls
              activeAlert.value = ActivePrayerAlert(
                prayerName: effectiveName,
                prayerTime: time,
                mode: mode,
                sound: effectiveSound,
              );
              await _markAlerted(alertKey);

              unawaited(HomeWidgetService.updateAllWidgets(prayerDay: day));
            } finally {
              _inFlightAlertKeys.remove(alertKey);
            }
          }
        }
      }

      // Periodically refresh the Home Screen Widget so time and prayer states stay active
      unawaited(
        HomeWidgetService.updateAllWidgets(prayerDay: day, referenceTime: now),
      );
    } catch (e) {
      debugPrint('ForegroundPrayerService._check error: $e');
    }
  }

  Future<bool?> _eventWasScheduled({
    required DateTime date,
    required String prayerName,
    required PrayerScheduleEvent event,
  }) async {
    try {
      return await PrayerScheduleService.wasEventScheduled(
        date: date,
        prayerName: prayerName,
        event: event,
      );
    } catch (e) {
      debugPrint('Unable to read prayer schedule state; using fallback: $e');
      return null;
    }
  }

  Future<void> _checkAdhkarReminders(DateTime now) async {
    final service = AdhkarReminderService();
    final settings = await service.getSettings();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final reminders =
        <(AdhkarReminderType, bool, int, int, int, String, String)>[
          (
            AdhkarReminderType.morning,
            settings.morningEnabled,
            AdhkarReminderService.idMorning,
            settings.morningHour,
            settings.morningMinute,
            'أذكار الصباح',
            'أصبحنا وأصبح الملك لله.. ابدأ يومك بحفظ الله وذكره',
          ),
          (
            AdhkarReminderType.evening,
            settings.eveningEnabled,
            AdhkarReminderService.idEvening,
            settings.eveningHour,
            settings.eveningMinute,
            'أذكار المساء',
            'أمسينا وأمسى الملك لله.. حصّن نفسك بحفظ الله وذكره',
          ),
          (
            AdhkarReminderType.sleep,
            settings.sleepEnabled,
            AdhkarReminderService.idSleep,
            settings.sleepHour,
            settings.sleepMinute,
            'أذكار النوم',
            'باسمك ربي وضعت جنبي وبك أرفعه.. لا تنسَ أذكار النوم وسورة الملك',
          ),
        ];

    for (final reminder in reminders) {
      final (type, enabled, id, hour, minute, title, body) = reminder;
      if (!enabled) continue;
      final reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
      final secondsFromReminder = now.difference(reminderTime).inSeconds;
      if (secondsFromReminder < -60 || secondsFromReminder > 60) continue;

      final alertKey = '${todayStr}_adhkar_${type.name}';
      if (_alertedKeys.contains(alertKey) ||
          !_inFlightAlertKeys.add(alertKey)) {
        continue;
      }
      try {
        final scheduled = await AdhkarReminderService.wasReminderScheduled(
          date: now,
          reminder: type,
        );
        if (scheduled == true) {
          await _markAlerted(alertKey);
          continue;
        }
        await _notificationService.showInstantAdhkarNotification(
          id: id,
          title: title,
          body: body,
          payload: type.name,
        );
        await _markAlerted(alertKey);
      } catch (e) {
        debugPrint(
          'Foreground Adhkar notification failed for ${type.name}: $e',
        );
      } finally {
        _inFlightAlertKeys.remove(alertKey);
      }
    }
  }

  int _prayerScheduleIndex(PrayerTimesDay day, String prayerName) {
    final entries = day.prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.indexWhere((entry) => entry.key == prayerName);
  }
}
