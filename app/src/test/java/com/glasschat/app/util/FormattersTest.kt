package com.glasschat.app.util

import org.junit.Assert.assertEquals
import org.junit.Test

class FormattersTest {

    @Test
    fun `formatBytes handles zero and small values`() {
        assertEquals("0 B", formatBytes(0))
        assertEquals("0 B", formatBytes(-12))
        assertEquals("512 B", formatBytes(512))
    }

    @Test
    fun `formatBytes scales to larger units`() {
        assertEquals("1.5 KB", formatBytes(1536))
        assertEquals("1.0 MB", formatBytes(1024L * 1024L))
        assertEquals("2.5 GB", formatBytes((2.5 * 1024 * 1024 * 1024).toLong()))
    }

    @Test
    fun `formatDuration renders minutes and hours`() {
        assertEquals("0:00", formatDuration(0))
        assertEquals("0:07", formatDuration(7_400))
        assertEquals("1:05", formatDuration(65_000))
        assertEquals("1:00:00", formatDuration(3_600_000))
        assertEquals("0:00", formatDuration(-5_000))
    }

    @Test
    fun `initialsOf copes with one two and no words`() {
        assertEquals("AL", initialsOf("Ava Lin"))
        assertEquals("A", initialsOf("  ava  "))
        assertEquals("?", initialsOf("   "))
        assertEquals("JD", initialsOf("john von doe"))
    }

    @Test
    fun `fileNameOf strips directories and falls back`() {
        assertEquals("photo.jpg", fileNameOf("file:///data/user/0/files/media/photo.jpg"))
        assertEquals("Attachment", fileNameOf(null))
        assertEquals("Attachment", fileNameOf(""))
    }

    @Test
    fun `extensionOf is lowercase and safe`() {
        assertEquals("jpg", extensionOf("Photo.JPG"))
        assertEquals("", extensionOf("no-extension"))
    }
}
