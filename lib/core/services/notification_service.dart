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

    await _plugin.initialize(settings);

    // Register all required high-priority notification channels in Android
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // ── Muezzin Full Adhan Channels ──────────────────────────────────────
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_makkah_v1',
          'أذان مكة المكرمة (الشيخ علي ملا)',
          description: 'صوت أذان الحرم المكي الشريف عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_makkah'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_madinah_v1',
          'أذان المسجد النبوي الشريف',
          description: 'صوت أذان المدينة المنورة عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_madinah'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_alafasy_v1',
          'أذان الشيخ مشاري العفاسي',
          description: 'صوت أذان الشيخ مشاري العفاسي عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_alafasy'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_abdulbasit_v1',
          'أذان الشيخ عبد الباسط عبد الصمد',
          description: 'صوت أذان الشيخ عبد الباسط عبد الصمد عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_abdulbasit'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_qatami_v1',
          'أذان الشيخ ناصر القطامي',
          description: 'صوت أذان الشيخ ناصر القطامي عند دخول وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_qatami'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );

      // ── Prayer-Specific Takbeer & Announcement Channels ───────────────────
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_takbeer_fajr_v1',
          'تنبيه صلاة الفجر (تكبير وصوت)',
          description: 'تكبير وتنبيه حان الآن وقت صلاة الفجر',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_takbeer_fajr'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_takbeer_dhuhr_v1',
          'تنبيه صلاة الظهر (تكبير وصوت)',
          description: 'تكبير وتنبيه حان الآن وقت صلاة الظهر',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_takbeer_dhuhr'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_takbeer_asr_v1',
          'تنبيه صلاة العصر (تكبير وصوت)',
          description: 'تكبير وتنبيه حان الآن وقت صلاة العصر',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_takbeer_asr'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_takbeer_maghrib_v1',
          'تنبيه صلاة المغرب (تكبير وصوت)',
          description: 'تكبير وتنبيه حان الآن وقت صلاة المغرب',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_takbeer_maghrib'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_takbeer_isha_v1',
          'تنبيه صلاة العشاء (تكبير وصوت)',
          description: 'تكبير وتنبيه حان الآن وقت صلاة العشاء',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_takbeer_isha'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_takbeer_v1',
          'تكبيرات الصلاة العامة',
          description: 'تكبيرات الأذان وتنبيه حان وقت الصلاة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_takbeer'),
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );

      // ── Tone & Silent Channels ──────────────────────────────────────────
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_tone_v1',
          'نغمة التنبيه الهادئة',
          description: 'نغمة هادئة عند دخول وقت الصلاة',
          importance: Importance.high,
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.notification,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'talib_prayer_silent_v1',
          'تنبيه مرئي صامت',
          description: 'إشعار مرئي بدون صوت لمواقيت الصلاة',
          importance: Importance.high,
          playSound: false,
          enableVibration: false,
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

  /// Schedules a prayer notification according to the chosen mode (Adhan, Takbeer, Tone, Silent)
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.makkah,
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
    final title = 'حان الآن وقت صلاة $prayerName';
    final body = prayerName.contains('فجر')
        ? 'الصلاة خير من النوم.. حي على الصلاة'
        : 'حي على الصلاة.. حي على الفلاح';

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
      debugPrint('Error scheduling prayer notification ($prayerName): $e');
    }
  }

  /// Triggers an immediate test notification right now so the user can verify sound and alerts.
  Future<void> showInstantTestNotification({
    required String prayerName,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.makkah,
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
    AdhanSound sound = AdhanSound.makkah,
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
        return 'تكبيرات وتنبيه موجز';
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

    final details = _buildPrayerDetails(mode: mode, sound: sound ?? AdhanSound.makkah);

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
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
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
        );
      case PrayerNotificationMode.takbeer:
        final rawSound = _takbeerRawSoundFor(prayerName);
        final channelId = _takbeerChannelIdFor(prayerName);
        final channelTitle = prayerName != null
            ? 'تنبيه صلاة $prayerName'
            : 'تكبيرات الصلاة';
        return AndroidNotificationDetails(
          channelId,
          channelTitle,
          channelDescription: 'تكبيرات الأذان وتنبيه حان وقت صلاة $prayerName',
          importance: Importance.max,
          priority: Priority.max,
          sound: RawResourceAndroidNotificationSound(rawSound),
          playSound: true,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );
      case PrayerNotificationMode.tone:
        return const AndroidNotificationDetails(
          'talib_prayer_tone_v1',
          'نغمة التنبيه الهادئة',
          channelDescription: 'نغمة هادئة عند دخول وقت الصلاة',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.notification,
        );
      case PrayerNotificationMode.silent:
      case PrayerNotificationMode.off:
        return const AndroidNotificationDetails(
          'talib_prayer_silent_v1',
          'تنبيه مرئي صامت',
          channelDescription: 'إشعار مرئي بدون صوت لمواقيت الصلاة',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
          visibility: NotificationVisibility.public,
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
        );
      case PrayerNotificationMode.takbeer:
        final raw = _takbeerRawSoundFor(prayerName);
        return DarwinNotificationDetails(
          sound: '$raw.mp3',
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
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
      case AdhanSound.takbeer:
        return 'adhan_takbeer';
      case AdhanSound.makkah:
      default:
        return 'adhan_makkah';
    }
  }

  String _channelIdForAdhan(AdhanSound sound) {
    switch (sound) {
      case AdhanSound.madinah:
        return 'talib_prayer_madinah_v1';
      case AdhanSound.alafasy:
        return 'talib_prayer_alafasy_v1';
      case AdhanSound.abdulbasit:
        return 'talib_prayer_abdulbasit_v1';
      case AdhanSound.qatami:
        return 'talib_prayer_qatami_v1';
      case AdhanSound.takbeer:
      case AdhanSound.makkah:
        return 'talib_prayer_makkah_v1';
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
      case AdhanSound.takbeer:
      case AdhanSound.makkah:
        return 'أذان مكة المكرمة (الشيخ علي ملا)';
    }
  }

  String _takbeerRawSoundFor(String? prayerName) {
    if (prayerName == null) return 'adhan_takbeer';
    if (prayerName.contains('فجر')) return 'adhan_takbeer_fajr';
    if (prayerName.contains('ظهر')) return 'adhan_takbeer_dhuhr';
    if (prayerName.contains('عصر')) return 'adhan_takbeer_asr';
    if (prayerName.contains('مغرب')) return 'adhan_takbeer_maghrib';
    if (prayerName.contains('عشاء')) return 'adhan_takbeer_isha';
    return 'adhan_takbeer';
  }

  String _takbeerChannelIdFor(String? prayerName) {
    if (prayerName == null) return 'talib_prayer_takbeer_v1';
    if (prayerName.contains('فجر')) return 'talib_prayer_takbeer_fajr_v1';
    if (prayerName.contains('ظهر')) return 'talib_prayer_takbeer_dhuhr_v1';
    if (prayerName.contains('عصر')) return 'talib_prayer_takbeer_asr_v1';
    if (prayerName.contains('مغرب')) return 'talib_prayer_takbeer_maghrib_v1';
    if (prayerName.contains('عشاء')) return 'talib_prayer_takbeer_isha_v1';
    return 'talib_prayer_takbeer_v1';
  }
}
