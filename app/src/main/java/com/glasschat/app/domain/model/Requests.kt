package com.glasschat.app.domain.model

/** Fields captured by the contact editor. */
data class ContactDraft(
    val name: String,
    val avatarUri: String? = null,
    val accentColor: Long,
    val bio: String = "",
    val phoneLabel: String = "",
    val notes: String = "",
)

/**
 * A local file that has already been copied into app-private storage and is waiting to be
 * attached to a message.
 */
data class PendingAttachment(
    val type: AttachmentType,
    val localUri: String,
    val mimeType: String?,
    val fileName: String?,
    val sizeBytes: Long,
    val durationMs: Long? = null,
    val caption: String? = null,
)

data class SendMessageRequest(
    val chatId: String,
    val senderType: SenderType,
    val senderContactId: String?,
    val text: String,
    val replyToMessageId: String? = null,
    val attachments: List<PendingAttachment> = emptyList(),
    /** Explicit timestamp used by template seeding and backup restore; `null` means now. */
    val createdAt: Long? = null,
)

data class CreateChatRequest(
    val title: String,
    val type: ChatType,
    val participantContactIds: List<String>,
    val wallpaper: String? = null,
    val accentColor: Long? = null,
    val templateId: String? = null,
)

/** Chat + its people, resolved for the chat screen header and settings. */
data class ChatDetail(
    val chat: Chat,
    val participants: List<Participant>,
    val primaryContact: Contact?,
)

/** Camera target handed back to the caller of the system camera intent. */
data class PendingCapture(
    val filePath: String,
    val contentUri: String,
)

data class BackupResult(
    val chats: Int,
    val contacts: Int,
    val messages: Int,
    val mediaFiles: Int,
    val bytesWritten: Long,
)
