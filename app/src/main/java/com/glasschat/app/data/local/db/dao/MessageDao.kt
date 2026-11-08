package com.glasschat.app.data.local.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.glasschat.app.data.local.db.entity.MessageEntity
import com.glasschat.app.data.local.db.entity.StarredMessageRow
import com.glasschat.app.domain.model.MessageStatus
import kotlinx.coroutines.flow.Flow

@Dao
interface MessageDao {

    /** Everything, including locally-hidden messages, so reply quotes can still resolve. */
    @Query("SELECT * FROM messages WHERE chatId = :chatId ORDER BY createdAt ASC, id ASC")
    fun observeAllForChat(chatId: String): Flow<List<MessageEntity>>

    @Query(
        """
        SELECT * FROM messages
        WHERE chatId = :chatId AND isHiddenLocally = 0
        ORDER BY createdAt ASC, id ASC
        """
    )
    fun observeVisibleForChat(chatId: String): Flow<List<MessageEntity>>

    @Query("SELECT * FROM messages WHERE chatId = :chatId ORDER BY createdAt ASC, id ASC")
    suspend fun getAllForChat(chatId: String): List<MessageEntity>

    @Query("SELECT * FROM messages WHERE id = :id")
    suspend fun getById(id: String): MessageEntity?

    @Query("SELECT * FROM messages WHERE id = :id")
    fun observeById(id: String): Flow<MessageEntity?>

    @Query("SELECT COUNT(*) FROM messages WHERE chatId = :chatId")
    suspend fun countForChat(chatId: String): Int

    @Query(
        """
        SELECT m.*, c.title AS chatTitle
        FROM messages m
        INNER JOIN chats c ON c.id = m.chatId
        WHERE m.isStarred = 1 AND m.isHiddenLocally = 0 AND m.isDeletedForEveryone = 0
        ORDER BY m.createdAt DESC
        """
    )
    fun observeStarred(): Flow<List<StarredMessageRow>>

    @Query(
        """
        SELECT * FROM messages
        WHERE chatId = :chatId AND isHiddenLocally = 0 AND isStarred = 1
            AND isDeletedForEveryone = 0
        ORDER BY createdAt DESC
        """
    )
    fun observeStarredForChat(chatId: String): Flow<List<MessageEntity>>

    @Query(
        """
        SELECT COUNT(*) FROM messages
        WHERE chatId = :chatId AND senderType = 'CONTACT' AND isRead = 0 AND isHiddenLocally = 0
        """
    )
    fun observeUnreadCount(chatId: String): Flow<Int>

    @Query(
        """
        SELECT * FROM messages
        WHERE chatId = :chatId AND isHiddenLocally = 0 AND text LIKE '%' || :query || '%'
        ORDER BY createdAt DESC
        """
    )
    fun searchInChat(chatId: String, query: String): Flow<List<MessageEntity>>

    @Query("SELECT * FROM messages ORDER BY createdAt ASC")
    suspend fun getAll(): List<MessageEntity>

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(message: MessageEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(messages: List<MessageEntity>)

    @Query("UPDATE messages SET text = :text, editedAt = :editedAt WHERE id = :id")
    suspend fun updateText(id: String, text: String, editedAt: Long)

    @Query("UPDATE messages SET status = :status WHERE id = :id")
    suspend fun updateStatus(id: String, status: MessageStatus)

    @Query("UPDATE messages SET isStarred = :starred WHERE id = :id")
    suspend fun setStarred(id: String, starred: Boolean)

    @Query("UPDATE messages SET isRead = 1 WHERE chatId = :chatId AND senderType = 'CONTACT'")
    suspend fun markIncomingRead(chatId: String)

    @Query(
        """
        UPDATE messages SET isRead = 0 WHERE id = (
            SELECT id FROM messages
            WHERE chatId = :chatId AND senderType = 'CONTACT' AND isHiddenLocally = 0
            ORDER BY createdAt DESC LIMIT 1
        )
        """
    )
    suspend fun markLastIncomingUnread(chatId: String)

    @Query(
        """
        UPDATE messages SET isDeletedForEveryone = 1, text = '', replyToMessageId = NULL,
            isStarred = 0
        WHERE id = :messageId
        """
    )
    suspend fun deleteForEveryone(messageId: String)

    @Query("UPDATE messages SET isHiddenLocally = 1 WHERE id = :messageId")
    suspend fun hideLocally(messageId: String)

    @Query("DELETE FROM messages WHERE chatId = :chatId")
    suspend fun deleteForChat(chatId: String)

    @Query("DELETE FROM messages WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM messages")
    suspend fun deleteAll()
}
