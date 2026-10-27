import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'adhan_settings_service.dart';

/// Helper to build and resolve platform-specific [NotificationDetails] for prayer alarms and reminders.
class PrayerNotificationDetailsBuilder {
  /// Allows the longest bundled Adhan recording to finish before Android
  /// removes its prayer alert from the notification shade.
  static const int prayerNotificationTimeoutMs = 300000;

  const PrayerNotificationDetailsBuilder._();

  /// Resolves the user-facing localized mode label.
  static String modeLabel(PrayerNotificationMode mode) {
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

  /// Builds cross-platform [NotificationDetails] for a prayer notification.
  static NotificationDetails buildPrayerDetails({
    required PrayerNotificationMode mode,
    required AdhanSound sound,
    String? prayerName,
  }) {
    final android = buildAndroidPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final ios = buildDarwinPrayerDetails(
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

  /// Builds [AndroidNotificationDetails] for prayer notifications based on selected mode and sound.
  static AndroidNotificationDetails buildAndroidPrayerDetails({
    required PrayerNotificationMode mode,
    required AdhanSound sound,
    String? prayerName,
  }) {
    switch (mode) {
      case PrayerNotificationMode.adhan:
        final effectiveSound = (sound == AdhanSound.takbeer)
            ? AdhanSound.qatami
            : sound;
        final soundNameStr = soundName(effectiveSound);
        final channelId = channelIdForAdhan(effectiveSound);
        final channelName = channelNameForAdhan(effectiveSound);
        return AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'صوت الأذان عند دخول وقت الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          sound: RawResourceAndroidNotificationSound(soundNameStr),
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
          timeoutAfter: prayerNotificationTimeoutMs,
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
          timeoutAfter: prayerNotificationTimeoutMs,
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
        final rawSound = announcementRawSoundFor(prayerName);
        final channelId = announcementChannelIdFor(prayerName);
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
          timeoutAfter: prayerNotificationTimeoutMs,
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
          timeoutAfter: prayerNotificationTimeoutMs,
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
          timeoutAfter: prayerNotificationTimeoutMs,
        );
    }
  }

  /// Builds [DarwinNotificationDetails] for prayer notifications based on selected mode and sound.
  static DarwinNotificationDetails buildDarwinPrayerDetails({
    required PrayerNotificationMode mode,
    required AdhanSound sound,
    String? prayerName,
  }) {
    switch (mode) {
      case PrayerNotificationMode.adhan:
        final effectiveSound = (sound == AdhanSound.takbeer)
            ? AdhanSound.qatami
            : sound;
        return DarwinNotificationDetails(
          sound: '${soundName(effectiveSound)}.caf',
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );
      case PrayerNotificationMode.takbeer:
        return const DarwinNotificationDetails(
          sound: 'adhan_takbeer.caf',
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );
      case PrayerNotificationMode.announcement:
        final raw = announcementRawSoundFor(prayerName);
        return DarwinNotificationDetails(
          sound: '$raw.caf',
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

  /// Maps [AdhanSound] to raw resource sound asset file name.
  static String soundName(AdhanSound? sound) {
    final effectiveSound = (sound == null || sound == AdhanSound.takbeer)
        ? AdhanSound.qatami
        : sound;
    switch (effectiveSound) {
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
      case AdhanSound.makkah:
        return 'adhan_makkah';
      case AdhanSound.takbeer:
        return 'adhan_qatami';
    }
  }

  /// Maps [AdhanSound] to its dedicated Android channel identifier.
  static String channelIdForAdhan(AdhanSound sound) {
    final effectiveSound = (sound == AdhanSound.takbeer)
        ? AdhanSound.qatami
        : sound;
    switch (effectiveSound) {
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
      case AdhanSound.makkah:
        return 'talib_prayer_makkah_v3';
      case AdhanSound.takbeer:
        return 'talib_prayer_qatami_v3';
    }
  }

  /// Maps [AdhanSound] to its human-readable Arabic channel name.
  static String channelNameForAdhan(AdhanSound sound) {
    final effectiveSound = (sound == AdhanSound.takbeer)
        ? AdhanSound.qatami
        : sound;
    switch (effectiveSound) {
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
      case AdhanSound.makkah:
        return 'أذان مكة المكرمة (الشيخ علي ملا)';
      case AdhanSound.takbeer:
        return 'أذان الشيخ ناصر القطامي';
    }
  }

  /// Resolves raw sound filename for voice announcements by prayer name.
  static String announcementRawSoundFor(String? prayerName) {
    if (prayerName == null) return 'adhan_announcement_general';
    if (prayerName.contains('فجر')) return 'adhan_announcement_fajr';
    if (prayerName.contains('ظهر')) return 'adhan_announcement_dhuhr';
    if (prayerName.contains('عصر')) return 'adhan_announcement_asr';
    if (prayerName.contains('مغرب')) return 'adhan_announcement_maghrib';
    if (prayerName.contains('عشاء')) return 'adhan_announcement_isha';
    return 'adhan_announcement_general';
  }

  /// Resolves Android channel ID for voice announcements by prayer name.
  static String announcementChannelIdFor(String? prayerName) {
    if (prayerName == null) {
      return 'talib_prayer_announcement_general_v3';
    }
    if (prayerName.contains('فجر')) {
      return 'talib_prayer_announcement_fajr_v3';
    }
    if (prayerName.contains('ظهر')) {
      return 'talib_prayer_announcement_dhuhr_v3';
    }
    if (prayerName.contains('عصر')) {
      return 'talib_prayer_announcement_asr_v3';
    }
    if (prayerName.contains('مغرب')) {
      return 'talib_prayer_announcement_maghrib_v3';
    }
    if (prayerName.contains('عشاء')) {
      return 'talib_prayer_announcement_isha_v3';
    }
    return 'talib_prayer_announcement_general_v3';
  }
}
