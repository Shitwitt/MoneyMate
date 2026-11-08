package com.glasschat.app.domain.model

enum class ThemeMode { SYSTEM, LIGHT, DARK }

/**
 * Every user-facing preference. Backed by DataStore, exposed as one immutable snapshot so
 * the UI can react to a single Flow instead of a dozen independent ones.
 */
data class AppPreferences(
    val onboardingComplete: Boolean = false,
    val displayName: String = "Me",
    val about: String = "Offline and on purpose.",
    val avatarUri: String? = null,
    val profileAccent: Long = 0xFF8C7CFF,
    val themeMode: ThemeMode = ThemeMode.SYSTEM,
    val accent: Long = 0xFF8C7CFF,
    val bubbleColorMe: Long? = null,
    val bubbleColorOther: Long? = null,
    val wallpaper: String = WALLPAPER_AURORA,
    val fontScale: Float = 1f,
    val reduceTransparency: Boolean = false,
    val reduceMotion: Boolean = false,
    val enterToSend: Boolean = false,
    val showTimestamps: Boolean = true,
    val showSimulatedStatus: Boolean = true,
    val hapticsEnabled: Boolean = true,
    val appLockEnabled: Boolean = false,
    val hidePreviewsInRecents: Boolean = false,
    val blurMediaInList: Boolean = false,
    val lastBackupAt: Long? = null,
) {
    companion object {
        const val WALLPAPER_AURORA = "aurora"
        const val WALLPAPER_ORCHID = "orchid"
        const val WALLPAPER_OCEAN = "ocean"
        const val WALLPAPER_GRAPHITE = "graphite"
        const val WALLPAPER_SAND = "sand"
        /** Prefix for a user-supplied wallpaper image stored in app-private storage. */
        const val CUSTOM_PREFIX = "custom:"
    }
}
