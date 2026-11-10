package com.talibilm.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings

class DhikrOverlayReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            return
        }
        val prefs = DhikrOverlayScheduler.prefs(context)
        if (!DhikrOverlayScheduler.isEnabled(prefs)) {
            return
        }

        val incomingAction = intent?.action ?: DhikrOverlayService.ACTION_ALARM_CHECK
        val serviceIntent = Intent(context, DhikrOverlayService::class.java).apply {
            action = when (incomingAction) {
                Intent.ACTION_USER_PRESENT -> DhikrOverlayService.ACTION_USER_UNLOCKED
                else -> incomingAction
            }
        }

        try {
            context.startService(serviceIntent)
        } catch (_: Exception) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                }
            } catch (_: Exception) {}
        }
    }
}
