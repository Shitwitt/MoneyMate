package com.glasschat.app.ui.features.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.MediaRepository
import com.glasschat.app.domain.repository.SettingsRepository
import com.glasschat.app.ui.common.UiEvent
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ProfileUiState(
    val preferences: AppPreferences = AppPreferences(),
    val chatCount: Int = 0,
    val contactCount: Int = 0,
    val isSaving: Boolean = false,
)

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository,
    private val mediaRepository: MediaRepository,
    chatRepository: ChatRepository,
    contactRepository: ContactRepository,
) : ViewModel() {

    private val saving = MutableStateFlow(false)
    private val eventsChannel = Channel<UiEvent>(Channel.BUFFERED)
    val events: Flow<UiEvent> = eventsChannel.receiveAsFlow()

    val uiState: StateFlow<ProfileUiState> = combine(
        settingsRepository.preferences,
        chatRepository.observeChatSummaries(archived = false),
        contactRepository.observeContacts(),
        saving,
    ) { prefs, chats, contacts, isSaving ->
        ProfileUiState(
            preferences = prefs,
            chatCount = chats.size,
            contactCount = contacts.size,
            isSaving = isSaving,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ProfileUiState())

    fun onAvatarPicked(uri: String) = viewModelScope.launch {
        val stored = mediaRepository.copyAvatarIntoStorage(uri)
        if (stored == null) {
            eventsChannel.send(UiEvent("That image could not be copied"))
        } else {
            val prefs = uiState.value.preferences
            settingsRepository.setProfile(prefs.displayName, prefs.about, stored, prefs.profileAccent)
        }
    }

    fun save(displayName: String, about: String, accent: Long) {
        saving.value = true
        viewModelScope.launch {
            val prefs = uiState.value.preferences
            settingsRepository.setProfile(displayName, about, prefs.avatarUri, accent)
            saving.value = false
            eventsChannel.send(UiEvent("Profile updated"))
        }
    }
}
