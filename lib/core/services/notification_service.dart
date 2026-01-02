import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
    final linux = LinuxInitializationSettings(defaultActionName: 'Open');

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
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final mac = _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
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
    if (scheduledTime.isBefore(DateTime.now())) return;
    await init();

    final details = _buildDetails(
      playSound: playSound,
      sound: sound,
    );

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
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> _initTimeZones() async {
    if (_tzInitialized) return;
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _tzInitialized = true;
  }

  NotificationDetails _buildDetails({
    required bool playSound,
    AdhanSound? sound,
  }) {
    final android = _buildAndroidDetails(
      playSound: playSound,
      sound: sound,
    );
    final ios = _buildDarwinDetails(
      playSound: playSound,
      sound: sound,
    );
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
        'Prayer Times',
        channelDescription: 'Prayer time reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
      );
    }

    final soundName = _soundName(sound);
    return AndroidNotificationDetails(
      'prayer_times_$soundName',
      'Prayer Times',
      channelDescription: 'Prayer time reminders',
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
