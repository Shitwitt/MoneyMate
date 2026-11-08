package com.glasschat.app.ui.theme

import androidx.compose.ui.graphics.Color
import com.glasschat.app.domain.model.AppPreferences

/**
 * Chat backdrops. Each preset is a gradient + two refraction blobs; the "custom" option
 * uses an image the user picked, copied into private storage.
 */
data class WallpaperOption(
    val id: String,
    val name: String,
)

object Wallpapers {

    val presets: List<WallpaperOption> = listOf(
        WallpaperOption(AppPreferences.WALLPAPER_AURORA, "Aurora"),
        WallpaperOption(AppPreferences.WALLPAPER_ORCHID, "Orchid"),
        WallpaperOption(AppPreferences.WALLPAPER_OCEAN, "Ocean"),
        WallpaperOption(AppPreferences.WALLPAPER_GRAPHITE, "Graphite"),
        WallpaperOption(AppPreferences.WALLPAPER_SAND, "Sand"),
    )

    fun displayName(id: String): String {
        if (id.startsWith(AppPreferences.CUSTOM_PREFIX)) return "Custom photo"
        return presets.firstOrNull { it.id == id }?.name ?: "Aurora"
    }

    /** Three-layer palette: backdrop top, backdrop bottom, blob tint. */
    fun palette(id: String, isDark: Boolean): List<Color> {
        val key = id.substringAfter("custom:", "").ifBlank { id }
        return when {
            key.startsWith("orchid") -> if (isDark) {
                listOf(Color(0xFF160B24), Color(0xFF241033), Color(0xFF9C5BFF))
            } else {
                listOf(Color(0xFFF9EDFF), Color(0xFFF2E4FF), Color(0xFFB98CFF))
            }

            key.startsWith("ocean") -> if (isDark) {
                listOf(Color(0xFF04121C), Color(0xFF07283A), Color(0xFF3FD0E0))
            } else {
                listOf(Color(0xFFE7FBFF), Color(0xFFD9F3FB), Color(0xFF6FD6E8))
            }

            key.startsWith("graphite") -> if (isDark) {
                listOf(Color(0xFF090B0F), Color(0xFF14181F), Color(0xFF4A5568))
            } else {
                listOf(Color(0xFFF3F4F7), Color(0xFFE7E9EF), Color(0xFF9AA4B8))
            }

            key.startsWith("sand") -> if (isDark) {
                listOf(Color(0xFF1A120B), Color(0xFF2A1D12), Color(0xFFE0A25B))
            } else {
                listOf(Color(0xFFFFF6E9), Color(0xFFFBEBD5), Color(0xFFE8B877))
            }

            else -> if (isDark) {
                listOf(Color(0xFF070B16), Color(0xFF0C1226), Color(0xFF6E5BFF))
            } else {
                listOf(Color(0xFFF1F3FC), Color(0xFFE6EAF8), Color(0xFF8C7CFF))
            }
        }
    }
}
