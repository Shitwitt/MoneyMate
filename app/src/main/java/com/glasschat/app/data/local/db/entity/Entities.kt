package com.glasschat.app.data.local.db.entity

import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.MessageStatus
import com.glasschat.app.domain.model.ParticipantRole
import com.glasschat.app.domain.model.SenderType

@Entity(tableName = "contacts", indices = [Index("name"), Index("isFavorite")])
data class ContactEntity(
    @PrimaryKey val id: String,
    val name: String,
    val avatarUri: String? = null,
    val accentColor: Long,
    val bio: String = "",
    val phoneLabel: String = "",
    val notes: String = "",
    val isFavorite: Boolean = false,
    val isBlocked: Boolean = false,
    val createdAt: Long,
)

@Entity(
    tableName = "chats",
    indices = [Index("isArchived"), Index("isPinned"), Index("updatedAt"), Index("isDeleted")],
)
data class ChatEntity(
    @PrimaryKey val id: String,
    val title: String,
    val type: ChatType,
    val wallpaper: String? = null,
    val accentColor: Long? = null,
    val bubbleColorMe: Long? = null,
    val bubbleColorOther: Long? = null,
    val isPinned: Boolean = false,
    val isArchived: Boolean = false,
    val isMuted: Boolean = false,
    /** Soft delete powers the "Undo" snackbar on the chat list. Purged on permanent delete. */
    val isDeleted: Boolean = false,
    val createdAt: Long,
    val updatedAt: Long,
    val draft: String = "",
)

@Entity(
    tableName = "chat_participants",
    primaryKeys = ["chatId", "contactId"],
    foreignKeys = [
        ForeignKey(
            entity = ChatEntity::class,
            parentColumns = ["id"],
            childColumns = ["chatId"],
            onDelete = ForeignKey.CASCADE,
        ),
        ForeignKey(
            entity = ContactEntity::class,
            parentColumns = ["id"],
            childColumns = ["contactId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("chatId"), Index("contactId")],
)
data class ChatParticipantEntity(
    val chatId: String,
    val contactId: String,
    val role: ParticipantRole = ParticipantRole.MEMBER,
    /** Stable ordering so "the other participant" never jumps around. */
    val position: Int = 0,
)

@Entity(
    tableName = "messages",
    foreignKeys = [
        ForeignKey(
            entity = ChatEntity::class,
            parentColumns = ["id"],
            childColumns = ["chatId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["chatId", "createdAt"]), Index("isStarred"), Index("chatId", "isHiddenLocally")],
)
data class MessageEntity(
    @PrimaryKey val id: String,
    val chatId: String,
    val senderType: SenderType,
    val senderContactId: String? = null,
    val text: String = "",
    val createdAt: Long,
    val editedAt: Long? = null,
    val replyToMessageId: String? = null,
    val isStarred: Boolean = false,
    /** "Delete for everyone": the bubble stays as a tombstone inside the simulation. */
    val isDeletedForEveryone: Boolean = false,
    /** "Delete for me": hidden from this device's view only. */
    val isHiddenLocally: Boolean = false,
    val status: MessageStatus = MessageStatus.SIMULATED_SENT,
    val isRead: Boolean = false,
) {
    companion object {
        const val DELETED_PLACEHOLDER = "This message was deleted"
    }
}

@Entity(
    tableName = "attachments",
    foreignKeys = [
        ForeignKey(
            entity = MessageEntity::class,
            parentColumns = ["id"],
            childColumns = ["messageId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("messageId")],
)
data class AttachmentEntity(
    @PrimaryKey val id: String,
    val messageId: String,
    val type: AttachmentType,
    /** Absolute path inside app-private storage, stored as a `file://` URI string. */
    val localUri: String,
    val mimeType: String? = null,
    val fileName: String? = null,
    val sizeBytes: Long = 0L,
    val durationMs: Long? = null,
    val caption: String? = null,
)

@Entity(
    tableName = "reactions",
    foreignKeys = [
        ForeignKey(
            entity = MessageEntity::class,
            parentColumns = ["id"],
            childColumns = ["messageId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["messageId", "senderType", "emoji"], unique = true)],
)
data class ReactionEntity(
    @PrimaryKey val id: String,
    val messageId: String,
    val senderType: SenderType,
    val emoji: String,
    val createdAt: Long,
)

/** Required key/value table (also used for lightweight counters and migration flags). */
@Entity(tableName = "app_settings")
data class AppSettingEntity(
    @PrimaryKey val key: String,
    val value: String,
)

// ---------------------------------------------------------------------------
// Query projections
// ---------------------------------------------------------------------------

data class ChatSummaryRow(
    @Embedded val chat: ChatEntity,
    val lastMessageText: String?,
    val lastMessageAt: Long?,
    val lastAttachmentType: AttachmentType?,
    val lastAttachmentUri: String?,
    val lastSenderType: SenderType?,
    val unreadCount: Int,
)

data class ParticipantRow(
    val chatId: String,
    val role: ParticipantRole,
    val position: Int,
    @Embedded val contact: ContactEntity,
)

data class MediaRow(
    @Embedded val attachment: AttachmentEntity,
    val chatId: String,
    val chatTitle: String,
    val messageCreatedAt: Long,
    val senderType: SenderType,
    val senderContactId: String?,
)

data class StarredMessageRow(
    @Embedded val message: MessageEntity,
    val chatTitle: String,
)
