package com.glasschat.app.data.repository

import android.content.Context
import android.net.Uri
import com.glasschat.app.data.local.db.dao.AttachmentDao
import com.glasschat.app.data.local.db.dao.ChatParticipantDao
import com.glasschat.app.data.local.media.AudioRecorder
import com.glasschat.app.data.local.media.MediaStorage
import com.glasschat.app.data.mapper.toDomain
import com.glasschat.app.di.IoDispatcher
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.MediaItem
import com.glasschat.app.domain.model.PendingAttachment
import com.glasschat.app.domain.model.PendingCapture
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.domain.repository.MediaRepository
import com.glasschat.app.util.fileNameOf
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MediaRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val storage: MediaStorage,
    private val recorder: AudioRecorder,
    private val attachmentDao: AttachmentDao,
    private val participantDao: ChatParticipantDao,
    @IoDispatcher private val io: CoroutineDispatcher,
) : MediaRepository {

    override fun observeMedia(): Flow<List<MediaItem>> = combine(
        attachmentDao.observeMedia(),
        participantDao.observeAllWithContact(),
    ) { rows, participants ->
        val names = participants.associate { it.contact.id to it.contact.name }
        rows.map { row ->
            MediaItem(
                attachment = row.attachment.toDomain(),
                messageId = row.attachment.messageId,
                chatId = row.chatId,
                chatTitle = row.chatTitle.ifBlank { "Chat" },
                senderLabel = if (row.senderType == SenderType.ME) {
                    "Me"
                } else {
                    row.senderContactId?.let { names[it] } ?: row.chatTitle
                },
                createdAt = row.messageCreatedAt,
                isFromMe = row.senderType == SenderType.ME,
            )
        }
    }

    override fun observeMediaForChat(chatId: String): Flow<List<MediaItem>> =
        observeMedia().map { items -> items.filter { it.chatId == chatId } }

    override suspend fun importFromUri(
        uri: String,
        type: AttachmentType,
        fileName: String?,
        mimeType: String?,
        caption: String?,
    ): PendingAttachment? = withContext(io) {
        val parsed = Uri.parse(uri)
        val file = storage.importStream(parsed, type, fileName, mimeType) ?: return@withContext null
        PendingAttachment(
            type = type,
            localUri = storage.fileUri(file),
            mimeType = mimeType ?: context.contentResolver.getType(parsed),
            fileName = fileName ?: file.name,
            sizeBytes = file.length(),
            caption = caption,
        )
    }

    override suspend fun createCameraTarget(): PendingCapture? = withContext(io) {
        runCatching {
            val file = storage.newCaptureFile()
            PendingCapture(
                filePath = file.absolutePath,
                contentUri = storage.contentUri(file).toString(),
            )
        }.getOrNull()
    }

    override suspend fun importCapturedPhoto(filePath: String): PendingAttachment? = withContext(io) {
        val source = File(filePath)
        if (!source.exists()) return@withContext null
        val file = storage.importFile(source, AttachmentType.IMAGE, "photo.jpg", "image/jpeg")
            ?: return@withContext null
        PendingAttachment(
            type = AttachmentType.IMAGE,
            localUri = storage.fileUri(file),
            mimeType = "image/jpeg",
            fileName = file.name,
            sizeBytes = file.length(),
        )
    }

    override suspend fun startRecording(): Boolean = withContext(io) { recorder.start() }

    override suspend fun stopRecording(): PendingAttachment? = withContext(io) {
        val recording = recorder.stop() ?: return@withContext null
        PendingAttachment(
            type = AttachmentType.AUDIO,
            localUri = storage.fileUri(recording.file),
            mimeType = "audio/mp4",
            fileName = fileNameOf("Voice note.m4a"),
            sizeBytes = recording.file.length(),
            durationMs = recording.durationMs,
        )
    }

    override fun isRecording(): Boolean = recorder.isRecording()

    override fun cancelRecording() = recorder.cancel()

    override suspend fun exportToDestination(attachmentId: String, destinationUri: String): Boolean =
        withContext(io) {
            val attachment = attachmentDao.getById(attachmentId) ?: return@withContext false
            val file = storage.fileFromLocalUri(attachment.localUri) ?: return@withContext false
            storage.copyToDestination(file, Uri.parse(destinationUri))
        }

    override suspend fun contentUriFor(attachmentId: String): String? = withContext(io) {
        val attachment = attachmentDao.getById(attachmentId)
        val file = attachment?.let { storage.fileFromLocalUri(it.localUri) } ?: return@withContext null
        runCatching { storage.contentUri(file).toString() }.getOrNull()
    }

    override suspend fun copyAvatarIntoStorage(uri: String): String? = withContext(io) {
        storage.copyAvatar(Uri.parse(uri))
    }

    override suspend fun deleteAttachment(attachmentId: String) = withContext(io) {
        val attachment = attachmentDao.getById(attachmentId) ?: return@withContext
        storage.deleteFile(storage.fileFromLocalUri(attachment.localUri))
        attachmentDao.deleteById(attachmentId)
        Unit
    }

    override suspend fun deleteMediaAt(localUri: String) = withContext(io) {
        storage.deleteFile(storage.fileFromLocalUri(localUri))
        Unit
    }

    override suspend fun cacheSizeBytes(): Long = storage.cacheSizeBytes()

    override suspend fun clearCache(): Long = storage.clearCache()

    override suspend fun deleteAllMedia() = withContext(io) {
        storage.deleteAllMedia()
    }

    override suspend fun pruneOrphanedMedia(): Int = withContext(io) {
        val known = attachmentDao.getAll()
            .mapNotNull { storage.fileFromLocalUri(it.localUri)?.absolutePath }
            .toSet()
        var removed = 0
        storage.rootDirectory().walkTopDown().filter { it.isFile }.forEach { candidate ->
            if (candidate.absolutePath !in known) {
                if (candidate.delete()) removed++
            }
        }
        removed
    }
}
