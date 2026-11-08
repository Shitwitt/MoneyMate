package com.glasschat.app.ui.features.gallery

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.MediaGroup
import com.glasschat.app.domain.model.MediaItem
import com.glasschat.app.domain.repository.MediaRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

enum class MediaFilter(val label: String) {
    ALL("All"),
    PHOTOS("Photos"),
    VIDEOS("Videos"),
    AUDIO("Audio"),
    DOCUMENTS("Docs"),
}

data class GalleryUiState(
    val isLoading: Boolean = true,
    val filter: MediaFilter = MediaFilter.ALL,
    val groups: List<MediaGroup> = emptyList(),
    val totalCount: Int = 0,
)

@HiltViewModel
class GalleryViewModel @Inject constructor(
    mediaRepository: MediaRepository,
) : ViewModel() {

    private val filter = MutableStateFlow(MediaFilter.ALL)

    val uiState: StateFlow<GalleryUiState> = combine(
        mediaRepository.observeMedia(),
        filter,
    ) { items, activeFilter ->
        val filtered = when (activeFilter) {
            MediaFilter.ALL -> items
            MediaFilter.PHOTOS -> items.filter { it.attachment.type == AttachmentType.IMAGE }
            MediaFilter.VIDEOS -> items.filter { it.attachment.type == AttachmentType.VIDEO }
            MediaFilter.AUDIO -> items.filter { it.attachment.type == AttachmentType.AUDIO }
            MediaFilter.DOCUMENTS -> items.filter { it.attachment.type == AttachmentType.DOCUMENT }
        }
        val groups = filtered
            .groupBy { it.chatId }
            .map { (chatId, media) ->
                MediaGroup(
                    chatId = chatId,
                    chatTitle = media.first().chatTitle,
                    items = media.sortedByDescending { it.createdAt },
                )
            }
            .sortedByDescending { group -> group.items.firstOrNull()?.createdAt ?: 0L }
        GalleryUiState(
            isLoading = false,
            filter = activeFilter,
            groups = groups,
            totalCount = filtered.size,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), GalleryUiState())

    fun setFilter(value: MediaFilter) {
        filter.value = value
    }
}

/** Convenience for screens that need a flat, ordered list for the pager. */
fun List<MediaGroup>.flattenMedia(): List<MediaItem> = flatMap { it.items }
