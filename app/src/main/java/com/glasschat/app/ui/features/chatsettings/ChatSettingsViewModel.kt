package com.glasschat.app.ui.features.chatsettings

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.Chat
import com.glasschat.app.domain.model.Contact
import com.glasschat.app.domain.model.Participant
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.MessageRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ChatSettingsUiState(
    val isLoading: Boolean = true,
    val chat: Chat? = null,
    val participants: List<Participant> = emptyList(),
    val availableContacts: List<Contact> = emptyList(),
) {
    val isGroup: Boolean get() = participants.size > 1
    val addableContacts: List<Contact>
        get() = availableContacts.filter { contact ->
            participants.none { it.contactId == contact.id } && !contact.isBlocked
        }
}

@HiltViewModel
class ChatSettingsViewModel @Inject constructor(
    private val chatRepository: ChatRepository,
    private val contactRepository: ContactRepository,
    private val messageRepository: MessageRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    val chatId: String = savedStateHandle.get<String>("chatId").orEmpty()
    val uiState: StateFlow<ChatSettingsUiState> = combine(
        chatRepository.observeChatDetail(chatId),
        contactRepository.observeContacts(),
    ) { detail, contacts ->
        if (detail == null) {
            ChatSettingsUiState(isLoading = false)
        } else {
            ChatSettingsUiState(
                isLoading = false,
                chat = detail.chat,
                participants = detail.participants,
                availableContacts = contacts,
            )
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ChatSettingsUiState())

    fun rename(title: String) = viewModelScope.launch {
        chatRepository.renameChat(chatId, title)
    }

    fun setWallpaper(wallpaper: String?) = viewModelScope.launch {
        val chat = uiState.value.chat ?: return@launch
        chatRepository.updateAppearance(
            chatId = chatId,
            wallpaper = wallpaper,
            accentColor = chat.accentColor,
            bubbleColorMe = chat.bubbleColorMe,
            bubbleColorOther = chat.bubbleColorOther,
        )
    }

    fun setAccent(color: Long?) = viewModelScope.launch {
        val chat = uiState.value.chat ?: return@launch
        chatRepository.updateAppearance(
            chatId = chatId,
            wallpaper = chat.wallpaper,
            accentColor = color,
            bubbleColorMe = chat.bubbleColorMe,
            bubbleColorOther = chat.bubbleColorOther,
        )
    }

    fun setBubbleColors(me: Long?, other: Long?) = viewModelScope.launch {
        val chat = uiState.value.chat ?: return@launch
        chatRepository.updateAppearance(
            chatId = chatId,
            wallpaper = chat.wallpaper,
            accentColor = chat.accentColor,
            bubbleColorMe = me,
            bubbleColorOther = other,
        )
    }

    fun toggleMute(muted: Boolean) = viewModelScope.launch {
        chatRepository.setMuted(chatId, !muted)
    }

    fun togglePin(pinned: Boolean) = viewModelScope.launch {
        chatRepository.setPinned(chatId, !pinned)
    }

    fun toggleArchive(archived: Boolean) = viewModelScope.launch {
        chatRepository.setArchived(chatId, !archived)
    }

    fun addParticipant(contactId: String) = viewModelScope.launch {
        chatRepository.addParticipants(chatId, listOf(contactId))
    }

    fun removeParticipant(contactId: String) = viewModelScope.launch {
        chatRepository.removeParticipant(chatId, contactId)
    }

    fun clearMessages() = viewModelScope.launch {
        messageRepository.clearChat(chatId)
    }

    fun deleteChat(onDeleted: () -> Unit) = viewModelScope.launch {
        chatRepository.deleteChat(chatId)
        onDeleted()
    }

    fun markUnread() = viewModelScope.launch {
        chatRepository.markUnread(chatId)
    }
}
