package com.glasschat.app.data.local.datastore

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.glasschat.app.di.ApplicationScope
import dagger.hilt.android.qualifiers.ApplicationContext
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.domain.model.ThemeMode
import com.glasschat.app.domain.repository.SettingsRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject
import javax.inject.Singleton

private val Context.settingsDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "glasschat_prefs",
)

@Singleton
class SettingsRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    @ApplicationScope private val appScope: CoroutineScope,
) : SettingsRepository {

    private val dataStore = context.settingsDataStore

    override val preferences: Flow<AppPreferences> = dataStore.data
        .map { it.toAppPreferences() }
        .distinctUntilChanged()

    /** Single process-wide snapshot used by the theme layer to avoid a first-frame flash. */
    val eagerlyCached: StateFlow<AppPreferences> = preferences.stateIn(
        scope = appScope,
        started = SharingStarted.Eagerly,
        initialValue = AppPreferences(),
    )

    override suspend fun update(transform: (AppPreferences) -> AppPreferences) {
        dataStore.edit { prefs ->
            val updated = transform(prefs.toAppPreferences())
            prefs.writeAll(updated)
        }
    }

    override suspend fun setOnboardingComplete(complete: Boolean) =
        update { it.copy(onboardingComplete = complete) }

    override suspend fun setThemeMode(mode: ThemeMode) = update { it.copy(themeMode = mode) }

    override suspend fun setAccent(color: Long) = update { it.copy(accent = color) }

    override suspend fun setBubbleColors(me: Long?, other: Long?) =
        update { it.copy(bubbleColorMe = me, bubbleColorOther = other) }

    override suspend fun setWallpaper(wallpaper: String) = update { it.copy(wallpaper = wallpaper) }

    override suspend fun setFontScale(scale: Float) =
        update { it.copy(fontScale = scale.coerceIn(0.85f, 1.35f)) }

    override suspend fun setReduceTransparency(reduce: Boolean) =
        update { it.copy(reduceTransparency = reduce) }

    override suspend fun setReduceMotion(reduce: Boolean) = update { it.copy(reduceMotion = reduce) }

    override suspend fun setEnterToSend(enabled: Boolean) = update { it.copy(enterToSend = enabled) }

    override suspend fun setShowTimestamps(enabled: Boolean) =
        update { it.copy(showTimestamps = enabled) }

    override suspend fun setShowSimulatedStatus(enabled: Boolean) =
        update { it.copy(showSimulatedStatus = enabled) }

    override suspend fun setHaptics(enabled: Boolean) = update { it.copy(hapticsEnabled = enabled) }

    override suspend fun setAppLock(enabled: Boolean) = update { it.copy(appLockEnabled = enabled) }

    override suspend fun setHidePreviewsInRecents(enabled: Boolean) =
        update { it.copy(hidePreviewsInRecents = enabled) }

    override suspend fun setBlurMediaInList(enabled: Boolean) =
        update { it.copy(blurMediaInList = enabled) }

    override suspend fun setProfile(
        displayName: String,
        about: String,
        avatarUri: String?,
        accent: Long,
    ) = update {
        it.copy(
            displayName = displayName.trim().ifBlank { "Me" }.take(40),
            about = about.trim().take(140),
            avatarUri = avatarUri,
            profileAccent = accent,
        )
    }

    override suspend fun markBackupCompleted(timestamp: Long) =
        update { it.copy(lastBackupAt = timestamp) }
}

// ---------------------------------------------------------------------------
// Preference <-> DataStore mapping
// ---------------------------------------------------------------------------

private object Keys {
    val onboarding = booleanPreferencesKey("onboarding_complete")
    val displayName = stringPreferencesKey("display_name")
    val about = stringPreferencesKey("about")
    val avatarUri = stringPreferencesKey("avatar_uri")
    val profileAccent = longPreferencesKey("profile_accent")
    val themeMode = stringPreferencesKey("theme_mode")
    val accent = longPreferencesKey("accent")
    val bubbleMe = longPreferencesKey("bubble_me")
    val bubbleOther = longPreferencesKey("bubble_other")
    val wallpaper = stringPreferencesKey("wallpaper")
    val fontScale = floatPreferencesKey("font_scale")
    val reduceTransparency = booleanPreferencesKey("reduce_transparency")
    val reduceMotion = booleanPreferencesKey("reduce_motion")
    val enterToSend = booleanPreferencesKey("enter_to_send")
    val showTimestamps = booleanPreferencesKey("show_timestamps")
    val showStatus = booleanPreferencesKey("show_simulated_status")
    val haptics = booleanPreferencesKey("haptics")
    val appLock = booleanPreferencesKey("app_lock")
    val hidePreviews = booleanPreferencesKey("hide_previews")
    val blurMedia = booleanPreferencesKey("blur_media")
    val lastBackupAt = longPreferencesKey("last_backup_at")
}

