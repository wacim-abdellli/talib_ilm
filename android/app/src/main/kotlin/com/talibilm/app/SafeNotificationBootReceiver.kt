package com.talibilm.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * Intercepts BOOT_COMPLETED and MY_PACKAGE_REPLACED (app update) to ensure
 * past-due notifications are pruned before rescheduling. This completely
 * prevents obsolete alarms (e.g. past Dhuhr / Jumua) from firing instantly
 * after a phone reboot or APK update.
 */
class SafeNotificationBootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "SafeBootReceiver"
        private const val PREFS_NAME = "scheduled_notifications"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != "android.intent.action.QUICKBOOT_POWERON" &&
            action != "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        Log.i(TAG, "SafeNotificationBootReceiver invoked with action: $action")
        try {
            pruneStaleScheduledNotifications(context)
            // Invoke plugin's rescheduleNotifications via reflection since it is package-private
            val method = FlutterLocalNotificationsPlugin::class.java.getDeclaredMethod(
                "rescheduleNotifications",
                Context::class.java
            )
            method.isAccessible = true
            method.invoke(null, context)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to safely reschedule notifications: ${e.message}", e)
        }

        try {
            DhikrOverlayScheduler.scheduleNext(context)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to reschedule dhikr overlay: ${e.message}", e)
        }
    }

    private fun pruneStaleScheduledNotifications(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonStr = prefs.getString(PREFS_NAME, null) ?: return

        try {
            val originalArray = JSONArray(jsonStr)
            val filteredArray = JSONArray()
            val nowEpoch = System.currentTimeMillis()
            var prunedCount = 0

            for (i in 0 until originalArray.length()) {
                val item = originalArray.getJSONObject(i)
                val repeatInterval = item.opt("repeatInterval")
                val repeatIntervalMs = item.opt("repeatIntervalMilliseconds")
                val matchComponents = item.opt("matchDateTimeComponents")

                // Repeating notifications are preserved because their next trigger date is dynamic
                val isRepeating = (repeatInterval != null && repeatInterval != JSONObject.NULL) ||
                        (repeatIntervalMs != null && repeatIntervalMs != JSONObject.NULL) ||
                        (matchComponents != null && matchComponents != JSONObject.NULL)

                if (isRepeating) {
                    filteredArray.put(item)
                    continue
                }

                // Non-repeating one-off scheduled notifications:
                val scheduledDateTimeStr = item.optString("scheduledDateTime", null)
                val timeZoneName = item.optString("timeZoneName", null)

                if (!scheduledDateTimeStr.isNullOrEmpty() && !timeZoneName.isNullOrEmpty()) {
                    try {
                        val zoneId = ZoneId.of(timeZoneName)
                        val ldt = LocalDateTime.parse(scheduledDateTimeStr)
                        val triggerEpoch = ZonedDateTime.of(ldt, zoneId).toInstant().toEpochMilli()

                        // If scheduled trigger time is in the past, drop it from cache!
                        if (triggerEpoch <= nowEpoch) {
                            prunedCount++
                            val notifId = item.optInt("id", -1)
                            Log.i(
                                TAG,
                                "Pruning stale notification ID $notifId scheduled for $scheduledDateTimeStr ($triggerEpoch <= $nowEpoch)"
                            )
                            continue
                        }
                    } catch (timeEx: Exception) {
                        Log.w(TAG, "Error calculating trigger epoch for item: ${timeEx.message}")
                    }
                }

                filteredArray.put(item)
            }

            if (prunedCount > 0) {
                prefs.edit().putString(PREFS_NAME, filteredArray.toString()).apply()
                Log.i(TAG, "Pruned $prunedCount stale scheduled notification(s) before rescheduling.")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error pruning scheduled notifications: ${e.message}", e)
        }
    }
}
