package com.glasschat.app.ui.features.contacts

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.Contact
import com.glasschat.app.domain.model.MediaItem
import com.glasschat.app.domain.model.StarredMessage
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.MediaRepository
import com.glasschat.app.domain.repository.MessageRepository
import com.glasschat.app.domain.usecase.CreateChatUseCase
import com.glasschat.app.ui.common.UiEvent
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ContactDetailUiState(
    val isLoading: Boolean = true,
    val contact: Contact? = null,
    val media: List<MediaItem> = emptyList(),
    val starred: List<StarredMessage> = emptyList(),
    val chatId: String? = null,
)

@HiltViewModel
class ContactDetailViewModel @Inject constructor(
    private val contactRepository: ContactRepository,
    private val chatRepository: ChatRepository,
    private val messageRepository: MessageRepository,
    mediaRepository: MediaRepository,
    private val createChatUseCase: CreateChatUseCase,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val contactId: String = savedStateHandle.get<String>("contactId").orEmpty()
    private val eventsChannel = Channel<UiEvent>(Channel.BUFFERED)
    val events: Flow<UiEvent> = eventsChannel.receiveAsFlow()

    val uiState: StateFlow<ContactDetailUiState> = combine(
        contactRepository.observeContact(contactId),
        chatRepository.observeChatSummaries(archived = false),
        mediaRepository.observeMedia(),
        messageRepository.observeStarred(),
    ) { contact, summaries, media, starred ->
        val chatIds = summaries
            .filter { summary -> summary.participants.any { it.contactId == contactId } }
            .map { it.chat.id }
        ContactDetailUiState(
            isLoading = false,
            contact = contact,
            media = media.filter { it.chatId in chatIds },
            starred = starred.filter { it.message.chatId in chatIds },
            chatId = chatIds.firstOrNull(),
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ContactDetailUiState())

    fun setFavorite(favorite: Boolean) = viewModelScope.launch {
        contactRepository.setFavorite(contactId, !favorite)
    }

    fun setBlocked(blocked: Boolean) = viewModelScope.launch {
        contactRepository.setBlocked(contactId, !blocked)
        eventsChannel.send(
            UiEvent(if (blocked) "Contact un-hidden" else "Contact hidden from new chats"),
        )
    }

    fun deleteContact(onDeleted: () -> Unit) = viewModelScope.launch {
        contactRepository.deleteContact(contactId)
        onDeleted()
    }

    /** Opens the existing one-to-one thread, or creates one on demand. */
    fun openChat(onReady: (String) -> Unit) = viewModelScope.launch {
        val existing = uiState.value.chatId
        if (existing != null) {
            onReady(existing)
            return@launch
        }
        val chatId = createChatUseCase(
            title = uiState.value.contact?.name.orEmpty(),
            type = ChatType.ONE_TO_ONE,
            existingContactIds = listOf(contactId),
        )
        onReady(chatId)
    }
}
