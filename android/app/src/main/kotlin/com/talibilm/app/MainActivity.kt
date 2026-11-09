package com.talibilm.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.talibilm.app/dhikr_overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                                val intent = Intent(this, DhikrOverlayService::class.java)
                                    .setAction(DhikrOverlayService.ACTION_START)
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent)
                                else startService(intent)
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        } else result.success(false)
                    }
                    "showOverlayTest" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)) {
                            try {
                                val intent = Intent(this, DhikrOverlayService::class.java)
                                    .setAction(DhikrOverlayService.ACTION_SHOW_NOW)
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent)
                                else startService(intent)
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        } else result.success(false)
                    }
                    "stopOverlayService" -> {
                        stopService(Intent(this, DhikrOverlayService::class.java))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
