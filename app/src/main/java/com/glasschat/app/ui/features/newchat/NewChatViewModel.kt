package com.glasschat.app.ui.features.newchat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.ChatTemplates
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.Contact
import com.glasschat.app.domain.model.ContactDraft
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.usecase.CreateChatUseCase
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
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NewChatUiState(
    val isLoading: Boolean = true,
    val contacts: List<Contact> = emptyList(),
    val query: String = "",
    val selectedIds: Set<String> = emptySet(),
    val title: String = "",
    val templateId: String = ChatTemplates.all.first().id,
    val showNewContactForm: Boolean = false,
    val newContactName: String = "",
    val newContactAccent: Long = 0xFF4FE3D5,
    val isCreating: Boolean = false,
) {
    val isGroup: Boolean get() = selectedIds.size > 1
    val canCreate: Boolean get() = selectedIds.isNotEmpty() || newContactName.isNotBlank()
    val templates get() = ChatTemplates.all
}

@HiltViewModel
class NewChatViewModel @Inject constructor(
    private val contactRepository: ContactRepository,
    private val createChatUseCase: CreateChatUseCase,
) : ViewModel() {

    private data class FormState(
        val query: String = "",
        val selectedIds: Set<String> = emptySet(),
        val title: String = "",
        val templateId: String = ChatTemplates.all.first().id,
        val showNewContactForm: Boolean = false,
        val newContactName: String = "",
        val newContactAccent: Long = 0xFF4FE3D5,
        val isCreating: Boolean = false,
    )

    private val form = MutableStateFlow(FormState())
    private val eventsChannel = Channel<UiEvent>(Channel.BUFFERED)
    val events: Flow<UiEvent> = eventsChannel.receiveAsFlow()

    val uiState: StateFlow<NewChatUiState> = combine(
        contactRepository.observeContacts(),
        form,
    ) { contacts, state ->
        val filtered = if (state.query.isBlank()) {
            contacts
        } else {
            contacts.filter { it.name.contains(state.query, ignoreCase = true) }
        }
        NewChatUiState(
            isLoading = false,
            contacts = filtered,
            query = state.query,
            selectedIds = state.selectedIds,
            title = state.title,
            templateId = state.templateId,
            showNewContactForm = state.showNewContactForm,
            newContactName = state.newContactName,
            newContactAccent = state.newContactAccent,
            isCreating = state.isCreating,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), NewChatUiState())

    fun onQueryChange(value: String) = form.update { it.copy(query = value) }

    fun toggleContact(contactId: String) = form.update { state ->
        val updated = if (contactId in state.selectedIds) {
            state.selectedIds - contactId
        } else {
            state.selectedIds + contactId
        }
        state.copy(selectedIds = updated)
    }

    fun onTitleChange(value: String) = form.update { it.copy(title = value.take(60)) }

    fun selectTemplate(templateId: String) = form.update { it.copy(templateId = templateId) }

    fun toggleNewContactForm() = form.update { it.copy(showNewContactForm = !it.showNewContactForm) }

    fun onNewContactNameChange(value: String) = form.update { it.copy(newContactName = value) }

    fun onNewContactAccentChange(color: Long) = form.update { it.copy(newContactAccent = color) }

    fun create(onCreated: (String) -> Unit) {
        val state = form.value
        val current = uiState.value
        if (!current.canCreate || state.isCreating) return
        form.update { it.copy(isCreating = true) }
        viewModelScope.launch {
            val newContacts = if (state.showNewContactForm && state.newContactName.isNotBlank()) {
                listOf(
                    ContactDraft(
                        name = state.newContactName,
                        accentColor = state.newContactAccent,
                    ),
                )
            } else {
                emptyList()
            }
            val chatId = createChatUseCase(
                title = state.title,
                type = if (state.selectedIds.size > 1) ChatType.GROUP else ChatType.ONE_TO_ONE,
                existingContactIds = state.selectedIds.toList(),
                newContacts = newContacts,
                templateId = state.templateId,
            )
            form.update { it.copy(isCreating = false) }
            onCreated(chatId)
        }
    }

    /** One-tap path used by "New chat with this contact" from the contacts list. */
    fun startWithContact(contactId: String, templateId: String, onCreated: (String) -> Unit) {
        viewModelScope.launch {
            val chatId = createChatUseCase(
                title = "",
                type = ChatType.ONE_TO_ONE,
                existingContactIds = listOf(contactId),
                templateId = templateId,
            )
            onCreated(chatId)
        }
    }

    fun notify(message: String) {
        viewModelScope.launch { eventsChannel.send(UiEvent(message)) }
    }
}
