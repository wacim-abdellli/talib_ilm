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
        val start = readInt(prefs, "dhikr_moment_start_minutes", 480).coerceIn(0, 1439)
        val end = readInt(prefs, "dhikr_moment_end_minutes", 1320).coerceIn(1, 1440)
        val windowSpanMinutes = if (end > start) {
            end - start
        } else {
            (1440 - start + end).coerceAtLeast(60)
        }
        val effectiveActiveMinutes = windowSpanMinutes.coerceAtMost(250).coerceAtLeast(30)
        val intervalMinutes = (effectiveActiveMinutes.toDouble() / count.toDouble())
            .roundToInt()
            .coerceIn(4, 120)
        return intervalMinutes * 60_000L
    }

    /**
     * Minimum cooldown before showing a Dhikr card right as the user unlocks their phone.
     * For 50/day (5 min active interval), unlocking after >= 2.5 minutes greets the user.
     */
    fun computeUnlockCooldownMs(prefs: SharedPreferences): Long {
        val activeInterval = computeActiveIntervalMs(prefs)
        return (activeInterval * 55L / 100L).coerceIn(150_000L, 1_800_000L)
    }

    fun isWithinTimeWindow(
        prefs: SharedPreferences,
        now: Calendar = Calendar.getInstance(),
    ): Boolean {
        val start = readInt(prefs, "dhikr_moment_start_minutes", 480).coerceIn(0, 1439)
        val end = readInt(prefs, "dhikr_moment_end_minutes", 1320).coerceIn(1, 1440)
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
        return shownToday < maxPerDay
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
    ): Boolean {
        if (!isEnabled(prefs)) return false
        if (!isWithinTimeWindow(prefs)) return false
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
        val now = Calendar.getInstance()
        if (!isWithinTimeWindow(prefs, now) || !canShowMoreToday(prefs, now)) {
            val start = readInt(prefs, "dhikr_moment_start_minutes", 480).coerceIn(0, 1439)
            val nowMinute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
            val target = Calendar.getInstance().apply {
                if (nowMinute >= start) {
                    add(Calendar.DAY_OF_YEAR, 1)
                }
                set(Calendar.HOUR_OF_DAY, start / 60)
                set(Calendar.MINUTE, start % 60)
                set(Calendar.SECOND, 5)
                set(Calendar.MILLISECOND, 0)
            }
            return (target.timeInMillis - System.currentTimeMillis()).coerceAtLeast(60_000L)
        }

        val lastShownMs = readLong(prefs, "dhikr_moment_last_shown_epoch_ms", 0L)
        val intervalMs = computeActiveIntervalMs(prefs)
        if (lastShownMs <= 0L) {
            return 12_000L
        }
        val elapsed = (System.currentTimeMillis() - lastShownMs).coerceAtLeast(0L)
        return (intervalMs - elapsed).coerceAtLeast(5_000L)
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
