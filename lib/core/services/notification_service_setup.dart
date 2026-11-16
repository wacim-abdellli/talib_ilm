part of 'notification_service.dart';

tz.Location? _findLocationByOffsetImpl(int offsetMinutes) {
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

extension _NotificationServiceSetupHandlers on NotificationService {
  Future<bool> _arePermissionsGrantedImpl() async {
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

  Future<bool?> _canScheduleExactNotificationsImpl() async {
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

  Future<NotificationDeliveryHealth> _getDeliveryHealthImpl(
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
    final requiredChannels = <String>{'talib_adhkar_reminders'};
    final soundChannels = <String>{'talib_adhkar_reminders'};

    if (settings.enabled) {
      for (final prayerName in AdhanSettingsService.prayerNames) {
        if (prayerName.contains('الشروق')) continue;
        final mode = settings.modeForPrayer(prayerName);
        final channelId = switch (mode) {
          PrayerNotificationMode.adhan =>
            PrayerNotificationDetailsBuilder.channelIdForAdhan(
              settings.effectiveMuezzinSound,
            ),
          PrayerNotificationMode.maryamAyah =>
            PrayerNotificationDetailsBuilder.channelIdForAdhan(
              AdhanSound.maryamAyah,
            ),
          PrayerNotificationMode.takbeer => 'talib_prayer_takbeer_v4',
          PrayerNotificationMode.announcement =>
            PrayerNotificationDetailsBuilder.announcementChannelIdFor(
              prayerName,
            ),
          PrayerNotificationMode.tone => 'talib_prayer_tone_v4',
          PrayerNotificationMode.silent => 'talib_prayer_silent_v4',
          PrayerNotificationMode.off => null,
        };
        if (channelId == null) continue;
        requiredChannels.add(channelId);
        if (mode != PrayerNotificationMode.silent) {
          soundChannels.add(channelId);
        }
      }
      if (settings.notifyBeforeMinutes > 0) {
        requiredChannels.add('talib_prayer_pre_reminder_v4');
        soundChannels.add('talib_prayer_pre_reminder_v4');
      }
      if (settings.iqamaReminders) {
        requiredChannels.add('talib_prayer_iqama_v4');
        soundChannels.add('talib_prayer_iqama_v4');
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

  Future<void> _requestPermissionsImpl() async {
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

  Future<void> _initTimeZonesImpl() async {
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
          final matched = NotificationService.findLocationByOffset(offsetMinutes);
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
}
