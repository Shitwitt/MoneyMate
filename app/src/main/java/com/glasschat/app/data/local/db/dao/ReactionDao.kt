package com.glasschat.app.data.local.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.glasschat.app.data.local.db.entity.ReactionEntity
import com.glasschat.app.domain.model.SenderType
import kotlinx.coroutines.flow.Flow

@Dao
interface ReactionDao {

    @Query(
        """
        SELECT r.* FROM reactions r
        INNER JOIN messages m ON m.id = r.messageId
        WHERE m.chatId = :chatId
        """
    )
    fun observeForChat(chatId: String): Flow<List<ReactionEntity>>

    @Query("SELECT * FROM reactions")
    fun observeAll(): Flow<List<ReactionEntity>>

    @Query("SELECT * FROM reactions WHERE messageId = :messageId")
    fun observeForMessage(messageId: String): Flow<List<ReactionEntity>>

    @Query("SELECT * FROM reactions WHERE messageId = :messageId")
    suspend fun getForMessage(messageId: String): List<ReactionEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(reaction: ReactionEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(reactions: List<ReactionEntity>)

    @Query(
        "DELETE FROM reactions WHERE messageId = :messageId AND senderType = :senderType " +
            "AND emoji = :emoji"
    )
    suspend fun remove(messageId: String, senderType: SenderType, emoji: String)

    @Query("DELETE FROM reactions WHERE messageId = :messageId")
    suspend fun deleteForMessage(messageId: String)

    @Query("DELETE FROM reactions")
    suspend fun deleteAll()
}
