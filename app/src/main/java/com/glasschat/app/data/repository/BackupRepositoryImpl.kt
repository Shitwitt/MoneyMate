package com.glasschat.app.data.repository

import android.content.Context
import android.net.Uri
import com.glasschat.app.BuildConfig
import com.glasschat.app.data.backup.AttachmentDto
import com.glasschat.app.data.backup.BackupBundle
import com.glasschat.app.data.backup.ChatDto
import com.glasschat.app.data.backup.ContactDto
import com.glasschat.app.data.backup.MessageDto
import com.glasschat.app.data.backup.ParticipantDto
import com.glasschat.app.data.backup.PreferencesDto
import com.glasschat.app.data.backup.ReactionDto
import com.glasschat.app.data.backup.SettingDto
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
import com.glasschat.app.data.local.media.MediaStorage
import com.glasschat.app.di.IoDispatcher
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.BackupResult
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.MessageStatus
import com.glasschat.app.domain.model.ParticipantRole
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.domain.model.ThemeMode
import com.glasschat.app.domain.repository.BackupRepository
import com.glasschat.app.domain.repository.SettingsRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Backup format v1: a ZIP with a readable JSON manifest plus every media file, keyed by
 * attachment id. Exported through the Storage Access Framework, so it needs no storage
 * permission on any supported Android version.
 */
