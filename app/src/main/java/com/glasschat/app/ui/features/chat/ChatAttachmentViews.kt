package com.glasschat.app.ui.features.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.InsertDriveFile
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.glasschat.app.domain.model.Attachment
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.ui.components.LocalGlassAudioPlayer
import com.glasschat.app.ui.components.WaveformBars
import com.glasschat.app.ui.components.rememberWaveform
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.util.formatBytes
import com.glasschat.app.util.formatDuration

/**
 * Image / video thumbnail inside a bubble. Media is always the gesture target, and both
 * open the full-screen viewer (which supports zoom, swipe, save and delete).
 */
@Composable
fun ImageAttachmentView(
    attachment: Attachment,
    isFromMe: Boolean,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val shape = RoundedCornerShape(16.dp)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(4f / 3f)
            .clip(shape)
            .background(colors.mediaPlaceholder)
            .clickable(onClick = onOpen),
    ) {
        AsyncImage(
            model = attachment.localUri,
            contentDescription = "Photo attachment",
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxWidth().height(240.dp),
        )
        if (attachment.type == AttachmentType.VIDEO) {
            Box(
                modifier = Modifier
                    .align(Alignment.Center)
                    .size(46.dp)
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.45f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Filled.PlayArrow,
                    contentDescription = "Play video",
                    tint = Color.White,
                    modifier = Modifier.size(24.dp),
                )
            }
        }
        if (attachment.durationMs != null && attachment.type == AttachmentType.VIDEO) {
            Text(
                text = formatDuration(attachment.durationMs),
                style = MaterialTheme.typography.labelSmall,
                color = Color.White,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(8.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(Color.Black.copy(alpha = 0.5f))
                    .padding(horizontal = 6.dp, vertical = 2.dp),
            )
        }
    }
}

/** Voice note row: play/pause, waveform with seek and a duration read-out. */
@Composable
fun AudioAttachmentView(
    attachment: Attachment,
    isFromMe: Boolean,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val player = LocalGlassAudioPlayer.current
    val scope = rememberCoroutineScope()
    val bars = rememberWaveform(seed = attachment.id, barCount = 28)
    val active = player?.activeKey == attachment.id
    val playing = active && player?.isPlaying == true
    val duration = when {
        active && (player?.durationMs ?: 0L) > 0L -> player?.durationMs ?: 0L
        else -> attachment.durationMs ?: 0L
    }
    val position = if (active) player?.positionMs ?: 0L else 0L
    val progress = if (duration > 0L) (position.toFloat() / duration).coerceIn(0f, 1f) else 0f
    val accent = if (isFromMe) colors.bubbleTextMe else colors.accent

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(42.dp)
                .clip(CircleShape)
                .background(if (isFromMe) Color.White.copy(alpha = 0.18f) else colors.accent.copy(alpha = 0.16f))
                .clickable {
                    player?.toggle(attachment.id, attachment.localUri, scope)
                },
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = if (playing) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                contentDescription = if (playing) "Pause voice note" else "Play voice note",
                tint = accent,
                modifier = Modifier.size(22.dp),
            )
        }
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            WaveformBars(
                bars = bars,
                progress = progress,
                playedColor = accent,
                remainingColor = if (isFromMe) {
                    colors.bubbleTextMe.copy(alpha = 0.35f)
                } else {
                    colors.textTertiary.copy(alpha = 0.45f)
                },
                height = 26.dp,
                onSeek = { fraction ->
                    player?.toggle(attachment.id, attachment.localUri, scope)
                    player?.seekToFraction(fraction)
                },
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = formatDuration(if (active && position > 0) position else duration),
                    style = MaterialTheme.typography.labelSmall,
                    color = if (isFromMe) colors.bubbleTextMe.copy(alpha = 0.85f) else colors.textTertiary,
                )
                if (duration > 0L) {
                    Text(
                        text = " · ${formatDuration(duration)}",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isFromMe) colors.bubbleTextMe.copy(alpha = 0.6f) else colors.textTertiary,
                    )
                }
            }
        }
    }
}

/** Document card: type glyph, file name and size. Tapping opens the system viewer. */
@Composable
fun DocumentAttachmentView(
    attachment: Attachment,
    isFromMe: Boolean,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val accent = if (isFromMe) colors.bubbleTextMe else colors.accent
    val icon = if (attachment.mimeType?.startsWith("application/pdf") == true) {
        Icons.Outlined.Description
    } else {
        Icons.Outlined.InsertDriveFile
    }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(if (isFromMe) Color.White.copy(alpha = 0.14f) else colors.glassFill)
            .clickable(onClick = onOpen)
            .padding(horizontal = 10.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(accent.copy(alpha = 0.18f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = accent,
                modifier = Modifier.size(19.dp),
            )
        }
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text(
                text = attachment.fileName ?: "Attachment",
                style = MaterialTheme.typography.bodySmall,
                color = if (isFromMe) colors.bubbleTextMe else colors.textPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = formatBytes(attachment.sizeBytes),
                style = MaterialTheme.typography.labelSmall,
                color = if (isFromMe) colors.bubbleTextMe.copy(alpha = 0.7f) else colors.textTertiary,
            )
        }
    }
}

/** Placeholder card used for the "location" and "contact card" attachment options. */
@Composable
fun PlaceholderAttachmentView(
    title: String,
    subtitle: String,
    isFromMe: Boolean,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val brush = if (isFromMe) {
        Brush.linearGradient(listOf(Color.White.copy(alpha = 0.16f), Color.White.copy(alpha = 0.06f)))
    } else {
        Brush.linearGradient(listOf(colors.accent.copy(alpha = 0.16f), colors.accent.copy(alpha = 0.05f)))
    }
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(brush)
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.labelLarge,
            color = if (isFromMe) colors.bubbleTextMe else colors.textPrimary,
        )
        Text(
            text = subtitle,
            style = MaterialTheme.typography.labelSmall,
            color = if (isFromMe) colors.bubbleTextMe.copy(alpha = 0.75f) else colors.textSecondary,
        )
    }
}

/** Small circular play overlay reused by the media viewer and gallery tiles. */
@Composable
fun PlayOverlay(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = 0.42f)),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = Icons.Outlined.PlayArrow,
            contentDescription = "Play",
            tint = Color.White,
            modifier = Modifier.size(22.dp),
        )
    }
}

/** Remembers the intrinsic aspect ratio of an image so bubbles keep their proportions. */
@Composable
fun rememberAspect(ratio: Float?): Float = remember(ratio) { ratio?.coerceIn(0.6f, 2.2f) ?: (4f / 3f) }
