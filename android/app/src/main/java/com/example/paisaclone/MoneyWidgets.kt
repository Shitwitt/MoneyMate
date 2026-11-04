package com.example.paisaclone

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

abstract class MoneyWidget(private val layout: Int) : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        for (id in ids) {
            val views = RemoteViews(context.packageName, layout)
            views.setTextViewText(R.id.widget_profile, prefs.getString("profile", "Tink"))
            when (layout) {
                R.layout.widget_balance -> views.setTextViewText(R.id.widget_value, prefs.getString("balance", "Open Tink"))
                R.layout.widget_budget -> {
                    views.setTextViewText(R.id.widget_value, prefs.getString("budget", "Create a budget"))
                    views.setTextViewText(R.id.widget_caption, prefs.getString("budgetName", "Your next good habit"))
                    // StandardMessageCodec can produce Int or Long. Handle both safely.
                    val percent = (prefs.all["budgetPercent"] as? Number)?.toInt() ?: 0
                    views.setProgressBar(R.id.widget_progress, 100, percent, false)
                }
            }
            val link = if (layout == R.layout.widget_quick_add) "paisa://quick_add" else "paisa://home"
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse(link)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_root, PendingIntent.getActivity(context, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            manager.updateAppWidget(id, views)
        }
    }
}
class BalanceWidget : MoneyWidget(R.layout.widget_balance)
class BudgetWidget : MoneyWidget(R.layout.widget_budget)
class QuickAddWidget : MoneyWidget(R.layout.widget_quick_add)
