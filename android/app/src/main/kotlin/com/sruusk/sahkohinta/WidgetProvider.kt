package com.sruusk.sahkohinta

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget).apply {
                val price = widgetData.getString("price", "0.00")
                val time = widgetData.getString("time", "12.12. 25-26")
                setTextViewText(R.id.text_price, price)
                setTextViewText(R.id.text_time, time)
                println("Price: $price, Time: $time")
            }
            // This line is important to trigger the update
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
