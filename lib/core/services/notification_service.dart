import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../app/constants/app_strings.dart';
import 'adhan_settings_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _tzInitialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_initialized) return;
    await _initTimeZones();

    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final linux = const LinuxInitializationSettings(
      defaultActionName: AppStrings.notificationDefaultAction,
    );

    final settings = InitializationSettings(
      android: android,
      iOS: ios,
      macOS: ios,
      linux: linux,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final mac = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await mac?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool playSound,
    AdhanSound? sound,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    if (scheduledTime.isBefore(DateTime.now())) return;
    await init();

    final details = _buildDetails(playSound: playSound, sound: sound);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> _initTimeZones() async {
    if (_tzInitialized) return;
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    _tzInitialized = true;
  }

  NotificationDetails _buildDetails({
    required bool playSound,
    AdhanSound? sound,
  }) {
    final android = _buildAndroidDetails(playSound: playSound, sound: sound);
    final ios = _buildDarwinDetails(playSound: playSound, sound: sound);
    return NotificationDetails(
      android: android,
      iOS: ios,
      macOS: ios,
      linux: const LinuxNotificationDetails(),
    );
  }

  AndroidNotificationDetails _buildAndroidDetails({
    required bool playSound,
    AdhanSound? sound,
  }) {
    if (!playSound) {
      return const AndroidNotificationDetails(
        'prayer_times_silent',
        AppStrings.notificationChannelName,
        channelDescription: AppStrings.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
      );
    }

    final soundName = _soundName(sound);
    return AndroidNotificationDetails(
      'prayer_times_$soundName',
      AppStrings.notificationChannelName,
      channelDescription: AppStrings.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(soundName),
      playSound: true,
    );
  }

  DarwinNotificationDetails _buildDarwinDetails({
    required bool playSound,
    AdhanSound? sound,
  }) {
    if (!playSound) {
      return const DarwinNotificationDetails(presentSound: false);
    }

    return DarwinNotificationDetails(
      sound: '${_soundName(sound)}.mp3',
      presentSound: true,
    );
  }

  String _soundName(AdhanSound? sound) {
    switch (sound) {
      case AdhanSound.madinah:
        return 'adhan_madinah';
      case AdhanSound.makkah:
      default:
        return 'adhan_makkah';
    }
  }
}
