package com.glasschat.app.ui.features.chat

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.di.ApplicationScope
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.Chat
import com.glasschat.app.domain.model.ChatDetail
import com.glasschat.app.domain.model.Contact
import com.glasschat.app.domain.model.Message
import com.glasschat.app.domain.model.Participant
import com.glasschat.app.domain.model.PendingAttachment
import com.glasschat.app.domain.model.PendingCapture
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.MediaRepository
import com.glasschat.app.domain.repository.MessageRepository
import com.glasschat.app.domain.repository.SettingsRepository
import com.glasschat.app.domain.usecase.SendMessageUseCase
import com.glasschat.app.ui.common.UiEvent
import com.glasschat.app.ui.features.chats.ChatTimelineItem
import com.glasschat.app.ui.features.chats.buildTimeline
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ChatUiState(
    val isLoading: Boolean = true,
    val notFound: Boolean = false,
    val chat: Chat? = null,
    val participants: List<Participant> = emptyList(),
    val contact: Contact? = null,
    val timeline: List<ChatTimelineItem> = emptyList(),
    val messageCount: Int = 0,
    val draft: String = "",
    val senderType: SenderType = SenderType.ME,
    val senderContactId: String? = null,
    val replyTo: Message? = null,
    val editing: Message? = null,
    val pendingAttachments: List<PendingAttachment> = emptyList(),
    val simulateTyping: Boolean = false,
    val starredOnly: Boolean = false,
    val starredMessages: List<Message> = emptyList(),
    val searchQuery: String = "",
    val searchResults: List<Message> = emptyList(),
    val preferences: AppPreferences = AppPreferences(),
    val wallpaper: String = AppPreferences.WALLPAPER_AURORA,
    val accentColor: Long = 0L,
    val bubbleColorMe: Long? = null,
    val bubbleColorOther: Long? = null,
    val isRecording: Boolean = false,
    val recordingElapsedMs: Long = 0L,
    val isSending: Boolean = false,
) {
    val isGroup: Boolean get() = participants.size > 1
    val activeSenderName: String
        get() = when (senderType) {
            SenderType.ME -> preferences.displayName.ifBlank { "Me" }
            SenderType.CONTACT -> participants
                .firstOrNull { it.contactId == senderContactId }
                ?.name
                ?: contact?.name
                ?: "Contact"
        }
}

