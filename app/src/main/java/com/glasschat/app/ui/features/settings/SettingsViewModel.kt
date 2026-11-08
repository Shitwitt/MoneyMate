package com.glasschat.app.ui.features.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.domain.model.ThemeMode
import com.glasschat.app.domain.repository.BackupRepository
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.MediaRepository
import com.glasschat.app.domain.repository.SettingsRepository
import com.glasschat.app.ui.common.UiEvent
import com.glasschat.app.util.formatBytes
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val preferences: AppPreferences = AppPreferences(),
    val cacheBytes: Long = 0L,
    val archivedChats: Int = 0,
    val chatCount: Int = 0,
    val contactCount: Int = 0,
    val isBusy: Boolean = false,
) {
    val cacheLabel: String get() = formatBytes(cacheBytes)
}

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository,
    chatRepository: ChatRepository,
    contactRepository: ContactRepository,
    private val mediaRepository: MediaRepository,
    private val backupRepository: BackupRepository,
) : ViewModel() {

    private data class LocalState(val cacheBytes: Long = 0L, val isBusy: Boolean = false)

    private val local = MutableStateFlow(LocalState())
    private val eventsChannel = Channel<UiEvent>(Channel.BUFFERED)
    val events: Flow<UiEvent> = eventsChannel.receiveAsFlow()

    val uiState: StateFlow<SettingsUiState> = combine(
        settingsRepository.preferences,
        local,
        chatRepository.observeChatSummaries(archived = false),
        chatRepository.observeArchivedCount(),
        contactRepository.observeContacts(),
    ) { prefs, localState, chats, archived, contacts ->
        SettingsUiState(
            preferences = prefs,
            cacheBytes = localState.cacheBytes,
            archivedChats = archived,
            chatCount = chats.size,
            contactCount = contacts.size,
            isBusy = localState.isBusy,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsUiState())

    init {
        refreshCacheSize()
    }

    fun refreshCacheSize() = viewModelScope.launch {
        val size = mediaRepository.cacheSizeBytes()
        local.update { it.copy(cacheBytes = size) }
    }

    // --- Appearance ---------------------------------------------------
    fun setThemeMode(mode: ThemeMode) = launchPref { settingsRepository.setThemeMode(mode) }
    fun setAccent(color: Long) = launchPref { settingsRepository.setAccent(color) }
    fun setBubbleColors(me: Long?, other: Long?) =
        launchPref { settingsRepository.setBubbleColors(me, other) }

    fun setWallpaper(id: String) = launchPref { settingsRepository.setWallpaper(id) }
    fun setFontScale(scale: Float) = launchPref { settingsRepository.setFontScale(scale) }
    fun setReduceTransparency(value: Boolean) =
        launchPref { settingsRepository.setReduceTransparency(value) }

    fun setReduceMotion(value: Boolean) = launchPref { settingsRepository.setReduceMotion(value) }

    // --- Behaviour ----------------------------------------------------
    fun setEnterToSend(value: Boolean) = launchPref { settingsRepository.setEnterToSend(value) }
    fun setShowTimestamps(value: Boolean) =
        launchPref { settingsRepository.setShowTimestamps(value) }

    fun setShowSimulatedStatus(value: Boolean) =
        launchPref { settingsRepository.setShowSimulatedStatus(value) }

    fun setHaptics(value: Boolean) = launchPref { settingsRepository.setHaptics(value) }

    // --- Privacy ------------------------------------------------------
    fun setAppLock(value: Boolean) = launchPref { settingsRepository.setAppLock(value) }
    fun setHidePreviews(value: Boolean) =
        launchPref { settingsRepository.setHidePreviewsInRecents(value) }

    fun setBlurMedia(value: Boolean) = launchPref { settingsRepository.setBlurMediaInList(value) }

    // --- Data ---------------------------------------------------------
    fun exportBackup(destinationUri: String) {
        local.update { it.copy(isBusy = true) }
        viewModelScope.launch {
            runCatching { backupRepository.exportBackup(destinationUri) }
                .onSuccess { result ->
                    eventsChannel.send(
                        UiEvent(
                            "Backup saved · ${result.chats} chats, ${result.messages} messages, " +
                                "${result.mediaFiles} files (${formatBytes(result.bytesWritten)})",
                        ),
                    )
                }
                .onFailure { error ->
                    eventsChannel.send(UiEvent("Backup failed: ${error.message ?: "unknown error"}"))
                }
            local.update { it.copy(isBusy = false) }
            refreshCacheSize()
        }
    }

    fun importBackup(sourceUri: String) {
        local.update { it.copy(isBusy = true) }
        viewModelScope.launch {
            runCatching { backupRepository.importBackup(sourceUri) }
                .onSuccess { result ->
                    eventsChannel.send(
                        UiEvent(
                            "Restored ${result.chats} chats and ${result.messages} messages",
                        ),
                    )
                }
                .onFailure { error ->
                    eventsChannel.send(UiEvent("Import failed: ${error.message ?: "unknown error"}"))
                }
            local.update { it.copy(isBusy = false) }
            refreshCacheSize()
        }
    }

    fun clearCache() = viewModelScope.launch {
        val freed = mediaRepository.clearCache()
        mediaRepository.pruneOrphanedMedia()
        eventsChannel.send(UiEvent("Cleared ${formatBytes(freed)} of cache"))
        refreshCacheSize()
    }

    fun deleteAllData(onDone: () -> Unit) {
        local.update { it.copy(isBusy = true) }
        viewModelScope.launch {
            runCatching { backupRepository.deleteAllData() }
                .onSuccess {
                    eventsChannel.send(UiEvent("All local data deleted"))
                    onDone()
                }
                .onFailure { eventsChannel.send(UiEvent("Could not delete all data")) }
            local.update { it.copy(isBusy = false) }
        }
    }

    private fun launchPref(block: suspend () -> Unit) {
        viewModelScope.launch { block() }
    }
}
