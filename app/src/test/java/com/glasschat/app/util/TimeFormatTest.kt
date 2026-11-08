package com.glasschat.app.util

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class TimeFormatTest {

    private fun at(daysAgo: Int, hour: Int = 12): Long {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -daysAgo)
        calendar.set(Calendar.HOUR_OF_DAY, hour)
        calendar.set(Calendar.MINUTE, 30)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }

    @Test
    fun `today is shown as a clock time`() {
        val now = at(0)
        assertEquals(TimeFormat.clock(now), TimeFormat.chatList(now, now))
    }

    @Test
    fun `yesterday is labelled`() {
        val now = at(0)
        assertEquals("Yesterday", TimeFormat.chatList(at(1), now))
    }

    @Test
    fun `day separators label today and yesterday`() {
        val now = at(0)
        assertEquals("Today", TimeFormat.daySeparator(now, now))
        assertEquals("Yesterday", TimeFormat.daySeparator(at(1), now))
        assertNotEquals("Today", TimeFormat.daySeparator(at(9), now))
    }

    @Test
    fun `dayKey groups by calendar day`() {
        val early = at(0, hour = 1)
        val late = at(0, hour = 23)
        assertEquals(TimeFormat.dayKey(early), TimeFormat.dayKey(late))
        assertNotEquals(TimeFormat.dayKey(early), TimeFormat.dayKey(at(1)))
        assertTrue(TimeFormat.dayKey(early).matches(Regex("\\d{4}-\\d{2}-\\d{2}")))
    }
}