@Singleton
class BackupRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val contactDao: ContactDao,
    private val chatDao: ChatDao,
    private val participantDao: ChatParticipantDao,
    private val messageDao: MessageDao,
    private val attachmentDao: AttachmentDao,
    private val reactionDao: ReactionDao,
    private val settingDao: SettingDao,
    private val settingsRepository: SettingsRepository,
    private val storage: MediaStorage,
    @IoDispatcher private val io: CoroutineDispatcher,
) : BackupRepository {

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        prettyPrint = false
    }

    override suspend fun exportBackup(destinationUri: String): BackupResult = withContext(io) {
        val contacts = contactDao.getAll()
        val chats = chatDao.getAll()
        val participants = participantDao.getAll()
        val messages = messageDao.getAll()
        val attachments = attachmentDao.getAll()
        val reactions = reactionDao.observeAll().first()
        val settings = settingDao.observeAll().first()
        val preferences = settingsRepository.preferences.first()

        val attachmentDtos = attachments.map { attachment ->
            val file = storage.fileFromLocalUri(attachment.localUri)
            AttachmentDto(
                id = attachment.id,
                messageId = attachment.messageId,
                type = attachment.type.name,
                mimeType = attachment.mimeType,
                fileName = attachment.fileName,
                sizeBytes = attachment.sizeBytes,
                durationMs = attachment.durationMs,
                caption = attachment.caption,
                entry = file?.let { "${BackupBundle.MEDIA_PREFIX}${attachment.id}.${it.extension}" },
            )
        }

        val bundle = BackupBundle(
            exportedAt = System.currentTimeMillis(),
            appVersion = BuildConfig.VERSION_NAME,
            preferences = preferences.toDto(),
            contacts = contacts.map {
                ContactDto(
                    id = it.id,
                    name = it.name,
                    avatarUri = null,
                    accentColor = it.accentColor,
                    bio = it.bio,
                    phoneLabel = it.phoneLabel,
                    notes = it.notes,
                    isFavorite = it.isFavorite,
                    isBlocked = it.isBlocked,
                    createdAt = it.createdAt,
                )
            },
            chats = chats.map {
                ChatDto(
                    id = it.id,
                    title = it.title,
                    type = it.type.name,
                    wallpaper = it.wallpaper,
                    accentColor = it.accentColor,
                    bubbleColorMe = it.bubbleColorMe,
                    bubbleColorOther = it.bubbleColorOther,
                    isPinned = it.isPinned,
                    isArchived = it.isArchived,
                    isMuted = it.isMuted,
                    isDeleted = it.isDeleted,
                    createdAt = it.createdAt,
                    updatedAt = it.updatedAt,
                    draft = it.draft,
                )
            },
            participants = participants.map {
                ParticipantDto(
                    chatId = it.chatId,
                    contactId = it.contactId,
                    role = it.role.name,
                    position = it.position,
                )
            },
            messages = messages.map {
                MessageDto(
                    id = it.id,
                    chatId = it.chatId,
                    senderType = it.senderType.name,
                    senderContactId = it.senderContactId,
                    text = it.text,
                    createdAt = it.createdAt,
                    editedAt = it.editedAt,
                    replyToMessageId = it.replyToMessageId,
                    isStarred = it.isStarred,
                    isDeletedForEveryone = it.isDeletedForEveryone,
                    isHiddenLocally = it.isHiddenLocally,
                    status = it.status.name,
                    isRead = it.isRead,
                )
            },
            attachments = attachmentDtos,
            reactions = reactions.map {
                ReactionDto(
                    id = it.id,
                    messageId = it.messageId,
                    senderType = it.senderType.name,
                    emoji = it.emoji,
                    createdAt = it.createdAt,
                )
            },
            settings = settings.map { SettingDto(it.key, it.value) },
        )

        val manifest = json.encodeToString(BackupBundle.serializer(), bundle)
        var mediaFiles = 0
        var bytes = 0L

        val output = context.contentResolver.openOutputStream(Uri.parse(destinationUri))
            ?: error("Could not open the selected backup file")
        output.use { raw ->
            ZipOutputStream(BufferedOutputStream(raw)).use { zip ->
                val manifestBytes = manifest.toByteArray()
                zip.putNextEntry(ZipEntry(BackupBundle.MANIFEST_ENTRY))
                zip.write(manifestBytes)
                zip.closeEntry()
                bytes += manifestBytes.size

                attachments.forEachIndexed { index, attachment ->
                    val entryName = attachmentDtos[index].entry ?: return@forEachIndexed
                    val file = storage.fileFromLocalUri(attachment.localUri) ?: return@forEachIndexed
                    zip.putNextEntry(ZipEntry(entryName))
                    file.inputStream().use { input -> input.copyTo(zip) }
                    zip.closeEntry()
                    mediaFiles++
                    bytes += file.length()
                }
            }
        }

        settingsRepository.markBackupCompleted(System.currentTimeMillis())

        BackupResult(
            chats = chats.size,
            contacts = contacts.size,
            messages = messages.size,
            mediaFiles = mediaFiles,
            bytesWritten = bytes,
        )
    }

    override suspend fun importBackup(sourceUri: String): BackupResult = withContext(io) {
        var bundle: BackupBundle? = null
        val extracted = mutableMapOf<String, File>()
        val staging = File(context.cacheDir, "import").apply {
            deleteRecursively()
            mkdirs()
        }

        val input = context.contentResolver.openInputStream(Uri.parse(sourceUri))
            ?: error("Could not open the selected backup file")
        input.use { raw ->
            ZipInputStream(BufferedInputStream(raw)).use { zip ->
                while (true) {
                    val entry = zip.nextEntry ?: break
                    if (!entry.isDirectory) {
                        when {
                            entry.name == BackupBundle.MANIFEST_ENTRY -> {
                                val text = zip.readBytes().toString(Charsets.UTF_8)
                                bundle = json.decodeFromString(BackupBundle.serializer(), text)
                            }

                            entry.name.startsWith(BackupBundle.MEDIA_PREFIX) -> {
                                val target = File(staging, entry.name.removePrefix(BackupBundle.MEDIA_PREFIX))
                                target.parentFile?.mkdirs()
                                target.outputStream().use { out -> zip.copyTo(out) }
                                extracted[entry.name] = target
                            }
                        }
                    }
                    zip.closeEntry()
                }
            }
        }

        val parsed = bundle ?: error("That file is not a GlassChat backup")
        require(parsed.format == BackupBundle.FORMAT) { "Unsupported backup format" }

        // Restore in foreign-key order; REPLACE keeps repeated imports idempotent.
        contactDao.insertAll(
            parsed.contacts.map {
                ContactEntity(
                    id = it.id,
                    name = it.name,
                    avatarUri = it.avatarUri,
                    accentColor = it.accentColor,
                    bio = it.bio,
                    phoneLabel = it.phoneLabel,
                    notes = it.notes,
                    isFavorite = it.isFavorite,
                    isBlocked = it.isBlocked,
                    createdAt = it.createdAt,
                )
            },
        )
        chatDao.insertAll(
            parsed.chats.map {
                ChatEntity(
                    id = it.id,
                    title = it.title,
                    type = enumOrDefault(it.type, ChatType.ONE_TO_ONE),
                    wallpaper = it.wallpaper,
                    accentColor = it.accentColor,
                    bubbleColorMe = it.bubbleColorMe,
                    bubbleColorOther = it.bubbleColorOther,
                    isPinned = it.isPinned,
                    isArchived = it.isArchived,
                    isMuted = it.isMuted,
                    isDeleted = it.isDeleted,
                    createdAt = it.createdAt,
                    updatedAt = it.updatedAt,
                    draft = it.draft,
                )
            },
        )
        participantDao.insertAll(
            parsed.participants.map {
                ChatParticipantEntity(
                    chatId = it.chatId,
                    contactId = it.contactId,
                    role = enumOrDefault(it.role, ParticipantRole.MEMBER),
                    position = it.position,
                )
            },
        )
        messageDao.insertAll(
            parsed.messages.map {
                MessageEntity(
                    id = it.id,
                    chatId = it.chatId,
                    senderType = enumOrDefault(it.senderType, SenderType.ME),
                    senderContactId = it.senderContactId,
                    text = it.text,
                    createdAt = it.createdAt,
                    editedAt = it.editedAt,
                    replyToMessageId = it.replyToMessageId,
                    isStarred = it.isStarred,
                    isDeletedForEveryone = it.isDeletedForEveryone,
                    isHiddenLocally = it.isHiddenLocally,
                    status = enumOrDefault(it.status, MessageStatus.SIMULATED_SENT),
                    isRead = it.isRead,
                )
            },
        )

        var restoredMedia = 0
        val attachmentEntities = mutableListOf<AttachmentEntity>()
        parsed.attachments.forEach { dto ->
            val type = enumOrDefault(dto.type, AttachmentType.DOCUMENT)
            val staged = dto.entry?.let { extracted[it] }
            val destination = if (staged != null) {
                val moved = storage.importFile(staged, type, dto.fileName, dto.mimeType)
                if (moved != null) restoredMedia++
                moved
            } else {
                null
            }
            attachmentEntities += AttachmentEntity(
                id = dto.id,
                messageId = dto.messageId,
                type = type,
                localUri = destination?.let { storage.fileUri(it) } ?: "",
                mimeType = dto.mimeType,
                fileName = dto.fileName,
                sizeBytes = dto.sizeBytes,
                durationMs = dto.durationMs,
                caption = dto.caption,
            )
        }
        // Attachments whose bytes were missing are dropped rather than left dangling.
        attachmentDao.insertAll(attachmentEntities.filter { it.localUri.isNotBlank() })

        reactionDao.insertAll(
            parsed.reactions.map {
                ReactionEntity(
                    id = it.id,
                    messageId = it.messageId,
                    senderType = enumOrDefault(it.senderType, SenderType.ME),
                    emoji = it.emoji,
                    createdAt = it.createdAt,
                )
            },
        )
        if (parsed.settings.isNotEmpty()) {
            settingDao.putAll(parsed.settings.map { AppSettingEntity(it.key, it.value) })
        }
        parsed.preferences?.let { restored -> settingsRepository.update { restored.toDomain() } }

        staging.deleteRecursively()

        BackupResult(
            chats = parsed.chats.size,
            contacts = parsed.contacts.size,
            messages = parsed.messages.size,
            mediaFiles = restoredMedia,
            bytesWritten = 0L,
        )
    }

    override suspend fun deleteAllData() = withContext(io) {
        // Children first so foreign keys never complain, then the files themselves.
        reactionDao.deleteAll()
        attachmentDao.deleteAll()
        messageDao.deleteAll()
        participantDao.deleteAll()
        chatDao.deleteAll()
        contactDao.deleteAll()
        settingDao.deleteAll()
        storage.deleteAllMedia()
        settingsRepository.update { AppPreferences() }
        Unit
    }

    private inline fun <reified T : Enum<T>> enumOrDefault(name: String, fallback: T): T =
        enumValues<T>().firstOrNull { it.name == name } ?: fallback

    private fun AppPreferences.toDto(): PreferencesDto = PreferencesDto(
        onboardingComplete = onboardingComplete,
        displayName = displayName,
        about = about,
        avatarUri = avatarUri,
        profileAccent = profileAccent,
        themeMode = themeMode.name,
        accent = accent,
        bubbleColorMe = bubbleColorMe,
        bubbleColorOther = bubbleColorOther,
        wallpaper = wallpaper,
        fontScale = fontScale,
        reduceTransparency = reduceTransparency,
        reduceMotion = reduceMotion,
        enterToSend = enterToSend,
        showTimestamps = showTimestamps,
        showSimulatedStatus = showSimulatedStatus,
        hapticsEnabled = hapticsEnabled,
        appLockEnabled = appLockEnabled,
        hidePreviewsInRecents = hidePreviewsInRecents,
        blurMediaInList = blurMediaInList,
    )

    private fun PreferencesDto.toDomain(): AppPreferences = AppPreferences(
        onboardingComplete = onboardingComplete,
        displayName = displayName,
        about = about,
        avatarUri = avatarUri,
        profileAccent = profileAccent ?: AppPreferences().profileAccent,
        themeMode = enumOrDefault(themeMode, ThemeMode.SYSTEM),
        accent = accent ?: AppPreferences().accent,
        bubbleColorMe = bubbleColorMe,
        bubbleColorOther = bubbleColorOther,
        wallpaper = wallpaper,
        fontScale = fontScale,
        reduceTransparency = reduceTransparency,
        reduceMotion = reduceMotion,
        enterToSend = enterToSend,
        showTimestamps = showTimestamps,
        showSimulatedStatus = showSimulatedStatus,
        hapticsEnabled = hapticsEnabled,
        appLockEnabled = appLockEnabled,
        hidePreviewsInRecents = hidePreviewsInRecents,
        blurMediaInList = blurMediaInList,
    )
}
