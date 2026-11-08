package com.glasschat.app.data.local.db

import androidx.room.TypeConverter
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.MessageStatus
import com.glasschat.app.domain.model.ParticipantRole
import com.glasschat.app.domain.model.SenderType

/**
 * Enums are stored by name (readable in `sqlite3` dumps, stable across refactors) and
 * decoded defensively so a corrupted/unknown value never crashes a query.
 */
class Converters {

    @TypeConverter
    fun fromChatType(value: ChatType): String = value.name

    @TypeConverter
    fun toChatType(value: String): ChatType = enumValueOrDefault(value, ChatType.ONE_TO_ONE)

    @TypeConverter
    fun fromSenderType(value: SenderType): String = value.name

    @TypeConverter
    fun toSenderType(value: String): SenderType = enumValueOrDefault(value, SenderType.ME)

    @TypeConverter
    fun fromMessageStatus(value: MessageStatus): String = value.name

    @TypeConverter
    fun toMessageStatus(value: String): MessageStatus =
        enumValueOrDefault(value, MessageStatus.SIMULATED_SENT)

    @TypeConverter
    fun fromAttachmentType(value: AttachmentType): String = value.name

    @TypeConverter
    fun toAttachmentType(value: String): AttachmentType =
        enumValueOrDefault(value, AttachmentType.DOCUMENT)

    @TypeConverter
    fun fromParticipantRole(value: ParticipantRole): String = value.name

    @TypeConverter
    fun toParticipantRole(value: String): ParticipantRole =
        enumValueOrDefault(value, ParticipantRole.MEMBER)

    private inline fun <reified T : Enum<T>> enumValueOrDefault(name: String, fallback: T): T =
        enumValues<T>().firstOrNull { it.name == name } ?: fallback
}
