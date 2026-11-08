package com.glasschat.app.domain.repository

import com.glasschat.app.domain.model.Message
import com.glasschat.app.domain.model.SendMessageRequest
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.domain.model.StarredMessage
import kotlinx.coroutines.flow.Flow

interface MessageRepository {
    /** Visible messages for a chat, oldest first, with attachments, reactions and reply quotes. */
    fun observeMessages(chatId: String): Flow<List<Message>>
    fun observeMessage(messageId: String): Flow<Message?>
    fun observeStarred(): Flow<List<StarredMessage>>
    fun observeStarredForChat(chatId: String): Flow<List<Message>>
    fun observeUnreadCount(chatId: String): Flow<Int>
    fun searchInChat(chatId: String, query: String): Flow<List<Message>>

    suspend fun sendMessage(request: SendMessageRequest): String

    /**
     * Walks a sent message through the simulated delivery states. Purely cosmetic — the
     * UI always labels these ticks as simulated.
     */
    suspend fun advanceSimulatedStatus(messageId: String)
    suspend fun editMessage(messageId: String, newText: String)
    suspend fun deleteForMe(messageId: String)
    suspend fun deleteForEveryone(messageId: String)
    suspend fun setStarred(messageId: String, starred: Boolean)
    suspend fun toggleReaction(messageId: String, senderType: SenderType, emoji: String)
    suspend fun clearChat(chatId: String)
}
