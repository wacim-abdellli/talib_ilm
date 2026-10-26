package com.example.talib_ilm

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

class RibbonWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val effectiveIds = if (appWidgetIds.isNotEmpty()) appWidgetIds else {
            appWidgetManager.getAppWidgetIds(ComponentName(context, this::class.java))
        }
        for (appWidgetId in effectiveIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        try {
            val views = RemoteViews(context.packageName, R.layout.widget_ribbon_layout)

            val pendingIntent = try {
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
            } catch (_: Exception) {
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            val widgetData = HomeWidgetPlugin.getData(context)
            WidgetChronometerHelper.setupChronometer(context, views, widgetData, this::class.java)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (_: Throwable) {}
    }
}
