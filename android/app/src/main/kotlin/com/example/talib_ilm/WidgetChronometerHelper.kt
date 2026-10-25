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

    private data class PrayerItem(
        val name: String,
        val adhanMs: Long,
        val iqamaMinutes: Int,
        val salahMinutes: Int,
        val color: Int,
        val iconRes: Int
    )

    fun setupChronometer(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        providerClass: Class<*>
    ) {
        try {
            val now = System.currentTimeMillis()

            // 1. Resolve theme mode & colors
            val isDark = resolveIsDark(widgetData)
            val defaultTextColor = if (isDark) 0xFFFFFFFF.toInt() else 0xFF1C1917.toInt()
            val textColor = getSafeInt(widgetData, "widget_text_color", defaultTextColor)
            val bgRes = if (isDark) R.drawable.widget_countdown_badge_dark else R.drawable.widget_countdown_badge_light

            // 2. Read full prayer schedule if available
            val fajrMs = getSafeLong(widgetData, "prayer_fajr_epoch_ms", 0L)
            val dhuhrMs = getSafeLong(widgetData, "prayer_dhuhr_epoch_ms", 0L)
            val asrMs = getSafeLong(widgetData, "prayer_asr_epoch_ms", 0L)
            val maghribMs = getSafeLong(widgetData, "prayer_maghrib_epoch_ms", 0L)
            val ishaMs = getSafeLong(widgetData, "prayer_isha_epoch_ms", 0L)

            val isRibbonOrLarge = providerClass.simpleName.contains("Ribbon") || providerClass.simpleName.contains("Large")

            if (fajrMs > 0L && dhuhrMs > 0L && asrMs > 0L && maghribMs > 0L && ishaMs > 0L) {
                // Full autonomous native schedule evaluation
                evaluateAndApplySchedule(
                    context = context,
                    views = views,
                    widgetData = widgetData,
                    now = now,
                    providerClass = providerClass,
                    isRibbonOrLarge = isRibbonOrLarge,
                    textColor = textColor,
                    bgRes = bgRes,
                    fajrMs = fajrMs,
                    dhuhrMs = dhuhrMs,
                    asrMs = asrMs,
                    maghribMs = maghribMs,
                    ishaMs = ishaMs
                )
            } else {
                // Fallback to single snapshot values with strict negative chronometer prevention
                applyFallbackSnapshot(
                    context = context,
                    views = views,
                    widgetData = widgetData,
                    now = now,
                    providerClass = providerClass,
                    isRibbonOrLarge = isRibbonOrLarge,
                    textColor = textColor,
                    bgRes = bgRes
                )
            }
        } catch (_: Throwable) {
            try {
                views.setViewVisibility(R.id.widget_countdown, View.GONE)
                views.setViewVisibility(R.id.widget_status_badge, View.GONE)
            } catch (_: Throwable) {}
        }
    }

    private fun evaluateAndApplySchedule(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        now: Long,
        providerClass: Class<*>,
        isRibbonOrLarge: Boolean,
        textColor: Int,
        bgRes: Int,
        fajrMs: Long,
        dhuhrMs: Long,
        asrMs: Long,
        maghribMs: Long,
        ishaMs: Long
    ) {
        val isFriday = getSafeBoolean(widgetData, "is_friday", false)
        val iqamaFajr = getSafeInt(widgetData, "iqama_fajr_min", 25)
        val iqamaDhuhr = getSafeInt(widgetData, "iqama_dhuhr_min", if (isFriday) 25 else 20)
        val iqamaAsr = getSafeInt(widgetData, "iqama_asr_min", 20)
        val iqamaMaghrib = getSafeInt(widgetData, "iqama_maghrib_min", 10)
        val iqamaIsha = getSafeInt(widgetData, "iqama_isha_min", 15)

        val fajrColor = getSafeInt(widgetData, "prayer_color_fajr", 0xFF38BDF8.toInt())
        val dhuhrColor = if (isFriday) 0xFF10B981.toInt() else getSafeInt(widgetData, "prayer_color_dhuhr", 0xFFF59E0B.toInt())
        val asrColor = getSafeInt(widgetData, "prayer_color_asr", 0xFFFB923C.toInt())
        val maghribColor = getSafeInt(widgetData, "prayer_color_maghrib", 0xFFF43F5E.toInt())
        val ishaColor = getSafeInt(widgetData, "prayer_color_isha", 0xFFA78BFA.toInt())

        val tomorrowFajrMs = getSafeLong(widgetData, "prayer_tomorrow_fajr_epoch_ms", fajrMs + 86400000L)

        val prayers = listOf(
            PrayerItem("الفجر", fajrMs, iqamaFajr, 15, fajrColor, R.drawable.ic_prayer_fajr),
            PrayerItem(if (isFriday) "الجمعة" else "الظهر", dhuhrMs, iqamaDhuhr, if (isFriday) 20 else 12, dhuhrColor, if (isFriday) R.drawable.ic_prayer_jumua else R.drawable.ic_prayer_dhuhr),
            PrayerItem("العصر", asrMs, iqamaAsr, 12, asrColor, R.drawable.ic_prayer_asr),
            PrayerItem("المغرب", maghribMs, iqamaMaghrib, 10, maghribColor, R.drawable.ic_prayer_maghrib),
            PrayerItem("العشاء", ishaMs, iqamaIsha, 12, ishaColor, R.drawable.ic_prayer_isha)
        )
        val tomorrowFajr = PrayerItem("الفجر", tomorrowFajrMs, iqamaFajr, 15, fajrColor, R.drawable.ic_prayer_fajr)

        val activeItem: PrayerItem
        val displayTitle: String
        val statusText: String?
        val countdownTargetMs: Long?
        val countdownPrefix: String
        val nextAlarmMs: Long

        if (now < prayers[0].adhanMs) {
            // Case 1: Before today's Fajr
            activeItem = prayers[0]
            displayTitle = "صلاة ${activeItem.name}"
            statusText = null
            countdownTargetMs = activeItem.adhanMs
            countdownPrefix = "بعد "
            nextAlarmMs = activeItem.adhanMs
        } else {
            // Find current prayer
            var currentIdx = -1
            for (i in prayers.indices.reversed()) {
                if (now >= prayers[i].adhanMs) {
                    currentIdx = i
                    break
                }
            }

            val p = prayers[currentIdx]
            val iqamaMs = p.adhanMs + (p.iqamaMinutes * 60_000L)
            val salahEndMs = iqamaMs + (p.salahMinutes * 60_000L)

            if (now < p.adhanMs + 60_000L) {
                // Case 2: At Adhan (first 60 seconds)
                activeItem = p
                displayTitle = if (p.name == "الجمعة") "أذان صلاة الجمعة" else "أذان صلاة ${p.name}"
                statusText = "الأذان الآن"
                countdownTargetMs = null
                countdownPrefix = ""
                nextAlarmMs = p.adhanMs + 60_000L
            } else if (now < iqamaMs) {
                // Case 3: Between Adhan and Iqama (active Iqama countdown)
                activeItem = p
                displayTitle = if (p.name == "الجمعة") "صلاة الجمعة" else "صلاة ${p.name}"
                statusText = null
                countdownTargetMs = iqamaMs
                countdownPrefix = "الإقامة بعد "
                nextAlarmMs = iqamaMs
            } else if (now < salahEndMs) {
                // Case 4: In Congregational Prayer
                activeItem = p
                displayTitle = if (p.name == "الجمعة") "صلاة الجمعة" else "صلاة ${p.name}"
                statusText = "تقام الصلاة الآن"
                countdownTargetMs = null
                countdownPrefix = ""
                nextAlarmMs = salahEndMs
            } else {
                // Case 5: Post Salah -> transitions cleanly to next upcoming prayer
                val nextPrayer = if (currentIdx + 1 < prayers.size) {
                    prayers[currentIdx + 1]
                } else {
                    tomorrowFajr
                }
                activeItem = nextPrayer
                displayTitle = if (nextPrayer.name == "الجمعة") "صلاة الجمعة" else "صلاة ${nextPrayer.name}"
                statusText = null
                countdownTargetMs = nextPrayer.adhanMs
                countdownPrefix = "بعد "
                nextAlarmMs = nextPrayer.adhanMs
            }
        }

        if (isRibbonOrLarge) {
            // Apply prayer title
            views.setTextViewText(R.id.widget_prayer_title, displayTitle)
            views.setTextColor(R.id.widget_prayer_title, activeItem.color)

            // Apply prayer celestial icon
            try {
                views.setImageViewResource(R.id.widget_prayer_icon, activeItem.iconRes)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    views.setInt(R.id.widget_prayer_icon, "setColorFilter", activeItem.color)
                }
                views.setViewVisibility(R.id.widget_prayer_icon, View.VISIBLE)
            } catch (_: Exception) {}

            // Apply countdown or status badge
            if (statusText != null) {
                try {
                    views.setChronometer(R.id.widget_countdown, 0L, null, false)
                    views.setViewVisibility(R.id.widget_countdown, View.GONE)
                } catch (_: Exception) {}

                try {
                    views.setTextViewText(R.id.widget_status_badge, statusText)
                    views.setTextColor(R.id.widget_status_badge, textColor)
                    views.setInt(R.id.widget_status_badge, "setBackgroundResource", bgRes)
                    views.setViewVisibility(R.id.widget_status_badge, View.VISIBLE)
                } catch (_: Exception) {}
            } else if (countdownTargetMs != null && countdownTargetMs > now) {
                try {
                    views.setViewVisibility(R.id.widget_status_badge, View.GONE)
                } catch (_: Exception) {}

                val remainingMs = countdownTargetMs - now
                val chronometerBase = SystemClock.elapsedRealtime() + remainingMs
                val formatString = "$countdownPrefix%s"

                views.setChronometer(R.id.widget_countdown, chronometerBase, formatString, true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    views.setChronometerCountDown(R.id.widget_countdown, true)
                }
                views.setTextColor(R.id.widget_countdown, textColor)
                try {
                    views.setInt(R.id.widget_countdown, "setBackgroundResource", bgRes)
                } catch (_: Exception) {}
                views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
            } else {
                try {
                    views.setChronometer(R.id.widget_countdown, 0L, null, false)
                    views.setViewVisibility(R.id.widget_countdown, View.GONE)
                    views.setViewVisibility(R.id.widget_status_badge, View.GONE)
                } catch (_: Exception) {}
            }
        }

        // Schedule exact alarm for next milestone
        if (nextAlarmMs > now) {
            schedulePrayerAlarm(context, nextAlarmMs, providerClass)
        }
    }

    private fun applyFallbackSnapshot(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        now: Long,
        providerClass: Class<*>,
        isRibbonOrLarge: Boolean,
        textColor: Int,
        bgRes: Int
    ) {
        val epochMs = getSafeLong(widgetData, "next_prayer_epoch_ms", 0L)
        val isPrayerActive = getSafeBoolean(widgetData, "is_prayer_active", false)
        val rawPrayerTitle = getSafeString(widgetData, "prayer_display_title", "صلاة الفجر")
        val effectiveTitle = if (rawPrayerTitle.startsWith("صلاة ")) rawPrayerTitle.substring(5) else rawPrayerTitle
        val prayerColor = getSafeInt(widgetData, "prayer_color_value", 0xFF38BDF8.toInt())
        val countdownPrefix = getSafeString(widgetData, "countdown_prefix", "بعد ")
        val prayerName = getSafeString(widgetData, "next_prayer_name", "")

        if (isRibbonOrLarge) {
            views.setTextViewText(R.id.widget_prayer_title, effectiveTitle)
            views.setTextColor(R.id.widget_prayer_title, prayerColor)

            try {
                val iconRes = resolvePrayerIconRes(prayerName, effectiveTitle)
                views.setImageViewResource(R.id.widget_prayer_icon, iconRes)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    views.setInt(R.id.widget_prayer_icon, "setColorFilter", prayerColor)
                }
                views.setViewVisibility(R.id.widget_prayer_icon, View.VISIBLE)
            } catch (_: Exception) {}

            val statusLabel = getSafeString(widgetData, "prayer_status_label", "")

            if (isPrayerActive || epochMs == 0L || epochMs <= now) {
                // Never show negative chronometer!
                val displayLabel = when {
                    statusLabel.isNotEmpty() -> statusLabel
                    now - epochMs < 60_000L -> "الأذان الآن"
                    now - epochMs < 20 * 60_000L -> "تقام الصلاة الآن"
                    else -> "الصلاة القادمة"
                }

                try {
                    views.setChronometer(R.id.widget_countdown, 0L, null, false)
                    views.setViewVisibility(R.id.widget_countdown, View.GONE)
                } catch (_: Exception) {}

                try {
                    views.setTextViewText(R.id.widget_status_badge, displayLabel)
                    views.setTextColor(R.id.widget_status_badge, textColor)
                    views.setInt(R.id.widget_status_badge, "setBackgroundResource", bgRes)
                    views.setViewVisibility(R.id.widget_status_badge, View.VISIBLE)
                } catch (_: Exception) {}
            } else {
                try {
                    views.setViewVisibility(R.id.widget_status_badge, View.GONE)
                } catch (_: Exception) {}

                val remainingMs = epochMs - now
                val chronometerBase = SystemClock.elapsedRealtime() + remainingMs
                val formatString = if (countdownPrefix.isNotEmpty()) "$countdownPrefix%s" else "%s"

                views.setChronometer(R.id.widget_countdown, chronometerBase, formatString, true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    views.setChronometerCountDown(R.id.widget_countdown, true)
                }
                views.setTextColor(R.id.widget_countdown, textColor)
                try {
                    views.setInt(R.id.widget_countdown, "setBackgroundResource", bgRes)
                } catch (_: Exception) {}
                views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
            }
        }

        if (epochMs > now) {
            schedulePrayerAlarm(context, epochMs, providerClass)
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

    fun resolvePrayerIconRes(prayerName: String, title: String): Int {
        val text = "$prayerName $title".lowercase()
        return when {
            text.contains("جمعة") || text.contains("jumu") -> R.drawable.ic_prayer_jumua
            text.contains("فجر") || text.contains("fajr") -> R.drawable.ic_prayer_fajr
            text.contains("ظهر") || text.contains("dhuhr") -> R.drawable.ic_prayer_dhuhr
            text.contains("عصر") || text.contains("asr") -> R.drawable.ic_prayer_asr
            text.contains("مغرب") || text.contains("maghrib") -> R.drawable.ic_prayer_maghrib
            text.contains("عشاء") || text.contains("isha") -> R.drawable.ic_prayer_isha
            else -> R.drawable.ic_prayer_fajr
        }
    }

    private fun getSafeLong(prefs: SharedPreferences, key: String, defaultVal: Long): Long {
        val keys = listOf(key, "flutter.$key")
        for (k in keys) {
            if (prefs.contains(k)) {
                try {
                    return prefs.getLong(k, defaultVal)
                } catch (_: ClassCastException) {
                    try {
                        return prefs.getInt(k, defaultVal.toInt()).toLong()
                    } catch (_: Exception) {}
                }
            }
        }
        return defaultVal
    }

    private fun getSafeInt(prefs: SharedPreferences, key: String, defaultVal: Int): Int {
        val keys = listOf(key, "flutter.$key")
        for (k in keys) {
            if (prefs.contains(k)) {
                try {
                    return prefs.getInt(k, defaultVal)
                } catch (_: ClassCastException) {
                    try {
                        return prefs.getLong(k, defaultVal.toLong()).toInt()
                    } catch (_: Exception) {}
                }
            }
        }
        return defaultVal
    }

    private fun getSafeBoolean(prefs: SharedPreferences, key: String, defaultVal: Boolean): Boolean {
        val keys = listOf(key, "flutter.$key")
        for (k in keys) {
            if (prefs.contains(k)) {
                try {
                    return prefs.getBoolean(k, defaultVal)
                } catch (_: Exception) {}
            }
        }
        return defaultVal
    }

    private fun getSafeString(prefs: SharedPreferences, key: String, defaultVal: String): String {
        val keys = listOf(key, "flutter.$key")
        for (k in keys) {
            if (prefs.contains(k)) {
                try {
                    val s = prefs.getString(k, defaultVal)
                    if (s != null) return s
                } catch (_: Exception) {}
            }
        }
        return defaultVal
    }

    private fun resolveIsDark(prefs: SharedPreferences): Boolean {
        if (prefs.contains("widget_is_dark")) return prefs.getBoolean("widget_is_dark", true)
        if (prefs.contains("flutter.widget_is_dark")) return prefs.getBoolean("flutter.widget_is_dark", true)
        val mode = getSafeString(prefs, "prayer_widget_theme_mode", "dark")
        val appTheme = getSafeString(prefs, "theme_mode", "dark")
        return when (mode) {
            "light" -> false
            "dark" -> true
            else -> appTheme != "light"
        }
    }
}
