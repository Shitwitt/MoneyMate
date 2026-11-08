package com.glasschat.app.ui.features.chats

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.ChatSummary
import com.glasschat.app.domain.repository.ChatRepository
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

data class ChatsUiState(
    val isLoading: Boolean = true,
    val query: String = "",
    val chats: List<ChatSummary> = emptyList(),
    val archivedCount: Int = 0,
    val blurMedia: Boolean = false,
    val hasChats: Boolean = false,
)

@HiltViewModel
class ChatsViewModel @Inject constructor(
    private val chatRepository: ChatRepository,
    settingsRepository: SettingsRepository,
) : ViewModel() {

    private val query = MutableStateFlow("")
    private val eventsChannel = Channel<UiEvent>(Channel.BUFFERED)
    val events: Flow<UiEvent> = eventsChannel.receiveAsFlow()

    val uiState: StateFlow<ChatsUiState> = combine(
        chatRepository.observeChatSummaries(archived = false),
        chatRepository.observeArchivedCount(),
        settingsRepository.preferences,
        query,
    ) { summaries, archivedCount, prefs, searchQuery ->
        val filtered = if (searchQuery.isBlank()) {
            summaries
        } else {
            summaries.filter { summary ->
                summary.displayTitle.contains(searchQuery, ignoreCase = true) ||
                    summary.lastMessagePreview.contains(searchQuery, ignoreCase = true) ||
                    summary.participants.any { it.name.contains(searchQuery, ignoreCase = true) }
            }
        }
        ChatsUiState(
            isLoading = false,
            query = searchQuery,
            chats = filtered,
            archivedCount = archivedCount,
            blurMedia = prefs.blurMediaInList,
            hasChats = summaries.isNotEmpty(),
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ChatsUiState())

    fun onQueryChange(value: String) {
        query.value = value
    }

    fun togglePin(chatId: String, pinned: Boolean) = viewModelScope.launch {
        chatRepository.setPinned(chatId, !pinned)
        eventsChannel.send(
            UiEvent(if (pinned) "Unpinned" else "Pinned to top"),
        )
    }

    fun toggleMute(chatId: String, muted: Boolean) = viewModelScope.launch {
        chatRepository.setMuted(chatId, !muted)
        eventsChannel.send(UiEvent(if (muted) "Notifications unmuted" else "Chat muted"))
    }

    fun archive(chatId: String) = viewModelScope.launch {
        chatRepository.setArchived(chatId, true)
        eventsChannel.send(
            UiEvent(
                message = "Chat archived",
                actionLabel = "Undo",
                action = { chatRepository.setArchived(chatId, false) },
            ),
        )
    }

    fun delete(chatId: String) = viewModelScope.launch {
        chatRepository.setDeleted(chatId, true)
        eventsChannel.send(
            UiEvent(
                message = "Chat deleted",
                actionLabel = "Undo",
                action = { chatRepository.setDeleted(chatId, false) },
            ),
        )
    }
}
