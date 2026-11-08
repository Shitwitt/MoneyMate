package com.glasschat.app.di

import com.glasschat.app.data.local.datastore.SettingsRepositoryImpl
import com.glasschat.app.data.repository.BackupRepositoryImpl
import com.glasschat.app.data.repository.ChatRepositoryImpl
import com.glasschat.app.data.repository.ContactRepositoryImpl
import com.glasschat.app.data.repository.MediaRepositoryImpl
import com.glasschat.app.data.repository.MessageRepositoryImpl
import com.glasschat.app.domain.repository.BackupRepository
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.MediaRepository
import com.glasschat.app.domain.repository.MessageRepository
import com.glasschat.app.domain.repository.SettingsRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindContactRepository(impl: ContactRepositoryImpl): ContactRepository

    @Binds
    @Singleton
    abstract fun bindChatRepository(impl: ChatRepositoryImpl): ChatRepository

    @Binds
    @Singleton
    abstract fun bindMessageRepository(impl: MessageRepositoryImpl): MessageRepository

    @Binds
    @Singleton
    abstract fun bindMediaRepository(impl: MediaRepositoryImpl): MediaRepository

    @Binds
    @Singleton
    abstract fun bindBackupRepository(impl: BackupRepositoryImpl): BackupRepository

    @Binds
    @Singleton
    abstract fun bindSettingsRepository(impl: SettingsRepositoryImpl): SettingsRepository
}
