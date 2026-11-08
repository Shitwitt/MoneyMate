package com.glasschat.app.data.local.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.glasschat.app.data.local.db.entity.ChatEntity
import com.glasschat.app.data.local.db.entity.ChatSummaryRow
import kotlinx.coroutines.flow.Flow

@Dao
interface ChatDao {

    /**
     * One query powers the whole chat list: last message text/timestamp/kind and the
     * simulated unread counter are all derived so nothing can drift out of sync.
     */
    @Query(
        """
        SELECT c.*,
            (SELECT m.text FROM messages m
                WHERE m.chatId = c.id AND m.isHiddenLocally = 0 AND m.isDeletedForEveryone = 0
                ORDER BY m.createdAt DESC, m.id DESC LIMIT 1) AS lastMessageText,
            (SELECT m.createdAt FROM messages m
                WHERE m.chatId = c.id AND m.isHiddenLocally = 0
                ORDER BY m.createdAt DESC, m.id DESC LIMIT 1) AS lastMessageAt,
            (SELECT a.type FROM attachments a
                INNER JOIN messages m ON m.id = a.messageId
                WHERE m.chatId = c.id AND m.isHiddenLocally = 0
                ORDER BY m.createdAt DESC, m.id DESC LIMIT 1) AS lastAttachmentType,
            (SELECT a.localUri FROM attachments a
                INNER JOIN messages m ON m.id = a.messageId
                WHERE m.chatId = c.id AND m.isHiddenLocally = 0
                ORDER BY m.createdAt DESC, m.id DESC LIMIT 1) AS lastAttachmentUri,
            (SELECT m.senderType FROM messages m
                WHERE m.chatId = c.id AND m.isHiddenLocally = 0
                ORDER BY m.createdAt DESC, m.id DESC LIMIT 1) AS lastSenderType,
            (SELECT COUNT(*) FROM messages m
                WHERE m.chatId = c.id AND m.senderType = 'CONTACT' AND m.isRead = 0
                    AND m.isHiddenLocally = 0) AS unreadCount
        FROM chats c
        WHERE c.isArchived = :archived AND c.isDeleted = 0
        ORDER BY c.isPinned DESC, c.updatedAt DESC
        """
    )
    fun observeSummaries(archived: Boolean): Flow<List<ChatSummaryRow>>

    @Query("SELECT * FROM chats ORDER BY updatedAt DESC")
    fun observeAll(): Flow<List<ChatEntity>>

    @Query("SELECT * FROM chats WHERE id = :id")
    fun observeById(id: String): Flow<ChatEntity?>

    @Query("SELECT * FROM chats WHERE id = :id")
    suspend fun getById(id: String): ChatEntity?

    @Query("SELECT COUNT(*) FROM chats WHERE isArchived = 1 AND isDeleted = 0")
    fun observeArchivedCount(): Flow<Int>

    @Query("SELECT * FROM chats ORDER BY updatedAt DESC")
    suspend fun getAll(): List<ChatEntity>

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(chat: ChatEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(chats: List<ChatEntity>)

    @Update
    suspend fun update(chat: ChatEntity)

    @Query("UPDATE chats SET isPinned = :pinned WHERE id = :id")
    suspend fun setPinned(id: String, pinned: Boolean)

    @Query("UPDATE chats SET isArchived = :archived WHERE id = :id")
    suspend fun setArchived(id: String, archived: Boolean)

    @Query("UPDATE chats SET isDeleted = :deleted WHERE id = :id")
    suspend fun setDeleted(id: String, deleted: Boolean)

    @Query("DELETE FROM chats WHERE isDeleted = 1")
    suspend fun purgeDeleted()

    @Query("UPDATE chats SET isMuted = :muted WHERE id = :id")
    suspend fun setMuted(id: String, muted: Boolean)

    @Query("UPDATE chats SET title = :title WHERE id = :id")
    suspend fun updateTitle(id: String, title: String)

    @Query("UPDATE chats SET draft = :draft WHERE id = :id")
    suspend fun updateDraft(id: String, draft: String)

    @Query(
        """
        UPDATE chats SET wallpaper = :wallpaper, accentColor = :accentColor,
            bubbleColorMe = :bubbleColorMe, bubbleColorOther = :bubbleColorOther
        WHERE id = :id
        """
    )
    suspend fun updateAppearance(
        id: String,
        wallpaper: String?,
        accentColor: Long?,
        bubbleColorMe: Long?,
        bubbleColorOther: Long?,
    )

    @Query("UPDATE chats SET updatedAt = :updatedAt WHERE id = :id")
    suspend fun touch(id: String, updatedAt: Long)

    @Query("DELETE FROM chats WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM chats")
    suspend fun deleteAll()
}
