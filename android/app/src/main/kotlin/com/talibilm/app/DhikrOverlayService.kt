package com.talibilm.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import java.util.Calendar
import kotlin.math.max
import kotlin.math.roundToInt

/** Opt-in, dismissible dhikr card for Android. It runs only after the user
 * grants draw-over permission and sees a persistent foreground notification. */
class DhikrOverlayService : Service() {
    private data class CardContent(val label: String, val text: String, val meaning: String)

    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var card: android.view.View? = null
    private var contentRotation = 0
    private val hideCard = Runnable {
        card?.animate()?.alpha(0f)?.setDuration(300)?.withEndAction { removeCard() }
    }
    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) removeCard()
        }
    }
    private val showCardRunnable = Runnable {
        try {
            val power = getSystemService(POWER_SERVICE) as PowerManager
            if (power.isInteractive &&
                !isLockScreenShowing() &&
                !isAppInForeground() &&
                Settings.canDrawOverlays(this)
            ) showCard()
        } catch (_: Exception) { }
        scheduleNext()
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createChannel()
        startForegroundCompat()
        val screenOffFilter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenOffReceiver, screenOffFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(screenOffReceiver, screenOffFilter)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val isTest = intent?.action == ACTION_SHOW_NOW
        if (!Settings.canDrawOverlays(this) || (!isEnabled() && !isTest)) {
            stopSelf()
            return START_NOT_STICKY
        }
        handler.removeCallbacks(showCardRunnable)
        handler.removeCallbacks(hideCard)
        if (intent?.action == ACTION_SHOW_NOW) showCard()
        if (isEnabled()) {
            try {
                scheduleNext()
            } catch (error: Exception) {
                Log.e(TAG, "Could not schedule the next floating dhikr", error)
            }
        }
        return START_STICKY
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            try {
                manager.deleteNotificationChannel("talib_dhikr_overlay_service")
            } catch (_: Exception) {}

            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "تذكير لحظة ذكر",
                    NotificationManager.IMPORTANCE_MIN,
                ).apply {
                    description = "إبقاء بطاقة الذكر العائمة متاحة"
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                    lockscreenVisibility = Notification.VISIBILITY_SECRET
                },
            )
        }
    }

    private fun startForegroundCompat() {
        val openApp = PendingIntent.getActivity(
            this, 0, packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle("لحظة ذكر مفعّلة")
                .setContentText("تظهر بطاقة ذكر صغيرة حسب جدولك")
                .setContentIntent(openApp)
                .setOngoing(false)
                .setShowWhen(false)
                .setVisibility(Notification.VISIBILITY_SECRET)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle("لحظة ذكر مفعّلة")
                .setContentText("تظهر بطاقة ذكر صغيرة حسب جدولك")
                .setContentIntent(openApp)
                .setOngoing(false)
                .setPriority(Notification.PRIORITY_MIN)
                .build()
        }
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun isEnabled(): Boolean =
        getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .getBoolean("flutter.dhikr_moment_enabled", false)

    private fun isAppInForeground(): Boolean {
        val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        return activityManager.runningAppProcesses?.any { process ->
            process.processName == packageName &&
                process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        } == true
    }

    private fun isLockScreenShowing(): Boolean =
        (getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked

    private fun readInt(prefs: android.content.SharedPreferences, key: String, fallback: Int): Int =
        (prefs.all["flutter.$key"] as? Number)?.toInt() ?: fallback

    private fun scheduleNext() {
        handler.removeCallbacks(showCardRunnable)
        if (!isEnabled()) {
            stopSelf()
            return
        }
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val count = readInt(prefs, "dhikr_moment_times_per_day", 20).coerceIn(1, 50)
        val start = readInt(prefs, "dhikr_moment_start_minutes", 480).coerceIn(0, 1439)
        val end = readInt(prefs, "dhikr_moment_end_minutes", 1320).coerceIn(1, 1440)
        if (end <= start) return
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
        val delay = max(1000L, target.timeInMillis - System.currentTimeMillis())
        handler.postDelayed(showCardRunnable, delay)
    }

    private fun currentContent(): CardContent {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val content = when (readInt(prefs, "dhikr_moment_content", 2)) {
            0 -> NAMES
            1 -> ADHKAR
            2 -> MIXED
            3 -> DUAS
            4 -> QURAN
            5 -> HADITH
            else -> MIXED
        }
        return content[contentRotation++ % content.size]
    }

    private fun showCard() {
        removeCard()
        val entry = currentContent()
        val label = TextView(this).apply {
            text = entry.label
            textSize = 11f
            setTextColor(Color.rgb(255, 215, 137))
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.END
            textDirection = TextView.TEXT_DIRECTION_RTL
            maxWidth = dp(300)
        }
        val body = TextView(this).apply {
            text = entry.text
            textSize = 18f
            setTextColor(Color.WHITE)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.END
            textDirection = TextView.TEXT_DIRECTION_RTL
            maxLines = 3
            maxWidth = dp(300)
        }
        val meaning = TextView(this).apply {
            text = entry.meaning
            textSize = 13f
            setTextColor(Color.rgb(246, 230, 195))
            gravity = Gravity.END
            textDirection = TextView.TEXT_DIRECTION_RTL
            maxLines = 2
            maxWidth = dp(300)
        }
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16), dp(12), dp(16), dp(12))
            addView(label)
            addView(body, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(5) })
            addView(meaning, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(4) })
        }
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT,
                intArrayOf(Color.rgb(103, 66, 18), Color.rgb(137, 88, 20)),
            ).apply {
                cornerRadius = dp(18).toFloat()
                setStroke(dp(1), Color.rgb(214, 170, 89))
            }
            addView(content, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ))
        }
        row.elevation = dp(5).toFloat()
        row.alpha = 0f
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.RIGHT
            y = dp(48)
            x = dp(12)
        }
        try {
            windowManager?.addView(row, params)
            card = row
            row.animate().alpha(1f).setDuration(160).start()
            handler.removeCallbacks(hideCard)
            handler.postDelayed(hideCard, CARD_DURATION_MS - FADE_DURATION_MS)
        } catch (_: Exception) {
            removeCard()
        }
    }

    private fun removeCard() {
        handler.removeCallbacks(hideCard)
        card?.let { view ->
            try { windowManager?.removeView(view) } catch (_: Exception) { }
        }
        card = null
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        try { unregisterReceiver(screenOffReceiver) } catch (_: Exception) { }
        removeCard()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val CHANNEL_ID = "talib_dhikr_overlay_silent_v2"
        const val NOTIFICATION_ID = 8490
        const val ACTION_START = "com.talibilm.app.DHIKR_OVERLAY_START"
        const val ACTION_STOP = "com.talibilm.app.DHIKR_OVERLAY_STOP"
        const val ACTION_SHOW_NOW = "com.talibilm.app.DHIKR_OVERLAY_SHOW_NOW"
        private const val CARD_DURATION_MS = 3_000L
        private const val FADE_DURATION_MS = 300L
        private const val DAY_MS = 86_400_000L
        private const val TAG = "DhikrOverlayService"
        private val NAMES = listOf(
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الرَّحْمَنُ", "واسع الرحمة بخلقه"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الرَّحِيمُ", "يرحم عباده ويُحسن إليهم"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْمَلِكُ", "له الملك والتدبير"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْقُدُّوسُ", "المنزَّه عن كل نقص"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "السَّلَامُ", "السالم من كل عيب ونقص"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْمُؤْمِنُ", "يؤمّن عباده ولا يظلمهم"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْمُهَيْمِنُ", "الرقيب الحافظ لكل شيء"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْعَزِيزُ", "له العزة والغلبة"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْجَبَّارُ", "العليّ القاهر، وجابر الكسير"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْمُتَكَبِّرُ", "له الكبرياء والعظمة"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْخَالِقُ", "خالق كل شيء"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْبَارِئُ", "مُنشئ الخلق على ما شاء"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْمُصَوِّرُ", "يعطي كل مخلوق صورته"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْغَفَّارُ", "كثير المغفرة لمن تاب"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْقَهَّارُ", "القاهر فوق عباده"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْوَهَّابُ", "كثير العطاء بلا مقابل"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الرَّزَّاقُ", "يرزق خلقه ويكفيهم"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْفَتَّاحُ", "يفتح أبواب رحمته وخيره"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْعَلِيمُ", "لا يخفى عليه شيء"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْحَكِيمُ", "يضع الأمور مواضعها بحكمة"),
        )
        private val ADHKAR = listOf(
            CardContent("ذِكْرٌ", "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", "تنزيهٌ لله وحمدٌ له"),
            CardContent("ذِكْرٌ", "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ", "إفراد الله بالعبادة والثناء"),
            CardContent("ذِكْرٌ", "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ", "طلب المغفرة والرجوع إلى الله"),
            CardContent("ذِكْرٌ", "سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ", "تسبيحٌ وحمدٌ وتهليلٌ وتكبير"),
            CardContent("ذِكْرٌ", "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", "التبرؤ من الحول والقوة إلا بالله"),
            CardContent("ذِكْرٌ", "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ", "صلاةٌ وسلامٌ على النبي ﷺ"),
            CardContent("دُعَاءٌ", "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ", "سؤال الله العون على الطاعة"),
            CardContent("دُعَاءٌ", "يَا حَيُّ يَا قَيُّومُ، بِرَحْمَتِكَ أَسْتَغِيثُ", "التوسل إلى الله الحي القيوم"),
            CardContent("دُعَاءٌ", "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي", "سؤال الله العفو"),
            CardContent("دُعَاءٌ", "رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ، إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ", "دعاءٌ بالمغفرة والتوبة"),
            CardContent("ذِكْرٌ", "الْحَمْدُ لِلَّهِ عَلَى كُلِّ حَالٍ", "حمدُ الله في السراء والضراء"),
            CardContent("دُعَاءٌ", "اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي", "سؤال الله الهداية والتوفيق"),
            CardContent("دُعَاءٌ", "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ", "سؤال الله العفو والسلامة"),
            CardContent("ذِكْرٌ", "حَسْبِيَ اللَّهُ وَنِعْمَ الْوَكِيلُ", "توكلٌ على الله"),
            CardContent("ذِكْرٌ", "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ نَبِيًّا", "تجديد الرضا بالله والإسلام والنبي ﷺ"),
            CardContent("ذِكْرٌ", "سُبْحَانَ اللَّهِ الْعَظِيمِ وَبِحَمْدِهِ", "تنزيهٌ لله العظيم وحمدٌ له"),
        )
        private val DUAS = listOf(
            CardContent("دُعَاءٌ", "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ", "سؤال الله العون على الطاعة"),
            CardContent("دُعَاءٌ", "رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ", "سؤال المغفرة والتوبة"),
            CardContent("دُعَاءٌ", "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ", "سؤال الله العفو والسلامة"),
            CardContent("دُعَاءٌ", "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي", "دعاءٌ بالعفو"),
            CardContent("دُعَاءٌ", "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", "دعاءٌ جامعٌ لخيري الدارين"),
            CardContent("دُعَاءٌ", "رَبِّ زِدْنِي عِلْمًا", "سؤال الله الزيادة في العلم"),
            CardContent("دُعَاءٌ", "اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي", "سؤال الهداية والتوفيق"),
            CardContent("دُعَاءٌ", "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ", "استغاثةٌ برحمة الله"),
        )
        private val QURAN = listOf(
            CardContent("آيَةٌ • البَقَرَة ١٥٢", "فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ", "تذكيرٌ بالذكر والشكر"),
            CardContent("آيَةٌ • الرَّعْد ٢٨", "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ", "من آيةٍ عن طمأنينة القلوب بالذكر"),
            CardContent("آيَةٌ • الشَّرْح ٦", "إِنَّ مَعَ الْعُسْرِ يُسْرًا", "من سورة الشرح"),
            CardContent("آيَةٌ • الحَدِيد ٤", "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنْتُمْ", "من آيةٍ تذكّر بعلم الله وإحاطته"),
            CardContent("آيَةٌ • الزُّمَر ٥٣", "لَا تَقْنَطُوا مِنْ رَحْمَةِ اللَّهِ", "دعوةٌ لعدم اليأس من رحمة الله"),
            CardContent("آيَةٌ • البَقَرَة ١٥٣", "إِنَّ اللَّهَ مَعَ الصَّابِرِينَ", "من آيةٍ في الصبر والصلاة"),
            CardContent("آيَةٌ • الطَّلَاق ٣", "وَمَنْ يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ", "من آيةٍ في التوكل على الله"),
            CardContent("آيَةٌ • البَقَرَة ١٨٦", "فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ", "من آيةٍ في قرب الله وإجابة الدعاء"),
        )
        private val HADITH = listOf(
            CardContent("حَدِيثٌ • البُخَارِي ١", "إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ", "النية أساس العمل"),
            CardContent("حَدِيثٌ • مُسْلِم ٥٥", "الدِّينُ النَّصِيحَةُ", "حديثٌ في النصيحة"),
            CardContent("حَدِيثٌ • مُتَّفَقٌ عَلَيْهِ", "فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ", "إرشادٌ لحفظ اللسان"),
            CardContent("حَدِيثٌ • مُتَّفَقٌ عَلَيْهِ", "لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ", "من كمال الإيمان محبة الخير للآخرين"),
        )
        private val MIXED = NAMES + ADHKAR + DUAS + QURAN + HADITH
    }
}
