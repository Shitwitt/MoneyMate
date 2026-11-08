package com.glasschat.app.util

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Timestamp helpers. All formatting is device-local and never touches the network.
 * A small in-memory cache keeps SimpleDateFormat instances out of the list bind path.
 */
object TimeFormat {

    private val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
    private val dayFormat = SimpleDateFormat("EEE, d MMM", Locale.getDefault())
    private val fullFormat = SimpleDateFormat("d MMM yyyy, HH:mm", Locale.getDefault())
    private val monthDayFormat = SimpleDateFormat("d MMM", Locale.getDefault())

    /** `14:05` */
    fun clock(timestamp: Long): String = synchronized(timeFormat) { timeFormat.format(Date(timestamp)) }

    /** `d MMM yyyy, HH:mm` */
    fun full(timestamp: Long): String = synchronized(fullFormat) { fullFormat.format(Date(timestamp)) }

    /**
     * Chat list style timestamp: today -> `14:05`, yesterday -> `Yesterday`,
     * this week -> weekday, older -> `12 Mar` (with year when not the current year).
     */
    fun chatList(timestamp: Long, now: Long = System.currentTimeMillis()): String {
        val cal = calendar(timestamp)
        val today = calendar(now)
        val dayDiff = daysBetween(cal, today)
        return when {
            dayDiff == 0L -> clock(timestamp)
            dayDiff == 1L -> "Yesterday"
            dayDiff in 2..6 -> synchronized(dayFormat) { dayFormat.format(Date(timestamp)) }
            cal.get(Calendar.YEAR) == today.get(Calendar.YEAR) ->
                synchronized(monthDayFormat) { monthDayFormat.format(Date(timestamp)) }
            else -> synchronized(fullFormat) { fullFormat.format(Date(timestamp)) }
        }
    }

    /** Day separator label: `Today`, `Yesterday`, `12 March 2025`. */
    fun daySeparator(timestamp: Long, now: Long = System.currentTimeMillis()): String {
        val cal = calendar(timestamp)
        val today = calendar(now)
        val dayDiff = daysBetween(cal, today)
        val sameYear = cal.get(Calendar.YEAR) == today.get(Calendar.YEAR)
        val pattern = if (sameYear) "EEEE, d MMMM" else "d MMMM yyyy"
        val formatted = SimpleDateFormat(pattern, Locale.getDefault()).format(Date(timestamp))
        return when (dayDiff) {
            0L -> "Today"
            1L -> "Yesterday"
            else -> formatted
        }
    }

    /** Key used to group messages into day buckets. */
    fun dayKey(timestamp: Long): String {
        val cal = calendar(timestamp)
        return "%04d-%02d-%02d".format(
            Locale.US,
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH),
        )
    }

    private fun calendar(timestamp: Long): Calendar =
        Calendar.getInstance().apply {
            timeInMillis = timestamp
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

    private fun daysBetween(from: Calendar, to: Calendar): Long {
        val diff = to.timeInMillis - from.timeInMillis
        return diff / (24 * 60 * 60 * 1000L)
    }
}
