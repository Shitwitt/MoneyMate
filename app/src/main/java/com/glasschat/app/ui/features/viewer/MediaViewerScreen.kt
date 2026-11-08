package com.glasschat.app.ui.features.viewer

import android.net.Uri
import android.widget.MediaController
import android.widget.VideoView
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.InsertDriveFile
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.glasschat.app.domain.model.Attachment
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.ui.components.LocalGlassAudioPlayer
import com.glasschat.app.ui.components.rememberGlassAudioPlayer
import com.glasschat.app.ui.features.chat.AudioAttachmentView
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassDialog
import com.glasschat.app.ui.glass.GlassIconButton
import com.glasschat.app.ui.glass.GlassLoadingState
import com.glasschat.app.ui.glass.GlassSnackbarHost
import com.glasschat.app.ui.glass.GlassSurface
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.util.TimeFormat
import com.glasschat.app.util.formatBytes
import kotlinx.coroutines.launch

/**
 * Full-screen media viewer: pinch-to-zoom photos, inline video playback, waveform audio and
 * document details — with save-to-device and delete actions.
 */
@Composable
fun MediaViewerScreen(
    onBack: () -> Unit,
    viewModel: MediaViewerViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    val audioPlayer = rememberGlassAudioPlayer()
    var confirmDelete by remember { mutableStateOf(false) }
    var pendingSave by remember { mutableStateOf<Attachment?>(null) }

    val saveLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.CreateDocument("application/octet-stream"),
    ) { uri ->
        val attachment = pendingSave
        pendingSave = null
        if (uri != null && attachment != null) {
            viewModel.saveTo(uri.toString(), attachment.id) { success ->
                scope.launch {
                    snackbarHostState.showSnackbar(
                        if (success) "Saved a copy to the chosen location" else "Could not save that file",
                    )
                }
            }
        }
    }

    if (state.isLoading) {
        Box(Modifier.fillMaxSize().background(colors.scrim)) {
            GlassLoadingState("Opening media…")
        }
        return
    }

    if (state.items.isEmpty()) {
        Box(Modifier.fillMaxSize().background(colors.scrim), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "This media is no longer available",
                    style = MaterialTheme.typography.titleLarge,
                    color = colors.textPrimary,
                )
                Spacer(Modifier.height(10.dp))
                GlassChip(label = "Close", selected = true, onClick = onBack)
            }
        }
        return
    }

    val pagerState = rememberPagerState(initialPage = 0, pageCount = { state.items.size })
    LaunchedEffect(state.initialIndex, state.items.size) {
        if (state.items.isNotEmpty()) {
            pagerState.scrollToPage(state.initialIndex.coerceIn(0, state.items.lastIndex))
        }
    }
    var zoomed by remember { mutableStateOf(false) }
    val current = state.items.getOrNull(pagerState.currentPage) ?: state.items.first()

    Box(Modifier.fillMaxSize().background(androidx.compose.ui.graphics.Color.Black)) {
        HorizontalPager(
            state = pagerState,
            userScrollEnabled = !zoomed,
            modifier = Modifier.fillMaxSize(),
            key = { index -> state.items[index].attachment.id },
        ) { page ->
            val item = state.items[page]
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                when (item.attachment.type) {
                    AttachmentType.IMAGE -> ZoomableImage(
                        uri = item.attachment.localUri,
                        onZoomChanged = { zoomed = it },
                    )

                    AttachmentType.VIDEO -> VideoAttachmentPlayer(
                        uri = item.attachment.localUri,
                        modifier = Modifier.fillMaxWidth(),
                    )

                    AttachmentType.AUDIO -> {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            Text(text = "🎧", style = MaterialTheme.typography.displayLarge)
                            Spacer(Modifier.height(18.dp))
                            GlassSurface(
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(GlassRadius.card),
                                fill = colors.glassFillStrong,
                            ) {
                                Box(Modifier.padding(16.dp)) {
                                    androidx.compose.runtime.CompositionLocalProvider(
                                        LocalGlassAudioPlayer provides audioPlayer,
                                    ) {
                                        AudioAttachmentView(attachment = item.attachment, isFromMe = false)
                                    }
                                }
                            }
                        }
                    }

                    AttachmentType.DOCUMENT -> {
                        Column(
                            modifier = Modifier.padding(28.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.InsertDriveFile,
                                contentDescription = null,
                                tint = colors.accent,
                                modifier = Modifier.size(64.dp),
                            )
                            Spacer(Modifier.height(14.dp))
                            Text(
                                text = item.attachment.fileName ?: "Document",
                                style = MaterialTheme.typography.titleLarge,
                                color = colors.textPrimary,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                            )
                            Text(
                                text = formatBytes(item.attachment.sizeBytes),
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.textSecondary,
                            )
                        }
                    }
                }
            }
        }

        // Top overlay chrome
        Row(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            GlassIconButton(
                icon = Icons.Filled.Close,
                contentDescription = "Close viewer",
                tint = androidx.compose.ui.graphics.Color.White,
                background = androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.35f),
                onClick = onBack,
            )
            Spacer(Modifier.width(10.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    text = current.chatTitle,
                    style = MaterialTheme.typography.titleMedium,
                    color = androidx.compose.ui.graphics.Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    text = "${TimeFormat.full(current.createdAt)} · ${current.senderLabel}",
                    style = MaterialTheme.typography.labelSmall,
                    color = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.72f),
                )
            }
            GlassIconButton(
                icon = Icons.Outlined.Download,
                contentDescription = "Save a copy",
                tint = androidx.compose.ui.graphics.Color.White,
                background = androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.35f),
                onClick = {
                    pendingSave = current.attachment
                    saveLauncher.launch(current.attachment.fileName ?: "glasschat-media")
                },
            )
            GlassIconButton(
                icon = Icons.Outlined.Delete,
                contentDescription = "Delete media",
                tint = androidx.compose.ui.graphics.Color.White,
                background = androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.35f),
                onClick = { confirmDelete = true },
            )
        }

        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            GlassSnackbarHost(snackbarHostState)
            Spacer(Modifier.height(6.dp))
            GlassChip(
                label = "${pagerState.currentPage + 1} / ${state.items.size}",
                onClick = {},
            )
        }
    }

    if (confirmDelete) {
        GlassDialog(
            title = "Delete this media?",
            message = "The file is removed from app storage. The message text stays, but the attachment disappears.",
            confirmLabel = "Delete",
            destructive = true,
            onConfirm = {
                confirmDelete = false
                val attachment = current.attachment
                viewModel.delete(attachment.id) {
                    if (state.items.size <= 1) onBack()
                }
            },
            onDismiss = { confirmDelete = false },
        )
    }
}

