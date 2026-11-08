package com.glasschat.app.data.local.media

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.os.SystemClock
import com.glasschat.app.domain.model.AttachmentType
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Minimal AAC voice-note recorder. Recording only starts once the caller has confirmed the
 * RECORD_AUDIO runtime permission, and files land directly in private media storage.
 */
@Singleton
class AudioRecorder @Inject constructor(
    @ApplicationContext private val context: Context,
    private val storage: MediaStorage,
) {

    private var recorder: MediaRecorder? = null
    private var target: File? = null
    private var startedAtElapsed = 0L
    private var startedAtWall = 0L

    data class Recording(val file: File, val durationMs: Long, val createdAt: Long)

    fun isRecording(): Boolean = recorder != null

    fun start(): Boolean {
        if (recorder != null) return true
        val file = File(storage.directoryFor(AttachmentType.AUDIO), "voice-${System.currentTimeMillis()}.m4a")
        val newRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        return try {
            newRecorder.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(96_000)
                setAudioSamplingRate(44_100)
                setOutputFile(file.absolutePath)
                prepare()
                start()
            }
            recorder = newRecorder
            target = file
            startedAtElapsed = SystemClock.elapsedRealtime()
            startedAtWall = System.currentTimeMillis()
            true
        } catch (throwable: Throwable) {
            runCatching { newRecorder.release() }
            file.delete()
            recorder = null
            target = null
            false
        }
    }

    fun stop(): Recording? {
        val active = recorder ?: return null
        val file = target
        recorder = null
        target = null
        val duration = SystemClock.elapsedRealtime() - startedAtElapsed
        return try {
            active.stop()
            active.release()
            if (file != null && file.exists() && file.length() > 0L) {
                Recording(file = file, durationMs = duration, createdAt = startedAtWall)
            } else {
                file?.delete()
                null
            }
        } catch (throwable: Throwable) {
            runCatching { active.release() }
            file?.delete()
            null
        }
    }

    fun cancel() {
        val active = recorder ?: return
        recorder = null
        runCatching { active.stop() }
        runCatching { active.release() }
        target?.delete()
        target = null
    }
}
