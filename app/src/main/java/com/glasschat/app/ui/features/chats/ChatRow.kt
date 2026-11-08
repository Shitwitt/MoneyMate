package com.glasschat.app.ui.features.chats

import androidx.compose.animation.SharedTransitionScope
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.VolumeOff
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.domain.model.ChatSummary
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.components.GlassStackedAvatars
import com.glasschat.app.ui.components.GlassSwipeRow
import com.glasschat.app.ui.glass.GlassBadge
import com.glasschat.app.ui.glass.GlassSurface
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.util.TimeFormat

/**
 * One conversation in the list.
 *
 * Swipe right = pin, swipe left = archive/delete. Long-press opens the same actions as a
 * sheet so nothing depends on gestures alone.
 */
@Composable
fun ChatRow(
    summary: ChatSummary,
    sharedTransitionScope: SharedTransitionScope,
    animatedVisibilityScope: androidx.compose.animation.AnimatedVisibilityScope,
    blurMedia: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
    onTogglePin: () -> Unit,
    onArchive: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val unread = summary.unreadCount
    val titleColor = colors.textPrimary
    val avatarAccent = summary.primaryContact?.accentColor?.let { Color(it) } ?: colors.accent
    val sharedAvatar = with(sharedTransitionScope) {
        Modifier.sharedElement(
            state = rememberSharedContentState(key = "chat-avatar-${summary.chat.id}"),
            animatedVisibilityScope = animatedVisibilityScope,
        )
    }
    val elevation by animateFloatAsState(
        targetValue = if (unread > 0) 12f else 6f,
        label = "row-elevation",
    )

    GlassSwipeRow(
        modifier = modifier,
        onSwipeRight = onTogglePin,
        onArchive = onArchive,
        onDelete = onDelete,
        content = {
            GlassSurface(
                modifier = Modifier
                    .fillMaxWidth()
                    .combinedClickable(onClick = onClick, onLongClick = onLongClick)
                    .semantics {
                        contentDescription = buildString {
                            append(summary.displayTitle)
                            if (unread > 0) append(", $unread unread")
                            append(", ${summary.lastMessagePreview}")
                        }
                    },
                shape = RoundedCornerShape(GlassRadius.card),
                fill = if (unread > 0) colors.glassFillStrong else colors.glassFill,
                shadowElevation = elevation.dp,
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 14.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    if (summary.isGroup) {
                        GlassStackedAvatars(
                            names = summary.participants.map { it.name },
                            accents = summary.participants.map { Color(it.accentColor) },
                            modifier = sharedAvatar,
                        )
                    } else {
                        GlassAvatar(
                            name = summary.displayTitle,
                            accentColor = avatarAccent,
                            avatarUri = summary.primaryContact?.avatarUri,
                            modifier = sharedAvatar,
                            size = 46.dp,
                        )
                    }
                    Spacer(Modifier.width(13.dp))
                    Column(Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = summary.displayTitle,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = if (unread > 0) FontWeight.SemiBold else FontWeight.Medium,
                                color = titleColor,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f, fill = false),
                            )
                            if (summary.chat.isPinned) {
                                Spacer(Modifier.width(5.dp))
                                Icon(
                                    imageVector = Icons.Filled.PushPin,
                                    contentDescription = "Pinned",
                                    tint = colors.accent,
                                    modifier = Modifier.size(13.dp),
                                )
                            }
                            if (summary.chat.isMuted) {
                                Spacer(Modifier.width(5.dp))
                                Icon(
                                    imageVector = Icons.Outlined.VolumeOff,
                                    contentDescription = "Muted",
                                    tint = colors.textTertiary,
                                    modifier = Modifier.size(14.dp),
                                )
                            }
                            Spacer(Modifier.width(8.dp))
                            Text(
                                text = summary.lastMessageAt?.let { TimeFormat.chatList(it) } ?: "",
                                style = MaterialTheme.typography.labelSmall,
                                color = if (unread > 0) colors.accent else colors.textTertiary,
                                maxLines = 1,
                            )
                        }
                        Spacer(Modifier.height(3.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = summary.lastMessagePreview,
                                style = MaterialTheme.typography.bodySmall,
                                color = if (unread > 0) colors.textSecondary else colors.textTertiary,
                                maxLines = if (unread > 0) 2 else 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f),
                            )
                            if (unread > 0) {
                                Spacer(Modifier.width(8.dp))
                                GlassBadge(count = unread, muted = summary.chat.isMuted)
                            } else if (
                                summary.lastAttachmentType == AttachmentType.IMAGE ||
                                summary.lastAttachmentType == AttachmentType.VIDEO
                            ) {
                                Spacer(Modifier.width(8.dp))
                                ChatThumbnail(
                                    uri = summary.lastAttachmentUri,
                                    blurred = blurMedia,
                                )
                            }
                        }
                    }
                }
            }
        },
    )
}

/** Tiny media preview used by the list; honours the "blur media in list" privacy setting. */
@Composable
private fun ChatThumbnail(
    uri: String?,
    blurred: Boolean,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val shape = remember { RoundedCornerShape(9.dp) }
    val blurModifier = if (blurred) Modifier.blur(16.dp) else Modifier
    Box(
        modifier = modifier
            .size(34.dp)
            .clip(shape)
            .background(colors.mediaPlaceholder),
        contentAlignment = Alignment.Center,
    ) {
        if (uri != null) {
            AsyncImage(
                model = uri,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(34.dp)
                    .then(blurModifier)
                    .clip(shape),
            )
        } else {
            Icon(
                imageVector = Icons.Outlined.Image,
                contentDescription = null,
                tint = colors.textTertiary,
                modifier = Modifier.size(16.dp),
            )
        }
        if (blurred) {
            // A frosted veil guarantees the preview is unreadable even on API < 31, where
            // Modifier.blur is a no-op.
            Box(
                Modifier
                    .size(34.dp)
                    .clip(shape)
                    .background(Color.Black.copy(alpha = 0.45f)),
            )
        }
    }
}

@Composable
fun EmptyChatsPlaceholder(
    hasChats: Boolean,
    onNewChat: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = if (hasChats) "No conversations match that search" else "A quiet, private place to write",
            style = MaterialTheme.typography.titleLarge,
            color = colors.textPrimary,
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = if (hasChats) {
                "Try a different name, or clear the search field."
            } else {
                "Create a chat with anyone — real or imagined. You write both sides, and everything stays on this device."
            },
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textSecondary,
        )
        if (!hasChats) {
            Spacer(Modifier.height(16.dp))
            com.glasschat.app.ui.glass.GlassChip(
                label = "Start a chat",
                selected = true,
                onClick = onNewChat,
            )
        }
    }
}
