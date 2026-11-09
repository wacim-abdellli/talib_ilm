package com.talibilm.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import java.util.Calendar
import kotlin.math.roundToInt

object DhikrOverlayScheduler {
    const val ALARM_REQUEST_CODE = 8491

    private fun readInt(prefs: android.content.SharedPreferences, key: String, fallback: Int): Int =
        (prefs.all["flutter.$key"] as? Number)?.toInt() ?: fallback

    fun scheduleNext(context: Context) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("flutter.dhikr_moment_enabled", false)
        if (!enabled) {
            cancel(context)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            cancel(context)
            return
        }

        val count = readInt(prefs, "dhikr_moment_times_per_day", 20).coerceIn(1, 50)
        val start = readInt(prefs, "dhikr_moment_start_minutes", 480).coerceIn(0, 1439)
        val end = readInt(prefs, "dhikr_moment_end_minutes", 1320).coerceIn(1, 1440)
        if (end <= start) {
            cancel(context)
            return
        }

        val span = end - start
        val now = Calendar.getInstance()
        val nowMinute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val scheduled = (1..count).map { index ->
            start + (span.toDouble() * index / (count + 1)).roundToInt()
        }.distinct().sorted()

        var next = scheduled.firstOrNull { it > nowMinute }
        var daysAhead = 0
        if (next == null) {
            next = scheduled.first()
            daysAhead = 1
        }

        val target = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, daysAhead)
            set(Calendar.HOUR_OF_DAY, next / 60)
            set(Calendar.MINUTE, next % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, DhikrOverlayReceiver::class.java).apply {
            action = DhikrOverlayService.ACTION_SHOW_NOW
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    target.timeInMillis,
                    pendingIntent,
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    target.timeInMillis,
                    pendingIntent,
                )
            }
        } catch (_: Exception) {
            alarmManager.set(
                AlarmManager.RTC_WAKEUP,
                target.timeInMillis,
                pendingIntent,
            )
        }
    }

    fun cancel(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, DhikrOverlayReceiver::class.java)
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

