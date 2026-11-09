package com.talibilm.app

import android.app.ActivityManager
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
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
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Opt-in, dismissible dhikr card for Android.
 * Runs briefly to display the card (4.5s), then removes the view,
 * clears the foreground notification, schedules the next alarm, and terminates.
 */
class DhikrOverlayService : Service() {
    private data class CardContent(val label: String, val text: String, val meaning: String)

    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var card: View? = null
    private var isCurrentRunTest = false
    private var contentRotation = 0

    private val autoRemoveRunnable = Runnable {
        removeCardAndStop()
    }

    private val fadeOutRunnable = Runnable {
        try {
            card?.animate()?.alpha(0f)?.setDuration(250L)?.start()
        } catch (_: Exception) {}
    }

    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                removeCardAndStop()
            }
        }
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
        if (!Settings.canDrawOverlays(this)) {
            removeCardAndStop()
            return START_NOT_STICKY
        }

        val hasExtraContent = intent?.hasExtra(EXTRA_TEXT) == true
        isCurrentRunTest = hasExtraContent || intent?.action == ACTION_SHOW_NOW && intent.hasExtra(EXTRA_LABEL)

        if (!isCurrentRunTest) {
            val power = getSystemService(POWER_SERVICE) as PowerManager
            val keyguard = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
            val isInteractive = power.isInteractive
            val isLocked = keyguard.isKeyguardLocked
            val isAppForeground = isAppInForeground()
            val isEnabled = isEnabled()

            if (!isEnabled || !isInteractive || isLocked || isAppForeground) {
                if (isEnabled) {
                    DhikrOverlayScheduler.scheduleNext(this)
                }
                removeCardAndStop()
                return START_NOT_STICKY
            }
        }

        val extraLabel = intent?.getStringExtra(EXTRA_LABEL)
        val extraText = intent?.getStringExtra(EXTRA_TEXT)
        val extraMeaning = intent?.getStringExtra(EXTRA_MEANING)

        val content = if (!extraText.isNullOrBlank()) {
            CardContent(
                label = if (!extraLabel.isNullOrBlank()) extraLabel else "لَحْظَةُ ذِكْر",
                text = extraText,
                meaning = extraMeaning ?: "",
            )
        } else {
            currentContent()
        }

        showCard(content)
        return START_NOT_STICKY
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
                    description = "إظهار بطاقة الذكر العائمة"
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
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle("لحظة ذكر")
                .setContentText("بطاقة الذكر معروضة الآن")
                .setContentIntent(openApp)
                .setOngoing(false)
                .setShowWhen(false)
                .setVisibility(Notification.VISIBILITY_SECRET)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle("لحظة ذكر")
                .setContentText("بطاقة الذكر معروضة الآن")
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

    private fun readInt(prefs: android.content.SharedPreferences, key: String, fallback: Int): Int =
        (prefs.all["flutter.$key"] as? Number)?.toInt() ?: fallback

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

    private fun showCard(entry: CardContent) {
        // Remove any previously showing card immediately
        cleanupCardView()

        val label = TextView(this).apply {
            text = entry.label
            textSize = 11f
            setTextColor(Color.rgb(255, 215, 137))
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.END
            textDirection = TextView.TEXT_DIRECTION_RTL
            maxWidth = dp(310)
        }
        val body = TextView(this).apply {
            text = entry.text
            textSize = 17f
            setTextColor(Color.WHITE)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.END
            textDirection = TextView.TEXT_DIRECTION_RTL
            maxLines = 4
            maxWidth = dp(310)
        }
        val meaning = TextView(this).apply {
            text = entry.meaning
            textSize = 12f
            setTextColor(Color.rgb(246, 230, 195))
            gravity = Gravity.END
            textDirection = TextView.TEXT_DIRECTION_RTL
            maxLines = 2
            maxWidth = dp(310)
        }

        val contentLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16), dp(12), dp(16), dp(12))
            addView(label)
            addView(
                body,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply { topMargin = dp(4) },
            )
            if (entry.meaning.isNotBlank()) {
                addView(
                    meaning,
                    LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                    ).apply { topMargin = dp(4) },
                )
            }
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
            addView(
                contentLayout,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ),
            )
            // Tap on card to dismiss instantly
            isClickable = true
            isFocusable = false
            setOnClickListener {
                removeCardAndStop()
            }
        }
        row.elevation = dp(6).toFloat()
        row.alpha = 0f

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.RIGHT
            y = dp(48)
            x = dp(12)
        }

        try {
            windowManager?.addView(row, params)
            card = row
            row.animate().alpha(1f).setDuration(160L).start()

            handler.removeCallbacks(fadeOutRunnable)
            handler.removeCallbacks(autoRemoveRunnable)
            handler.postDelayed(fadeOutRunnable, 4200L)
            handler.postDelayed(autoRemoveRunnable, 4500L)
        } catch (_: Exception) {
            removeCardAndStop()
        }
    }

    private fun cleanupCardView() {
        handler.removeCallbacks(fadeOutRunnable)
        handler.removeCallbacks(autoRemoveRunnable)
        val view = card ?: return
        card = null
        try {
            windowManager?.removeViewImmediate(view)
        } catch (_: Exception) {
            try {
                windowManager?.removeView(view)
            } catch (_: Exception) {}
        }
    }

    private fun removeCardAndStop() {
        cleanupCardView()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {}

        if (!isCurrentRunTest && isEnabled()) {
            try {
                DhikrOverlayScheduler.scheduleNext(this)
            } catch (_: Exception) {}
        }
        stopSelf()
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        try {
            unregisterReceiver(screenOffReceiver)
        } catch (_: Exception) {}
        cleanupCardView()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val CHANNEL_ID = "talib_dhikr_overlay_silent_v2"
        const val NOTIFICATION_ID = 8490
        const val ACTION_START = "com.talibilm.app.DHIKR_OVERLAY_START"
        const val ACTION_STOP = "com.talibilm.app.DHIKR_OVERLAY_STOP"
        const val ACTION_SHOW_NOW = "com.talibilm.app.DHIKR_OVERLAY_SHOW_NOW"
        const val EXTRA_LABEL = "extra_dhikr_label"
        const val EXTRA_TEXT = "extra_dhikr_text"
        const val EXTRA_MEANING = "extra_dhikr_meaning"

        private val NAMES = listOf(
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الرَّحْمَنُ", "واسع الرحمة بجميع خلقه في الدنيا والآخرة"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الرَّحِيمُ", "ذو الرحمة الخاصة بعباده المؤمنين إحسانًا وتوفيقًا"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْمَلِكُ", "المتصرّف في ملكه بلا منازع، المالك لكل شيء"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْقُدُّوسُ", "المنزَّه عن كل عيب ونقص، الطاهر المبارك"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "السَّلَامُ", "السالم من كل آفة، وواهب الأمان والسلام لعباده"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْمُؤْمِنُ", "المصدّق لوعده، الذي يؤمّن عباده من الخوف والظلم"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْمُهَيْمِنُ", "الرقيب الحافظ لكل شيء، الشاهد المطلع على خلقه"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْعَزِيزُ", "القوي الغالب الذي لا يُعجزه شيءٌ في الأرض ولا في السماء"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْجَبَّارُ", "العليّ القاهر، وجابر قلوب المنكسرين بلطفه ورحمته"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْغَفَّارُ", "السَّتّار لذنوب عباده، المتجاوز عن خطاياهم تكرارًا"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْوَهَّابُ", "كثير النعم والمنح بلا مقابل ولا عوض"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الرَّزَّاقُ", "المتكفّل بأرزاق خلقه، المفيض عليهم بالخيرات"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْفَتَّاحُ", "يفتح أبواب رحمته وخزائن رزقه، ويحكم بين خلقه بالعدل"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْعَلِيمُ", "المحيط بكل شيء ظاهرًا وباطنًا، دقيقًا وجليلاً"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْحَكِيمُ", "الذي يضع الأشياء في مواضعها بعدل تام وحكمة بالغة"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْوَدُودُ", "المحب لأوليائه، والمحبوب في قلوب عباده الصالحين"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْغَفُورُ", "عظيم المغفرة والستر، يغفر الذنب ويعفو عن العقوبة"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الشَّكُورُ", "الذي يزكو عنده القليل من العمل فيضاعف الجزاء عليه"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْقَرِيبُ الْمُجِيبُ", "القريب بعلمه، يجيب دعوة المضطر إذا دعاه"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْحَيُّ الْقَيُّومُ", "الدائم الباقي، القائم بنفسه المقيم لكل ما سواه"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْكَرِيمُ", "الذي يعطي بلا سؤال، ويجود بأفضل مما يؤمّل السائل"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "اللَّطِيفُ", "البارّ بعباده، الموصل للخيرات برفق وإحسان خفي"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "التَّوَّابُ", "الذي يقبل توبة التائبين ويفرح بأوبتهم واستغفارهم"),
            CardContent("مِنْ أَسْمَاءِ اللَّهِ", "الْوَكِيلُ", "الكافي لمن توكل عليه، القائم بمصالح خلقه"),
        )

        private val ADHKAR = listOf(
            CardContent("ذِكْرٌ مَأْثُور", "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", "تُحَطُّ خطاياه وإن كانت مثل زبد البحر"),
            CardContent("ذِكْرٌ مَأْثُور", "سُبْحَانَ اللَّهِ الْعَظِيمِ وَبِحَمْدِهِ", "غُرست له بها نخلةٌ في الجنة"),
            CardContent("ذِكْرٌ مَأْثُور", "سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ", "أحبُّ الكلام إلى الله، وهنّ الباقيات الصالحات"),
            CardContent("ذِكْرٌ مَأْثُور", "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ", "تعدل عتق رقاب، وحرزٌ تام من الشيطان"),
            CardContent("ذِكْرٌ مَأْثُور", "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", "كنزٌ من كنوز الجنة، وباب عظيم لدفع الهم"),
            CardContent("ذِكْرٌ مَأْثُور", "أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ", "مغفرةٌ للذنوب وسعةٌ في الرزق وتفريجٌ للكروب"),
            CardContent("ذِكْرٌ مَأْثُور", "اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ", "من صلّى عليه صلاةً صلّى الله عليه بها عشرًا"),
            CardContent("ذِكْرٌ مَأْثُور", "لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ", "دعوة ذي النون، لم يدعُ بها مكروب إلا فرّج الله عنه"),
            CardContent("ذِكْرٌ مَأْثُور", "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا", "وجبت له الجنة وذاق حلاوة الإيمان"),
            CardContent("ذِكْرٌ مَأْثُور", "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ", "صلاح الشأن كله وتمام التوكل والافتقار"),
            CardContent("ذِكْرٌ مَأْثُور", "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", "أمانٌ من كل خوف وكفايةٌ من كل هم"),
            CardContent("ذِكْرٌ مَأْثُور", "أَسْتَغْفِرُ اللَّهَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ", "غُفرت ذنوبه وإن كان فرّ من الزحف"),
            CardContent("ذِكْرٌ مَأْثُور", "الْحَمْدُ لِلَّهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ", "ثقل في الميزان وأجر عظيم تتسابق الملائكة لكتابته"),
            CardContent("ذِكْرٌ مَأْثُور", "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ", "حفظٌ وحرزٌ تام لا يضره شيء معه"),
            CardContent("ذِكْرٌ مَأْثُور", "سُبْحَانَ اللَّهِ عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ", "تسبيحٌ مضاعف يزن عبادة ساعات طويلة"),
            CardContent("ذِكْرٌ مَأْثُور", "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ", "سيد الاستغفار، من قاله موقنًا به دخل الجنة"),
            CardContent("ذِكْرٌ مَأْثُور", "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", "أفضل الدعاء، تملأ ميزان العبد يوم القيامة"),
            CardContent("ذِكْرٌ مَأْثُور", "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، أَسْتَغْفِرُكَ وَأَتُوبُ إِلَيْكَ", "كفارة للمجلس ومحوٌ لما سواه"),
            CardContent("ذِكْرٌ مَأْثُور", "تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", "يُقال له: كُفيتَ ووُقيتَ وهُديتَ وتنحى عنه الشيطان"),
            CardContent("ذِكْرٌ مَأْثُور", "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ", "السلامة التامة في الدين والنفس والأهل والمال"),
        )

        private val DUAS = listOf(
            CardContent("دُعَاءٌ مُبَارَك", "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", "دعاءٌ جامع لخيري الدنيا والآخرة والوقاية من النار"),
            CardContent("دُعَاءٌ مُبَارَك", "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ", "طلب معونة الله وتوفيقه على دوام الطاعة"),
            CardContent("دُعَاءٌ مُبَارَك", "رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ", "طلب المغفرة والتوبة الصادقة"),
            CardContent("دُعَاءٌ مُبَارَك", "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي", "سؤال الله المحو التام للذنوب والصفح الجميل"),
            CardContent("دُعَاءٌ مُبَارَك", "رَبِّ زِدْنِي عِلْمًا", "سؤال البركة والزيادة في العلم النافع"),
            CardContent("دُعَاءٌ مُبَارَك", "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي", "انشراح الصدر وتيسير الأمور وزوال العسر"),
            CardContent("دُعَاءٌ مُبَارَك", "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى", "جوامع الخير في الدين والدنيا وغنى النفس"),
            CardContent("دُعَاءٌ مُبَارَك", "رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ", "استجلاب فضل الله والافتقار إلى جوده"),
            CardContent("دُعَاءٌ مُبَارَك", "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ", "استعاذة جامعة من آفات النفس وثقل الحياة"),
            CardContent("دُعَاءٌ مُبَارَك", "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً", "الثبات على الإيمان والهدى حتى الممات"),
            CardContent("دُعَاءٌ مُبَارَك", "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا", "دعاء الصباح المبارك لبركة اليوم ورزقه"),
            CardContent("دُعَاءٌ مُبَارَك", "يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ", "سؤال الثبات والاستقامة في زمن الفتن"),
            CardContent("دُعَاءٌ مُبَارَك", "اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي", "سؤال الله السداد في القول والعمل والهدى"),
            CardContent("دُعَاءٌ مُبَارَك", "اللَّهُمَّ آتِ نَفْسِي تَقْوَاهَا، وَزَكِّهَا أَنْتَ خَيْرُ مَنْ زَكَّاهَا", "تزكية النفس وصلاح السريرة والأخلاق"),
            CardContent("دُعَاءٌ مُبَارَك", "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا", "صلاح الأهل والذرية والقدوة في الخير"),
            CardContent("دُعَاءٌ مُبَارَك", "اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا، وَفِي سَمْعِي نُورًا، وَفِي بَصَرِي نُورًا", "سؤال النور والبركة في الحواس والأركان"),
        )

        private val QURAN = listOf(
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾", "سورة الرعد • ٢٨"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ﴾", "سورة البقرة • ١٥٢"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ﴾", "سورة البقرة • ١٨٦"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿إِنَّ مَعَ الْعُسْرِ يُسْرًا﴾", "سورة الشرح • ٦"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿وَمَنْ يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ﴾", "سورة الطلاق • ٣"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿وَمَنْ يَتَّقِ اللَّهَ يَجْعَلْ لَهُ مَخْرَجًا • وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ﴾", "سورة الطلاق • ٢-٣"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَى أَنْفُسِهِمْ لَا تَقْنَطُوا مِنْ رَحْمَةِ اللَّهِ﴾", "سورة الزمر • ٥٣"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿وَهُوَ مَعَكُمْ أَيْنَ مَا كُنْتُمْ﴾", "سورة الحديد • ٤"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿وَاصْبِرْ لِحُكْمِ رَبِّكَ فَإِنَّكَ بِأَعْيُنِنَا﴾", "سورة الطور • ٤٨"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿إِنَّ اللَّهَ مَعَ الصَّابِرِينَ﴾", "سورة البقرة • ١٥٣"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿وَتَوَكَّلْ عَلَى الْحَيِّ الَّذِي لَا يَمُوتُ وَسَبِّحْ بِحَمْدِهِ﴾", "سورة الفرقان • ٥٨"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ﴾", "سورة غافر • ٦٠"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ﴾", "سورة الأعراف • ١٥٦"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿فَصَبْرٌ جَمِيلٌ وَاللَّهُ الْمُسْتَعَانُ﴾", "سورة يوسف • ١٨"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿إِنَّ رَبِّي قَرِيبٌ مُجِيبٌ﴾", "سورة هود • ٦١"),
            CardContent("آيَةٌ قُرْآنِيَّة", "﴿وَمَا كَانَ اللَّهُ لِيُعْجِزَهُ مِنْ شَيْءٍ فِي السَّمَاوَاتِ وَلَا فِي الْأَرْضِ﴾", "سورة فاطر • ٤٤"),
        )

        private val HADITH = listOf(
            CardContent("حَدِيثٌ نَبَوِيّ", "«إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى»", "صحيح البخاري • ١"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«الدِّينُ النَّصِيحَةُ: لِلَّهِ، وَلِكِتَابِهِ، وَلِرَسُولِهِ، وَلِأَئِمَّةِ الْمُسْلِمِينَ وَعَامَّتِهِمْ»", "صحيح مسلم • ٥٥"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ»", "متفق عليه"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ»", "متفق عليه"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ: سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ»", "متفق عليه"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ»", "صحيح مسلم"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ»", "سنن الترمذي"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«أَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ»", "متفق عليه"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«احْفَظِ اللَّهَ يَحْفَظْكَ، احْفَظِ اللَّهَ تَجِدْهُ تُجَاهَكَ، إِذَا سَأَلْتَ فَاسْأَلِ اللَّهَ»", "سنن الترمذي"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«مَنْ صَلَّى عَلَيَّ صَلَاةً صَلَّى اللَّهُ عَلَيْهِ بِهَا عَشْرًا»", "صحيح مسلم"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ»", "صحيح البخاري"),
            CardContent("حَدِيثٌ نَبَوِيّ", "«عَجَبًا لِأَمْرِ الْمُؤْمِنِ، إِنَّ أَمْرَهُ كُلَّهُ خَيْرٌ»", "صحيح مسلم"),
        )

        private val MIXED = NAMES + ADHKAR + DUAS + QURAN + HADITH
    }
}
