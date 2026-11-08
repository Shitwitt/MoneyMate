package com.glasschat.app.di

import android.content.Context
import com.glasschat.app.data.local.db.GlassChatDatabase
import com.glasschat.app.data.local.db.dao.AttachmentDao
import com.glasschat.app.data.local.db.dao.ChatDao
import com.glasschat.app.data.local.db.dao.ChatParticipantDao
import com.glasschat.app.data.local.db.dao.ContactDao
import com.glasschat.app.data.local.db.dao.MessageDao
import com.glasschat.app.data.local.db.dao.ReactionDao
import com.glasschat.app.data.local.db.dao.SettingDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): GlassChatDatabase =
        GlassChatDatabase.build(context)

    @Provides
    fun provideContactDao(db: GlassChatDatabase): ContactDao = db.contactDao()

    @Provides
    fun provideChatDao(db: GlassChatDatabase): ChatDao = db.chatDao()

    @Provides
    fun provideParticipantDao(db: GlassChatDatabase): ChatParticipantDao = db.participantDao()

    @Provides
    fun provideMessageDao(db: GlassChatDatabase): MessageDao = db.messageDao()

    @Provides
    fun provideAttachmentDao(db: GlassChatDatabase): AttachmentDao = db.attachmentDao()

    @Provides
    fun provideReactionDao(db: GlassChatDatabase): ReactionDao = db.reactionDao()

    @Provides
    fun provideSettingDao(db: GlassChatDatabase): SettingDao = db.settingDao()
}
