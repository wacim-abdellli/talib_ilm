package com.example.talib_ilm

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
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
        for (appWidgetId in appWidgetIds) {
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
            val imagePath = widgetData.getString("prayer_ribbon_widget", null)
            if (imagePath != null) {
                val file = File(imagePath)
                if (file.exists() && file.length() > 0) {
                    val boundsOptions = BitmapFactory.Options().apply {
                        inJustDecodeBounds = true
                    }
                    BitmapFactory.decodeFile(imagePath, boundsOptions)

                    var sampleSize = 1
                    while ((boundsOptions.outWidth / sampleSize) * (boundsOptions.outHeight / sampleSize) * 4 > 2_000_000) {
                        sampleSize *= 2
                    }

                    val decodeOptions = BitmapFactory.Options().apply {
                        inSampleSize = sampleSize
                        inPreferredConfig = Bitmap.Config.ARGB_8888
                    }
                    val bitmap = BitmapFactory.decodeFile(imagePath, decodeOptions)
                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.widget_image, bitmap)
                    }
                }
            }

            WidgetChronometerHelper.setupChronometer(context, views, widgetData, this::class.java)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (_: Throwable) {}
    }
}
