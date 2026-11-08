package com.glasschat.app.data.repository

import com.glasschat.app.data.local.db.dao.AttachmentDao
import com.glasschat.app.data.local.db.dao.ChatDao
import com.glasschat.app.data.local.db.dao.ChatParticipantDao
import com.glasschat.app.data.local.db.dao.MessageDao
import com.glasschat.app.data.local.db.dao.ReactionDao
import com.glasschat.app.data.local.db.entity.AttachmentEntity
import com.glasschat.app.data.local.db.entity.MessageEntity
import com.glasschat.app.data.local.db.entity.ParticipantRow
import com.glasschat.app.data.local.db.entity.ReactionEntity
import com.glasschat.app.data.mapper.toDomain
import com.glasschat.app.di.IoDispatcher
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.Message
import com.glasschat.app.domain.model.MessagePreview
import com.glasschat.app.domain.model.MessageStatus
import com.glasschat.app.domain.model.SendMessageRequest
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.domain.model.StarredMessage
import com.glasschat.app.domain.repository.MediaRepository
import com.glasschat.app.domain.repository.MessageRepository
import com.glasschat.app.domain.repository.SettingsRepository
import com.glasschat.app.util.newId
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MessageRepositoryImpl @Inject constructor(
    private val messageDao: MessageDao,
    private val attachmentDao: AttachmentDao,
    private val reactionDao: ReactionDao,
    private val participantDao: ChatParticipantDao,
    private val chatDao: ChatDao,
    private val settingsRepository: SettingsRepository,
    private val mediaRepository: MediaRepository,
    @IoDispatcher private val io: CoroutineDispatcher,
) : MessageRepository {

    override fun observeMessages(chatId: String): Flow<List<Message>> = combine(
        messageDao.observeAllForChat(chatId),
        attachmentDao.observeForChat(chatId),
        reactionDao.observeForChat(chatId),
        participantDao.observeAllWithContact(),
        settingsRepository.preferences,
    ) { messages, attachments, reactions, participants, prefs ->
        AssemblyContext(messages, attachments, reactions, participants, prefs)
    }.map { context -> context.assembleVisible() }

    override fun observeMessage(messageId: String): Flow<Message?> = combine(
        messageDao.observeById(messageId),
        attachmentDao.observeForMessage(messageId),
        reactionDao.observeForMessage(messageId),
        participantDao.observeAllWithContact(),
        settingsRepository.preferences,
    ) { entity, attachments, reactions, participants, prefs ->
        entity?.let {
            AssemblyContext(
                messages = listOf(it),
                attachments = attachments,
                reactions = reactions,
                participants = participants,
                prefs = prefs,
            ).assembleOne(it, emptyMap())
        }
    }

    override fun observeStarred(): Flow<List<StarredMessage>> = combine(
        messageDao.observeStarred(),
        attachmentDao.observeAll(),
        reactionDao.observeAll(),
        participantDao.observeAllWithContact(),
        settingsRepository.preferences,
    ) { rows, attachments, reactions, participants, prefs ->
        val attachmentsByMessage = attachments.groupBy { it.messageId }
        val reactionsByMessage = reactions.groupBy { it.messageId }
        val names = participants.associate { it.contact.id to it.contact.name }
        rows.map { row ->
            StarredMessage(
                message = row.message.toDomain(
                    attachments = attachmentsByMessage[row.message.id].orEmpty().map { it.toDomain() },
                    reactions = reactionsByMessage[row.message.id].orEmpty().map { it.toDomain() },
                    senderLabel = labelFor(row.message, names, prefs),
                ),
                chatTitle = row.chatTitle.ifBlank { "Chat" },
            )
        }
    }

    override fun observeStarredForChat(chatId: String): Flow<List<Message>> = combine(
        messageDao.observeStarredForChat(chatId),
        observeMessages(chatId),
    ) { starred, all ->
        val ids = starred.map { it.id }.toSet()
        all.filter { it.id in ids }.sortedByDescending { it.createdAt }
    }

    override fun observeUnreadCount(chatId: String): Flow<Int> = messageDao.observeUnreadCount(chatId)

    override fun searchInChat(chatId: String, query: String): Flow<List<Message>> {
        if (query.isBlank()) return flowOf(emptyList())
        return combine(
            messageDao.searchInChat(chatId, query.trim()),
            observeMessages(chatId),
        ) { matches, all ->
            val ids = matches.map { it.id }.toSet()
            all.filter { it.id in ids }.sortedByDescending { it.createdAt }
        }
    }

    override suspend fun sendMessage(request: SendMessageRequest): String = withContext(io) {
        val timestamp = request.createdAt ?: System.currentTimeMillis()
        val messageId = newId()
        val entity = MessageEntity(
            id = messageId,
            chatId = request.chatId,
            senderType = request.senderType,
            senderContactId = request.senderContactId,
            text = request.text.trim(),
            createdAt = timestamp,
            editedAt = null,
            replyToMessageId = request.replyToMessageId,
            isStarred = false,
            isDeletedForEveryone = false,
            isHiddenLocally = false,
            status = if (request.senderType == SenderType.ME) {
                MessageStatus.SIMULATED_SENT
            } else {
                MessageStatus.SIMULATED_READ
            },
            isRead = request.senderType == SenderType.ME,
        )
        messageDao.insert(entity)
        if (request.attachments.isNotEmpty()) {
            attachmentDao.insertAll(
                request.attachments.map { pending ->
                    AttachmentEntity(
                        id = newId(),
                        messageId = messageId,
                        type = pending.type,
                        localUri = pending.localUri,
                        mimeType = pending.mimeType,
                        fileName = pending.fileName,
                        sizeBytes = pending.sizeBytes,
                        durationMs = pending.durationMs,
                        caption = pending.caption?.takeIf { it.isNotBlank() },
                    )
                },
            )
        }
        chatDao.touch(request.chatId, timestamp)
        messageId
    }

    override suspend fun advanceSimulatedStatus(messageId: String) {
        delay(700)
        messageDao.updateStatus(messageId, MessageStatus.SIMULATED_DELIVERED)
        delay(1100)
        messageDao.updateStatus(messageId, MessageStatus.SIMULATED_READ)
    }

    override suspend fun editMessage(messageId: String, newText: String) = withContext(io) {
        val trimmed = newText.trim()
        if (trimmed.isEmpty()) return@withContext
        messageDao.updateText(messageId, trimmed, System.currentTimeMillis())
        messageDao.getById(messageId)?.let { chatDao.touch(it.chatId, System.currentTimeMillis()) }
        Unit
    }

    override suspend fun deleteForMe(messageId: String) = withContext(io) {
        messageDao.hideLocally(messageId)
        Unit
    }

    override suspend fun deleteForEveryone(messageId: String) = withContext(io) {
        val attachments = attachmentDao.getForMessage(messageId)
        attachments.forEach { attachment -> mediaRepository.deleteMediaAt(attachment.localUri) }
        attachmentDao.deleteForMessage(messageId)
        reactionDao.deleteForMessage(messageId)
        messageDao.deleteForEveryone(messageId)
        Unit
    }

    override suspend fun setStarred(messageId: String, starred: Boolean) = withContext(io) {
        messageDao.setStarred(messageId, starred)
    }

    override suspend fun toggleReaction(messageId: String, senderType: SenderType, emoji: String) =
        withContext(io) {
            val existing = reactionDao.getForMessage(messageId)
                .firstOrNull { it.senderType == senderType && it.emoji == emoji }
            if (existing != null) {
                reactionDao.remove(messageId, senderType, emoji)
            } else {
                reactionDao.upsert(
                    ReactionEntity(
                        id = newId(),
                        messageId = messageId,
                        senderType = senderType,
                        emoji = emoji,
                        createdAt = System.currentTimeMillis(),
                    ),
                )
            }
            Unit
        }

    override suspend fun clearChat(chatId: String) = withContext(io) {
        messageDao.getAllForChat(chatId).forEach { message ->
            attachmentDao.getForMessage(message.id).forEach { attachment ->
                mediaRepository.deleteMediaAt(attachment.localUri)
            }
            attachmentDao.deleteForMessage(message.id)
            reactionDao.deleteForMessage(message.id)
        }
        messageDao.deleteForChat(chatId)
        Unit
    }

    // -----------------------------------------------------------------------
    // Assembly helpers
    // -----------------------------------------------------------------------

    private data class AssemblyContext(
        val messages: List<MessageEntity>,
        val attachments: List<AttachmentEntity>,
        val reactions: List<ReactionEntity>,
        val participants: List<ParticipantRow>,
        val prefs: AppPreferences,
    ) {
        val attachmentsByMessage: Map<String, List<AttachmentEntity>> = attachments.groupBy { it.messageId }
        val reactionsByMessage: Map<String, List<ReactionEntity>> = reactions.groupBy { it.messageId }
        val names: Map<String, String> = participants.associate { it.contact.id to it.contact.name }
        val byId: Map<String, MessageEntity> = messages.associateBy { it.id }

        fun assembleVisible(): List<Message> = messages
            .filterNot { it.isHiddenLocally }
            .sortedWith(compareBy({ it.createdAt }, { it.id }))
            .map { entity ->
                val reply = entity.replyToMessageId?.let { byId[it] }
                assembleOne(entity, if (reply == null) emptyMap() else mapOf(entity.id to reply))
            }

        fun assembleOne(
            entity: MessageEntity,
            replySourceOverride: Map<String, MessageEntity>,
        ): Message {
            val replySource = entity.replyToMessageId?.let { replySourceOverride[entity.id] ?: byId[it] }
            val replyPreview = replySource?.let { original ->
                MessagePreview(
                    messageId = original.id,
                    senderLabel = labelFor(original, names, prefs),
                    text = bodyPreview(original, attachmentsByMessage[original.id].orEmpty()),
                )
            }
            return entity.toDomain(
                attachments = attachmentsByMessage[entity.id].orEmpty().map { it.toDomain() },
                reactions = reactionsByMessage[entity.id].orEmpty()
                    .sortedBy { it.createdAt }
                    .map { it.toDomain() },
                senderLabel = labelFor(entity, names, prefs),
                replyPreview = replyPreview,
            )
        }
    }

    private companion object {
        fun labelFor(
            entity: MessageEntity,
            names: Map<String, String>,
            prefs: AppPreferences,
        ): String = if (entity.senderType == SenderType.ME) {
            prefs.displayName.ifBlank { "Me" }
        } else {
            entity.senderContactId?.let { names[it] } ?: "Contact"
        }

        fun bodyPreview(entity: MessageEntity, attachments: List<AttachmentEntity>): String {
            if (entity.isDeletedForEveryone) return MessageEntity.DELETED_PLACEHOLDER
            if (entity.text.isNotBlank()) return entity.text
            return when (attachments.firstOrNull()?.type) {
                AttachmentType.IMAGE -> "Photo"
                AttachmentType.VIDEO -> "Video"
                AttachmentType.AUDIO -> "Voice note"
                AttachmentType.DOCUMENT -> "Document"
                null -> "Message"
            }
        }
    }
}
