import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../app/constants/app_strings.dart';
import 'adhan_service.dart';
import 'adhan_settings_service.dart';
import 'athkar_notification_scheduler.dart';
import 'foreground_prayer_service.dart';
import 'notification_delivery_health.dart';
import 'notification_channel_manager.dart';
import 'notification_router.dart';
import 'prayer_notification_details_builder.dart';
import 'prayer_notification_scheduler.dart';
import 'schedule_outcome.dart';
export 'schedule_outcome.dart';
export 'notification_delivery_health.dart';

class NotificationService {
  static Future<void>? _sharedInFlightInit;
  static bool _sharedInitialized = false;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _tzInitialized = false;

  late final PrayerNotificationScheduler _prayerScheduler;
  late final AthkarNotificationScheduler _athkarScheduler;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin() {
    _prayerScheduler = PrayerNotificationScheduler(
      plugin: _plugin,
      ensureInitialized: init,
      requestPermissions: requestPermissions,
      safeZonedSchedule: _safeZonedSchedule,
    );
    _athkarScheduler = AthkarNotificationScheduler(
      ensureInitialized: init,
      safeZonedSchedule: _safeZonedSchedule,
    );
  }

  bool get isInitialized => _initialized || _sharedInitialized;

  @visibleForTesting
  static void resetSharedStateForTesting() {
    _sharedInFlightInit = null;
    _sharedInitialized = false;
  }

  Future<void> init() async {
    if (_initialized || _sharedInitialized) {
      _initialized = true;
      return;
    }

    if (_sharedInFlightInit != null) {
      await _sharedInFlightInit;
      _initialized = _sharedInitialized;
      return;
    }

    final completer = Completer<void>();
    _sharedInFlightInit = completer.future;

    try {
      await _performInit();
      _sharedInitialized = true;
      _initialized = true;
      completer.complete();
    } catch (e) {
      _sharedInitialized = false;
      _initialized = false;
      completer.completeError(e);
      rethrow;
    } finally {
      _sharedInFlightInit = null;
    }
  }

