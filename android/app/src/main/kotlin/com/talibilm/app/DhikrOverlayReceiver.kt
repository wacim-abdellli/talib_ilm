package com.talibilm.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class DhikrOverlayReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val serviceIntent = Intent(context, DhikrOverlayService::class.java).apply {
            action = DhikrOverlayService.ACTION_SHOW_NOW
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (_: Exception) {}
    }
}

