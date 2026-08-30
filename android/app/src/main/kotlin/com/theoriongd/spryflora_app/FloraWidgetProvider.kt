package com.theoriongd.spryflora_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class FloraWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.flora_widget_layout).apply {
                // Open App on click
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                // Populate dynamic data saved from Flutter
                val plantName = widgetData.getString("widget_plant_name", "SpryFlora Garden")
                val plantStage = widgetData.getString("widget_plant_stage", "Active Growth")
                val plantHealth = widgetData.getString("widget_plant_health", "100% Health")
                val waterStatus = widgetData.getString("widget_water_status", "💧 All watered")
                val sunStatus = widgetData.getString("widget_sun_status", "☀️ Sun: Optimal")

                setTextViewText(R.id.widget_plant_name, plantName)
                setTextViewText(R.id.widget_plant_stage, plantStage)
                setTextViewText(R.id.widget_plant_health, plantHealth)
                setTextViewText(R.id.widget_water_status, waterStatus)
                setTextViewText(R.id.widget_sun_status, sunStatus)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
