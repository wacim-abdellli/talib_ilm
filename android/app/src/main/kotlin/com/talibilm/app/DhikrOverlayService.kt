package com.talibilm.app

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
import android.view.animation.DecelerateInterpolator
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Smart Active-Usage Dhikr Moment Service for Android.
 *
 * Tracks when the user is actually using their phone (unlocked + interactive screen):
 * 1. Never renders while the screen is off or locked; if a slot becomes due while locked,
 *    it marks `pending_on_unlock` and displays 2.5s after the user unlocks their phone.
 * 2. While the user continues actively using their phone across any app, paces reminders
 *    at `computeActiveIntervalMs` (~5 min for 50/day) and rotates categories without consecutive repeats.
 */
class DhikrOverlayService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var card: View? = null
    private var receiverRegistered = false

    private val autoRemoveRunnable = Runnable {
        finishCardDisplay()
    }

    private val fadeOutRunnable = Runnable {
        try {
            card?.animate()
                ?.alpha(0f)
                ?.translationY(-dp(10).toFloat())
                ?.setDuration(260L)
                ?.start()
        } catch (_: Exception) {}
    }

    private val unlockTriggerRunnable = Runnable {
        evaluateAndShowIfDue(isUnlockEvent = true)
    }

    private val activeUsageCheckRunnable = Runnable {
        evaluateAndShowIfDue(isUnlockEvent = false)
    }

    private val usageStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    handler.removeCallbacks(unlockTriggerRunnable)
                    handler.removeCallbacks(activeUsageCheckRunnable)
                    cleanupCardView()
                    clearForegroundNotification()
                    if (isEnabled()) {
                        DhikrOverlayScheduler.scheduleNext(this@DhikrOverlayService)
                    }
                }
                Intent.ACTION_USER_PRESENT -> {
                    scheduleUnlockEvaluation(delayMs = 1200L)
                }
                Intent.ACTION_SCREEN_ON -> {
                    if (isDeviceActivelyUsed()) {
                        scheduleUnlockEvaluation(delayMs = 1400L)
                    }
                }
                Intent.ACTION_TIME_TICK -> {
                    if (isDeviceActivelyUsed()) {
                        evaluateAndShowIfDue(isUnlockEvent = false)
                    }
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createChannel()
        startForegroundSafe()
        registerUsageReceiver()
    }

    private fun registerUsageReceiver() {
        if (receiverRegistered) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_TIME_TICK)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(usageStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(usageStateReceiver, filter)
            }
            receiverRegistered = true
        } catch (_: Exception) {}
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundSafe()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            stopAndCleanupService()
            return START_NOT_STICKY
        }

        val action = intent?.action ?: ACTION_START
        if (action == ACTION_STOP) {
            stopAndCleanupService()
            return START_NOT_STICKY
        }

        val hasExplicitTestContent = intent?.hasExtra(EXTRA_TEXT) == true
        if (hasExplicitTestContent) {
            val extraLabel = intent?.getStringExtra(EXTRA_LABEL)
            val extraText = intent?.getStringExtra(EXTRA_TEXT) ?: ""
            val extraMeaning = intent?.getStringExtra(EXTRA_MEANING) ?: ""
            showCard(
                DhikrCardEntry(
                    label = if (!extraLabel.isNullOrBlank()) extraLabel else "لَحْظَةُ ذِكْر",
                    text = extraText,
                    meaning = extraMeaning,
                ),
                isTestRun = true,
            )
            if (isEnabled()) {
                scheduleNextActiveCheck(delayMs = DhikrOverlayScheduler.computeNextDelayMs(DhikrOverlayScheduler.prefs(this)))
            }
            return START_STICKY
        }

        if (!isEnabled()) {
            stopAndCleanupService()
            return START_NOT_STICKY
        }

        when (action) {
            ACTION_START -> {
                val kickOffFast = intent?.getBooleanExtra(EXTRA_KICKOFF_FAST, false) == true
                if (kickOffFast && isDeviceActivelyUsed()) {
                    scheduleNextActiveCheck(delayMs = 6_000L)
                    DhikrOverlayScheduler.scheduleNext(this, delayMsOverride = 8_000L)
                } else {
                    evaluateAndShowIfDue(isUnlockEvent = false)
                }
            }
            ACTION_USER_UNLOCKED -> {
                scheduleUnlockEvaluation(delayMs = 1200L)
            }
            ACTION_ALARM_CHECK, ACTION_SHOW_NOW -> {
                evaluateAndShowIfDue(isUnlockEvent = false)
            }
            else -> {
                evaluateAndShowIfDue(isUnlockEvent = false)
            }
        }

        return START_STICKY
    }

    private fun scheduleUnlockEvaluation(delayMs: Long = 1200L) {
        if (!isEnabled()) return
        handler.removeCallbacks(unlockTriggerRunnable)
        handler.postDelayed(unlockTriggerRunnable, delayMs)
    }

    private fun scheduleNextActiveCheck(delayMs: Long) {
        handler.removeCallbacks(activeUsageCheckRunnable)
        if (!isEnabled() || !isDeviceActivelyUsed()) return
        val safeDelay = delayMs.coerceIn(5_000L, 60_000L)
        handler.postDelayed(activeUsageCheckRunnable, safeDelay)
    }

    private fun isDeviceActivelyUsed(): Boolean {
        val power = getSystemService(POWER_SERVICE) as? PowerManager ?: return false
        val keyguard = getSystemService(KEYGUARD_SERVICE) as? KeyguardManager ?: return false
        return power.isInteractive && !keyguard.isKeyguardLocked
    }

    private fun evaluateAndShowIfDue(isUnlockEvent: Boolean) {
        val prefs = DhikrOverlayScheduler.prefs(this)
        if (!DhikrOverlayScheduler.isEnabled(prefs)) {
            stopAndCleanupService()
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            stopAndCleanupService()
            return
        }

        val activelyUsed = isDeviceActivelyUsed()
        if (!activelyUsed) {
            // Phone is locked or screen is off: never show on a locked screen!
            // Instead, mark pending so it immediately greets the user upon unlocking.
            DhikrOverlayScheduler.markPendingOnUnlock(prefs)
            DhikrOverlayScheduler.scheduleNext(this)
            return
        }

        if (card != null) {
            // A card is already visible on screen; wait for it to finish.
            return
        }

        if (DhikrOverlayScheduler.isDueNow(prefs, isUnlockEvent = isUnlockEvent, isInteractiveActiveUse = true)) {
            val entry = currentContent()
            DhikrOverlayScheduler.recordShownNow(prefs)
            showCard(entry, isTestRun = false)
        }

        val nextDelay = DhikrOverlayScheduler.computeNextDelayMs(prefs)
        scheduleNextActiveCheck(nextDelay)
        DhikrOverlayScheduler.scheduleNext(this, delayMsOverride = nextDelay)
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
                    description = "إظهار بطاقة الذكر العائمة أثناء استخدام الهاتف"
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                    lockscreenVisibility = Notification.VISIBILITY_SECRET
                },
            )
        }
    }

    private fun startForegroundSafe() {
        try {
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
                    .setContentText("بطاقة الذكر نشطة أثناء استخدام الهاتف")
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
                    .setContentText("بطاقة الذكر نشطة أثناء استخدام الهاتف")
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
        } catch (_: Exception) {}
    }

    private fun clearForegroundNotification() {
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
    }

    private fun isEnabled(): Boolean =
        DhikrOverlayScheduler.isEnabled(DhikrOverlayScheduler.prefs(this))

    private fun currentContent(): DhikrCardEntry {
        val prefs = DhikrOverlayScheduler.prefs(this)
        val contentMode = DhikrOverlayScheduler.readInt(prefs, "dhikr_moment_content", 2)
        val lastCategoryIndex = DhikrOverlayScheduler.readInt(prefs, "dhikr_moment_last_category_index", -1)
        val lastItemText = prefs.getString("flutter.dhikr_moment_last_item_text", "") ?: ""

        val candidateCategories = if (contentMode == 2) {
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
            .putLong("flutter.dhikr_moment_last_category_index", chosenCategory.toLong())
            .putString("flutter.dhikr_moment_last_item_text", selected.text)
            .apply()

        return selected
    }

    private fun showCard(entry: DhikrCardEntry, isTestRun: Boolean) {
        cleanupCardView()

        val label = TextView(this).apply {
            text = entry.label
            textSize = 11f
            setTextColor(Color.rgb(255, 215, 137))
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.END
            textDirection = TextView.TEXT_DIRECTION_RTL
            maxWidth = dp(320)
        }
        val body = TextView(this).apply {
            text = entry.text
            textSize = 16.5f
            setTextColor(Color.WHITE)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.END
            textDirection = TextView.TEXT_DIRECTION_RTL
            maxLines = 4
            maxWidth = dp(320)
        }
        val meaning = TextView(this).apply {
            text = entry.meaning
            textSize = 12f
            setTextColor(Color.rgb(246, 230, 195))
            gravity = Gravity.END
            textDirection = TextView.TEXT_DIRECTION_RTL
            maxLines = 2
            maxWidth = dp(320)
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
                intArrayOf(Color.rgb(92, 58, 14), Color.rgb(132, 84, 18)),
            ).apply {
                cornerRadius = dp(18).toFloat()
                setStroke(dp(1), Color.rgb(218, 174, 92))
            }
            addView(
                contentLayout,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ),
            )
            isClickable = true
            isFocusable = false
            setOnClickListener {
                finishCardDisplay()
            }
        }
        row.elevation = dp(8).toFloat()
        row.alpha = 0f
        row.translationY = -dp(14).toFloat()

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
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = dp(52)
        }

        try {
            windowManager?.addView(row, params)
            card = row
            row.animate()
                .alpha(1f)
                .translationY(0f)
                .setDuration(220L)
                .setInterpolator(DecelerateInterpolator())
                .start()

            handler.removeCallbacks(fadeOutRunnable)
            handler.removeCallbacks(autoRemoveRunnable)
            val displayDuration = if (isTestRun) 4800L else 5800L
            handler.postDelayed(fadeOutRunnable, displayDuration - 300L)
            handler.postDelayed(autoRemoveRunnable, displayDuration)
        } catch (_: Exception) {
            finishCardDisplay()
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

    private fun finishCardDisplay() {
        cleanupCardView()
        if (isEnabled()) {
            val prefs = DhikrOverlayScheduler.prefs(this)
            val nextDelay = DhikrOverlayScheduler.computeNextDelayMs(prefs)
            scheduleNextActiveCheck(nextDelay)
            DhikrOverlayScheduler.scheduleNext(this, delayMsOverride = nextDelay)
        } else {
            stopAndCleanupService()
        }
    }

    private fun stopAndCleanupService() {
        handler.removeCallbacksAndMessages(null)
        cleanupCardView()
        clearForegroundNotification()
        stopSelf()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        if (isEnabled()) {
            DhikrOverlayScheduler.scheduleNext(this, delayMsOverride = 15_000L)
        }
        super.onTaskRemoved(rootIntent)
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        if (receiverRegistered) {
            try {
                unregisterReceiver(usageStateReceiver)
            } catch (_: Exception) {}
            receiverRegistered = false
        }
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
        const val ACTION_ALARM_CHECK = "com.talibilm.app.DHIKR_OVERLAY_ALARM_CHECK"
        const val ACTION_USER_UNLOCKED = "com.talibilm.app.DHIKR_OVERLAY_USER_UNLOCKED"
        const val EXTRA_KICKOFF_FAST = "extra_dhikr_kickoff_fast"
        const val EXTRA_LABEL = "extra_dhikr_label"
        const val EXTRA_TEXT = "extra_dhikr_text"
        const val EXTRA_MEANING = "extra_dhikr_meaning"
    }
}
