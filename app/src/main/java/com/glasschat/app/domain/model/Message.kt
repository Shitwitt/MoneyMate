package com.glasschat.app.domain.model

enum class SenderType { ME, CONTACT }

/**
 * Simulated delivery states. These are labelled "Simulated" everywhere they surface so the
 * app never pretends a message was actually transmitted.
 */
enum class MessageStatus { SIMULATED_SENT, SIMULATED_DELIVERED, SIMULATED_READ }

enum class AttachmentType { IMAGE, VIDEO, AUDIO, DOCUMENT }

data class Attachment(
    val id: String,
    val messageId: String,
    val type: AttachmentType,
    val localUri: String,
    val mimeType: String?,
    val fileName: String?,
    val sizeBytes: Long,
    val durationMs: Long?,
    val caption: String?,
) {
    val isMedia: Boolean get() = type == AttachmentType.IMAGE || type == AttachmentType.VIDEO
}

/** Minimal snapshot of the message a reply points at. */
data class MessagePreview(
    val messageId: String,
    val senderLabel: String,
    val text: String,
)

data class Reaction(
    val id: String,
    val messageId: String,
    val senderType: SenderType,
    val emoji: String,
    val createdAt: Long,
)

data class Message(
    val id: String,
    val chatId: String,
    val senderType: SenderType,
    val senderContactId: String?,
    val senderLabel: String,
    val text: String,
    val createdAt: Long,
    val editedAt: Long?,
    val replyToMessageId: String?,
    val replyPreview: MessagePreview?,
    val isStarred: Boolean,
    val isDeletedForEveryone: Boolean,
    val status: MessageStatus,
    val isRead: Boolean,
    val attachments: List<Attachment>,
    val reactions: List<Reaction>,
) {
    val isFromMe: Boolean get() = senderType == SenderType.ME
    val hasBody: Boolean get() = text.isNotBlank()
    val isDeleted: Boolean get() = isDeletedForEveryone
    val hasContent: Boolean get() = text.isNotBlank() || attachments.isNotEmpty()
}
