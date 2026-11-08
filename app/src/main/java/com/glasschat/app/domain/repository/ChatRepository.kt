package com.glasschat.app.domain.repository

import com.glasschat.app.domain.model.Chat
import com.glasschat.app.domain.model.ChatDetail
import com.glasschat.app.domain.model.ChatSummary
import com.glasschat.app.domain.model.CreateChatRequest
import kotlinx.coroutines.flow.Flow

interface ChatRepository {
    fun observeChatSummaries(archived: Boolean = false): Flow<List<ChatSummary>>
    fun observeChat(chatId: String): Flow<Chat?>
    fun observeChatDetail(chatId: String): Flow<ChatDetail?>
    suspend fun getChatDetailOnce(chatId: String): ChatDetail?
    fun observeArchivedCount(): Flow<Int>

    suspend fun createChat(request: CreateChatRequest): String
    suspend fun renameChat(chatId: String, title: String)
    suspend fun setPinned(chatId: String, pinned: Boolean)
    suspend fun setArchived(chatId: String, archived: Boolean)
    suspend fun setMuted(chatId: String, muted: Boolean)
    suspend fun updateAppearance(
        chatId: String,
        wallpaper: String?,
        accentColor: Long?,
        bubbleColorMe: Long?,
        bubbleColorOther: Long?,
    )

    suspend fun saveDraft(chatId: String, draft: String)
    suspend fun addParticipants(chatId: String, contactIds: List<String>)
    suspend fun removeParticipant(chatId: String, contactId: String)
    suspend fun markRead(chatId: String)
    suspend fun markUnread(chatId: String)
    /** Soft delete (undoable from the chat list). */
    suspend fun setDeleted(chatId: String, deleted: Boolean)

    /** Permanent delete: removes the chat, its messages and all attachment rows. */
    suspend fun deleteChat(chatId: String)
}