/** Pinch-to-zoom + double-tap-to-reset image surface. */
@Composable
private fun ZoomableImage(
    uri: String,
    onZoomChanged: (Boolean) -> Unit,
) {
    var scale by remember(uri) { mutableFloatStateOf(1f) }
    var offset by remember(uri) { mutableStateOf(Offset.Zero) }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .pointerInput(uri) {
                detectTransformGestures { _, pan, zoom, _ ->
                    scale = (scale * zoom).coerceIn(1f, 5f)
                    offset = if (scale > 1f) offset + pan else Offset.Zero
                    onZoomChanged(scale > 1.01f)
                }
            }
            .pointerInput(uri) {
                detectTapGestures(
                    onDoubleTap = {
                        scale = 1f
                        offset = Offset.Zero
                        onZoomChanged(false)
                    },
                )
            },
        contentAlignment = Alignment.Center,
    ) {
        AsyncImage(
            model = uri,
            contentDescription = "Full screen media",
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer(
                    scaleX = scale,
                    scaleY = scale,
                    translationX = offset.x,
                    translationY = offset.y,
                ),
        )
    }
}

/** Minimal inline video player. Playback stops as soon as the screen leaves composition. */
@Composable
private fun VideoAttachmentPlayer(
    uri: String,
    modifier: Modifier = Modifier,
) {
    var videoView by remember { mutableStateOf<VideoView?>(null) }
    AndroidView(
        modifier = modifier,
        factory = { ctx ->
            VideoView(ctx).apply {
                setVideoURI(Uri.parse(uri))
                setMediaController(
                    MediaController(ctx).also { controller ->
                        controller.setAnchorView(this)
                    },
                )
                setOnPreparedListener { player ->
                    player.isLooping = false
                    start()
                }
            }.also { videoView = it }
        },
        update = { view ->
            if (view.tag != uri) {
                view.tag = uri
                view.setVideoURI(Uri.parse(uri))
                view.start()
            }
        },
    )
    DisposableEffect(uri) {
        onDispose {
            videoView?.stopPlayback()
            videoView = null
        }
    }
}
