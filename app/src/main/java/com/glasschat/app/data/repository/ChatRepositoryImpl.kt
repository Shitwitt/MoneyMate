package com.glasschat.app.data.repository

import com.glasschat.app.data.local.db.dao.ChatDao
import com.glasschat.app.data.local.db.dao.ChatParticipantDao
import com.glasschat.app.data.local.db.dao.ContactDao
import com.glasschat.app.data.local.db.dao.MessageDao
import com.glasschat.app.data.local.db.entity.ChatEntity
import com.glasschat.app.data.local.db.entity.ChatParticipantEntity
import com.glasschat.app.data.local.db.entity.ParticipantRow
import com.glasschat.app.data.mapper.toDomain
import com.glasschat.app.data.mapper.toParticipant
import com.glasschat.app.di.IoDispatcher
import com.glasschat.app.domain.model.Chat
import com.glasschat.app.domain.model.ChatDetail
import com.glasschat.app.domain.model.ChatSummary
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.CreateChatRequest
import com.glasschat.app.domain.model.ParticipantRole
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.util.newId
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ChatRepositoryImpl @Inject constructor(
    private val chatDao: ChatDao,
    private val participantDao: ChatParticipantDao,
    private val contactDao: ContactDao,
    private val messageDao: MessageDao,
    @IoDispatcher private val io: CoroutineDispatcher,
) : ChatRepository {

    override fun observeChatSummaries(archived: Boolean): Flow<List<ChatSummary>> =
        combine(
            chatDao.observeSummaries(archived),
            participantDao.observeAllWithContact(),
        ) { rows, participants ->
            val byChat = participants.groupBy { it.chatId }
            rows.map { row ->
                row.toDomain(
                    participants = byChat[row.chat.id].orEmpty().map { it.toParticipant() },
                )
            }
        }

    override fun observeChat(chatId: String): Flow<Chat?> =
        chatDao.observeById(chatId).map { it?.toDomain() }

    override fun observeChatDetail(chatId: String): Flow<ChatDetail?> = combine(
        chatDao.observeById(chatId),
        participantDao.observeAllWithContact(),
    ) { chat, participants ->
        if (chat == null) return@combine null
        val rows = participants.filter { it.chatId == chatId }
        ChatDetail(
            chat = chat.toDomain(),
            participants = rows.map { it.toParticipant() },
            primaryContact = rows.firstOrNull()?.contact?.toDomain(),
        )
    }

    override fun observeArchivedCount(): Flow<Int> = chatDao.observeArchivedCount()

    override suspend fun createChat(request: CreateChatRequest): String = withContext(io) {
        val chatId = newId()
        val now = System.currentTimeMillis()
        val type = if (request.participantContactIds.size > 1) ChatType.GROUP else request.type
        chatDao.insert(
            ChatEntity(
                id = chatId,
                title = request.title.trim(),
                type = type,
                wallpaper = request.wallpaper,
                accentColor = request.accentColor,
                isPinned = false,
                isArchived = false,
                isMuted = false,
                createdAt = now,
                updatedAt = now,
                draft = "",
            ),
        )
        participantDao.insertAll(
            request.participantContactIds.mapIndexed { index, contactId ->
                ChatParticipantEntity(
                    chatId = chatId,
                    contactId = contactId,
                    role = if (index == 0) ParticipantRole.OWNER else ParticipantRole.MEMBER,
                    position = index,
                )
            },
        )
        chatId
    }

    override suspend fun renameChat(chatId: String, title: String) = withContext(io) {
        val trimmed = title.trim()
        if (trimmed.isNotEmpty()) chatDao.updateTitle(chatId, trimmed.take(80))
    }

    override suspend fun setPinned(chatId: String, pinned: Boolean) = withContext(io) {
        chatDao.setPinned(chatId, pinned)
    }

    override suspend fun setArchived(chatId: String, archived: Boolean) = withContext(io) {
        chatDao.setArchived(chatId, archived)
        if (archived) chatDao.setPinned(chatId, false)
    }

    override suspend fun setMuted(chatId: String, muted: Boolean) = withContext(io) {
        chatDao.setMuted(chatId, muted)
    }

    override suspend fun updateAppearance(
        chatId: String,
        wallpaper: String?,
        accentColor: Long?,
        bubbleColorMe: Long?,
        bubbleColorOther: Long?,
    ) = withContext(io) {
        chatDao.updateAppearance(chatId, wallpaper, accentColor, bubbleColorMe, bubbleColorOther)
    }

    override suspend fun saveDraft(chatId: String, draft: String) = withContext(io) {
        chatDao.updateDraft(chatId, draft)
    }

    override suspend fun addParticipants(chatId: String, contactIds: List<String>) = withContext(io) {
        val existing = participantDao.getForChat(chatId).map { it.contact.id }
        val additions = contactIds.filterNot { it in existing }
        if (additions.isEmpty()) return@withContext
        participantDao.insertAll(
            additions.mapIndexed { index, contactId ->
                ChatParticipantEntity(
                    chatId = chatId,
                    contactId = contactId,
                    role = ParticipantRole.MEMBER,
                    position = existing.size + index,
                )
            },
        )
        if (existing.size + additions.size > 1) {
            chatDao.getById(chatId)?.let { chat ->
                if (chat.type == ChatType.ONE_TO_ONE) {
                    chatDao.update(chat.copy(type = ChatType.GROUP))
                }
            }
        }
        Unit
    }

    override suspend fun removeParticipant(chatId: String, contactId: String) = withContext(io) {
        val remaining = participantDao.getForChat(chatId).filterNot { it.contact.id == contactId }
        if (remaining.isEmpty()) return@withContext
        participantDao.remove(chatId, contactId)
        if (remaining.size == 1) {
            chatDao.getById(chatId)?.let { chat ->
                if (chat.type == ChatType.GROUP) {
                    chatDao.update(chat.copy(type = ChatType.ONE_TO_ONE))
                }
            }
        }
        Unit
    }

    override suspend fun markRead(chatId: String) = withContext(io) {
        messageDao.markIncomingRead(chatId)
    }

    override suspend fun markUnread(chatId: String) = withContext(io) {
        messageDao.markLastIncomingUnread(chatId)
    }

    override suspend fun setDeleted(chatId: String, deleted: Boolean) = withContext(io) {
        chatDao.setDeleted(chatId, deleted)
        if (deleted) chatDao.setPinned(chatId, false)
        Unit
    }

    override suspend fun deleteChat(chatId: String) = withContext(io) {
        chatDao.deleteById(chatId)
    }

    override suspend fun getChatDetailOnce(chatId: String): ChatDetail? = withContext(io) {
        val chat = chatDao.getById(chatId) ?: return@withContext null
        val rows: List<ParticipantRow> = participantDao.getForChat(chatId)
        ChatDetail(
            chat = chat.toDomain(),
            participants = rows.map { it.toParticipant() },
            primaryContact = rows.firstOrNull()?.contact?.toDomain(),
        )
    }

    /** Kept for symmetry with contacts: a chat with no participants has no counterpart. */
    suspend fun contactExists(contactId: String): Boolean = withContext(io) {
        contactDao.getById(contactId) != null
    }
}
