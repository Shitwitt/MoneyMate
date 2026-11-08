package com.glasschat.app.ui.components

import android.content.Context
import android.media.MediaPlayer
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.io.File

/**
 * Very small MediaPlayer wrapper: one voice note at a time, with observable transport state.
 * Deliberately dependency-free (no background service) because playback only ever happens
 * while a chat or the media viewer is on screen.
 */
@Stable
class GlassAudioPlayer(private val context: Context) {

    var activeKey by mutableStateOf<String?>(null)
        private set
    var isPlaying by mutableStateOf(false)
        private set
    var positionMs by mutableLongStateOf(0L)
        private set
    var durationMs by mutableLongStateOf(0L)
        private set

    private var player: MediaPlayer? = null
    private var ticker: Job? = null
    private var scope: CoroutineScope? = null

    fun toggle(key: String, localUri: String, coroutineScope: CoroutineScope) {
        scope = coroutineScope
        if (activeKey == key && player != null) {
            if (isPlaying) pause() else resume()
            return
        }
        releasePlayer()
        val mediaPlayer = MediaPlayer()
        val uri = if (localUri.startsWith("file://") || localUri.startsWith("content://")) {
            Uri.parse(localUri)
        } else {
            Uri.fromFile(File(localUri))
        }
        runCatching {
            mediaPlayer.setDataSource(context, uri)
            mediaPlayer.setOnPreparedListener { prepared ->
                durationMs = prepared.duration.toLong().coerceAtLeast(0L)
                prepared.start()
                isPlaying = true
                activeKey = key
                startTicker(coroutineScope)
            }
            mediaPlayer.setOnCompletionListener { completed ->
                completed.seekTo(0)
                positionMs = 0L
                isPlaying = false
                ticker?.cancel()
            }
            mediaPlayer.setOnErrorListener { _, _, _ ->
                isPlaying = false
                true
            }
            mediaPlayer.prepareAsync()
            player = mediaPlayer
            activeKey = key
            positionMs = 0L
        }.onFailure {
            runCatching { mediaPlayer.release() }
            player = null
            activeKey = null
            isPlaying = false
        }
    }

    fun pause() {
        runCatching { player?.takeIf { it.isPlaying }?.pause() }
        isPlaying = false
        ticker?.cancel()
    }

    fun resume() {
        runCatching { player?.start() }
        isPlaying = true
        scope?.let { startTicker(it) }
    }

    fun seekTo(position: Long) {
        val target = position.coerceIn(0L, durationMs.coerceAtLeast(0L))
        runCatching { player?.seekTo(target.toInt()) }
        positionMs = target
    }

    fun seekToFraction(fraction: Float) {
        if (durationMs <= 0L) return
        seekTo((durationMs * fraction.coerceIn(0f, 1f)).toLong())
    }

    fun release() {
        releasePlayer()
        activeKey = null
        isPlaying = false
        positionMs = 0L
        durationMs = 0L
    }

    private fun releasePlayer() {
        ticker?.cancel()
        ticker = null
        runCatching {
            player?.reset()
            player?.release()
        }
        player = null
    }

    private fun startTicker(coroutineScope: CoroutineScope) {
        ticker?.cancel()
        ticker = coroutineScope.launch {
            while (isActive) {
                val current = runCatching { player?.currentPosition?.toLong() }.getOrNull()
                if (current != null) positionMs = current
                delay(180)
            }
        }
    }
}

@Composable
fun rememberGlassAudioPlayer(): GlassAudioPlayer {
    val context = LocalContext.current
    val player = remember(context) { GlassAudioPlayer(context) }
    DisposableEffect(player) {
        onDispose { player.release() }
    }
    return player
}

/** Shared per-screen player so only one voice note ever plays at a time. */
val LocalGlassAudioPlayer = staticCompositionLocalOf<GlassAudioPlayer?> { null }
