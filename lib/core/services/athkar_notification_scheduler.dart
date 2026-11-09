import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/theme/app_colors.dart';
import 'schedule_outcome.dart';

typedef SafeZonedScheduleCallback =
    Future<ScheduleOutcome> Function({
      required int id,
      required String title,
      required String body,
      required tz.TZDateTime scheduledDate,
      required NotificationDetails notificationDetails,
      required UILocalNotificationDateInterpretation
      uiLocalNotificationDateInterpretation,
      DateTimeComponents? matchDateTimeComponents,
      String? payload,
      AndroidScheduleMode scheduleMode,
    });

/// Handles scheduling for recurring daily Athkar and Sunnah fasting reminders.
class AthkarNotificationScheduler {
  final Future<void> Function() _ensureInitialized;
  final SafeZonedScheduleCallback _safeZonedSchedule;

  const AthkarNotificationScheduler({
    required Future<void> Function() ensureInitialized,
    required SafeZonedScheduleCallback safeZonedSchedule,
  }) : _ensureInitialized = ensureInitialized,
       _safeZonedSchedule = safeZonedSchedule;

  /// Schedules a repeating daily notification for Morning, Evening, or Sleep Adhkar.
  Future<ScheduleOutcome> scheduleDailyAdhkarNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return ScheduleOutcome.skippedPast;
    }
    await _ensureInitialized();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final timeoutMs = (id == 301)
        ? 4 * 60 * 60 * 1000
        : (id == 302 ? 5 * 60 * 60 * 1000 : 8 * 60 * 60 * 1000);
    final androidDetails = AndroidNotificationDetails(
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
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: AppColors.notificationAccent,
      ticker: 'أذكار المسلم',
      timeoutAfter: timeoutMs,
      showWhen: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    return await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<ScheduleOutcome> scheduleAdhkarTestNotification({
    required int id,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return ScheduleOutcome.skippedPast;
    }
    await _ensureInitialized();
    final android = AndroidNotificationDetails(
      'talib_adhkar_reminders',
      'تنبيهات الأذكار اليومية',
      channelDescription: 'تذكير بالأذكار التي يختارها المستخدم',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
      color: AppColors.notificationAccent,
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return _safeZonedSchedule(
      id: id,
      title: 'اختبار لحظة ذكر',
      body: 'إذا وصل هذا التنبيه بعد إغلاق التطبيق، فالتذكيرات تعمل على جهازك.',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'dhikr_moment',
      scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedules a notification for Sunnah Fasting (White Days / Monday / Thursday).
  Future<ScheduleOutcome> scheduleFastingReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return ScheduleOutcome.skippedPast;
    }
    if (scheduledDate.isBefore(DateTime.now())) {
      return ScheduleOutcome.skippedPast;
    }
    await _ensureInitialized();

    final androidDetails = AndroidNotificationDetails(
      'talib_fasting_reminders',
      'تنبيهات صيام السنن والأيام البيض',
      channelDescription:
          'تذكير مسنون بصيام الأيام البيض والإثنين والخميس في موعدها',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: AppColors.notificationAccent,
      ticker: 'صيام السنن',
      timeoutAfter: 4 * 60 * 60 * 1000,
      when: scheduledDate.millisecondsSinceEpoch,
      showWhen: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    return await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }
}
