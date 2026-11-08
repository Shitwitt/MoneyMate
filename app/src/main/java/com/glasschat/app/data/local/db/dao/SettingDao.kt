package com.glasschat.app.data.local.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.glasschat.app.data.local.db.entity.AppSettingEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface SettingDao {

    @Query("SELECT * FROM app_settings")
    fun observeAll(): Flow<List<AppSettingEntity>>

    @Query("SELECT value FROM app_settings WHERE key = :key")
    suspend fun get(key: String): String?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun put(setting: AppSettingEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun putAll(settings: List<AppSettingEntity>)

    @Query("DELETE FROM app_settings WHERE key = :key")
    suspend fun remove(key: String)

    @Query("DELETE FROM app_settings")
    suspend fun deleteAll()
}
