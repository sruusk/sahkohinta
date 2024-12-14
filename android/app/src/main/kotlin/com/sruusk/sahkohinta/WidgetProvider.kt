package com.sruusk.sahkohinta

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.util.SizeF
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class WidgetProvider : HomeWidgetProvider() {
    @RequiresApi(Build.VERSION_CODES.S)
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->

            val narrowView = RemoteViews(context.packageName, R.layout.widget).apply {
                val price = widgetData.getString("price", "0.00")
                val time = widgetData.getString("time", "12.12. 25-26")
                setTextViewText(R.id.text_price, price)
                setTextViewText(R.id.text_time, time)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_layout, pendingIntent)
            }

            val mediumView = RemoteViews(context.packageName, R.layout.widget_medium).apply {
                val prices = Array<String>(3) { i -> widgetData.getString("price$i", "0.00").toString() }
                val time = widgetData.getString("time", "12.12.").toString()
                val times = Array<String>(3) { i -> widgetData.getString("time$i", "25-26").toString() }
                setTextViewText(R.id.text_price1, prices[0])
                setTextViewText(R.id.text_price2, prices[1])
                setTextViewText(R.id.text_time, time.split(" ")[0]) // Only date
                setTextViewText(R.id.text_time1, times[0])
                setTextViewText(R.id.text_time2, times[1])

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_layout, pendingIntent)
            }

            val wideView = RemoteViews(context.packageName, R.layout.widget_wide).apply {
                val prices = Array<String>(3) { i -> widgetData.getString("price$i", "0.00").toString() }
                val time = widgetData.getString("time", "12.12.").toString()
                val times = Array<String>(3) { i -> widgetData.getString("time$i", "25-26").toString() }
                setTextViewText(R.id.text_price1, prices[0])
                setTextViewText(R.id.text_price2, prices[1])
                setTextViewText(R.id.text_price3, prices[2])
                setTextViewText(R.id.text_time, time.split(" ")[0]) // Only date
                setTextViewText(R.id.text_time1, times[0])
                setTextViewText(R.id.text_time2, times[1])
                setTextViewText(R.id.text_time3, times[2])

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_layout, pendingIntent)
            }

            val viewMapping: Map<SizeF, RemoteViews> = mapOf(
                SizeF(40f, 100f) to narrowView,
                SizeF(120f, 100f) to mediumView,
                SizeF(180f, 100f) to wideView
            )

            val remoteViews = RemoteViews(viewMapping)

            // This line is important to trigger the update
            appWidgetManager.updateAppWidget(widgetId, remoteViews)
        }
    }
}
