package com.glasschat.app.data.local.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.glasschat.app.data.local.db.entity.ContactEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ContactDao {

    @Query("SELECT * FROM contacts ORDER BY name COLLATE NOCASE ASC")
    fun observeAll(): Flow<List<ContactEntity>>

    @Query("SELECT * FROM contacts WHERE id = :id")
    fun observeById(id: String): Flow<ContactEntity?>

    @Query("SELECT * FROM contacts WHERE id = :id")
    suspend fun getById(id: String): ContactEntity?

    @Query("SELECT * FROM contacts ORDER BY name COLLATE NOCASE ASC")
    suspend fun getAll(): List<ContactEntity>

    @Query("SELECT COUNT(*) FROM contacts")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(contact: ContactEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(contacts: List<ContactEntity>)

    @Update
    suspend fun update(contact: ContactEntity)

    @Query("UPDATE contacts SET isFavorite = :favorite WHERE id = :id")
    suspend fun setFavorite(id: String, favorite: Boolean)

    @Query("UPDATE contacts SET isBlocked = :blocked WHERE id = :id")
    suspend fun setBlocked(id: String, blocked: Boolean)

    @Query("DELETE FROM contacts WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM contacts")
    suspend fun deleteAll()
}