  Future<void> _performInit() async {
    await _initTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linux = LinuxInitializationSettings(
      defaultActionName: AppStrings.notificationDefaultAction,
    );

    const settings = InitializationSettings(
      android: android,
      iOS: ios,
      macOS: ios,
      linux: linux,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == 'stop_adhan') {
          try {
            AdhanService().stop();
          } catch (_) {}
          try {
            ForegroundPrayerService().dismissAlert();
          } catch (_) {}
          return;
        }
        final p = response.payload;
        if (p != null && p.isNotEmpty) {
          try {
            AdhanService().stop();
          } catch (_) {}
          try {
            ForegroundPrayerService().dismissAlert();
          } catch (_) {}
          NotificationRouter.handlePayload(p);
        }
      },
    );

    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final p = launchDetails?.notificationResponse?.payload;
        if (p != null && p.isNotEmpty) {
          NotificationRouter.pendingPayload = p;
        }
      }
    } catch (e) {
      debugPrint('Notification launch details error: $e');
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await NotificationChannelManager.registerChannels(androidPlugin);
    }
  }

  /// Queries whether notifications permission is currently granted without prompting the user.
  Future<bool> arePermissionsGranted() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final permissions = await ios?.checkPermissions();
        return permissions?.isEnabled == true &&
            permissions?.isAlertEnabled == true;
      }
      if (Platform.isMacOS) {
        final mac = _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        final permissions = await mac?.checkPermissions();
        return permissions?.isEnabled == true &&
            permissions?.isAlertEnabled == true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns whether Android currently allows exact alarms. A null result means
  /// the platform does not expose this capability (for example iOS/macOS).
  /// Callers include this value in schedule fingerprints so granting the
  /// permission causes previously inexact alarms to be replaced with exact ones.
  Future<bool?> canScheduleExactNotifications() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.canScheduleExactNotifications();
    } catch (e) {
      debugPrint('Unable to query exact-alarm capability: $e');
      return null;
    }
  }

  /// Reads Android's current app permission, exact-alarm access, and channel
  /// settings for every alert family currently enabled in [settings].
  Future<NotificationDeliveryHealth> getDeliveryHealth(
    AdhanSettings settings,
  ) async {
    if (kIsWeb || !Platform.isAndroid) {
      return const NotificationDeliveryHealth(
        notificationsAllowed: null,
        exactAlarmsAllowed: null,
      );
    }

    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return const NotificationDeliveryHealth(
        notificationsAllowed: null,
        exactAlarmsAllowed: null,
      );
    }

    final notificationsAllowed = await arePermissionsGranted();
    final exactAlarmsAllowed = await canScheduleExactNotifications();
    final channels = await android.getNotificationChannels() ?? const [];
    final requiredChannels = <String>{
      'talib_adhkar_reminders',
    };
    final soundChannels = <String>{
      'talib_adhkar_reminders',
    };

    if (settings.enabled) {
      for (final prayerName in AdhanSettingsService.prayerNames) {
        if (prayerName.contains('الشروق')) continue;
        final mode = settings.modeForPrayer(prayerName);
        final channelId = switch (mode) {
          PrayerNotificationMode.adhan =>
            PrayerNotificationDetailsBuilder.channelIdForAdhan(
              settings.effectiveMuezzinSound,
            ),
          PrayerNotificationMode.takbeer => 'talib_prayer_takbeer_v3',
          PrayerNotificationMode.announcement =>
            PrayerNotificationDetailsBuilder.announcementChannelIdFor(
              prayerName,
            ),
          PrayerNotificationMode.tone => 'talib_prayer_tone_v3',
          PrayerNotificationMode.silent => 'talib_prayer_silent_v3',
          PrayerNotificationMode.off => null,
        };
        if (channelId == null) continue;
        requiredChannels.add(channelId);
        if (mode != PrayerNotificationMode.silent) {
          soundChannels.add(channelId);
        }
      }
      if (settings.notifyBeforeMinutes > 0) {
        requiredChannels.add('talib_prayer_pre_reminder_v3');
        soundChannels.add('talib_prayer_pre_reminder_v3');
      }
      if (settings.iqamaReminders) {
        requiredChannels.add('talib_prayer_iqama_v3');
        soundChannels.add('talib_prayer_iqama_v3');
      }
      if (settings.modeForPrayer(AppStrings.prayerDhuhr) ==
          PrayerNotificationMode.announcement) {
        // Friday Dhuhr is announced through the general Jumua channel.
        requiredChannels.add(
          PrayerNotificationDetailsBuilder.announcementChannelIdFor(null),
        );
        soundChannels.add(
          PrayerNotificationDetailsBuilder.announcementChannelIdFor(null),
        );
      }
    }

    return NotificationDeliveryHealth.fromAndroid(
      notificationsAllowed: notificationsAllowed,
      exactAlarmsAllowed: exactAlarmsAllowed,
      channels: channels,
      requiredChannelIds: requiredChannels,
      soundRequiredChannelIds: soundChannels,
    );
  }

  /// Requests notification and alarm permissions explicitly with user intent.
  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      await android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
    try {
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Exact-alarm permission request failed: $e');
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    try {
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('iOS notification permission request failed: $e');
    }

    final mac = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    try {
      await mac?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('macOS notification permission request failed: $e');
    }
  }

  Future<ScheduleOutcome> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required UILocalNotificationDateInterpretation
    uiLocalNotificationDateInterpretation,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            uiLocalNotificationDateInterpretation,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
      return ScheduleOutcome(
        status: ScheduleOutcomeStatus.exact,
        notificationId: id,
      );
    } catch (e) {
      debugPrint(
        'Warning: Schedule mode $scheduleMode restricted ($e) for $id. Retrying with exactAllowWhileIdle.',
      );
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              uiLocalNotificationDateInterpretation,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
        return ScheduleOutcome(
          status: ScheduleOutcomeStatus.exact,
          notificationId: id,
        );
      } catch (fallbackError) {
        debugPrint(
          'Warning: exactAllowWhileIdle failed ($fallbackError) for $id. Retrying with inexactAllowWhileIdle.',
        );
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                uiLocalNotificationDateInterpretation,
            matchDateTimeComponents: matchDateTimeComponents,
            payload: payload,
          );
          return ScheduleOutcome(
            status: ScheduleOutcomeStatus.inexactFallback,
            notificationId: id,
          );
        } catch (inexactError) {
          debugPrint(
            'Final fallback inexact scheduling error ($id): $inexactError',
          );
          return ScheduleOutcome(
            status: ScheduleOutcomeStatus.failed,
            errorMessage: inexactError.toString(),
            notificationId: id,
          );
        }
      }
    }
  }

  /// Schedules a prayer notification according to the chosen mode (Adhan, Takbeer, Tone, Silent)
  /// using Android AlarmClock mode for guaranteed execution even during deep Doze.
  Future<ScheduleOutcome> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
    bool isJumua = false,
  }) => _prayerScheduler.schedulePrayerNotification(
    id: id,
    prayerName: prayerName,
    scheduledTime: scheduledTime,
    mode: mode,
    sound: sound,
    isJumua: isJumua,
  );

  /// Schedules an advance reminder (e.g. 15 minutes before) so the user can make wudhu and prepare.
  Future<ScheduleOutcome> schedulePrePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required int minutesBefore,
    bool isJumua = false,
  }) => _prayerScheduler.schedulePrePrayerNotification(
    id: id,
    prayerName: prayerName,
    scheduledTime: scheduledTime,
    minutesBefore: minutesBefore,
    isJumua: isJumua,
  );

  /// Displays an instant heads-up advance reminder for foreground prayer detection.
  Future<void> showInstantPrePrayerNotification({
    required int id,
    required String prayerName,
    required int minutesBefore,
    bool isJumua = false,
  }) => _prayerScheduler.showInstantPrePrayerNotification(
    id: id,
    prayerName: prayerName,
    minutesBefore: minutesBefore,
    isJumua: isJumua,
  );

  /// Schedules an Iqama notification after prayer time
  Future<ScheduleOutcome> scheduleIqamaNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    bool isJumua = false,
  }) => _prayerScheduler.scheduleIqamaNotification(
    id: id,
    prayerName: prayerName,
    scheduledTime: scheduledTime,
    isJumua: isJumua,
  );

  /// Displays an Iqama reminder immediately as foreground recovery.
  Future<void> showInstantIqamaNotification({
    required int id,
    required String prayerName,
    bool isJumua = false,
  }) => _prayerScheduler.showInstantIqamaNotification(
    id: id,
    prayerName: prayerName,
    isJumua: isJumua,
  );

  /// Schedules a dedicated reminder to recite Surat Al-Kahf on Friday
  Future<ScheduleOutcome> scheduleSurahAlKahfNotification({
    required int id,
    required DateTime scheduledTime,
  }) => _prayerScheduler.scheduleSurahAlKahfNotification(
    id: id,
    scheduledTime: scheduledTime,
  );

  /// Shows an instant prayer alert notification with heads-up alarm presentation
  Future<void> showInstantPrayerAlert({
    required int id,
    required String prayerName,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
  }) => _prayerScheduler.showInstantPrayerAlert(
    id: id,
    prayerName: prayerName,
    mode: mode,
    sound: sound,
  );

  /// Triggers an immediate test notification right now so the user can verify sound and alerts.
  Future<void> showInstantTestNotification({
    required String prayerName,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
  }) => _prayerScheduler.showInstantTestNotification(
    prayerName: prayerName,
    mode: mode,
    sound: sound,
  );

  /// Schedules a test notification after [seconds] (e.g. 5 seconds)
  /// allowing the user to minimize the app or lock the screen to test outside the app.
  Future<ScheduleOutcome> scheduleTestNotificationAfter({
    required int seconds,
    required String prayerName,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
  }) => _prayerScheduler.scheduleTestNotificationAfter(
    seconds: seconds,
    prayerName: prayerName,
    mode: mode,
    sound: sound,
  );

  /// Legacy support
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool playSound,
    AdhanSound? sound,
  }) => _prayerScheduler.scheduleNotification(
    id: id,
    title: title,
    body: body,
    scheduledTime: scheduledTime,
    playSound: playSound,
    sound: sound,
  );

  Future<void> cancelAll() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    await _plugin.cancelAll();
  }

  /// Dismisses only the active in-progress heads-up prayer alerts and tone notifications (700..710, 750..760)
  /// without clearing any of the 7-day scheduled future prayer alarms.
  Future<void> cancelActivePrayerAlertsOnly() =>
      _prayerScheduler.cancelActivePrayerAlertsOnly();

  /// Cancels all scheduled prayer-related notification slots across the 7-day rolling schedule,
  /// strictly preserving other notification categories like Athkar reminders (301, 302, 303),
  /// and preserving any actively sounding prayer notification IDs.
  Future<void> cancelPrayerNotificationsOnly({Set<int>? preserveIds}) =>
      _prayerScheduler.cancelPrayerNotificationsOnly(preserveIds: preserveIds);

  Future<void> _initTimeZones() async {
    if (_tzInitialized) return;
    tz.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      final String tzName = tzInfo is String
          ? tzInfo
          : (tzInfo?.identifier ?? tzInfo.toString());
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      try {
        final currentTzName = DateTime.now().timeZoneName;
        if (tz.timeZoneDatabase.locations.containsKey(currentTzName)) {
          tz.setLocalLocation(tz.getLocation(currentTzName));
        } else {
          final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
          final matched = findLocationByOffset(offsetMinutes);
          if (matched != null) {
            tz.setLocalLocation(matched);
          } else {
            tz.setLocalLocation(tz.getLocation('UTC'));
          }
        }
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    _tzInitialized = true;
  }

  /// Resolves an IANA location matching the given offset in minutes for timezone resilience.
  @visibleForTesting
  static tz.Location? findLocationByOffset(int offsetMinutes) {
    switch (offsetMinutes) {
      case 60:
        if (tz.timeZoneDatabase.locations.containsKey('Africa/Algiers')) {
          return tz.getLocation('Africa/Algiers');
        }
        break;
      case 120:
        if (tz.timeZoneDatabase.locations.containsKey('Africa/Cairo')) {
          return tz.getLocation('Africa/Cairo');
        }
        break;
      case 180:
        if (tz.timeZoneDatabase.locations.containsKey('Asia/Riyadh')) {
          return tz.getLocation('Asia/Riyadh');
        }
        break;
      case 240:
        if (tz.timeZoneDatabase.locations.containsKey('Asia/Dubai')) {
          return tz.getLocation('Asia/Dubai');
        }
        break;
      case 0:
        return tz.getLocation('UTC');
    }
    final targetMs = offsetMinutes * 60 * 1000;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.currentTimeZone.offset == targetMs) {
        return loc;
      }
    }
    return null;
  }

  /// Schedules a repeating daily notification for Morning, Evening, or Sleep Adhkar.
  Future<ScheduleOutcome> scheduleDailyAdhkarNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) => _athkarScheduler.scheduleDailyAdhkarNotification(
    id: id,
    title: title,
    body: body,
    hour: hour,
    minute: minute,
    payload: payload,
  );

  /// Displays a one-off Adhkar reminder when the daily platform alarm could
  /// not be confirmed and the app is currently foregrounded.
  Future<void> showInstantAdhkarNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    await init();
    const androidDetails = AndroidNotificationDetails(
      'talib_adhkar_reminders',
      'تنبيهات الأذكار اليومية',
      channelDescription:
          'تذكير بأذكار الصباح والمساء والنوم في أوقاتها المسنونة',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: 'أذكار المسلم',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Schedules a notification for Sunnah Fasting (White Days / Monday / Thursday).
  Future<ScheduleOutcome> scheduleFastingReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) => _athkarScheduler.scheduleFastingReminder(
    id: id,
    title: title,
    body: body,
    scheduledDate: scheduledDate,
    payload: payload,
  );

  /// Cancels a specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification $id: $e');
    }
  }

  /// Cancels one notification and reports whether the platform call completed.
  Future<bool> tryCancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
      return true;
    } catch (e) {
      debugPrint('Error cancelling notification $id: $e');
      return false;
    }
  }
}
