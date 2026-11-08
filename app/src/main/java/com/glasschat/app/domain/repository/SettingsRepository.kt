package com.glasschat.app.domain.repository

import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.domain.model.ThemeMode
import kotlinx.coroutines.flow.Flow

interface SettingsRepository {
    val preferences: Flow<AppPreferences>

    suspend fun update(transform: (AppPreferences) -> AppPreferences)

    suspend fun setOnboardingComplete(complete: Boolean)
    suspend fun setThemeMode(mode: ThemeMode)
    suspend fun setAccent(color: Long)
    suspend fun setBubbleColors(me: Long?, other: Long?)
    suspend fun setWallpaper(wallpaper: String)
    suspend fun setFontScale(scale: Float)
    suspend fun setReduceTransparency(reduce: Boolean)
    suspend fun setReduceMotion(reduce: Boolean)
    suspend fun setEnterToSend(enabled: Boolean)
    suspend fun setShowTimestamps(enabled: Boolean)
    suspend fun setShowSimulatedStatus(enabled: Boolean)
    suspend fun setHaptics(enabled: Boolean)
    suspend fun setAppLock(enabled: Boolean)
    suspend fun setHidePreviewsInRecents(enabled: Boolean)
    suspend fun setBlurMediaInList(enabled: Boolean)
    suspend fun setProfile(displayName: String, about: String, avatarUri: String?, accent: Long)
    suspend fun markBackupCompleted(timestamp: Long)
}
