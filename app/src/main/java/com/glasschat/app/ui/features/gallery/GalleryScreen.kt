package com.glasschat.app.ui.features.gallery

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Image
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.MediaItem
import com.glasschat.app.ui.components.ListCaption
import com.glasschat.app.ui.features.chat.PlayOverlay
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassEmptyState
import com.glasschat.app.ui.glass.GlassLoadingState
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.navigation.GlassTab
import com.glasschat.app.ui.navigation.GlassTabBar
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.util.TimeFormat
import com.glasschat.app.util.formatBytes
import com.glasschat.app.util.formatDuration

@Composable
fun GalleryScreen(
    onOpenMedia: (String, String) -> Unit,
    onSelectTab: (GlassTab) -> Unit,
    viewModel: GalleryViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current

    GlassScaffold(
        topBar = {
            GlassTopBar(
                title = "Media",
                subtitle = "${state.totalCount} items across ${state.groups.size} chats",
            )
        },
        bottomBar = { GlassTabBar(selected = GlassTab.GALLERY, onSelect = onSelectTab) },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(items = MediaFilter.entries.toList(), key = { it.name }) { filter ->
                    GlassChip(
                        label = filter.label,
                        selected = state.filter == filter,
                        onClick = { viewModel.setFilter(filter) },
                    )
                }
            }
            when {
                state.isLoading -> GlassLoadingState("Gathering media…")
                state.groups.isEmpty() -> GlassEmptyState(
                    icon = Icons.Filled.Image,
                    title = "Nothing here yet",
                    body = "Photos, videos, voice notes and documents you attach to a chat are collected here.",
                    actionLabel = "Open chats",
                    onAction = { onSelectTab(GlassTab.CHATS) },
                )

                else -> LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    state.groups.forEach { group ->
                        item(key = "group-${group.chatId}") {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 12.dp, bottom = 2.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Text(
                                    text = group.chatTitle,
                                    style = MaterialTheme.typography.titleSmall,
                                    color = colors.textPrimary,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.weight(1f),
                                )
                                Text(
                                    text = "${group.items.size}",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = colors.textTertiary,
                                )
                            }
                        }
                        items(items = group.items.chunked(3), key = { row -> "${group.chatId}-${row.first().attachment.id}" }) { row ->
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                            ) {
                                row.forEach { item ->
                                    MediaTile(
                                        item = item,
                                        modifier = Modifier.weight(1f),
                                        onClick = { onOpenMedia(item.chatId, item.messageId) },
                                    )
                                }
                                repeat(3 - row.size) {
                                    Spacer(Modifier.weight(1f))
                                }
                            }
                        }
                    }
                    item {
                        Spacer(Modifier.height(8.dp))
                        ListCaption("Media lives in private app storage. Deleting a chat deletes its media.")
                    }
                }
            }
        }
    }
}

@Composable
private fun MediaTile(
    item: MediaItem,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val colors = LocalGlassColors.current
    val type = item.attachment.type
    Box(
        modifier = modifier
            .aspectRatio(1f)
            .clip(RoundedCornerShape(16.dp))
            .background(colors.mediaPlaceholder)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        when (type) {
            AttachmentType.IMAGE, AttachmentType.VIDEO -> {
                AsyncImage(
                    model = item.attachment.localUri,
                    contentDescription = if (type == AttachmentType.VIDEO) "Video" else "Photo",
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize(),
                )
                if (type == AttachmentType.VIDEO) {
                    PlayOverlay()
                }
            }

            AttachmentType.AUDIO -> Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(text = "🎧", style = MaterialTheme.typography.headlineSmall)
                Text(
                    text = item.attachment.durationMs?.let { formatDuration(it) } ?: "Audio",
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.textSecondary,
                )
            }

            AttachmentType.DOCUMENT -> Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(6.dp),
            ) {
                Text(text = "📄", style = MaterialTheme.typography.headlineSmall)
                Text(
                    text = item.attachment.fileName ?: "File",
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.textSecondary,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    text = formatBytes(item.attachment.sizeBytes),
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.textTertiary,
                )
            }
        }
    }
}
