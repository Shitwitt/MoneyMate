package com.glasschat.app.data.local.media

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import com.glasschat.app.di.IoDispatcher
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.util.newId
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext
import java.io.File
import java.io.InputStream
import javax.inject.Inject
import javax.inject.Singleton

/**
 * All attachment bytes live under `files/media/<kind>/` inside the app sandbox. Original
 * files chosen through the Photo Picker or SAF are only ever *read* — never modified or
 * moved — so the user's library is untouched.
 */
@Singleton
class MediaStorage @Inject constructor(
    @ApplicationContext private val context: Context,
    @IoDispatcher private val io: CoroutineDispatcher,
) {

    private val root = File(context.filesDir, "media")
    private val avatarRoot = File(context.filesDir, "avatars")
    private val captureRoot = File(context.cacheDir, "capture")

    fun rootDirectory(): File = root.apply { mkdirs() }
    fun avatarDirectory(): File = avatarRoot.apply { mkdirs() }

    fun directoryFor(type: AttachmentType): File {
        val folder = when (type) {
            AttachmentType.IMAGE -> "photos"
            AttachmentType.VIDEO -> "videos"
            AttachmentType.AUDIO -> "audio"
            AttachmentType.DOCUMENT -> "documents"
        }
        return File(root, folder).apply { mkdirs() }
    }

    /** Copies a `content://` document into private storage and returns the new file. */
    suspend fun importStream(
        uri: Uri,
        type: AttachmentType,
        fileName: String?,
        mimeType: String?,
    ): File? = withContext(io) {
        val displayName = fileName ?: queryDisplayName(uri)
        val resolvedMime = mimeType ?: context.contentResolver.getType(uri)
        val extension = extensionFor(displayName, resolvedMime, type)
        val target = File(directoryFor(type), "${newId()}.$extension")
        runCatching {
            context.contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            } ?: return@runCatching null
            target
        }.getOrNull()?.takeIf { it.length() > 0L } ?: run {
            target.delete()
            null
        }
    }

    suspend fun importFile(
        source: File,
        type: AttachmentType,
        fileName: String?,
        mimeType: String?,
    ): File? = withContext(io) {
        if (!source.exists()) return@withContext null
        val extension = extensionFor(fileName ?: source.name, mimeType, type)
        val target = File(directoryFor(type), "${newId()}.$extension")
        runCatching {
            source.inputStream().use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            }
            source.delete()
            target
        }.getOrNull()
    }

    suspend fun writeTo(
        file: File,
        type: AttachmentType,
        openInput: () -> InputStream?,
    ): File? = withContext(io) {
        val target = File(directoryFor(type), "${newId()}.${file.extension.ifBlank { "bin" }}")
        runCatching {
            openInput()?.use { input -> target.outputStream().use { input.copyTo(it) } }
            target
        }.getOrNull()?.takeIf { it.length() > 0L }
    }

    fun newCaptureFile(): File {
        captureRoot.mkdirs()
        return File(captureRoot, "capture-${System.currentTimeMillis()}.jpg")
    }

    fun fileFromLocalUri(localUri: String): File? {
        val path = when {
            localUri.startsWith("file://") -> Uri.parse(localUri).path
            localUri.startsWith("/") -> localUri
            else -> Uri.parse(localUri).path
        } ?: return null
        val file = File(path)
        return file.takeIf { it.exists() }
    }

    fun fileUri(file: File): String = Uri.fromFile(file).toString()

    fun contentUri(file: File): Uri =
        FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)

    /** SAF destination write used by "Save to device" and backup export. */
    suspend fun copyToDestination(file: File, destination: Uri): Boolean = withContext(io) {
        runCatching {
            context.contentResolver.openOutputStream(destination)?.use { output ->
                file.inputStream().use { input -> input.copyTo(output) }
            } ?: return@runCatching false
            true
        }.getOrDefault(false)
    }

    suspend fun copyAvatar(uri: Uri): String? = withContext(io) {
        val extension = extensionFor(queryDisplayName(uri), context.contentResolver.getType(uri), AttachmentType.IMAGE)
        val target = File(avatarDirectory(), "${newId()}.$extension")
        runCatching {
            context.contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            } ?: return@runCatching null
            fileUri(target)
        }.getOrNull()
    }

    suspend fun deleteFile(file: File?): Boolean = withContext(io) {
        file?.delete() ?: false
    }

    suspend fun cacheSizeBytes(): Long = withContext(io) {
        val coilCache = File(context.cacheDir, "image_cache")
        listOf(captureRoot, coilCache).sumOf { dir -> dir.walkTopDown().filter { it.isFile }.sumOf { it.length() } }
    }

    suspend fun clearCache(): Long = withContext(io) {
        val before = cacheSizeBytes()
        File(context.cacheDir, "capture").deleteRecursively()
        File(context.cacheDir, "image_cache").deleteRecursively()
        before
    }

    suspend fun deleteAllMedia() = withContext(io) {
        root.deleteRecursively()
        avatarRoot.deleteRecursively()
        captureRoot.deleteRecursively()
        File(context.cacheDir, "image_cache").deleteRecursively()
        Unit
    }

    private fun queryDisplayName(uri: Uri): String? = runCatching {
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) cursor.getString(index) else null
                } else {
                    null
                }
            }
    }.getOrNull()

    private fun extensionFor(fileName: String?, mimeType: String?, type: AttachmentType): String {
        val fromName = fileName?.substringAfterLast('.', "")?.lowercase()
        if (!fromName.isNullOrBlank() && fromName.length <= 6 && fromName.all { it.isLetterOrDigit() }) {
            return fromName
        }
        val fromMime = mimeType?.let { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) }
        if (!fromMime.isNullOrBlank()) return fromMime
        return when (type) {
            AttachmentType.IMAGE -> "jpg"
            AttachmentType.VIDEO -> "mp4"
            AttachmentType.AUDIO -> "m4a"
            AttachmentType.DOCUMENT -> "bin"
        }
    }
}
