package com.example.talib_ilm

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews

object WidgetChronometerHelper {

    fun setupChronometer(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        providerClass: Class<*>
    ) {
        try {
            val epochMs = try {
                if (widgetData.contains("next_prayer_epoch_ms")) {
                    widgetData.getLong("next_prayer_epoch_ms", 0L)
                } else {
                    widgetData.getLong("flutter.next_prayer_epoch_ms", 0L)
                }
            } catch (_: ClassCastException) {
                try {
                    widgetData.getInt("next_prayer_epoch_ms", 0).toLong()
                } catch (_: Exception) {
                    0L
                }
            }

            val isPrayerActive = widgetData.getBoolean(
                "is_prayer_active",
                widgetData.getBoolean("flutter.is_prayer_active", false)
            )

            val now = System.currentTimeMillis()

            // Resolve theme mode
            val themeMode = widgetData.getString(
                "prayer_widget_theme_mode",
                widgetData.getString("flutter.prayer_widget_theme_mode", "dark")
            ) ?: "dark"
            val appTheme = widgetData.getString(
                "theme_mode",
                widgetData.getString("flutter.theme_mode", "dark")
            ) ?: "dark"
            val isDark = when (themeMode) {
                "light" -> false
                "dark" -> true
                else -> appTheme != "light"
            }

            val textColor = if (isDark) 0xFFFFFFFF.toInt() else 0xFF141210.toInt()
            val bgRes = if (isDark) R.drawable.widget_countdown_badge_dark else R.drawable.widget_countdown_badge_light

            val rawPrayerTitle = widgetData.getString(
                "prayer_display_title",
                widgetData.getString("flutter.prayer_display_title", "صلاة الفجر")
            ) ?: "صلاة الفجر"

            val effectiveTitle = if (rawPrayerTitle.startsWith("صلاة ")) {
                rawPrayerTitle.substring(5)
            } else {
                rawPrayerTitle
            }

            val prayerColor = try {
                if (widgetData.contains("prayer_color_value")) {
                    widgetData.getInt("prayer_color_value", 0xFF38BDF8.toInt())
                } else {
                    widgetData.getInt("flutter.prayer_color_value", 0xFF38BDF8.toInt())
                }
            } catch (_: Exception) {
                0xFF38BDF8.toInt()
            }

            val countdownPrefix = widgetData.getString(
                "countdown_prefix",
                widgetData.getString("flutter.countdown_prefix", "بعد ")
            ) ?: "بعد "

            val prayerName = widgetData.getString(
                "next_prayer_name",
                widgetData.getString("flutter.next_prayer_name", "")
            ) ?: ""

            val isRibbonOrLarge = providerClass.simpleName.contains("Ribbon") || providerClass.simpleName.contains("Large")

            if (isRibbonOrLarge) {
                try {
                    views.setTextViewText(R.id.widget_prayer_title, effectiveTitle)
                    views.setTextColor(R.id.widget_prayer_title, prayerColor)
                } catch (_: Exception) {}

                try {
                    val iconRes = resolvePrayerIconRes(prayerName, effectiveTitle)
                    views.setImageViewResource(R.id.widget_prayer_icon, iconRes)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        views.setInt(R.id.widget_prayer_icon, "setColorFilter", prayerColor)
                    }
                    views.setViewVisibility(R.id.widget_prayer_icon, View.VISIBLE)
                } catch (_: Exception) {}

                if (isPrayerActive || epochMs == 0L || epochMs <= now) {
                    views.setViewVisibility(R.id.widget_countdown, View.GONE)
                } else {
                    val remainingMs = epochMs - now
                    val chronometerBase = SystemClock.elapsedRealtime() + remainingMs

                    views.setChronometer(R.id.widget_countdown, chronometerBase, "%s", true)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        views.setChronometerCountDown(R.id.widget_countdown, true)
                    }
                    views.setTextColor(R.id.widget_countdown, textColor)
                    try {
                        views.setInt(R.id.widget_countdown, "setBackgroundResource", bgRes)
                    } catch (_: Exception) {}
                    views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
                }
            } else {
                try {
                    views.setViewVisibility(R.id.widget_countdown, View.GONE)
                } catch (_: Exception) {}
            }

            // Schedule exact alarm to update the widget right when countdown hits zero
            if (epochMs > now) {
                schedulePrayerAlarm(context, epochMs, providerClass)
            }
        } catch (_: Throwable) {
            try {
                views.setViewVisibility(R.id.widget_countdown, View.GONE)
            } catch (_: Throwable) {}
        }
    }

    private fun schedulePrayerAlarm(
        context: Context,
        triggerEpochMs: Long,
        providerClass: Class<*>
    ) {
        if (triggerEpochMs <= System.currentTimeMillis()) return
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, providerClass).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, providerClass))
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                providerClass.name.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
            }
        } catch (_: Exception) {}
    }

    private fun resolvePrayerIconRes(prayerName: String, title: String): Int {
        val text = "$prayerName $title"
        return when {
            text.contains("جمعة") -> R.drawable.ic_prayer_jumua
            text.contains("فجر") -> R.drawable.ic_prayer_fajr
            text.contains("ظهر") -> R.drawable.ic_prayer_dhuhr
            text.contains("عصر") -> R.drawable.ic_prayer_asr
            text.contains("مغرب") -> R.drawable.ic_prayer_maghrib
            text.contains("عشاء") -> R.drawable.ic_prayer_isha
            else -> R.drawable.ic_prayer_fajr
        }
    }
}

