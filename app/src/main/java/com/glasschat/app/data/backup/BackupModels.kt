package com.glasschat.app.data.backup

import kotlinx.serialization.Serializable

/**
 * Portable snapshot of the whole app. Enums are stored as strings so a future rename of a
 * Kotlin enum cannot silently corrupt an old backup.
 */
@Serializable
data class BackupBundle(
    val format: String = FORMAT,
    val version: Int = VERSION,
    val exportedAt: Long,
    val appVersion: String,
    val preferences: PreferencesDto? = null,
    val contacts: List<ContactDto> = emptyList(),
    val chats: List<ChatDto> = emptyList(),
    val participants: List<ParticipantDto> = emptyList(),
    val messages: List<MessageDto> = emptyList(),
    val attachments: List<AttachmentDto> = emptyList(),
    val reactions: List<ReactionDto> = emptyList(),
    val settings: List<SettingDto> = emptyList(),
) {
    companion object {
        const val FORMAT = "glasschat-backup"
        const val VERSION = 1
        const val MANIFEST_ENTRY = "backup.json"
        const val MEDIA_PREFIX = "media/"
    }
}

@Serializable
data class ContactDto(
    val id: String,
    val name: String,
    val avatarUri: String? = null,
    val accentColor: Long,
    val bio: String = "",
    val phoneLabel: String = "",
    val notes: String = "",
    val isFavorite: Boolean = false,
    val isBlocked: Boolean = false,
    val createdAt: Long = 0L,
)

@Serializable
data class ChatDto(
    val id: String,
    val title: String,
    val type: String,
    val wallpaper: String? = null,
    val accentColor: Long? = null,
    val bubbleColorMe: Long? = null,
    val bubbleColorOther: Long? = null,
    val isPinned: Boolean = false,
    val isArchived: Boolean = false,
    val isMuted: Boolean = false,
    val isDeleted: Boolean = false,
    val createdAt: Long = 0L,
    val updatedAt: Long = 0L,
    val draft: String = "",
)

@Serializable
data class ParticipantDto(
    val chatId: String,
    val contactId: String,
    val role: String = "MEMBER",
    val position: Int = 0,
)

@Serializable
data class MessageDto(
    val id: String,
    val chatId: String,
    val senderType: String,
    val senderContactId: String? = null,
    val text: String = "",
    val createdAt: Long,
    val editedAt: Long? = null,
    val replyToMessageId: String? = null,
    val isStarred: Boolean = false,
    val isDeletedForEveryone: Boolean = false,
    val isHiddenLocally: Boolean = false,
    val status: String = "SIMULATED_SENT",
    val isRead: Boolean = false,
)

@Serializable
data class AttachmentDto(
    val id: String,
    val messageId: String,
    val type: String,
    val mimeType: String? = null,
    val fileName: String? = null,
    val sizeBytes: Long = 0L,
    val durationMs: Long? = null,
    val caption: String? = null,
    /** Zip entry holding the bytes, e.g. `media/<id>.jpg`. */
    val entry: String? = null,
)

@Serializable
data class ReactionDto(
    val id: String,
    val messageId: String,
    val senderType: String,
    val emoji: String,
    val createdAt: Long = 0L,
)

@Serializable
data class SettingDto(
    val key: String,
    val value: String,
)

@Serializable
data class PreferencesDto(
    val onboardingComplete: Boolean = true,
    val displayName: String = "Me",
    val about: String = "",
    val avatarUri: String? = null,
    val profileAccent: Long? = null,
    val themeMode: String = "SYSTEM",
    val accent: Long? = null,
    val bubbleColorMe: Long? = null,
    val bubbleColorOther: Long? = null,
    val wallpaper: String = "aurora",
    val fontScale: Float = 1f,
    val reduceTransparency: Boolean = false,
    val reduceMotion: Boolean = false,
    val enterToSend: Boolean = false,
    val showTimestamps: Boolean = true,
    val showSimulatedStatus: Boolean = true,
    val hapticsEnabled: Boolean = true,
    val appLockEnabled: Boolean = false,
    val hidePreviewsInRecents: Boolean = false,
    val blurMediaInList: Boolean = false,
)
