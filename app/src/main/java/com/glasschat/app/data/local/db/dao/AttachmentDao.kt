package com.glasschat.app.data.local.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.glasschat.app.data.local.db.entity.AttachmentEntity
import com.glasschat.app.data.local.db.entity.MediaRow
import kotlinx.coroutines.flow.Flow

@Dao
interface AttachmentDao {

    @Query(
        """
        SELECT a.* FROM attachments a
        INNER JOIN messages m ON m.id = a.messageId
        WHERE m.chatId = :chatId AND m.isHiddenLocally = 0
        ORDER BY m.createdAt ASC
        """
    )
    fun observeForChat(chatId: String): Flow<List<AttachmentEntity>>

    @Query("SELECT * FROM attachments")
    fun observeAll(): Flow<List<AttachmentEntity>>

    /** Gallery tab: every attachment with the chat it belongs to, newest first. */
    @Query(
        """
        SELECT a.*, m.chatId AS chatId, c.title AS chatTitle,
            m.createdAt AS messageCreatedAt, m.senderType AS senderType,
            m.senderContactId AS senderContactId
        FROM attachments a
        INNER JOIN messages m ON m.id = a.messageId
        INNER JOIN chats c ON c.id = m.chatId
        WHERE m.isHiddenLocally = 0 AND m.isDeletedForEveryone = 0
        ORDER BY m.createdAt DESC
        """
    )
    fun observeMedia(): Flow<List<MediaRow>>

    @Query("SELECT * FROM attachments WHERE id = :id")
    suspend fun getById(id: String): AttachmentEntity?

    @Query("SELECT * FROM attachments WHERE messageId = :messageId")
    fun observeForMessage(messageId: String): Flow<List<AttachmentEntity>>

    @Query("SELECT * FROM attachments WHERE messageId = :messageId")
    suspend fun getForMessage(messageId: String): List<AttachmentEntity>

    @Query("SELECT * FROM attachments ORDER BY messageId ASC")
    suspend fun getAll(): List<AttachmentEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(attachments: List<AttachmentEntity>)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(attachment: AttachmentEntity)

    @Query("DELETE FROM attachments WHERE messageId = :messageId")
    suspend fun deleteForMessage(messageId: String)

    @Query("DELETE FROM attachments WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM attachments")
    suspend fun deleteAll()
}
