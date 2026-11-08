package com.glasschat.app.domain.usecase

import com.glasschat.app.domain.model.Chat
import com.glasschat.app.domain.model.ChatDetail
import com.glasschat.app.domain.model.ChatSummary
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.Contact
import com.glasschat.app.domain.model.ContactDraft
import com.glasschat.app.domain.model.CreateChatRequest
import com.glasschat.app.domain.model.Message
import com.glasschat.app.domain.model.Participant
import com.glasschat.app.domain.model.ParticipantRole
import com.glasschat.app.domain.model.SendMessageRequest
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.domain.model.StarredMessage
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.MessageRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf

/**
 * Tiny in-memory doubles used by the use-case tests. They only implement the behaviour the
 * production code actually touches, and fail loudly if something unexpected is called.
 */
class FakeContactRepository : ContactRepository {

    val contacts = linkedMapOf<String, Contact>()
    private var sequence = 0

    override fun observeContacts(): Flow<List<Contact>> = flowOf(contacts.values.toList())

    override fun observeContact(contactId: String): Flow<Contact?> = flowOf(contacts[contactId])

    override suspend fun getContact(contactId: String): Contact? = contacts[contactId]

    override suspend fun countContacts(): Int = contacts.size

    override suspend fun createContact(draft: ContactDraft): String {
        val id = "contact-${++sequence}"
        contacts[id] = Contact(
            id = id,
            name = draft.name,
            avatarUri = draft.avatarUri,
            accentColor = draft.accentColor,
            bio = draft.bio,
            phoneLabel = draft.phoneLabel,
            notes = draft.notes,
            isFavorite = false,
            isBlocked = false,
            createdAt = sequence.toLong(),
        )
        return id
    }

    override suspend fun updateContact(contactId: String, draft: ContactDraft) {
        val existing = contacts[contactId] ?: return
        contacts[contactId] = existing.copy(name = draft.name, bio = draft.bio)
    }

    override suspend fun deleteContact(contactId: String) {
        contacts.remove(contactId)
    }

    override suspend fun setFavorite(contactId: String, favorite: Boolean) {
        contacts[contactId]?.let { contacts[contactId] = it.copy(isFavorite = favorite) }
    }

    override suspend fun setBlocked(contactId: String, blocked: Boolean) {
        contacts[contactId]?.let { contacts[contactId] = it.copy(isBlocked = blocked) }
    }
}

class FakeChatRepository : ChatRepository {

    val requests = mutableListOf<CreateChatRequest>()
    val unreadChats = mutableSetOf<String>()
    val archived = mutableMapOf<String, Boolean>()
    private val chats = linkedMapOf<String, Chat>()

    override fun observeChatSummaries(archived: Boolean): Flow<List<ChatSummary>> = flowOf(emptyList())

    override fun observeChat(chatId: String): Flow<Chat?> = flowOf(chats[chatId])

    override fun observeChatDetail(chatId: String): Flow<ChatDetail?> = flowOf(null)

    override suspend fun getChatDetailOnce(chatId: String): ChatDetail? = null

    override fun observeArchivedCount(): Flow<Int> = flowOf(archivedChatCount)

    private val archivedChatCount: Int get() = archived.values.count { it }

    override suspend fun createChat(request: CreateChatRequest): String {
        requests += request
        val id = "chat-${requests.size}"
        chats[id] = Chat(
            id = id,
            title = request.title,
            type = request.type,
            wallpaper = request.wallpaper,
            accentColor = request.accentColor,
            bubbleColorMe = null,
            bubbleColorOther = null,
            isPinned = false,
            isArchived = false,
            isMuted = false,
            createdAt = 0L,
            updatedAt = 0L,
            draft = "",
        )
        return id
    }

    override suspend fun renameChat(chatId: String, title: String) {
        chats[chatId]?.let { chats[chatId] = it.copy(title = title) }
    }

    override suspend fun setPinned(chatId: String, pinned: Boolean) = Unit

    override suspend fun setArchived(chatId: String, archived: Boolean) {
        this.archived[chatId] = archived
    }

    override suspend fun setMuted(chatId: String, muted: Boolean) = Unit

    override suspend fun updateAppearance(
        chatId: String,
        wallpaper: String?,
        accentColor: Long?,
        bubbleColorMe: Long?,
        bubbleColorOther: Long?,
    ) = Unit

    override suspend fun saveDraft(chatId: String, draft: String) = Unit

    override suspend fun addParticipants(chatId: String, contactIds: List<String>) = Unit

    override suspend fun removeParticipant(chatId: String, contactId: String) = Unit

    override suspend fun markRead(chatId: String) {
        unreadChats.remove(chatId)
    }

    override suspend fun markUnread(chatId: String) {
        unreadChats += chatId
    }

    override suspend fun setDeleted(chatId: String, deleted: Boolean) = Unit

    override suspend fun deleteChat(chatId: String) {
        chats.remove(chatId)
    }
}

class FakeMessageRepository : MessageRepository {

    val sent = mutableListOf<SendMessageRequest>()

    override fun observeMessages(chatId: String): Flow<List<Message>> = flowOf(emptyList())

    override fun observeMessage(messageId: String): Flow<Message?> = flowOf(null)

    override fun observeStarred(): Flow<List<StarredMessage>> = flowOf(emptyList())

    override fun observeStarredForChat(chatId: String): Flow<List<Message>> = flowOf(emptyList())

    override fun observeUnreadCount(chatId: String): Flow<Int> = flowOf(0)

    override fun searchInChat(chatId: String, query: String): Flow<List<Message>> = flowOf(emptyList())

    override suspend fun sendMessage(request: SendMessageRequest): String {
        sent += request
        return "message-${sent.size}"
    }

    override suspend fun advanceSimulatedStatus(messageId: String) = Unit

    override suspend fun editMessage(messageId: String, newText: String) = Unit

    override suspend fun deleteForMe(messageId: String) = Unit

    override suspend fun deleteForEveryone(messageId: String) = Unit

    override suspend fun setStarred(messageId: String, starred: Boolean) = Unit

    override suspend fun toggleReaction(messageId: String, senderType: SenderType, emoji: String) = Unit

    override suspend fun clearChat(chatId: String) = Unit
}
