import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Registers all Android notification channels used across the application.
class NotificationChannelManager {
  const NotificationChannelManager._();

  /// Creates and configures all required high-priority notification channels.
  static Future<void> registerChannels(
    AndroidFlutterLocalNotificationsPlugin androidPlugin,
  ) async {
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

    // ── Dedicated Pre-Prayer Advance Reminder Channel (v3) ───────────────
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'talib_prayer_pre_reminder_v3',
        'تنبيهات اقتراب وقت الصلاة',
        description: 'تنبيه مسبق قبل دخول وقت الصلاة للاستعداد والوضوء',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
    );

    // ── Dedicated Iqama Channel (v3) ─────────────────────────────────────
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'talib_prayer_iqama_v3',
        'تنبيهات إقامة الصلاة',
        description: 'تنبيه بحلول موعد إقامة الصلاة في المسجد',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
    );

    // ── Tone & Silent Channels (v3) ───────────────────────────────────────
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'talib_prayer_tone_v3',
        'نغمة التنبيه الهادئة',
        description: 'نغمة هادئة عند دخول وقت الصلاة',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
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
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
    );

    // ── Sunnah Fasting Reminders Channel ──────────────────────────────────
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'talib_fasting_reminders',
        'تنبيهات صيام السنن والأيام البيض',
        description: 'تذكير مسنون بصيام الأيام البيض والإثنين والخميس في موعدها',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
    );
  }
}
