package com.glasschat.app.ui.features.contacts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.Contact
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.ContactRepository
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

data class ContactGroup(
    val letter: String,
    val contacts: List<Contact>,
)

data class ContactsUiState(
    val isLoading: Boolean = true,
    val query: String = "",
    val favorites: List<Contact> = emptyList(),
    val groups: List<ContactGroup> = emptyList(),
    val totalContacts: Int = 0,
)

@HiltViewModel
class ContactsViewModel @Inject constructor(
    private val contactRepository: ContactRepository,
    chatRepository: ChatRepository,
) : ViewModel() {

    private val query = MutableStateFlow("")
    private val eventsChannel = Channel<UiEvent>(Channel.BUFFERED)
    val events: Flow<UiEvent> = eventsChannel.receiveAsFlow()

    /** Chats let the contacts screen show how many threads each person appears in. */
    @Suppress("unused")
    private val chats = chatRepository.observeChatSummaries(archived = false)

    val uiState: StateFlow<ContactsUiState> = combine(
        contactRepository.observeContacts(),
        query,
        chats,
    ) { contacts, searchQuery, chatSummaries ->
        val filtered = if (searchQuery.isBlank()) {
            contacts
        } else {
            contacts.filter {
                it.name.contains(searchQuery, ignoreCase = true) ||
                    it.bio.contains(searchQuery, ignoreCase = true) ||
                    it.phoneLabel.contains(searchQuery, ignoreCase = true)
            }
        }
        val groups = filtered
            .groupBy { contact ->
                contact.name.trim().firstOrNull()?.uppercaseChar()?.takeIf { it.isLetter() }?.toString()
                    ?: "#"
            }
            .toSortedMap()
            .map { (letter, people) -> ContactGroup(letter, people.sortedBy { it.name.lowercase() }) }
        ContactsUiState(
            isLoading = false,
            query = searchQuery,
            favorites = filtered.filter { it.isFavorite },
            groups = groups,
            totalContacts = contacts.size,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ContactsUiState())

    fun onQueryChange(value: String) {
        query.value = value
    }

    fun toggleFavorite(contactId: String, favorite: Boolean) = viewModelScope.launch {
        contactRepository.setFavorite(contactId, !favorite)
        eventsChannel.send(
            UiEvent(if (favorite) "Removed from favourites" else "Added to favourites"),
        )
    }
}
