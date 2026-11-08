package com.glasschat.app.domain.repository

import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.MediaItem
import com.glasschat.app.domain.model.PendingAttachment
import com.glasschat.app.domain.model.PendingCapture
import kotlinx.coroutines.flow.Flow

/**
 * Owns everything that touches the file system: importing picked media into private
 * storage, saving copies back out to a user-chosen document location, and voice recording.
 */
interface MediaRepository {
    fun observeMedia(): Flow<List<MediaItem>>
    fun observeMediaForChat(chatId: String): Flow<List<MediaItem>>

    suspend fun importFromUri(
        uri: String,
        type: AttachmentType,
        fileName: String? = null,
        mimeType: String? = null,
        caption: String? = null,
    ): PendingAttachment?

    /** Creates a cache file + FileProvider URI for the system camera intent. */
    suspend fun createCameraTarget(): PendingCapture?
    suspend fun importCapturedPhoto(filePath: String): PendingAttachment?

    suspend fun startRecording(): Boolean
    suspend fun stopRecording(): PendingAttachment?
    fun isRecording(): Boolean
    fun cancelRecording()

    /** Writes a private media file into a user-selected SAF destination. */
    suspend fun exportToDestination(attachmentId: String, destinationUri: String): Boolean
    suspend fun contentUriFor(attachmentId: String): String?
    suspend fun copyAvatarIntoStorage(uri: String): String?
    suspend fun deleteAttachment(attachmentId: String)
    suspend fun deleteMediaAt(localUri: String)
    suspend fun cacheSizeBytes(): Long
    suspend fun clearCache(): Long
    suspend fun deleteAllMedia()

    /** Deletes files that no longer have a database row. @return number of files removed. */
    suspend fun pruneOrphanedMedia(): Int
}
