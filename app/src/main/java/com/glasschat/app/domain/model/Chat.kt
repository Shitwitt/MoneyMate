package com.glasschat.app.domain.model

enum class ChatType { ONE_TO_ONE, GROUP }

enum class ParticipantRole { OWNER, MEMBER }

/** A participant as presented to the UI (contact identity joined onto membership). */
data class Participant(
    val contactId: String,
    val name: String,
    val avatarUri: String?,
    val accentColor: Long,
    val role: ParticipantRole,
)

/**
 * A locally stored conversation.
 *
 * [wallpaper] and [accentColor] are per-chat overrides; `null` means "inherit the app
 * theme". [draft] persists the composer text so leaving a chat never loses a half-written
 * message.
 */
data class Chat(
    val id: String,
    val title: String,
    val type: ChatType,
    val wallpaper: String?,
    val accentColor: Long?,
    val bubbleColorMe: Long?,
    val bubbleColorOther: Long?,
    val isPinned: Boolean,
    val isArchived: Boolean,
    val isMuted: Boolean,
    val createdAt: Long,
    val updatedAt: Long,
    val draft: String,
)

/** Row model for the chat list. */
data class ChatSummary(
    val chat: Chat,
    val participants: List<Participant>,
    val lastMessagePreview: String,
    val lastMessageAt: Long?,
    val unreadCount: Int,
    val lastAttachmentType: AttachmentType? = null,
    val lastAttachmentUri: String? = null,
) {
    val primaryContact: Participant? get() = participants.firstOrNull()
    val isGroup: Boolean get() = chat.type == ChatType.GROUP
    val displayTitle: String get() = chat.title.ifBlank { primaryContact?.name ?: "Untitled chat" }
    val avatarSource: Participant? get() = primaryContact
}

/** Seed content used when creating a chat from a template. */
data class ChatTemplate(
    val id: String,
    val title: String,
    val description: String,
    val seeds: List<SeedMessage>,
)

data class SeedMessage(
    val fromMe: Boolean,
    val text: String,
    /** Minutes offset before "now" so template chats look naturally spaced. */
    val minutesAgo: Long,
)
