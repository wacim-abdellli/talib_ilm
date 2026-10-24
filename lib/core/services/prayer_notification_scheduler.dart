import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'adhan_settings_service.dart';
import 'athkar_notification_scheduler.dart';
import 'prayer_notification_details_builder.dart';
import 'schedule_outcome.dart';

/// Handles prayer-specific notification scheduling, instant alerts, and cancellations.
class PrayerNotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;
  final Future<void> Function() _ensureInitialized;
  final Future<void> Function() _requestPermissions;
  final SafeZonedScheduleCallback _safeZonedSchedule;

  const PrayerNotificationScheduler({
    required FlutterLocalNotificationsPlugin plugin,
    required Future<void> Function() ensureInitialized,
    required Future<void> Function() requestPermissions,
    required SafeZonedScheduleCallback safeZonedSchedule,
  })  : _plugin = plugin,
        _ensureInitialized = ensureInitialized,
        _requestPermissions = requestPermissions,
        _safeZonedSchedule = safeZonedSchedule;

  /// Schedules a prayer notification according to the chosen mode (Adhan, Takbeer, Tone, Silent)
  /// using Android AlarmClock mode for guaranteed execution even during deep Doze.
  Future<ScheduleOutcome> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
    bool isJumua = false,
  }) async {
    if (mode == PrayerNotificationMode.off) return ScheduleOutcome.skippedPast;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return ScheduleOutcome.skippedPast;
    }
    if (scheduledTime.isBefore(DateTime.now())) return ScheduleOutcome.skippedPast;
    await _ensureInitialized();

    final details = PrayerNotificationDetailsBuilder.buildPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final cleanPrayerName = prayerName.replaceAll('صلاة ', '').trim();
    final isEffectiveJumua =
        isJumua || cleanPrayerName == 'الجمعة' || cleanPrayerName.contains('جمعة');
    final title = isEffectiveJumua
        ? 'حان الآن موعد أذان صلاة الجمعة'
        : 'حان الآن موعد أذان صلاة $cleanPrayerName';
    final body = isEffectiveJumua
        ? 'حي على الصلاة · حي على الفلاح · يَا أَيُّهَا الَّذِينَ آمَنُوا إِذَا نُودِيَ لِلصَّلَاةِ مِن يَوْمِ الْجُمُعَةِ فَاسْعَوْا إِلَىٰ ذِكْرِ اللَّهِ'
        : (cleanPrayerName.contains('فجر')
            ? 'الصلاة خيرٌ من النوم · حان وقت الصلاة'
            : 'حي على الصلاة · حي على الفلاح');

    return await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      scheduleMode: AndroidScheduleMode.alarmClock,
      payload: 'prayer_${prayerName.trim()}',
    );
  }

  /// Schedules an advance reminder (e.g. 15 minutes before) so the user can make wudhu and prepare.
  Future<ScheduleOutcome> schedulePrePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required int minutesBefore,
    bool isJumua = false,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return ScheduleOutcome.skippedPast;
    }
    if (scheduledTime.isBefore(DateTime.now())) return ScheduleOutcome.skippedPast;
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'talib_prayer_pre_reminder_v3',
      'تنبيهات اقتراب وقت الصلاة',
      channelDescription: 'تنبيه مسبق قبل دخول وقت الصلاة للاستعداد والوضوء',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: 'اقترب وقت الصلاة',
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

    final title = isJumua
        ? 'اقترب موعد صلاة الجمعة'
        : 'اقترب وقت صلاة $prayerName';
    final body = isJumua
        ? 'تبقى $minutesBefore دقيقة على أذان الجمعة.. تهيأ للغسل والتطيب والسواك وقراءة سورة الكهف والتبكير للمسجد'
        : 'تبقى $minutesBefore دقيقة على دخول وقت صلاة $prayerName.. تهيأ للصلاة وتوضأ';

    return await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      scheduleMode: AndroidScheduleMode.alarmClock,
      payload: 'prayer_pre_${prayerName.trim()}',
    );
  }

  /// Displays an instant heads-up advance reminder for foreground prayer detection.
  Future<void> showInstantPrePrayerNotification({
    required int id,
    required String prayerName,
    required int minutesBefore,
    bool isJumua = false,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'talib_prayer_pre_reminder_v3',
      'تنبيهات اقتراب وقت الصلاة',
      channelDescription: 'تنبيه مسبق قبل دخول وقت الصلاة للاستعداد والوضوء',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: 'اقترب وقت الصلاة',
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

    final title = isJumua
        ? 'اقترب موعد صلاة الجمعة'
        : 'اقترب وقت صلاة $prayerName';
    final body = isJumua
        ? 'تبقى $minutesBefore دقيقة على أذان الجمعة.. تهيأ للغسل والتطيب والسواك وقراءة سورة الكهف والتبكير للمسجد'
        : 'تبقى $minutesBefore دقيقة على دخول وقت صلاة $prayerName.. تهيأ للصلاة وتوضأ';

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: 'prayer_pre_${prayerName.trim()}',
    );
  }

  /// Schedules an Iqama notification after prayer time
  Future<ScheduleOutcome> scheduleIqamaNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    bool isJumua = false,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return ScheduleOutcome.skippedPast;
    }
    if (scheduledTime.isBefore(DateTime.now())) return ScheduleOutcome.skippedPast;
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'talib_prayer_iqama_v3',
      'تنبيهات إقامة الصلاة',
      channelDescription: 'تنبيه بحلول موعد إقامة الصلاة في المسجد',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: 'موعد إقامة الصلاة',
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

    final title = isJumua
        ? 'موعد خطبة وصلاة الجمعة'
        : 'موعد إقامة صلاة $prayerName';
    final body = isJumua
        ? 'حان الآن موعد خطبة وصلاة الجمعة المباركة.. استمع وأنصت للخطبة بخشوع'
        : 'حان الآن موعد إقامة صلاة $prayerName.. أقيمت الصلاة';

    return await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'iqama_${prayerName.trim()}',
    );
  }

  /// Schedules a dedicated reminder to recite Surat Al-Kahf on Friday
  Future<ScheduleOutcome> scheduleSurahAlKahfNotification({
    required int id,
    required DateTime scheduledTime,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return ScheduleOutcome.skippedPast;
    }
    if (scheduledTime.isBefore(DateTime.now())) return ScheduleOutcome.skippedPast;
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'talib_adhkar_reminders',
      'تذكير سورة الكهف يوم الجمعة',
      channelDescription: 'تذكير بقراءة سورة الكهف والصلاة على النبي ﷺ يوم الجمعة',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: 'سورة الكهف يوم الجمعة',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    const title = 'نور ما بين الجمعتين · سورة الكهف';
    const body =
        'قال ﷺ: «من قرأ سورة الكهف في يوم الجمعة أضاء له من النور ما بين الجمعتين» · لا تنسَ قراءتها والصلاة على النبي ﷺ';

    return await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'surah_18',
    );
  }

  /// Shows an instant prayer alert notification with heads-up alarm presentation
  Future<void> showInstantPrayerAlert({
    required int id,
    required String prayerName,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    await _ensureInitialized();

    final details = PrayerNotificationDetailsBuilder.buildPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final cleanPrayerName = prayerName.replaceAll('صلاة ', '').trim();
    final isJumua = cleanPrayerName == 'الجمعة' || cleanPrayerName.contains('جمعة');
    final title = isJumua
        ? 'حان الآن موعد أذان صلاة الجمعة'
        : 'حان الآن موعد أذان صلاة $cleanPrayerName';
    final body = cleanPrayerName.contains('فجر')
        ? 'الصلاة خيرٌ من النوم · حان وقت الصلاة'
        : 'حي على الصلاة · حي على الفلاح';

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: 'prayer_${prayerName.trim()}',
    );
  }

  /// Triggers an immediate test notification right now so the user can verify sound and alerts.
  Future<void> showInstantTestNotification({
    required String prayerName,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    await _ensureInitialized();
    await _requestPermissions();

    final details = PrayerNotificationDetailsBuilder.buildPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final title = 'حان الآن وقت صلاة $prayerName (إشعار تجريبي)';
    final body = prayerName.contains('فجر')
        ? 'الصلاة خير من النوم (النمط: ${PrayerNotificationDetailsBuilder.modeLabel(mode)})'
        : 'حي على الصلاة.. حي على الفلاح (النمط: ${PrayerNotificationDetailsBuilder.modeLabel(mode)})';

    await _plugin.show(
      9999,
      title,
      body,
      details,
      payload: 'prayer_test_${prayerName.trim()}',
    );
  }

  /// Schedules a test notification after [seconds] (e.g. 5 seconds)
  /// allowing the user to minimize the app or lock the screen to test outside the app.
  Future<void> scheduleTestNotificationAfter({
    required int seconds,
    required String prayerName,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    await _ensureInitialized();
    await _requestPermissions();

    final scheduledTime =
        DateTime.now().add(Duration(seconds: seconds)); // ui-lint: allow
    final details = PrayerNotificationDetailsBuilder.buildPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final title = 'حان الآن وقت صلاة $prayerName (تجربة خارج التطبيق)';
    final body = prayerName.contains('فجر')
        ? 'الصلاة خير من النوم (النمط: ${PrayerNotificationDetailsBuilder.modeLabel(mode)})'
        : 'حي على الصلاة.. حي على الفلاح (النمط: ${PrayerNotificationDetailsBuilder.modeLabel(mode)})';

    try {
      await _plugin.zonedSchedule(
        8888,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'prayer_test_${prayerName.trim()}',
      );
    } catch (e) {
      debugPrint('Error scheduling test notification with exact alarm: $e');
      // Direct timer fallback if exact alarms are restricted
      Future.delayed(Duration(seconds: seconds), () { // ui-lint: allow
        _plugin.show(
          8888,
          title,
          body,
          details,
          payload: 'prayer_test_${prayerName.trim()}',
        );
      });
    }
  }

  /// Legacy support
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
    await _ensureInitialized();

    final mode = playSound
        ? (sound == AdhanSound.takbeer ? PrayerNotificationMode.takbeer : PrayerNotificationMode.adhan)
        : PrayerNotificationMode.silent;

    final details = PrayerNotificationDetailsBuilder.buildPrayerDetails(
      mode: mode,
      sound: sound ?? AdhanSound.qatami,
    );

    await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Dismisses only the active in-progress heads-up prayer alerts and tone notifications (700..710, 750..760)
  /// without clearing any of the 7-day scheduled future prayer alarms.
  Future<void> cancelActivePrayerAlertsOnly() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    for (int i = 700; i <= 710; i++) {
      await _plugin.cancel(i);
    }
    for (int i = 750; i <= 760; i++) {
      await _plugin.cancel(i);
    }
    for (int i = 1000; i <= 1005; i++) {
      await _plugin.cancel(i);
    }
    for (int i = 100; i <= 105; i++) {
      await _plugin.cancel(i);
    }
  }

  /// Cancels all scheduled prayer-related notification slots across the 7-day rolling schedule,
  /// strictly preserving other notification categories like Athkar reminders (301, 302, 303),
  /// and preserving any actively sounding prayer notification IDs.
  Future<void> cancelPrayerNotificationsOnly({Set<int>? preserveIds}) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    // Cancel 7-day rolling schedule IDs:
    // Adhans: 1000..1605 (base: 1000 + d * 100 + i)
    // Pre-prayers: 2000..2605 (base: 2000 + d * 100 + i)
    // Iqamas: 3000..3605 (base: 3000 + d * 100 + i)
    // Friday Kahf: 4000..4600 (base: 4000 + d * 100)
    for (var d = 0; d < 7; d++) {
      for (var i = 0; i <= 5; i++) {
        final adhanId = 1000 + (d * 100) + i;
        if (preserveIds == null || !preserveIds.contains(adhanId)) {
          await _plugin.cancel(adhanId);
        }
        final preId = 2000 + (d * 100) + i;
        if (preserveIds == null || !preserveIds.contains(preId)) {
          await _plugin.cancel(preId);
        }
        final iqamaId = 3000 + (d * 100) + i;
        if (preserveIds == null || !preserveIds.contains(iqamaId)) {
          await _plugin.cancel(iqamaId);
        }
      }
      final kahfId = 4000 + (d * 100);
      if (preserveIds == null || !preserveIds.contains(kahfId)) {
        await _plugin.cancel(kahfId);
      }
    }

    // Cancel legacy IDs (100..299)
    for (int i = 100; i <= 299; i++) {
      if (preserveIds != null && preserveIds.contains(i)) continue;
      await _plugin.cancel(i);
    }
    // Cancel instant alert IDs (700..710)
    for (int i = 700; i <= 710; i++) {
      if (preserveIds != null && preserveIds.contains(i)) continue;
      await _plugin.cancel(i);
    }
    // Cancel instant pre-prayer alert IDs (750..760)
    for (int i = 750; i <= 760; i++) {
      if (preserveIds != null && preserveIds.contains(i)) continue;
      await _plugin.cancel(i);
    }
  }
}
