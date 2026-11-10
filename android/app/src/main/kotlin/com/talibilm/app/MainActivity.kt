package com.talibilm.app

import android.content.ComponentCallbacks
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.talibilm.app/dhikr_overlay"

    companion object {
        private var configCallbacksRegistered = false

        fun syncSystemUiModeAndRefreshWidgets(context: Context, newConfig: Configuration) {
            try {
                val isNight = (newConfig.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                    Configuration.UI_MODE_NIGHT_YES
                val widgetData = HomeWidgetPlugin.getData(context)
                val prevNight = if (widgetData.contains("last_seen_system_night")) {
                    widgetData.getBoolean("last_seen_system_night", !isNight)
                } else {
                    !isNight
                }
                if (prevNight != isNight) {
                    widgetData.edit()
                        .putBoolean("last_seen_system_night", isNight)
                        .putBoolean("widget_is_dark", isNight)
                        .putString("prayer_widget_theme_mode", if (isNight) "dark" else "light")
                        .apply()
                }
            } catch (_: Exception) {}
            WidgetChronometerHelper.refreshAllWidgets(context)
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        syncSystemUiModeAndRefreshWidgets(applicationContext, newConfig)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (!configCallbacksRegistered) {
            configCallbacksRegistered = true
            val appCtx = applicationContext
            appCtx.registerComponentCallbacks(object : ComponentCallbacks {
                override fun onConfigurationChanged(newConfig: Configuration) {
                    syncSystemUiModeAndRefreshWidgets(appCtx, newConfig)
                }

                override fun onLowMemory() {}
            })
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasOverlayPermission" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)
                    )
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            try {
                                val intent = Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName"),
                                )
                                startActivity(intent)
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    "startOverlayService" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)) {
                            try {
                                val args = call.arguments as? Map<*, *>
                                val resetFirstTrigger = args?.get("resetFirstTrigger") as? Boolean ?: false
                                if (resetFirstTrigger) {
                                    DhikrOverlayScheduler.resetForImmediateSession(this)
                                }
                                DhikrOverlayScheduler.scheduleNext(
                                    this,
                                    delayMsOverride = if (resetFirstTrigger) 12_000L else null,
                                )
                                val serviceIntent = Intent(this, DhikrOverlayService::class.java).apply {
                                    action = DhikrOverlayService.ACTION_START
                                    putExtra(DhikrOverlayService.EXTRA_KICKOFF_FAST, resetFirstTrigger)
                                }
                                try {
                                    startService(serviceIntent)
                                } catch (_: Exception) {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                        startForegroundService(serviceIntent)
                                    }
                                }
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        } else result.success(false)
                    }
                    "showOverlayTest" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)) {
                            try {
                                val args = call.arguments as? Map<*, *>
                                val label = args?.get("label") as? String
                                val text = args?.get("text") as? String
                                val meaning = args?.get("meaning") as? String
                                val intent = Intent(this, DhikrOverlayService::class.java).apply {
                                    action = DhikrOverlayService.ACTION_SHOW_NOW
                                    putExtra(DhikrOverlayService.EXTRA_LABEL, label)
                                    putExtra(DhikrOverlayService.EXTRA_TEXT, text)
                                    putExtra(DhikrOverlayService.EXTRA_MEANING, meaning)
                                }
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    startForegroundService(intent)
                                } else {
                                    startService(intent)
                                }
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        } else result.success(false)
                    }
                    "stopOverlayService" -> {
                        try {
                            DhikrOverlayScheduler.cancel(this)
                            stopService(Intent(this, DhikrOverlayService::class.java))
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
