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
    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var card: View? = null
    private var isCurrentRunTest = false

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
            DhikrCardEntry(
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

    private fun currentContent(): DhikrCardEntry {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val contentMode = readInt(prefs, "dhikr_moment_content", 2)
        val lastCategoryIndex = readInt(prefs, "dhikr_moment_last_category_index", -1)
        val lastItemText = prefs.getString("flutter.dhikr_moment_last_item_text", "") ?: ""

        val candidateCategories = if (contentMode == 2) {
            // Mixed mode: strictly exclude the previous category so consecutive
            // appearances NEVER show the same section twice.
            val filtered = listOf(0, 1, 3, 4, 5).filter { it != lastCategoryIndex }
            if (filtered.isNotEmpty()) filtered else listOf(0, 1, 3, 4, 5)
        } else {
            listOf(contentMode)
        }

        val chosenCategory = candidateCategories.random()
        val pool = when (chosenCategory) {
            0 -> DhikrMomentContent.NAMES
            1 -> DhikrMomentContent.ADHKAR
            3 -> DhikrMomentContent.DUAS
            4 -> DhikrMomentContent.QURAN
            5 -> DhikrMomentContent.HADITH
            else -> DhikrMomentContent.ADHKAR
        }

        val candidateItems = if (pool.size > 1) pool.filter { it.text != lastItemText } else pool
        val selected = (if (candidateItems.isNotEmpty()) candidateItems else pool).random()

        prefs.edit()
            .putInt("flutter.dhikr_moment_last_category_index", chosenCategory)
            .putString("flutter.dhikr_moment_last_item_text", selected.text)
            .apply()

        return selected
    }

    private fun showCard(entry: DhikrCardEntry) {
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
    }
}
