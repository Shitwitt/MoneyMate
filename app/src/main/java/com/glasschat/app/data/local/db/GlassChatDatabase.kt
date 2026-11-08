package com.glasschat.app.data.local.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.glasschat.app.data.local.db.dao.AttachmentDao
import com.glasschat.app.data.local.db.dao.ChatDao
import com.glasschat.app.data.local.db.dao.ChatParticipantDao
import com.glasschat.app.data.local.db.dao.ContactDao
import com.glasschat.app.data.local.db.dao.MessageDao
import com.glasschat.app.data.local.db.dao.ReactionDao
import com.glasschat.app.data.local.db.dao.SettingDao
import com.glasschat.app.data.local.db.entity.AppSettingEntity
import com.glasschat.app.data.local.db.entity.AttachmentEntity
import com.glasschat.app.data.local.db.entity.ChatEntity
import com.glasschat.app.data.local.db.entity.ChatParticipantEntity
import com.glasschat.app.data.local.db.entity.ContactEntity
import com.glasschat.app.data.local.db.entity.MessageEntity
import com.glasschat.app.data.local.db.entity.ReactionEntity

@Database(
    entities = [
        ContactEntity::class,
        ChatEntity::class,
        ChatParticipantEntity::class,
        MessageEntity::class,
        AttachmentEntity::class,
        ReactionEntity::class,
        AppSettingEntity::class,
    ],
    version = 1,
    exportSchema = true,
)
@TypeConverters(Converters::class)
abstract class GlassChatDatabase : RoomDatabase() {

    abstract fun contactDao(): ContactDao
    abstract fun chatDao(): ChatDao
    abstract fun participantDao(): ChatParticipantDao
    abstract fun messageDao(): MessageDao
    abstract fun attachmentDao(): AttachmentDao
    abstract fun reactionDao(): ReactionDao
    abstract fun settingDao(): SettingDao

    companion object {
        const val NAME = "glasschat.db"

        fun build(context: Context): GlassChatDatabase =
            Room.databaseBuilder(context, GlassChatDatabase::class.java, NAME)
                // Foreign keys are declared on every child table; Room enables them by default.
                .fallbackToDestructiveMigrationOnDowngrade()
                .build()

        /** Used by instrumented tests: real schema, zero disk footprint. */
        fun buildInMemory(context: Context): GlassChatDatabase =
            Room.inMemoryDatabaseBuilder(context, GlassChatDatabase::class.java)
                .allowMainThreadQueries()
                .build()
    }
}
