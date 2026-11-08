package com.glasschat.app.data.local.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.glasschat.app.data.local.db.entity.ChatParticipantEntity
import com.glasschat.app.data.local.db.entity.ParticipantRow
import kotlinx.coroutines.flow.Flow

@Dao
interface ChatParticipantDao {

    @Query(
        """
        SELECT p.chatId AS chatId, p.role AS role, p.position AS position, c.*
        FROM chat_participants p
        INNER JOIN contacts c ON c.id = p.contactId
        ORDER BY p.position ASC
        """
    )
    fun observeAllWithContact(): Flow<List<ParticipantRow>>

    @Query(
        """
        SELECT p.chatId AS chatId, p.role AS role, p.position AS position, c.*
        FROM chat_participants p
        INNER JOIN contacts c ON c.id = p.contactId
        WHERE p.chatId = :chatId
        ORDER BY p.position ASC
        """
    )
    suspend fun getForChat(chatId: String): List<ParticipantRow>

    @Query("SELECT contactId FROM chat_participants WHERE chatId = :chatId ORDER BY position ASC")
    suspend fun getContactIds(chatId: String): List<String>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(participants: List<ChatParticipantEntity>)

    @Query("DELETE FROM chat_participants WHERE chatId = :chatId AND contactId = :contactId")
    suspend fun remove(chatId: String, contactId: String)

    @Query("DELETE FROM chat_participants WHERE chatId = :chatId")
    suspend fun deleteForChat(chatId: String)

    @Query("SELECT * FROM chat_participants")
    suspend fun getAll(): List<ChatParticipantEntity>

    @Query("DELETE FROM chat_participants")
    suspend fun deleteAll()
}
