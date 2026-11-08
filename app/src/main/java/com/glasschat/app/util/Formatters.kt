package com.glasschat.app.util

import java.util.Locale
import kotlin.math.roundToLong

/** Human readable byte size, e.g. `1.4 MB`. */
fun formatBytes(bytes: Long): String {
    if (bytes <= 0L) return "0 B"
    val units = listOf("B", "KB", "MB", "GB", "TB")
    var value = bytes.toDouble()
    var index = 0
    while (value >= 1024.0 && index < units.lastIndex) {
        value /= 1024.0
        index++
    }
    val pattern = if (index == 0 || value >= 100) "%.0f %s" else "%.1f %s"
    return String.format(Locale.getDefault(), pattern, value, units[index])
}

/** `m:ss` (or `h:mm:ss` for long clips) duration label. */
fun formatDuration(durationMs: Long): String {
    val totalSeconds = (durationMs / 1000.0).roundToLong().coerceAtLeast(0L)
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return if (hours > 0) {
        String.format(Locale.getDefault(), "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format(Locale.getDefault(), "%d:%02d", minutes, seconds)
    }
}

/** Initials used by generated avatars: `Ava Lin` -> `AL`, `Ava` -> `A`. */
fun initialsOf(name: String): String {
    val parts = name.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
    return when {
        parts.isEmpty() -> "?"
        parts.size == 1 -> parts.first().take(1).uppercase(Locale.getDefault())
        else -> (parts.first().take(1) + parts.last().take(1)).uppercase(Locale.getDefault())
    }
}

/** Short file name for document bubbles. */
fun fileNameOf(path: String?): String {
    if (path.isNullOrBlank()) return "Attachment"
    val cleaned = path.trimEnd('/')
    val name = cleaned.substringAfterLast('/')
    return name.ifBlank { "Attachment" }
}

fun extensionOf(fileName: String): String =
    fileName.substringAfterLast('.', "").lowercase(Locale.getDefault())
