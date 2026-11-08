package com.glasschat.app.ui.features.viewer

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.MediaItem
import com.glasschat.app.domain.repository.MediaRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class MediaViewerUiState(
    val isLoading: Boolean = true,
    val items: List<MediaItem> = emptyList(),
    val initialIndex: Int = 0,
    val wasDeleted: Boolean = false,
)

@HiltViewModel
class MediaViewerViewModel @Inject constructor(
    private val mediaRepository: MediaRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val chatId: String = savedStateHandle.get<String>("chatId").orEmpty()
    private val startMessageId: String = savedStateHandle.get<String>("messageId").orEmpty()
    private val deleted = MutableStateFlow(false)

    val uiState: StateFlow<MediaViewerUiState> = combine(
        mediaRepository.observeMediaForChat(chatId),
        deleted,
    ) { items, wasDeleted ->
        val ordered = items.sortedBy { it.createdAt }
        val index = ordered.indexOfFirst { it.messageId == startMessageId }.coerceAtLeast(0)
        MediaViewerUiState(
            isLoading = false,
            items = ordered,
            initialIndex = index,
            wasDeleted = wasDeleted,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), MediaViewerUiState())

    /** Streams the private copy into a user-chosen SAF destination. */
    fun saveTo(destinationUri: String, attachmentId: String, onDone: (Boolean) -> Unit) =
        viewModelScope.launch {
            val success = mediaRepository.exportToDestination(attachmentId, destinationUri)
            onDone(success)
        }

    fun delete(attachmentId: String, onDeleted: () -> Unit) = viewModelScope.launch {
        mediaRepository.deleteAttachment(attachmentId)
        onDeleted()
    }

    fun contentUriFor(attachmentId: String, onReady: (String?) -> Unit) = viewModelScope.launch {
        onReady(mediaRepository.contentUriFor(attachmentId))
    }
}
