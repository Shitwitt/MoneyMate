package com.glasschat.app.data.mapper

import com.glasschat.app.data.local.db.entity.AttachmentEntity
import com.glasschat.app.data.local.db.entity.ChatEntity
import com.glasschat.app.data.local.db.entity.ContactEntity
import com.glasschat.app.data.local.db.entity.MessageEntity
import com.glasschat.app.data.local.db.entity.ParticipantRow
import com.glasschat.app.data.local.db.entity.ReactionEntity
import com.glasschat.app.data.local.db.entity.ChatSummaryRow
import com.glasschat.app.domain.model.Attachment
import com.glasschat.app.domain.model.Chat
import com.glasschat.app.domain.model.ChatSummary
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.Contact
import com.glasschat.app.domain.model.MessageStatus
import com.glasschat.app.domain.model.Participant
import com.glasschat.app.domain.model.Reaction
import com.glasschat.app.domain.model.SenderType

fun ContactEntity.toDomain(): Contact = Contact(
    id = id,
    name = name,
    avatarUri = avatarUri,
    accentColor = accentColor,
    bio = bio,
    phoneLabel = phoneLabel,
    notes = notes,
    isFavorite = isFavorite,
    isBlocked = isBlocked,
    createdAt = createdAt,
)

fun Contact.toEntity(): ContactEntity = ContactEntity(
    id = id,
    name = name,
    avatarUri = avatarUri,
    accentColor = accentColor,
    bio = bio,
    phoneLabel = phoneLabel,
    notes = notes,
    isFavorite = isFavorite,
    isBlocked = isBlocked,
    createdAt = createdAt,
)

fun ChatEntity.toDomain(): Chat = Chat(
    id = id,
    title = title,
    type = type,
    wallpaper = wallpaper,
    accentColor = accentColor,
    bubbleColorMe = bubbleColorMe,
    bubbleColorOther = bubbleColorOther,
    isPinned = isPinned,
    isArchived = isArchived,
    isMuted = isMuted,
    createdAt = createdAt,
    updatedAt = updatedAt,
    draft = draft,
)

fun Chat.toEntity(): ChatEntity = ChatEntity(
    id = id,
    title = title,
    type = type,
    wallpaper = wallpaper,
    accentColor = accentColor,
    bubbleColorMe = bubbleColorMe,
    bubbleColorOther = bubbleColorOther,
    isPinned = isPinned,
    isArchived = isArchived,
    isMuted = isMuted,
    createdAt = createdAt,
    updatedAt = updatedAt,
    draft = draft,
)

fun ParticipantRow.toParticipant(): Participant = Participant(
    contactId = contact.id,
    name = contact.name,
    avatarUri = contact.avatarUri,
    accentColor = contact.accentColor,
    role = role,
)

fun AttachmentEntity.toDomain(): Attachment = Attachment(
    id = id,
    messageId = messageId,
    type = type,
    localUri = localUri,
    mimeType = mimeType,
    fileName = fileName,
    sizeBytes = sizeBytes,
    durationMs = durationMs,
    caption = caption,
)

fun ReactionEntity.toDomain(): Reaction = Reaction(
    id = id,
    messageId = messageId,
    senderType = senderType,
    emoji = emoji,
    createdAt = createdAt,
)

fun MessageEntity.toDomain(
    attachments: List<Attachment> = emptyList(),
    reactions: List<Reaction> = emptyList(),
    senderLabel: String = "",
    replyPreview: com.glasschat.app.domain.model.MessagePreview? = null,
): com.glasschat.app.domain.model.Message = com.glasschat.app.domain.model.Message(
    id = id,
    chatId = chatId,
    senderType = senderType,
    senderContactId = senderContactId,
    senderLabel = senderLabel,
    text = text,
    createdAt = createdAt,
    editedAt = editedAt,
    replyToMessageId = replyToMessageId,
    replyPreview = replyPreview,
    isStarred = isStarred,
    isDeletedForEveryone = isDeletedForEveryone,
    status = status,
    isRead = isRead,
    attachments = attachments,
    reactions = reactions,
)

/** Chat-list preview copy, e.g. `You: See you at noon` or `Voice note`. */
fun ChatSummaryRow.toDomain(participants: List<Participant>): ChatSummary = ChatSummary(
    chat = chat.toDomain(),
    participants = participants,
    lastMessagePreview = buildPreview(),
    lastMessageAt = lastMessageAt,
    unreadCount = unreadCount,
    lastAttachmentType = lastAttachmentType,
    lastAttachmentUri = lastAttachmentUri,
)

private fun ChatSummaryRow.buildPreview(): String {
    if (lastMessageAt == null) return "No messages yet — write the first line"
    val attachmentLabel = when (lastAttachmentType) {
        AttachmentType.IMAGE -> "Photo"
        AttachmentType.VIDEO -> "Video"
        AttachmentType.AUDIO -> "Voice note"
        AttachmentType.DOCUMENT -> "Document"
        null -> null
    }
    val body = lastMessageText?.takeIf { it.isNotBlank() } ?: attachmentLabel ?: "Message"
    return if (lastSenderType == SenderType.ME) "You: $body" else body
}

fun guessChatType(participantCount: Int): ChatType =
    if (participantCount > 1) ChatType.GROUP else ChatType.ONE_TO_ONE

fun defaultStatusFor(sender: SenderType): MessageStatus =
    if (sender == SenderType.ME) MessageStatus.SIMULATED_SENT else MessageStatus.SIMULATED_READ
