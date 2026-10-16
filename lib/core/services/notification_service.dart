import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../app/constants/app_strings.dart';
import 'adhan_service.dart';
import 'adhan_settings_service.dart';
import 'foreground_prayer_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _tzInitialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_initialized) return;
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
        }
      },
    );

    // Register all required high-priority notification channels in Android
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // ── Muezzin Full Adhan Channels (v3) ──────────────────────────────────
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_makkah_v3',
          'أذان مكة المكرمة (الشيخ علي ملا)',
          description: 'صوت أذان الحرم المكي الشريف عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_makkah'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_madinah_v3',
          'أذان المسجد النبوي الشريف',
          description: 'صوت أذان المدينة المنورة عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_madinah'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_alafasy_v3',
          'أذان الشيخ مشاري العفاسي',
          description: 'صوت أذان الشيخ مشاري العفاسي عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_alafasy'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_abdulbasit_v3',
          'أذان الشيخ عبد الباسط عبد الصمد',
          description: 'صوت أذان الشيخ عبد الباسط عبد الصمد عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_abdulbasit'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_qatami_v3',
          'أذان الشيخ ناصر القطامي',
          description: 'صوت أذان الشيخ ناصر القطامي عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_qatami'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_aqsa_v3',
          'أذان المسجد الأقصى (القدس الشريف)',
          description: 'صوت أذان المسجد الأقصى المبارك عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_aqsa'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );

      // ── Pure Takbeerat Channel (v3) ───────────────────────────────────────
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_takbeer_v3',
          'تكبيرات الأذان المباركة',
          description: 'تكبيرات الأذان فقط عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_takbeer'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );

      // ── Prayer-Specific Voice Announcement Channels (v3) ──────────────────
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_announcement_fajr_v3',
          'نداء صلاة الفجر (صوت)',
          description: 'نداء حان الآن وقت صلاة الفجر.. الصلاة خير من النوم',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_announcement_fajr'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_announcement_dhuhr_v3',
          'نداء صلاة الظهر (صوت)',
          description: 'نداء حان الآن وقت صلاة الظهر',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_announcement_dhuhr'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_announcement_asr_v3',
          'نداء صلاة العصر (صوت)',
          description: 'نداء حان الآن وقت صلاة العصر',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_announcement_asr'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_announcement_maghrib_v3',
          'نداء صلاة المغرب (صوت)',
          description: 'نداء حان الآن وقت صلاة المغرب',
          importance: Importance.max,
          sound:
              RawResourceAndroidNotificationSound('adhan_announcement_maghrib'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_announcement_isha_v3',
          'نداء صلاة العشاء (صوت)',
          description: 'نداء حان الآن وقت صلاة العشاء',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_announcement_isha'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_announcement_general_v3',
          'نداء وقت الصلاة (صوت)',
          description: 'نداء حان الآن وقت الصلاة',
          importance: Importance.max,
          sound:
              RawResourceAndroidNotificationSound('adhan_announcement_general'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );

      // ── Tone & Silent Channels (v3) ───────────────────────────────────────
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_tone_v3',
          'نغمة التنبيه الهادئة',
          description: 'نغمة هادئة عند دخول وقت الصلاة',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.notification,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_silent_v3',
          'تنبيه مرئي صامت',
          description: 'إشعار مرئي بدون صوت لمواقيت الصلاة',
          importance: Importance.high,
          playSound: false,
          enableVibration: false,
        ),
      );

      // ── Daily Adhkar Reminders Channel ────────────────────────────────────
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_adhkar_reminders',
          'تنبيهات الأذكار اليومية',
          description: 'تذكير بأذكار الصباح والمساء والنوم في أوقاتها المسنونة',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.notification,
        ),
      );
    }

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

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

  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required UILocalNotificationDateInterpretation
        uiLocalNotificationDateInterpretation,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
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
    } catch (e) {
      debugPrint(
        'Warning: Exact alarm restricted ($e). Falling back to inexact alarm for notification $id.',
      );
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              uiLocalNotificationDateInterpretation,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
      } catch (fallbackError) {
        debugPrint('Fallback inexact scheduling error ($id): $fallbackError');
      }
    }
  }

  /// Schedules a prayer notification according to the chosen mode (Adhan, Takbeer, Tone, Silent)
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
    bool isJumua = false,
  }) async {
    if (mode == PrayerNotificationMode.off) return;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    if (scheduledTime.isBefore(DateTime.now())) return;
    await init();

    final details = _buildPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final title = isJumua
        ? 'حان الآن موعد أذان صلاة الجمعة 🕌'
        : 'صلاة $prayerName';
    final body = isJumua
        ? 'حي على الصلاة · حي على الفلاح · يَا أَيُّهَا الَّذِينَ آمَنُوا إِذَا نُودِيَ لِلصَّلَاةِ مِن يَوْمِ الْجُمُعَةِ فَاسْعَوْا إِلَىٰ ذِكْرِ اللَّهِ'
        : (prayerName.contains('فجر')
            ? 'الصلاة خيرٌ من النوم · حان وقت الصلاة'
            : 'حي على الصلاة · حي على الفلاح');

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

  /// Schedules an advance reminder (e.g. 15 minutes before) so the user can make wudhu and prepare.
  Future<void> schedulePrePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required int minutesBefore,
    bool isJumua = false,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    if (scheduledTime.isBefore(DateTime.now())) return;
    await init();

    const androidDetails = AndroidNotificationDetails(
      'talib_prayer_tone_v3',
      'تنبيهات اقتراب وقت الصلاة',
      channelDescription: 'تنبيه مسبق قبل دخول وقت الصلاة للاستعداد والوضوء',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: 'اقترب وقت الصلاة',
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

    final title = isJumua
        ? 'اقترب موعد صلاة الجمعة 🕌'
        : 'اقترب وقت صلاة $prayerName';
    final body = isJumua
        ? 'تبقى $minutesBefore دقيقة على أذان الجمعة.. تهيأ للغسل والتطيب والسواك وقراءة سورة الكهف والتبكير للمسجد'
        : 'تبقى $minutesBefore دقيقة على دخول وقت صلاة $prayerName.. تهيأ للصلاة وتوضأ';

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

  /// Schedules an Iqama notification after prayer time
  Future<void> scheduleIqamaNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    bool isJumua = false,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    if (scheduledTime.isBefore(DateTime.now())) return;
    await init();

    const androidDetails = AndroidNotificationDetails(
      'talib_prayer_tone_v3',
      'تنبيهات إقامة الصلاة',
      channelDescription: 'تنبيه بحلول موعد إقامة الصلاة في المسجد',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: 'موعد إقامة الصلاة',
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

    final title = isJumua
        ? 'موعد خطبة وصلاة الجمعة 🕌'
        : 'موعد إقامة صلاة $prayerName';
    final body = isJumua
        ? 'حان الآن موعد خطبة وصلاة الجمعة المباركة.. استمع وأنصت للخطبة بخشوع'
        : 'حان الآن موعد إقامة صلاة $prayerName.. أقيمت الصلاة';

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

  /// Schedules a dedicated reminder to recite Surat Al-Kahf on Friday
  Future<void> scheduleSurahAlKahfNotification({
    required int id,
    required DateTime scheduledTime,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    if (scheduledTime.isBefore(DateTime.now())) return;
    await init();

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

    const title = 'نور ما بين الجمعتين 📖 · سورة الكهف';
    const body =
        'قال ﷺ: «من قرأ سورة الكهف في يوم الجمعة أضاء له من النور ما بين الجمعتين» · لا تنسَ قراءتها والصلاة على النبي ﷺ';

    await _safeZonedSchedule(
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
    await init();

    final details = _buildPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final title = 'صلاة $prayerName';
    final body = prayerName.contains('فجر')
        ? 'الصلاة خيرٌ من النوم · حان وقت الصلاة'
        : 'حي على الصلاة · حي على الفلاح';

    await _plugin.show(
      id,
      title,
      body,
      details,
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
    await init();
    await requestPermissions();

    final details = _buildPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final title = 'حان الآن وقت صلاة $prayerName (إشعار تجريبي)';
    final body = prayerName.contains('فجر')
        ? 'الصلاة خير من النوم (النمط: ${_modeLabel(mode)})'
        : 'حي على الصلاة.. حي على الفلاح (النمط: ${_modeLabel(mode)})';

    await _plugin.show(
      9999,
      title,
      body,
      details,
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
    await init();
    await requestPermissions();

    final scheduledTime =
        DateTime.now().add(Duration(seconds: seconds)); // ui-lint: allow
    final details = _buildPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final title = 'حان الآن وقت صلاة $prayerName (تجربة خارج التطبيق)';
    final body = prayerName.contains('فجر')
        ? 'الصلاة خير من النوم (النمط: ${_modeLabel(mode)})'
        : 'حي على الصلاة.. حي على الفلاح (النمط: ${_modeLabel(mode)})';

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
      );
    } catch (e) {
      debugPrint('Error scheduling test notification with exact alarm: $e');
      // Direct timer fallback if exact alarms are restricted
      Future.delayed(Duration(seconds: seconds), () { // ui-lint: allow
        _plugin.show(8888, title, body, details);
      });
    }
  }

  String _modeLabel(PrayerNotificationMode mode) {
    switch (mode) {
      case PrayerNotificationMode.adhan:
        return 'أذان كامل';
      case PrayerNotificationMode.takbeer:
        return 'تكبيرات فقط';
      case PrayerNotificationMode.announcement:
        return 'نداء وقت الصلاة';
      case PrayerNotificationMode.tone:
        return 'نغمة هادئة';
      case PrayerNotificationMode.silent:
        return 'إشعار صامت';
      case PrayerNotificationMode.off:
        return 'إيقاف';
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
    await init();

    final mode = playSound
        ? (sound == AdhanSound.takbeer ? PrayerNotificationMode.takbeer : PrayerNotificationMode.adhan)
        : PrayerNotificationMode.silent;

    final details = _buildPrayerDetails(mode: mode, sound: sound ?? AdhanSound.qatami);

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

  Future<void> cancelAll() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    await _plugin.cancelAll();
  }

  /// Cancels only prayer-related notification slots (IDs 100-299 and 700-799),
  /// strictly preserving other notification categories like Athkar reminders (301, 302, 303).
  Future<void> cancelPrayerNotificationsOnly() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    // Cancel today & tomorrow prayer, pre-prayer, and iqama IDs (100..299)
    for (int i = 100; i <= 299; i++) {
      await _plugin.cancel(i);
    }
    // Cancel instant alert IDs (700..710)
    for (int i = 700; i <= 710; i++) {
      await _plugin.cancel(i);
    }
  }

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
        final offset = DateTime.now().timeZoneOffset;
        final matching = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) => loc.currentTimeZone.offset == offset.inMilliseconds,
          orElse: () => tz.getLocation('UTC'),
        );
        tz.setLocalLocation(matching);
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    _tzInitialized = true;
  }

  NotificationDetails _buildPrayerDetails({
    required PrayerNotificationMode mode,
    required AdhanSound sound,
    String? prayerName,
  }) {
    final android = _buildAndroidPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final ios = _buildDarwinPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    return NotificationDetails(
      android: android,
      iOS: ios,
      macOS: ios,
      linux: const LinuxNotificationDetails(),
    );
  }

  AndroidNotificationDetails _buildAndroidPrayerDetails({
    required PrayerNotificationMode mode,
    required AdhanSound sound,
    String? prayerName,
  }) {
    switch (mode) {
      case PrayerNotificationMode.adhan:
        final soundName = _soundName(sound);
        final channelId = _channelIdForAdhan(sound);
        final channelName = _channelNameForAdhan(sound);
        return AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'صوت الأذان عند دخول وقت الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          sound: RawResourceAndroidNotificationSound(soundName),
          playSound: true,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ticker: 'صلاة $prayerName',
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              'stop_adhan',
              'إيقاف الأذان',
              cancelNotification: true,
              showsUserInterface: false,
            ),
          ],
        );
      case PrayerNotificationMode.takbeer:
        return AndroidNotificationDetails(
          'talib_prayer_takbeer_v3',
          'تكبيرات الأذان المباركة',
          channelDescription: 'تكبيرات الأذان فقط عند دخول وقت الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          sound: const RawResourceAndroidNotificationSound('adhan_takbeer'),
          playSound: true,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ticker: 'صلاة $prayerName',
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              'stop_adhan',
              'إيقاف التكبيرات',
              cancelNotification: true,
              showsUserInterface: false,
            ),
          ],
        );
      case PrayerNotificationMode.announcement:
        final rawSound = _announcementRawSoundFor(prayerName);
        final channelId = _announcementChannelIdFor(prayerName);
        final channelTitle = prayerName != null
            ? 'نداء صلاة $prayerName'
            : 'نداء وقت الصلاة';
        return AndroidNotificationDetails(
          channelId,
          channelTitle,
          channelDescription: 'نداء صوتي عند دخول وقت الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          sound: RawResourceAndroidNotificationSound(rawSound),
          playSound: true,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ticker: 'صلاة $prayerName',
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              'stop_adhan',
              'إيقاف النداء',
              cancelNotification: true,
              showsUserInterface: false,
            ),
          ],
        );
      case PrayerNotificationMode.tone:
        return const AndroidNotificationDetails(
          'talib_prayer_tone_v3',
          'نغمة التنبيه الهادئة',
          channelDescription: 'نغمة هادئة عند دخول وقت الصلاة',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.notification,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );
      case PrayerNotificationMode.silent:
      case PrayerNotificationMode.off:
        return const AndroidNotificationDetails(
          'talib_prayer_silent_v3',
          'تنبيه مرئي صامت',
          channelDescription: 'إشعار مرئي بدون صوت لمواقيت الصلاة',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );
    }
  }

  DarwinNotificationDetails _buildDarwinPrayerDetails({
    required PrayerNotificationMode mode,
    required AdhanSound sound,
    String? prayerName,
  }) {
    switch (mode) {
      case PrayerNotificationMode.adhan:
        return DarwinNotificationDetails(
          sound: '${_soundName(sound)}.mp3',
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );
      case PrayerNotificationMode.takbeer:
        return const DarwinNotificationDetails(
          sound: 'adhan_takbeer.mp3',
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );
      case PrayerNotificationMode.announcement:
        final raw = _announcementRawSoundFor(prayerName);
        return DarwinNotificationDetails(
          sound: '$raw.mp3',
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );
      case PrayerNotificationMode.tone:
        return const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
        );
      case PrayerNotificationMode.silent:
      case PrayerNotificationMode.off:
        return const DarwinNotificationDetails(
          presentSound: false,
          presentAlert: true,
          presentBadge: false,
        );
    }
  }

  String _soundName(AdhanSound? sound) {
    switch (sound) {
      case AdhanSound.madinah:
        return 'adhan_madinah';
      case AdhanSound.alafasy:
        return 'adhan_alafasy';
      case AdhanSound.abdulbasit:
        return 'adhan_abdulbasit';
      case AdhanSound.qatami:
        return 'adhan_qatami';
      case AdhanSound.aqsa:
        return 'adhan_aqsa';
      case AdhanSound.takbeer:
        return 'adhan_takbeer';
      case AdhanSound.makkah:
        return 'adhan_makkah';
      default:
        return 'adhan_qatami';
    }
  }

  String _channelIdForAdhan(AdhanSound sound) {
    switch (sound) {
      case AdhanSound.madinah:
        return 'talib_prayer_madinah_v3';
      case AdhanSound.alafasy:
        return 'talib_prayer_alafasy_v3';
      case AdhanSound.abdulbasit:
        return 'talib_prayer_abdulbasit_v3';
      case AdhanSound.qatami:
        return 'talib_prayer_qatami_v3';
      case AdhanSound.aqsa:
        return 'talib_prayer_aqsa_v3';
      case AdhanSound.takbeer:
      case AdhanSound.makkah:
        return 'talib_prayer_makkah_v3';
    }
  }

  String _channelNameForAdhan(AdhanSound sound) {
    switch (sound) {
      case AdhanSound.madinah:
        return 'أذان المسجد النبوي الشريف';
      case AdhanSound.alafasy:
        return 'أذان الشيخ مشاري العفاسي';
      case AdhanSound.abdulbasit:
        return 'أذان الشيخ عبد الباسط عبد الصمد';
      case AdhanSound.qatami:
        return 'أذان الشيخ ناصر القطامي';
      case AdhanSound.aqsa:
        return 'أذان المسجد الأقصى (القدس الشريف)';
      case AdhanSound.takbeer:
      case AdhanSound.makkah:
        return 'أذان مكة المكرمة (الشيخ علي ملا)';
    }
  }

  String _announcementRawSoundFor(String? prayerName) {
    if (prayerName == null) return 'adhan_announcement_general';
    if (prayerName.contains('فجر')) return 'adhan_announcement_fajr';
    if (prayerName.contains('ظهر')) return 'adhan_announcement_dhuhr';
    if (prayerName.contains('عصر')) return 'adhan_announcement_asr';
    if (prayerName.contains('مغرب')) return 'adhan_announcement_maghrib';
    if (prayerName.contains('عشاء')) return 'adhan_announcement_isha';
    return 'adhan_announcement_general';
  }

  String _announcementChannelIdFor(String? prayerName) {
    if (prayerName == null) return 'talib_prayer_announcement_general_v3';
    if (prayerName.contains('فجر')) return 'talib_prayer_announcement_fajr_v3';
    if (prayerName.contains('ظهر')) return 'talib_prayer_announcement_dhuhr_v3';
    if (prayerName.contains('عصر')) return 'talib_prayer_announcement_asr_v3';
    if (prayerName.contains('مغرب')) return 'talib_prayer_announcement_maghrib_v3';
    if (prayerName.contains('عشاء')) return 'talib_prayer_announcement_isha_v3';
    return 'talib_prayer_announcement_general_v3';
  }

  /// Schedules a repeating daily notification for Morning, Evening, or Sleep Adhkar.
  Future<void> scheduleDailyAdhkarNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    await init();
    await requestPermissions();

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

    const androidDetails = AndroidNotificationDetails(
      'talib_adhkar_reminders',
      'تنبيهات الأذكار اليومية',
      channelDescription: 'تذكير بأذكار الصباح والمساء والنوم في أوقاتها المسنونة',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: 'أذكار المسلم',
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

    await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Cancels a specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification $id: $e');
    }
  }
}

