package com.glasschat.app.ui.features.archived

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.ChatSummary
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.ui.common.UiEvent
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ArchivedUiState(
    val isLoading: Boolean = true,
    val chats: List<ChatSummary> = emptyList(),
)

@HiltViewModel
class ArchivedChatsViewModel @Inject constructor(
    private val chatRepository: ChatRepository,
) : ViewModel() {

    private val eventsChannel = Channel<UiEvent>(Channel.BUFFERED)
    val events: Flow<UiEvent> = eventsChannel.receiveAsFlow()

    val uiState: StateFlow<ArchivedUiState> = chatRepository.observeChatSummaries(archived = true)
        .map { ArchivedUiState(isLoading = false, chats = it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ArchivedUiState())

    fun restore(chatId: String) = viewModelScope.launch {
        chatRepository.setArchived(chatId, false)
        eventsChannel.send(
            UiEvent(
                message = "Chat restored",
                actionLabel = "Undo",
                action = { chatRepository.setArchived(chatId, true) },
            ),
        )
    }

    fun delete(chatId: String) = viewModelScope.launch {
        chatRepository.deleteChat(chatId)
        eventsChannel.send(UiEvent("Archived chat deleted"))
    }
}
