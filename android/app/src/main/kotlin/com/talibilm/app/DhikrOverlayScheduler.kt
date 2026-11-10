package com.talibilm.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.provider.Settings
import java.util.Calendar
import kotlin.math.roundToInt

object DhikrOverlayScheduler {
    const val ALARM_REQUEST_CODE = 8491
    private const val PREFS_FILE = "FlutterSharedPreferences"

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)

    fun readInt(prefs: SharedPreferences, key: String, fallback: Int): Int =
        (prefs.all["flutter.$key"] as? Number)?.toInt() ?: fallback

    fun readLong(prefs: SharedPreferences, key: String, fallback: Long): Long =
        (prefs.all["flutter.$key"] as? Number)?.toLong() ?: fallback

    fun isEnabled(prefs: SharedPreferences): Boolean =
        prefs.getBoolean("flutter.dhikr_moment_enabled", false)

    /**
     * Computes the target interval between Dhikr cards during active phone usage.
     * Because typical active screen-on time is ~3.5-4.5 hours/day (not 14 continuous hours),
     * pacing against active screen usage ensures a user who selects 50 dhikrs/day sees
     * a Dhikr card roughly every ~5 minutes of active phone use.
     */
    fun computeActiveIntervalMs(prefs: SharedPreferences): Long {
        val count = readInt(prefs, "dhikr_moment_times_per_day", 20).coerceIn(1, 50)
        val intervalSeconds = when {
            count >= 50 -> 80L      // ~1.3 min of active use
            count >= 40 -> 110L     // ~1.8 min
            count >= 30 -> 150L     // 2.5 min
            count >= 20 -> 240L     // 4 min
            count >= 10 -> 420L     // 7 min
            else -> 600L            // 10 min
        }
        return intervalSeconds * 1000L
    }

    /**
     * Minimum cooldown before showing a Dhikr card right as the user unlocks their phone.
     */
    fun computeUnlockCooldownMs(prefs: SharedPreferences): Long {
        val count = readInt(prefs, "dhikr_moment_times_per_day", 20).coerceIn(1, 50)
        val seconds = when {
            count >= 50 -> 20L
            count >= 30 -> 35L
            count >= 20 -> 50L
            else -> 90L
        }
        return seconds * 1000L
    }

    fun isWithinTimeWindow(
        prefs: SharedPreferences,
        now: Calendar = Calendar.getInstance(),
        isInteractiveActiveUse: Boolean = false,
    ): Boolean {
        // Active interactive phone usage ALWAYS takes priority over quiet hours.
        // A user actively interacting with their unlocked phone is awake.
        if (isInteractiveActiveUse) return true

        val start = readInt(prefs, "dhikr_moment_start_minutes", 0).coerceIn(0, 1439)
        val end = readInt(prefs, "dhikr_moment_end_minutes", 1440).coerceIn(1, 1440)
        if (start == 0 && end >= 1440) return true

        val nowMinute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        return if (end > start) {
            nowMinute in start..end
        } else {
            nowMinute >= start || nowMinute <= end
        }
    }

    private fun todayKey(now: Calendar = Calendar.getInstance()): Int =
        now.get(Calendar.YEAR) * 10000 +
            (now.get(Calendar.MONTH) + 1) * 100 +
            now.get(Calendar.DAY_OF_MONTH)

    fun canShowMoreToday(
        prefs: SharedPreferences,
        now: Calendar = Calendar.getInstance(),
    ): Boolean {
        val key = todayKey(now)
        val savedKey = readInt(prefs, "dhikr_moment_day_key", 0)
        val shownToday = if (savedKey == key) {
            readInt(prefs, "dhikr_moment_shown_today", 0)
        } else {
            0
        }
        val maxPerDay = readInt(prefs, "dhikr_moment_times_per_day", 20).coerceIn(1, 50)
        return shownToday < (maxPerDay * 3)
    }

    fun recordShownNow(
        prefs: SharedPreferences,
        now: Calendar = Calendar.getInstance(),
    ) {
        val key = todayKey(now)
        val savedKey = readInt(prefs, "dhikr_moment_day_key", 0)
        val prevCount = if (savedKey == key) {
            readInt(prefs, "dhikr_moment_shown_today", 0)
        } else {
            0
        }
        prefs.edit()
            .putLong("flutter.dhikr_moment_day_key", key.toLong())
            .putLong("flutter.dhikr_moment_shown_today", (prevCount + 1).toLong())
            .putLong("flutter.dhikr_moment_last_shown_epoch_ms", System.currentTimeMillis())
            .putBoolean("flutter.dhikr_moment_pending_on_unlock", false)
            .apply()
    }

    fun markPendingOnUnlock(prefs: SharedPreferences) {
        if (isWithinTimeWindow(prefs) && canShowMoreToday(prefs)) {
            prefs.edit()
                .putBoolean("flutter.dhikr_moment_pending_on_unlock", true)
                .apply()
        }
    }

    fun resetForImmediateSession(context: Context) {
        prefs(context).edit()
            .putLong("flutter.dhikr_moment_last_shown_epoch_ms", 0L)
            .putBoolean("flutter.dhikr_moment_pending_on_unlock", true)
            .apply()
    }

    fun isDueNow(
        prefs: SharedPreferences,
        isUnlockEvent: Boolean = false,
        isInteractiveActiveUse: Boolean = false,
    ): Boolean {
        if (!isEnabled(prefs)) return false
        if (!isWithinTimeWindow(prefs, isInteractiveActiveUse = isInteractiveActiveUse)) return false
        if (!canShowMoreToday(prefs)) return false

        val lastShownMs = readLong(prefs, "dhikr_moment_last_shown_epoch_ms", 0L)
        val pendingOnUnlock = prefs.getBoolean("flutter.dhikr_moment_pending_on_unlock", false)
        if (lastShownMs <= 0L || pendingOnUnlock) return true

        val elapsed = System.currentTimeMillis() - lastShownMs
        if (elapsed < 0L) return true // Clock adjusted backwards

        val threshold = if (isUnlockEvent) {
            computeUnlockCooldownMs(prefs)
        } else {
            computeActiveIntervalMs(prefs)
        }
        return elapsed >= threshold
    }

    fun computeNextDelayMs(prefs: SharedPreferences): Long {
        val lastShownMs = readLong(prefs, "dhikr_moment_last_shown_epoch_ms", 0L)
        val intervalMs = computeActiveIntervalMs(prefs)
        if (lastShownMs <= 0L) {
            return 8_000L
        }
        val elapsed = (System.currentTimeMillis() - lastShownMs).coerceAtLeast(0L)
        return (intervalMs - elapsed).coerceIn(8_000L, intervalMs)
    }

    fun scheduleNext(context: Context, delayMsOverride: Long? = null) {
        val p = prefs(context)
        if (!isEnabled(p)) {
            cancel(context)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            cancel(context)
            return
        }

        val delayMs = (delayMsOverride ?: computeNextDelayMs(p)).coerceAtLeast(5_000L)
        val triggerAtMillis = System.currentTimeMillis() + delayMs

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, DhikrOverlayReceiver::class.java).apply {
            action = DhikrOverlayService.ACTION_ALARM_CHECK
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        try {
            val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                alarmManager.canScheduleExactAlarms()
            } else {
                true
            }
            if (canExact && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
            }
        } catch (_: Exception) {
            try {
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
            } catch (_: Exception) {}
        }
    }

    fun cancel(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, DhikrOverlayReceiver::class.java).apply {
            action = DhikrOverlayService.ACTION_ALARM_CHECK
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        try {
            alarmManager.cancel(pendingIntent)
        } catch (_: Exception) {}
    }
}
