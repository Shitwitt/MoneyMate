package com.glasschat.app.domain.model

/** An attachment joined with the context needed by the Gallery tab and media viewer. */
data class MediaItem(
    val attachment: Attachment,
    val messageId: String,
    val chatId: String,
    val chatTitle: String,
    val senderLabel: String,
    val createdAt: Long,
    val isFromMe: Boolean,
)

/** A starred message plus the chat title it belongs to (Contacts > Starred). */
data class StarredMessage(
    val message: Message,
    val chatTitle: String,
)

/** All media for a single conversation, used to group the Gallery tab. */
data class MediaGroup(
    val chatId: String,
    val chatTitle: String,
    val items: List<MediaItem>,
)
