package com.glasschat.app.ui.features.contacts

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.ContactDraft
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.MediaRepository
import com.glasschat.app.ui.common.UiEvent
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ContactEditorUiState(
    val isLoading: Boolean = true,
    val isNew: Boolean = true,
    val contactId: String? = null,
    val name: String = "",
    val bio: String = "",
    val phoneLabel: String = "",
    val notes: String = "",
    val accentColor: Long = 0xFF8C7CFF,
    val avatarUri: String? = null,
    val isFavorite: Boolean = false,
    val nameError: Boolean = false,
    val isSaving: Boolean = false,
)

@HiltViewModel
class ContactEditorViewModel @Inject constructor(
    private val contactRepository: ContactRepository,
    private val mediaRepository: MediaRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val contactId: String? = savedStateHandle.get<String>("contactId")
        ?.takeIf { it.isNotBlank() && it != "new" }

    private val _uiState = MutableStateFlow(ContactEditorUiState(isNew = contactId == null))
    val uiState: StateFlow<ContactEditorUiState> = _uiState.asStateFlow()

    private val eventsChannel = Channel<UiEvent>(Channel.BUFFERED)
    val events: Flow<UiEvent> = eventsChannel.receiveAsFlow()

    init {
        viewModelScope.launch {
            if (contactId == null) {
                _uiState.update { it.copy(isLoading = false) }
            } else {
                val contact = contactRepository.getContact(contactId)
                _uiState.update { state ->
                    if (contact == null) {
                        state.copy(isLoading = false)
                    } else {
                        state.copy(
                            isLoading = false,
                            isNew = false,
                            contactId = contact.id,
                            name = contact.name,
                            bio = contact.bio,
                            phoneLabel = contact.phoneLabel,
                            notes = contact.notes,
                            accentColor = contact.accentColor,
                            avatarUri = contact.avatarUri,
                            isFavorite = contact.isFavorite,
                        )
                    }
                }
            }
        }
    }

    fun onNameChange(value: String) = _uiState.update { it.copy(name = value, nameError = false) }
    fun onBioChange(value: String) = _uiState.update { it.copy(bio = value.take(140)) }
    fun onPhoneLabelChange(value: String) = _uiState.update { it.copy(phoneLabel = value.take(40)) }
    fun onNotesChange(value: String) = _uiState.update { it.copy(notes = value.take(600)) }
    fun onAccentChange(color: Long) = _uiState.update { it.copy(accentColor = color) }

    fun onAvatarPicked(uri: String) = viewModelScope.launch {
        val stored = mediaRepository.copyAvatarIntoStorage(uri)
        if (stored != null) {
            _uiState.update { it.copy(avatarUri = stored) }
        } else {
            eventsChannel.send(UiEvent("That image could not be copied"))
        }
    }

    fun clearAvatar() = _uiState.update { it.copy(avatarUri = null) }

    fun save(onSaved: (String) -> Unit) = viewModelScope.launch {
        val state = _uiState.value
        if (state.name.isBlank()) {
            _uiState.update { it.copy(nameError = true) }
            return@launch
        }
        _uiState.update { it.copy(isSaving = true) }
        val draft = ContactDraft(
            name = state.name,
            avatarUri = state.avatarUri,
            accentColor = state.accentColor,
            bio = state.bio,
            phoneLabel = state.phoneLabel,
            notes = state.notes,
        )
        val id = if (state.contactId == null) {
            contactRepository.createContact(draft)
        } else {
            contactRepository.updateContact(state.contactId, draft)
            state.contactId
        }
        _uiState.update { it.copy(isSaving = false) }
        onSaved(id)
    }

    fun delete(onDeleted: () -> Unit) = viewModelScope.launch {
        val id = _uiState.value.contactId ?: return@launch
        contactRepository.deleteContact(id)
        eventsChannel.send(UiEvent("Contact deleted"))
        onDeleted()
    }
}
