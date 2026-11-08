package com.glasschat.app.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlin.random.Random

/**
 * Deterministic waveform for a voice note. Bars are derived from the attachment id, so the
 * shape is stable across recompositions and app restarts.
 */
fun waveformFor(seed: String, barCount: Int = 32): List<Float> {
    val random = Random(seed.hashCode().toLong())
    return List(barCount) { 0.22f + random.nextFloat() * 0.78f }
}

@Composable
fun WaveformBars(
    bars: List<Float>,
    progress: Float,
    playedColor: Color,
    remainingColor: Color,
    modifier: Modifier = Modifier,
    height: Dp = 30.dp,
    onSeek: ((Float) -> Unit)? = null,
) {
    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .pointerInput(bars, onSeek) {
                if (onSeek != null) {
                    detectTapGestures { offset ->
                        val fraction = (offset.x / size.width).coerceIn(0f, 1f)
                        onSeek(fraction)
                    }
                }
            },
    ) {
        if (bars.isEmpty()) return@Canvas
        val barWidth = size.width / (bars.size * 1.8f)
        val gap = (size.width - barWidth * bars.size) / (bars.size - 1).coerceAtLeast(1)
        val centerY = size.height / 2f
        val playedBars = (progress.coerceIn(0f, 1f) * bars.size).toInt()
        bars.forEachIndexed { index, amplitude ->
            val barHeight = (size.height * amplitude).coerceAtLeast(2f)
            val x = index * (barWidth + gap)
            drawRoundRect(
                color = if (index < playedBars) playedColor else remainingColor,
                topLeft = Offset(x, centerY - barHeight / 2f),
                size = Size(barWidth, barHeight),
                cornerRadius = CornerRadius(barWidth / 2f, barWidth / 2f),
            )
        }
    }
}

/** Pre-computed bars, remembered per attachment. */
@Composable
fun rememberWaveform(seed: String, barCount: Int = 32): List<Float> =
    remember(seed, barCount) { waveformFor(seed, barCount) }
