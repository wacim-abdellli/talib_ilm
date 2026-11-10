package com.talibilm.app

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
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import org.json.JSONObject
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import kotlin.math.abs
import kotlin.math.acos
import kotlin.math.asin
import kotlin.math.atan
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.sin
import kotlin.math.tan

object WidgetChronometerHelper {

    private data class PrayerColumnSpec(
        val key: String,
        val displayName: String,
        val adhanMs: Long,
        val iqamaMinutes: Int,
        val salahMinutes: Int,
        val color: Int,
        val iconRes: Int,
        val pillRes: Int,
        val iconViewId: Int,
        val nameViewId: Int,
        val timeViewId: Int
    )

    fun setupChronometer(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        providerClass: Class<*>
    ) {
        try {
            val now = System.currentTimeMillis()
            val isLarge = providerClass.simpleName.contains("Large") ||
                providerClass.simpleName.contains("Standard")

            // 1. Resolve theme mode & palette
            val isDark = resolveIsDark(widgetData)
            val cardBgRes = if (isDark) R.drawable.widget_card_dark else R.drawable.widget_card_light
            val heroBoxBgRes = if (isDark) R.drawable.widget_hero_box_dark else R.drawable.widget_hero_box_light
            val countdownBgRes = if (isDark) R.drawable.widget_countdown_badge_dark else R.drawable.widget_countdown_badge_light

            val primaryTextColor = if (isDark) 0xFFF4EFE6.toInt() else 0xFF14130F.toInt()
            val mutedTextColor = if (isDark) 0xFFA9A59C.toInt() else 0xFF6B665B.toInt()
            val goldColor = if (isDark) 0xFFE3B341.toInt() else 0xFF9A6700.toInt()

            try {
                views.setInt(R.id.widget_container, "setBackgroundResource", cardBgRes)
            } catch (_: Exception) {}

            if (isLarge) {
                try {
                    views.setInt(R.id.widget_hero_box, "setBackgroundResource", heroBoxBgRes)
                } catch (_: Exception) {}
            }

            // 2. Read or autonomously compute today's 5 prayer timestamps
            val json = loadJsonPayload(widgetData)
            var fajrMs = getSafeLong(widgetData, json, "prayer_fajr_epoch_ms", "fajr", 0L)
            var dhuhrMs = getSafeLong(widgetData, json, "prayer_dhuhr_epoch_ms", "dhuhr", 0L)
            var asrMs = getSafeLong(widgetData, json, "prayer_asr_epoch_ms", "asr", 0L)
            var maghribMs = getSafeLong(widgetData, json, "prayer_maghrib_epoch_ms", "maghrib", 0L)
            var ishaMs = getSafeLong(widgetData, json, "prayer_isha_epoch_ms", "isha", 0L)
            var tomorrowFajrMs = getSafeLong(widgetData, json, "prayer_tomorrow_fajr_epoch_ms", null, 0L)

            val scheduleValidForToday = fajrMs > 0L && dhuhrMs > 0L && asrMs > 0L &&
                maghribMs > 0L && ishaMs > 0L && isSameCalendarDay(fajrMs, now)

            if (!scheduleValidForToday) {
                if (fajrMs > 0L && now > fajrMs + 86_400_000L) {
                    try {
                        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                            context,
                            android.net.Uri.parse("talibilm://refresh")
                        )
                        backgroundIntent.send()
                    } catch (_: Exception) {}
                }

                val coords = resolveCoordinates(widgetData, json)
                val tzOffsetHours = TimeZone.getDefault().getOffset(now) / 3_600_000.0
                val todayCalc = calculateSolarPrayers(now, coords.first, coords.second, tzOffsetHours)
                val tomorrowCalc = calculateSolarPrayers(now + 86_400_000L, coords.first, coords.second, tzOffsetHours)

                fajrMs = todayCalc["fajr"] ?: fajrMs
                dhuhrMs = todayCalc["dhuhr"] ?: dhuhrMs
                asrMs = todayCalc["asr"] ?: asrMs
                maghribMs = todayCalc["maghrib"] ?: maghribMs
                ishaMs = todayCalc["isha"] ?: ishaMs
                tomorrowFajrMs = tomorrowCalc["fajr"] ?: (fajrMs + 86_400_000L)
            } else if (tomorrowFajrMs <= 0L) {
                tomorrowFajrMs = fajrMs + 86_400_000L
            }

            // 3. Populate Hijri Date & City Name
            val fullHijri = resolveHijriDate(widgetData, json, now, scheduleValidForToday)
            val compactHijri = fullHijri.replace(Regex("\\s*\\d{4}\\s*هـ?"), "").trim().ifEmpty { fullHijri }
            val displayHijri = if (isLarge) fullHijri else compactHijri

            try {
                views.setTextViewText(R.id.widget_hijri_date, displayHijri)
                views.setTextColor(R.id.widget_hijri_date, primaryTextColor)
            } catch (_: Exception) {}

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    views.setInt(R.id.widget_calendar_icon, "setColorFilter", if (isLarge) goldColor else mutedTextColor)
                }
            } catch (_: Exception) {}

            if (isLarge) {
                val city = resolveCityName(widgetData, json)
                try {
                    views.setTextViewText(R.id.widget_city_name, city)
                    views.setTextColor(R.id.widget_city_name, mutedTextColor)
                } catch (_: Exception) {}
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        views.setInt(R.id.widget_location_icon, "setColorFilter", goldColor)
                    }
                } catch (_: Exception) {}
            }

            // 4. Evaluate active prayer & populate all views
            evaluateAndApplySchedule(
                context = context,
                views = views,
                widgetData = widgetData,
                now = now,
                providerClass = providerClass,
                isLarge = isLarge,
                isDark = isDark,
                primaryTextColor = primaryTextColor,
                mutedTextColor = mutedTextColor,
                countdownBgRes = countdownBgRes,
                fajrMs = fajrMs,
                dhuhrMs = dhuhrMs,
                asrMs = asrMs,
                maghribMs = maghribMs,
                ishaMs = ishaMs,
                tomorrowFajrMs = tomorrowFajrMs
            )
        } catch (_: Throwable) {}
    }

    private fun evaluateAndApplySchedule(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        now: Long,
        providerClass: Class<*>,
        isLarge: Boolean,
        isDark: Boolean,
        primaryTextColor: Int,
        mutedTextColor: Int,
        countdownBgRes: Int,
        fajrMs: Long,
        dhuhrMs: Long,
        asrMs: Long,
        maghribMs: Long,
        ishaMs: Long,
        tomorrowFajrMs: Long
    ) {
        val cal = Calendar.getInstance().apply { timeInMillis = if (dhuhrMs > 0L) dhuhrMs else now }
        val isFriday = cal.get(Calendar.DAY_OF_WEEK) == Calendar.FRIDAY

        val iqamaFajr = getSafeInt(widgetData, "iqama_fajr_min", 25)
        val iqamaDhuhr = getSafeInt(widgetData, "iqama_dhuhr_min", if (isFriday) 25 else 20)
        val iqamaAsr = getSafeInt(widgetData, "iqama_asr_min", 20)
        val iqamaMaghrib = getSafeInt(widgetData, "iqama_maghrib_min", 10)
        val iqamaIsha = getSafeInt(widgetData, "iqama_isha_min", 15)

        val fajrColor = if (isDark) 0xFF38BDF8.toInt() else 0xFF0284C7.toInt()
        val dhuhrColor = if (isFriday) {
            if (isDark) 0xFF34D399.toInt() else 0xFF047857.toInt()
        } else {
            if (isDark) 0xFFE3B341.toInt() else 0xFF9A6700.toInt()
        }
        val asrColor = if (isDark) 0xFFFB923C.toInt() else 0xFFC2410C.toInt()
        val maghribColor = if (isDark) 0xFFF43F5E.toInt() else 0xFFBE123C.toInt()
        val ishaColor = if (isDark) 0xFFA78BFA.toInt() else 0xFF6D28D9.toInt()

        val dhuhrLabel = if (isFriday) "الجمعة" else "الظهر"
        val dhuhrIcon = if (isFriday) R.drawable.ic_prayer_jumua else R.drawable.ic_prayer_dhuhr
        val dhuhrPill = if (isFriday) R.drawable.widget_pill_jumua else R.drawable.widget_pill_dhuhr

        val columns = listOf(
            PrayerColumnSpec(
                key = "fajr",
                displayName = "الفجر",
                adhanMs = fajrMs,
                iqamaMinutes = iqamaFajr,
                salahMinutes = 15,
                color = fajrColor,
                iconRes = R.drawable.ic_prayer_fajr,
                pillRes = R.drawable.widget_pill_fajr,
                iconViewId = R.id.icon_fajr,
                nameViewId = R.id.name_fajr,
                timeViewId = R.id.time_fajr
            ),
            PrayerColumnSpec(
                key = "dhuhr",
                displayName = dhuhrLabel,
                adhanMs = dhuhrMs,
                iqamaMinutes = iqamaDhuhr,
                salahMinutes = if (isFriday) 20 else 12,
                color = dhuhrColor,
                iconRes = dhuhrIcon,
                pillRes = dhuhrPill,
                iconViewId = R.id.icon_dhuhr,
                nameViewId = R.id.name_dhuhr,
                timeViewId = R.id.time_dhuhr
            ),
            PrayerColumnSpec(
                key = "asr",
                displayName = "العصر",
                adhanMs = asrMs,
                iqamaMinutes = iqamaAsr,
                salahMinutes = 12,
                color = asrColor,
                iconRes = R.drawable.ic_prayer_asr,
                pillRes = R.drawable.widget_pill_asr,
                iconViewId = R.id.icon_asr,
                nameViewId = R.id.name_asr,
                timeViewId = R.id.time_asr
            ),
            PrayerColumnSpec(
                key = "maghrib",
                displayName = "المغرب",
                adhanMs = maghribMs,
                iqamaMinutes = iqamaMaghrib,
                salahMinutes = 10,
                color = maghribColor,
                iconRes = R.drawable.ic_prayer_maghrib,
                pillRes = R.drawable.widget_pill_maghrib,
                iconViewId = R.id.icon_maghrib,
                nameViewId = R.id.name_maghrib,
                timeViewId = R.id.time_maghrib
            ),
            PrayerColumnSpec(
                key = "isha",
                displayName = "العشاء",
                adhanMs = ishaMs,
                iqamaMinutes = iqamaIsha,
                salahMinutes = 12,
                color = ishaColor,
                iconRes = R.drawable.ic_prayer_isha,
                pillRes = R.drawable.widget_pill_isha,
                iconViewId = R.id.icon_isha,
                nameViewId = R.id.name_isha,
                timeViewId = R.id.time_isha
            )
        )

        val tomorrowFajrSpec = columns[0].copy(adhanMs = tomorrowFajrMs)

        val activeSpec: PrayerColumnSpec
        val activeIndex: Int
        val allTodayCompleted: Boolean
        val heroTitle: String
        val activeTimeLabel: String
        val statusText: String?
        val countdownTargetMs: Long?
        val countdownPrefix: String
        val nextAlarmMs: Long

        if (now < columns[0].adhanMs) {
            // Before today's Fajr
            activeSpec = columns[0]
            activeIndex = 0
            allTodayCompleted = false
            heroTitle = "صلاة ${activeSpec.displayName}"
            activeTimeLabel = formatTime12hWithPeriod(activeSpec.adhanMs)
            statusText = null
            countdownTargetMs = activeSpec.adhanMs
            countdownPrefix = "بعد"
            nextAlarmMs = activeSpec.adhanMs
        } else {
            var currentIdx = 0
            for (i in columns.indices.reversed()) {
                if (now >= columns[i].adhanMs) {
                    currentIdx = i
                    break
                }
            }

            val p = columns[currentIdx]
            val iqamaMs = p.adhanMs + (p.iqamaMinutes * 60_000L)
            val salahEndMs = iqamaMs + (p.salahMinutes * 60_000L)

            if (now < p.adhanMs + 60_000L) {
                // Phase A: At Adhan (first 60s)
                activeSpec = p
                activeIndex = currentIdx
                allTodayCompleted = false
                heroTitle = if (p.displayName == "الجمعة") "أذان الجمعة" else "أذان ${p.displayName}"
                activeTimeLabel = formatTime12hWithPeriod(p.adhanMs)
                statusText = "الأذان الآن"
                countdownTargetMs = null
                countdownPrefix = ""
                nextAlarmMs = p.adhanMs + 60_000L
            } else if (now < iqamaMs) {
                // Phase B: Between Adhan and Iqama
                activeSpec = p
                activeIndex = currentIdx
                allTodayCompleted = false
                heroTitle = "صلاة ${p.displayName}"
                activeTimeLabel = "الإقامة ${formatTime12hWithPeriod(iqamaMs)}"
                statusText = null
                countdownTargetMs = iqamaMs
                countdownPrefix = "الإقامة بعد"
                nextAlarmMs = iqamaMs
            } else if (now < salahEndMs) {
                // Phase C: In Congregational Salah
                activeSpec = p
                activeIndex = currentIdx
                allTodayCompleted = false
                heroTitle = "صلاة ${p.displayName}"
                activeTimeLabel = "وقت الصلاة"
                statusText = "تقام الصلاة الآن"
                countdownTargetMs = null
                countdownPrefix = ""
                nextAlarmMs = salahEndMs
            } else {
                // Phase D: Post Salah -> advance to next prayer
                if (currentIdx + 1 < columns.size) {
                    val nextP = columns[currentIdx + 1]
                    activeSpec = nextP
                    activeIndex = currentIdx + 1
                    allTodayCompleted = false
                    heroTitle = "صلاة ${nextP.displayName}"
                    activeTimeLabel = formatTime12hWithPeriod(nextP.adhanMs)
                    statusText = null
                    countdownTargetMs = nextP.adhanMs
                    countdownPrefix = "بعد"
                    nextAlarmMs = nextP.adhanMs
                } else {
                    activeSpec = tomorrowFajrSpec
                    activeIndex = 0
                    allTodayCompleted = true
                    heroTitle = "صلاة الفجر"
                    activeTimeLabel = formatTime12hWithPeriod(tomorrowFajrSpec.adhanMs)
                    statusText = null
                    countdownTargetMs = tomorrowFajrSpec.adhanMs
                    countdownPrefix = "بعد"
                    nextAlarmMs = tomorrowFajrSpec.adhanMs
                }
            }
        }

        // 1. Update Hero Prayer Title, Time & Icon
        try {
            views.setTextViewText(R.id.widget_prayer_title, heroTitle)
            views.setTextColor(R.id.widget_prayer_title, if (isLarge) primaryTextColor else activeSpec.color)
        } catch (_: Exception) {}

        if (isLarge) {
            try {
                views.setTextViewText(R.id.widget_active_prayer_time, activeTimeLabel)
                views.setTextColor(R.id.widget_active_prayer_time, activeSpec.color)
            } catch (_: Exception) {}
        }

        try {
            views.setImageViewResource(R.id.widget_prayer_icon, activeSpec.iconRes)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                views.setInt(R.id.widget_prayer_icon, "setColorFilter", activeSpec.color)
            }
            views.setViewVisibility(R.id.widget_prayer_icon, View.VISIBLE)
        } catch (_: Exception) {}

        // 2. Update Live Countdown Chronometer or Status Badge
        if (statusText != null) {
            try {
                views.setChronometer(R.id.widget_countdown, 0L, null, false)
                views.setViewVisibility(R.id.widget_countdown, View.GONE)
            } catch (_: Exception) {}

            try {
                views.setTextViewText(R.id.widget_status_badge, statusText)
                views.setTextColor(R.id.widget_status_badge, primaryTextColor)
                views.setInt(R.id.widget_status_badge, "setBackgroundResource", countdownBgRes)
                views.setViewVisibility(R.id.widget_status_badge, View.VISIBLE)
            } catch (_: Exception) {}
        } else if (countdownTargetMs != null && countdownTargetMs > now) {
            try {
                views.setViewVisibility(R.id.widget_status_badge, View.GONE)
            } catch (_: Exception) {}

            val remainingMs = countdownTargetMs - now
            val chronometerBase = SystemClock.elapsedRealtime() + remainingMs
            val formatString = if (countdownPrefix.isNotEmpty()) {
                "\u200F$countdownPrefix \u200E%s\u200F"
            } else {
                "%s"
            }

            try {
                views.setChronometer(R.id.widget_countdown, chronometerBase, formatString, true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    views.setChronometerCountDown(R.id.widget_countdown, true)
                }
                views.setTextColor(R.id.widget_countdown, primaryTextColor)
                views.setInt(R.id.widget_countdown, "setBackgroundResource", countdownBgRes)
                views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
            } catch (_: Exception) {}
        } else {
            try {
                views.setChronometer(R.id.widget_countdown, 0L, null, false)
                views.setViewVisibility(R.id.widget_countdown, View.GONE)
                views.setViewVisibility(R.id.widget_status_badge, View.GONE)
            } catch (_: Exception) {}
        }

        // 3. Populate the 5 Daily Prayer Columns (Fajr -> Dhuhr -> Asr -> Maghrib -> Isha)
        for (i in columns.indices) {
            val col = columns[i]
            val isCurrent = (i == activeIndex)
            val isPast = if (allTodayCompleted) {
                i != 0 // After Isha, Fajr is active for tomorrow while today's other prayers are past
            } else {
                i < activeIndex
            }

            val timeMs = if (allTodayCompleted && i == 0) tomorrowFajrSpec.adhanMs else col.adhanMs
            val timeStr = formatTime12hCompact(timeMs)

            val iconColor = when {
                isCurrent -> col.color
                isPast -> mutedTextColor
                else -> col.color
            }
            val nameColor = when {
                isCurrent -> col.color
                isPast -> mutedTextColor
                else -> primaryTextColor
            }
            val timeColor = when {
                isCurrent -> 0xFFFFFFFF.toInt()
                isPast -> mutedTextColor
                else -> primaryTextColor
            }

            try {
                views.setImageViewResource(col.iconViewId, col.iconRes)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    views.setInt(col.iconViewId, "setColorFilter", iconColor)
                }
            } catch (_: Exception) {}

            try {
                views.setTextViewText(col.nameViewId, col.displayName)
                views.setTextColor(col.nameViewId, nameColor)
            } catch (_: Exception) {}

            try {
                views.setTextViewText(col.timeViewId, timeStr)
                views.setTextColor(col.timeViewId, timeColor)
                views.setInt(
                    col.timeViewId,
                    "setBackgroundResource",
                    if (isCurrent) col.pillRes else 0
                )
            } catch (_: Exception) {}
        }

        // 4. Schedule exact alarm for the next transition milestone
        if (nextAlarmMs > now) {
            schedulePrayerAlarm(context, nextAlarmMs, providerClass)
        }
    }

    private fun formatTime12hCompact(epochMs: Long): String {
        if (epochMs <= 0L) return "--:--"
        val cal = Calendar.getInstance().apply { timeInMillis = epochMs }
        val hour24 = cal.get(Calendar.HOUR_OF_DAY)
        val minute = cal.get(Calendar.MINUTE)
        val hour12 = if (hour24 % 12 == 0) 12 else hour24 % 12
        return String.format(Locale.US, "%02d:%02d", hour12, minute)
    }

    private fun formatTime12hWithPeriod(epochMs: Long): String {
        if (epochMs <= 0L) return "--:--"
        val cal = Calendar.getInstance().apply { timeInMillis = epochMs }
        val hour24 = cal.get(Calendar.HOUR_OF_DAY)
        val minute = cal.get(Calendar.MINUTE)
        val hour12 = if (hour24 % 12 == 0) 12 else hour24 % 12
        val period = if (hour24 >= 12) "م" else "ص"
        return String.format(Locale.US, "%02d:%02d %s", hour12, minute, period)
    }

    private fun isSameCalendarDay(ms1: Long, ms2: Long): Boolean {
        val c1 = Calendar.getInstance().apply { timeInMillis = ms1 }
        val c2 = Calendar.getInstance().apply { timeInMillis = ms2 }
        return c1.get(Calendar.YEAR) == c2.get(Calendar.YEAR) &&
            c1.get(Calendar.DAY_OF_YEAR) == c2.get(Calendar.DAY_OF_YEAR)
    }

    private fun resolveHijriDate(
        prefs: SharedPreferences,
        json: JSONObject?,
        nowMs: Long,
        scheduleValidForToday: Boolean
    ): String {
        if (scheduleValidForToday) {
            val saved = getSafeString(prefs, "hijri_date", "").ifEmpty {
                json?.optString("hijri", "") ?: ""
            }
            if (saved.isNotEmpty() && saved != "طالب العلم") {
                return saved
            }
        }

        // Autonomous ICU Umm al-Qura Hijri formatting (API 24+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                val uLocale = android.icu.util.ULocale("ar@calendar=islamic-umalqura")
                val cal = android.icu.util.Calendar.getInstance(uLocale)
                cal.timeInMillis = nowMs
                val day = cal.get(android.icu.util.Calendar.DAY_OF_MONTH)
                val month = cal.get(android.icu.util.Calendar.MONTH)
                val year = cal.get(android.icu.util.Calendar.YEAR)
                val months = arrayOf(
                    "محرم", "صفر", "ربيع الأول", "ربيع الآخر",
                    "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان",
                    "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
                )
                if (month in 0..11) {
                    return "$day ${months[month]} $year هـ"
                }
            } catch (_: Throwable) {}
        }

        val fallbackSaved = getSafeString(prefs, "hijri_date", "")
        return if (fallbackSaved.isNotEmpty()) fallbackSaved else "طالب العلم"
    }

    private fun resolveCityName(prefs: SharedPreferences, json: JSONObject?): String {
        val saved = getSafeString(prefs, "location_city", "").ifEmpty {
            json?.optString("city", "") ?: ""
        }
        if (saved.isNotEmpty()) return saved
        val tzId = TimeZone.getDefault().id
        return when {
            tzId.contains("Algiers", ignoreCase = true) -> "الجزائر"
            tzId.contains("Tunis", ignoreCase = true) -> "تونس"
            tzId.contains("Casablanca", ignoreCase = true) -> "الدار البيضاء"
            tzId.contains("Cairo", ignoreCase = true) -> "القاهرة"
            else -> "مكة المكرمة"
        }
    }

    private fun resolveCoordinates(prefs: SharedPreferences, json: JSONObject?): Pair<Double, Double> {
        val lat = getSafeDouble(prefs, json, "location_latitude", "latitude")
        val lon = getSafeDouble(prefs, json, "location_longitude", "longitude")
        if (lat != 0.0 || lon != 0.0) {
            return Pair(lat, lon)
        }
        val tzId = TimeZone.getDefault().id
        return when {
            tzId.contains("Algiers", ignoreCase = true) -> Pair(36.7538, 3.0588)
            tzId.contains("Tunis", ignoreCase = true) -> Pair(36.8065, 10.1815)
            tzId.contains("Casablanca", ignoreCase = true) -> Pair(33.5731, -7.5898)
            tzId.contains("Cairo", ignoreCase = true) -> Pair(30.0444, 31.2357)
            else -> Pair(21.4225, 39.8262)
        }
    }

    /**
     * Autonomous Jean Meeus Astronomical Solar Prayer Calculator.
     * Guarantees accurate prayer times even before the Flutter app is ever opened or days later.
     */
    private fun calculateSolarPrayers(
        dateMs: Long,
        latitude: Double,
        longitude: Double,
        timezoneOffsetHours: Double
    ): Map<String, Long> {
        val cal = Calendar.getInstance().apply { timeInMillis = dateMs }
        var y = cal.get(Calendar.YEAR).toDouble()
        var m = (cal.get(Calendar.MONTH) + 1).toDouble()
        val d = cal.get(Calendar.DAY_OF_MONTH).toDouble()

        if (m <= 2.0) {
            y -= 1.0
            m += 12.0
        }
        val a = floor(y / 100.0)
        val b = 2.0 - a + floor(a / 4.0)
        val jd = floor(365.25 * (y + 4716.0)) + floor(30.6001 * (m + 1.0)) + d + b - 1524.5

        val t = (jd - 2451545.0) / 36525.0
        val l0 = (280.46646 + 36000.76983 * t) % 360.0
        val mSun = (357.52911 + 35999.05029 * t) % 360.0
        val mRad = Math.toRadians(mSun)
        val c = (1.914602 - 0.004817 * t) * sin(mRad) +
            0.019993 * sin(2.0 * mRad) +
            0.000289 * sin(3.0 * mRad)
        val trueLong = l0 + c
        val lambdaRad = Math.toRadians(trueLong)

        val eps = Math.toRadians(23.439291 - 0.0130042 * t)
        val declination = asin(sin(eps) * sin(lambdaRad))

        val yTan = tan(eps / 2.0) * tan(eps / 2.0)
        val eotMinutes = 4.0 * Math.toDegrees(
            yTan * sin(2.0 * lambdaRad) -
                2.0 * 0.016708634 * sin(mRad) +
                4.0 * 0.016708634 * yTan * sin(mRad) * cos(2.0 * lambdaRad) -
                0.5 * yTan * yTan * sin(4.0 * lambdaRad) -
                1.25 * 0.016708634 * 0.016708634 * sin(2.0 * mRad)
        )

        val noonHours = 12.0 + timezoneOffsetHours - (longitude / 15.0) - (eotMinutes / 60.0) + (2.0 / 60.0)
        val latRad = Math.toRadians(latitude)

        fun hourAngle(altitudeDeg: Double): Double {
            val altRad = Math.toRadians(altitudeDeg)
            val cosH = (sin(altRad) - sin(latRad) * sin(declination)) / (cos(latRad) * cos(declination))
            val clamped = cosH.coerceIn(-1.0, 1.0)
            return Math.toDegrees(acos(clamped))
        }

        fun msFromHours(hours: Double): Long {
            var adj = hours % 24.0
            if (adj < 0) adj += 24.0
            val h = floor(adj).toInt()
            val mFloat = (adj - h) * 60.0
            val min = floor(mFloat).toInt()
            val sec = floor((mFloat - min) * 60.0).toInt()
            val cObj = Calendar.getInstance().apply {
                timeInMillis = dateMs
                set(Calendar.HOUR_OF_DAY, h)
                set(Calendar.MINUTE, min)
                set(Calendar.SECOND, sec)
                set(Calendar.MILLISECOND, 0)
            }
            return cObj.timeInMillis
        }

        val hSunrise = hourAngle(-0.8333)
        val hFajr = hourAngle(-18.0)
        val hIsha = hourAngle(-17.5)
        val asrAltDeg = Math.toDegrees(atan(1.0 / (1.0 + tan(abs(latRad - declination)))))
        val hAsr = hourAngle(asrAltDeg)

        return mapOf(
            "fajr" to msFromHours(noonHours - (hFajr / 15.0)),
            "dhuhr" to msFromHours(noonHours),
            "asr" to msFromHours(noonHours + (hAsr / 15.0)),
            "maghrib" to msFromHours(noonHours + (hSunrise / 15.0) + (2.0 / 60.0)),
            "isha" to msFromHours(noonHours + (hIsha / 15.0))
        )
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

    private fun loadJsonPayload(prefs: SharedPreferences): JSONObject? {
        val raw = getSafeString(prefs, "prayer_data_json", "")
        if (raw.isEmpty()) return null
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }
    }

    private fun getSafeLong(
        prefs: SharedPreferences,
        json: JSONObject?,
        key: String,
        prayerSlug: String?,
        defaultVal: Long
    ): Long {
        val keys = listOf(key, "flutter.$key")
        for (k in keys) {
            if (prefs.contains(k)) {
                try {
                    val v = prefs.getLong(k, defaultVal)
                    if (v > 0L) return v
                } catch (_: ClassCastException) {
                    try {
                        val v = prefs.getInt(k, defaultVal.toInt()).toLong()
                        if (v > 0L) return v
                    } catch (_: Exception) {}
                }
            }
        }
        if (json != null) {
            if (prayerSlug != null) {
                val pObj = json.optJSONObject("prayers")?.optJSONObject(prayerSlug)
                val v = pObj?.optLong("epoch_ms", 0L) ?: 0L
                if (v > 0L) return v
            }
            val direct = json.optLong(key, 0L)
            if (direct > 0L) return direct
        }
        return defaultVal
    }

    private fun getSafeDouble(
        prefs: SharedPreferences,
        json: JSONObject?,
        key: String,
        jsonKey: String
    ): Double {
        val keys = listOf(key, "flutter.$key")
        for (k in keys) {
            if (prefs.contains(k)) {
                try {
                    val s = prefs.all[k]?.toString()?.toDoubleOrNull()
                    if (s != null && s != 0.0) return s
                } catch (_: Exception) {}
            }
        }
        if (json != null && json.has(jsonKey)) {
            val d = json.optDouble(jsonKey, 0.0)
            if (!d.isNaN() && d != 0.0) return d
        }
        return 0.0
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
        if (prefs.contains("widget_is_dark")) return getSafeBoolean(prefs, "widget_is_dark", true)
        if (prefs.contains("flutter.widget_is_dark")) return getSafeBoolean(prefs, "flutter.widget_is_dark", true)
        val mode = getSafeString(prefs, "prayer_widget_theme_mode", "dark")
        val appTheme = getSafeString(prefs, "theme_mode", "dark")
        return when (mode) {
            "light" -> false
            "dark" -> true
            else -> appTheme != "light"
        }
    }
}