@OptIn(FlowPreview::class, ExperimentalCoroutinesApi::class)
@HiltViewModel
class ChatViewModel @Inject constructor(
    private val chatRepository: ChatRepository,
    private val messageRepository: MessageRepository,
    private val mediaRepository: MediaRepository,
    private val contactRepository: ContactRepository,
    private val settingsRepository: SettingsRepository,
    private val sendMessageUseCase: SendMessageUseCase,
    @ApplicationScope private val appScope: CoroutineScope,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    val chatId: String = savedStateHandle.get<String>("chatId").orEmpty()

    private data class ComposerState(
        val senderType: SenderType = SenderType.ME,
        val senderContactId: String? = null,
        val replyTo: Message? = null,
        val editing: Message? = null,
        val pending: List<PendingAttachment> = emptyList(),
        val simulateTyping: Boolean = false,
        val starredOnly: Boolean = false,
        val isRecording: Boolean = false,
        val recordingElapsedMs: Long = 0L,
        val isSending: Boolean = false,
    )

    private data class CoreState(
        val detail: ChatDetail?,
        val messages: List<Message>,
        val preferences: AppPreferences,
        val searchQuery: String,
        val searchResults: List<Message>,
    )

    private val composer = MutableStateFlow(ComposerState())
    private val draftState = MutableStateFlow<String?>(null)
    private val searchQuery = MutableStateFlow("")
    private val eventsChannel = Channel<UiEvent>(Channel.BUFFERED)
    private var recordingTicker: Job? = null

    val events: Flow<UiEvent> = eventsChannel.receiveAsFlow()

    private val detailFlow = chatRepository.observeChatDetail(chatId)
    private val messagesFlow = messageRepository.observeMessages(chatId)
    private val starredFlow = messageRepository.observeStarredForChat(chatId)
    private val searchResults = searchQuery.flatMapLatest { query ->
        if (query.isBlank()) flowOf(emptyList()) else messageRepository.searchInChat(chatId, query)
    }

    private val coreFlow = combine(
        detailFlow,
        messagesFlow,
        settingsRepository.preferences,
        searchQuery,
        searchResults,
    ) { detail, messages, preferences, query, results ->
        CoreState(detail, messages, preferences, query, results)
    }

    val uiState: StateFlow<ChatUiState> = combine(
        coreFlow,
        composer,
        draftState,
        starredFlow,
    ) { core, comp, draft, starred ->
        val chat = core.detail?.chat
        ChatUiState(
            isLoading = false,
            notFound = core.detail == null,
            chat = chat,
            participants = core.detail?.participants.orEmpty(),
            contact = core.detail?.primaryContact,
            timeline = buildTimeline(core.messages),
            messageCount = core.messages.size,
            draft = draft ?: chat?.draft.orEmpty(),
            senderType = comp.senderType,
            senderContactId = comp.senderContactId ?: core.detail?.primaryContact?.id,
            replyTo = comp.replyTo,
            editing = comp.editing,
            pendingAttachments = comp.pending,
            simulateTyping = comp.simulateTyping,
            starredOnly = comp.starredOnly,
            starredMessages = starred,
            searchQuery = core.searchQuery,
            searchResults = core.searchResults,
            preferences = core.preferences,
            wallpaper = chat?.wallpaper ?: core.preferences.wallpaper,
            accentColor = chat?.accentColor ?: core.preferences.accent,
            bubbleColorMe = chat?.bubbleColorMe ?: core.preferences.bubbleColorMe,
            bubbleColorOther = chat?.bubbleColorOther ?: core.preferences.bubbleColorOther,
            isRecording = comp.isRecording,
            recordingElapsedMs = comp.recordingElapsedMs,
            isSending = comp.isSending,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ChatUiState())

    init {
        viewModelScope.launch {
            if (draftState.value == null) {
                val detail = detailFlow.firstOrNull()
                draftState.value = detail?.chat?.draft.orEmpty()
            }
        }
        // Drafts persist 350ms after the last keystroke and again on screen exit.
        viewModelScope.launch {
            draftState
                .filterNotNull()
                .debounce(350)
                .distinctUntilChanged()
                .collect { draft -> chatRepository.saveDraft(chatId, draft) }
        }
        viewModelScope.launch {
            messageRepository.observeUnreadCount(chatId).collect { count ->
                if (count > 0) chatRepository.markRead(chatId)
            }
        }
    }

    // ------------------------------------------------------------------
    // Composer
    // ------------------------------------------------------------------

    fun onDraftChange(text: String) {
        draftState.value = text
    }

    fun selectSender(type: SenderType, contactId: String? = null) {
        composer.update {
            it.copy(
                senderType = type,
                senderContactId = if (type == SenderType.ME) null else contactId ?: it.senderContactId,
            )
        }
    }

    fun selectSenderParticipant(contactId: String) {
        composer.update { it.copy(senderType = SenderType.CONTACT, senderContactId = contactId) }
    }

    fun onReply(message: Message) {
        composer.update { it.copy(replyTo = message, editing = null) }
    }

    fun cancelReply() {
        composer.update { it.copy(replyTo = null) }
    }

    fun onStartEdit(message: Message) {
        composer.update { it.copy(editing = message, replyTo = null) }
        draftState.value = message.text
    }

    fun cancelEdit() {
        composer.update { it.copy(editing = null) }
        draftState.value = ""
    }

    fun onSend() {
        val state = uiState.value
        val comp = composer.value
        val text = (draftState.value ?: state.chat?.draft.orEmpty()).trim()

        val editing = comp.editing
        if (editing != null) {
            if (text.isBlank()) {
                cancelEdit()
                return
            }
            viewModelScope.launch {
                messageRepository.editMessage(editing.id, text)
                composer.update { it.copy(editing = null) }
                draftState.value = ""
                chatRepository.saveDraft(chatId, "")
            }
            return
        }

        if (text.isEmpty() && comp.pending.isEmpty()) return

        viewModelScope.launch {
            composer.update { it.copy(isSending = true) }
            val messageId = sendMessageUseCase(
                chatId = chatId,
                senderType = comp.senderType,
                senderContactId = comp.senderContactId ?: state.contact?.id,
                text = text,
                replyToMessageId = comp.replyTo?.id,
                attachments = comp.pending,
            )
            if (messageId == null) {
                composer.update { it.copy(isSending = false) }
                eventsChannel.send(UiEvent("That message could not be saved"))
                return@launch
            }
            composer.update { it.copy(replyTo = null, pending = emptyList(), isSending = false) }
            draftState.value = ""
            chatRepository.saveDraft(chatId, "")
            if (comp.senderType == SenderType.ME) {
                // Cosmetic only: ticks are labelled "Simulated" wherever they are shown.
                launch { messageRepository.advanceSimulatedStatus(messageId) }
            }
        }
    }

    // ------------------------------------------------------------------
    // Attachments
    // ------------------------------------------------------------------

    fun attach(uri: String, mimeType: String?) = viewModelScope.launch {
        val type = attachmentTypeFor(mimeType)
        val pending = mediaRepository.importFromUri(uri, type, mimeType = mimeType)
        if (pending == null) {
            eventsChannel.send(UiEvent("That file could not be copied"))
        } else {
            composer.update { it.copy(pending = it.pending + pending) }
        }
    }

    fun attachDocument(uri: String, fileName: String?, mimeType: String?) = viewModelScope.launch {
        val pending = mediaRepository.importFromUri(
            uri = uri,
            type = AttachmentType.DOCUMENT,
            fileName = fileName,
            mimeType = mimeType,
        )
        if (pending == null) {
            eventsChannel.send(UiEvent("That document could not be copied"))
        } else {
            composer.update { it.copy(pending = it.pending + pending) }
        }
    }

    fun attachCameraResult(capture: PendingCapture) = viewModelScope.launch {
        val pending = mediaRepository.importCapturedPhoto(capture.filePath)
        if (pending == null) {
            eventsChannel.send(UiEvent("The photo could not be saved"))
        } else {
            composer.update { it.copy(pending = it.pending + pending) }
        }
    }

    fun removePendingAttachment(index: Int) {
        val target = composer.value.pending.getOrNull(index) ?: return
        viewModelScope.launch { mediaRepository.deleteMediaAt(target.localUri) }
        composer.update { state ->
            state.copy(pending = state.pending.filterIndexed { i, _ -> i != index })
        }
    }

    fun updatePendingCaption(caption: String) {
        composer.update { state ->
            val updated = state.pending.mapIndexed { index, attachment ->
                if (index == 0) attachment.copy(caption = caption) else attachment
            }
            state.copy(pending = updated)
        }
    }

    /** Creates a cache file + content URI for the system camera intent. */
    fun prepareCameraCapture(onReady: (PendingCapture?) -> Unit) = viewModelScope.launch {
        onReady(mediaRepository.createCameraTarget())
    }

    /** Resolves a FileProvider URI for opening an attachment in another app. */
    fun resolveContentUri(attachmentId: String, onReady: (String?) -> Unit) = viewModelScope.launch {
        onReady(mediaRepository.contentUriFor(attachmentId))
    }

    /** Location / contact-card placeholders are plain locally authored messages. */
    fun sendPlaceholderMessage(body: String) = viewModelScope.launch {
        val state = uiState.value
        val comp = composer.value
        sendMessageUseCase(
            chatId = chatId,
            senderType = comp.senderType,
            senderContactId = comp.senderContactId ?: state.contact?.id,
            text = body,
        )
    }

    fun deleteChat(onDeleted: () -> Unit) = viewModelScope.launch {
        chatRepository.deleteChat(chatId)
        onDeleted()
    }

    fun startRecording() = viewModelScope.launch {
        if (!mediaRepository.startRecording()) {
            eventsChannel.send(UiEvent("Microphone unavailable — check the permission"))
            return@launch
        }
        composer.update { it.copy(isRecording = true, recordingElapsedMs = 0L) }
        recordingTicker?.cancel()
        recordingTicker = viewModelScope.launch {
            var elapsed = 0L
            while (isActive && elapsed < 120_000L) {
                delay(150)
                elapsed += 150
                composer.update { it.copy(recordingElapsedMs = elapsed) }
            }
            if (isActive) stopRecording()
        }
    }

    fun stopRecording() = viewModelScope.launch {
        recordingTicker?.cancel()
        recordingTicker = null
        val pending = mediaRepository.stopRecording()
        composer.update { it.copy(isRecording = false, recordingElapsedMs = 0L) }
        if (pending != null) {
            composer.update { it.copy(pending = it.pending + pending) }
        }
    }

    fun cancelRecording() {
        recordingTicker?.cancel()
        recordingTicker = null
        mediaRepository.cancelRecording()
        composer.update { it.copy(isRecording = false, recordingElapsedMs = 0L) }
    }

    // ------------------------------------------------------------------
    // Message actions
    // ------------------------------------------------------------------

    fun toggleTypingSimulation() {
        composer.update { it.copy(simulateTyping = !it.simulateTyping) }
    }

    fun onSearchChange(value: String) {
        searchQuery.value = value
    }

    fun closeSearch() {
        searchQuery.value = ""
    }

    fun toggleStarredOnly() {
        composer.update { it.copy(starredOnly = !it.starredOnly) }
    }

    fun toggleReaction(messageId: String, emoji: String, senderType: SenderType = SenderType.ME) =
        viewModelScope.launch {
            messageRepository.toggleReaction(messageId, senderType, emoji)
        }

    fun setStarred(messageId: String, starred: Boolean) = viewModelScope.launch {
        messageRepository.setStarred(messageId, starred)
        eventsChannel.send(UiEvent(if (starred) "Message starred" else "Star removed"))
    }

    fun deleteForMe(messageId: String) = viewModelScope.launch {
        messageRepository.deleteForMe(messageId)
        eventsChannel.send(UiEvent("Message deleted for you"))
    }

    fun deleteForEveryone(messageId: String) = viewModelScope.launch {
        messageRepository.deleteForEveryone(messageId)
        eventsChannel.send(UiEvent("Message deleted for everyone"))
    }

    fun markUnread() = viewModelScope.launch {
        chatRepository.markUnread(chatId)
        eventsChannel.send(UiEvent("Marked as unread"))
    }

    fun toggleMute(muted: Boolean) = viewModelScope.launch {
        chatRepository.setMuted(chatId, !muted)
    }

    fun togglePin(pinned: Boolean) = viewModelScope.launch {
        chatRepository.setPinned(chatId, !pinned)
    }

    fun archive() = viewModelScope.launch {
        chatRepository.setArchived(chatId, true)
        eventsChannel.send(UiEvent("Chat archived"))
    }

    fun clearChat() = viewModelScope.launch {
        messageRepository.clearChat(chatId)
        eventsChannel.send(UiEvent("All messages removed"))
    }

    fun contactDetails(): Contact? = uiState.value.contact

    fun loadContact(contactId: String, onLoaded: (Contact?) -> Unit) = viewModelScope.launch {
        onLoaded(contactRepository.getContact(contactId))
    }

    override fun onCleared() {
        super.onCleared()
        recordingTicker?.cancel()
        if (mediaRepository.isRecording()) mediaRepository.cancelRecording()
        // Persist whatever is in the composer so nothing is lost when leaving.
        val pendingDraft = draftState.value
        if (pendingDraft != null) {
            appScope.launch { chatRepository.saveDraft(chatId, pendingDraft) }
        }
    }

    private fun attachmentTypeFor(mimeType: String?): AttachmentType = when {
        mimeType == null -> AttachmentType.DOCUMENT
        mimeType.startsWith("image/") -> AttachmentType.IMAGE
        mimeType.startsWith("video/") -> AttachmentType.VIDEO
        mimeType.startsWith("audio/") -> AttachmentType.AUDIO
        else -> AttachmentType.DOCUMENT
    }
}