private fun Preferences.toAppPreferences(): AppPreferences {
    val defaults = AppPreferences()
    return AppPreferences(
        onboardingComplete = this[Keys.onboarding] ?: defaults.onboardingComplete,
        displayName = this[Keys.displayName] ?: defaults.displayName,
        about = this[Keys.about] ?: defaults.about,
        avatarUri = this[Keys.avatarUri] ?: defaults.avatarUri,
        profileAccent = this[Keys.profileAccent] ?: defaults.profileAccent,
        themeMode = this[Keys.themeMode]?.let { stored ->
            ThemeMode.entries.firstOrNull { it.name == stored }
        } ?: defaults.themeMode,
        accent = this[Keys.accent] ?: defaults.accent,
        bubbleColorMe = this[Keys.bubbleMe],
        bubbleColorOther = this[Keys.bubbleOther],
        wallpaper = this[Keys.wallpaper] ?: defaults.wallpaper,
        fontScale = this[Keys.fontScale] ?: defaults.fontScale,
        reduceTransparency = this[Keys.reduceTransparency] ?: defaults.reduceTransparency,
        reduceMotion = this[Keys.reduceMotion] ?: defaults.reduceMotion,
        enterToSend = this[Keys.enterToSend] ?: defaults.enterToSend,
        showTimestamps = this[Keys.showTimestamps] ?: defaults.showTimestamps,
        showSimulatedStatus = this[Keys.showStatus] ?: defaults.showSimulatedStatus,
        hapticsEnabled = this[Keys.haptics] ?: defaults.hapticsEnabled,
        appLockEnabled = this[Keys.appLock] ?: defaults.appLockEnabled,
        hidePreviewsInRecents = this[Keys.hidePreviews] ?: defaults.hidePreviewsInRecents,
        blurMediaInList = this[Keys.blurMedia] ?: defaults.blurMediaInList,
        lastBackupAt = this[Keys.lastBackupAt],
    )
}

private fun androidx.datastore.preferences.core.MutablePreferences.writeAll(value: AppPreferences) {
    this[Keys.onboarding] = value.onboardingComplete
    this[Keys.displayName] = value.displayName
    this[Keys.about] = value.about
    if (value.avatarUri != null) {
        this[Keys.avatarUri] = value.avatarUri
    } else {
        remove(Keys.avatarUri)
    }
    this[Keys.profileAccent] = value.profileAccent
    this[Keys.themeMode] = value.themeMode.name
    this[Keys.accent] = value.accent
    if (value.bubbleColorMe != null) this[Keys.bubbleMe] = value.bubbleColorMe else remove(Keys.bubbleMe)
    if (value.bubbleColorOther != null) {
        this[Keys.bubbleOther] = value.bubbleColorOther
    } else {
        remove(Keys.bubbleOther)
    }
    this[Keys.wallpaper] = value.wallpaper
    this[Keys.fontScale] = value.fontScale
    this[Keys.reduceTransparency] = value.reduceTransparency
    this[Keys.reduceMotion] = value.reduceMotion
    this[Keys.enterToSend] = value.enterToSend
    this[Keys.showTimestamps] = value.showTimestamps
    this[Keys.showStatus] = value.showSimulatedStatus
    this[Keys.haptics] = value.hapticsEnabled
    this[Keys.appLock] = value.appLockEnabled
    this[Keys.hidePreviews] = value.hidePreviewsInRecents
    this[Keys.blurMedia] = value.blurMediaInList
    if (value.lastBackupAt != null) {
        this[Keys.lastBackupAt] = value.lastBackupAt
    } else {
        remove(Keys.lastBackupAt)
    }
}
