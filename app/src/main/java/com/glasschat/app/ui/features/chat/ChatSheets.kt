package com.glasschat.app.ui.features.chat

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.AttachFile
import androidx.compose.material.icons.outlined.CameraAlt
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.InsertDriveFile
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.outlined.Reply
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.VolumeOff
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.glasschat.app.domain.model.Message
import com.glasschat.app.domain.model.Participant
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.ui.components.QuickReactionBar
import com.glasschat.app.ui.glass.GlassSegmentedControl
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassSheet
import com.glasschat.app.ui.glass.GlassSwitch
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.util.TimeFormat

/**
 * Long-press menu for a message: reactions (as either participant), reply, copy, star, edit
 * and the two delete modes, plus a clearly-labelled simulated delivery read-out.
 */
@Composable
fun MessageActionsSheet(
    message: Message,
    meName: String,
    contactName: String,
    participants: List<Participant>,
    onDismiss: () -> Unit,
    onReply: () -> Unit,
    onCopy: () -> Unit,
    onToggleStar: () -> Unit,
    onEdit: () -> Unit,
    onDeleteForMe: () -> Unit,
    onDeleteForEveryone: () -> Unit,
    onReact: (String, SenderType, String?) -> Unit,
) {
    val colors = LocalGlassColors.current
    val identities = remember(participants) { listOf(SenderType.ME) + participants.map { SenderType.CONTACT } }
    var identityIndex by remember { mutableStateOf(0) }
    val activeIdentity = identities.getOrNull(identityIndex) ?: SenderType.ME
    val activeName = if (activeIdentity == SenderType.ME) {
        meName
    } else {
        participants.firstOrNull()?.name ?: contactName
    }

    GlassSheet(onDismissRequest = onDismiss) {
        Column(Modifier.padding(bottom = 26.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 18.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "React as",
                    style = MaterialTheme.typography.labelMedium,
                    color = colors.textTertiary,
                    modifier = Modifier.weight(1f),
                )
                if (identities.size > 1) {
                    GlassSegmentedControl(
                        options = identities,
                        selected = activeIdentity,
                        onSelect = { type ->
                            identityIndex = identities.indexOf(type).coerceAtLeast(0)
                        },
                        label = { type ->
                            if (type == SenderType.ME) {
                                meName
                            } else {
                                participants.firstOrNull()?.name?.substringBefore(' ') ?: contactName
                            }
                        },
                    )
                }
            }
            QuickReactionBar(
                onPick = { emoji ->
                    onReact(
                        emoji,
                        activeIdentity,
                        if (activeIdentity == SenderType.CONTACT) {
                            participants.firstOrNull()?.contactId
                        } else {
                            null
                        },
                    )
                },
            )
            Spacer(Modifier.height(6.dp))
            if (!message.isDeleted) {
                GlassSettingRow(title = "Reply", icon = Icons.Outlined.Reply, onClick = onReply)
            }
            if (message.text.isNotBlank() && !message.isDeleted) {
                GlassSettingRow(title = "Copy text", icon = Icons.Outlined.ContentCopy, onClick = onCopy)
            }
            GlassSettingRow(
                title = if (message.isStarred) "Remove star" else "Star message",
                icon = Icons.Filled.Star,
                iconTint = colors.warning,
                onClick = onToggleStar,
            )
            if (message.isFromMe && !message.isDeleted) {
                GlassSettingRow(
                    title = "Edit message",
                    icon = Icons.Outlined.Edit,
                    onClick = onEdit,
                )
            }
            GlassSettingRow(
                title = "Delete for me",
                icon = Icons.Outlined.Delete,
                iconTint = colors.danger,
                onClick = onDeleteForMe,
            )
            if (message.isFromMe && !message.isDeleted) {
                GlassSettingRow(
                    title = "Delete for everyone",
                    subtitle = "Removes the message from this simulated thread",
                    icon = Icons.Outlined.Delete,
                    iconTint = colors.danger,
                    onClick = onDeleteForEveryone,
                )
            }
            Spacer(Modifier.height(8.dp))
            Text(
                text = buildString {
                    append("Sent ${TimeFormat.full(message.createdAt)}")
                    if (message.editedAt != null) append(" · edited")
                    append(" · simulated ")
                    append(message.status.name.removePrefix("SIMULATED_").lowercase())
                    append(" (no message leaves this device)")
                },
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
                modifier = Modifier.padding(horizontal = 18.dp),
            )
        }
    }
}

/** Attachment chooser: system pickers everywhere, no storage permission required. */
@Composable
fun AttachmentSheet(
    onDismiss: () -> Unit,
    onPhoto: () -> Unit,
    onVideo: () -> Unit,
    onDocument: () -> Unit,
    onAudioFile: () -> Unit,
    onCamera: () -> Unit,
    onVoiceNote: () -> Unit,
    onLocation: () -> Unit,
    onContactCard: () -> Unit,
) {
    val colors = LocalGlassColors.current
    GlassSheet(onDismissRequest = onDismiss) {
        Column(Modifier.padding(bottom = 26.dp)) {
            Text(
                text = "Attach",
                style = MaterialTheme.typography.headlineSmall,
                color = colors.textPrimary,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp),
            )
            Text(
                text = "Files are copied into private app storage. Your originals are never modified.",
                style = MaterialTheme.typography.bodySmall,
                color = colors.textSecondary,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 2.dp),
            )
            Spacer(Modifier.height(6.dp))
            GlassSettingRow(title = "Photo", icon = Icons.Outlined.Image, onClick = onPhoto)
            GlassSettingRow(title = "Video", icon = Icons.Outlined.Videocam, onClick = onVideo)
            GlassSettingRow(title = "Document", icon = Icons.Outlined.InsertDriveFile, onClick = onDocument)
            GlassSettingRow(title = "Audio file", icon = Icons.Outlined.AttachFile, onClick = onAudioFile)
            GlassSettingRow(title = "Take a photo", icon = Icons.Outlined.CameraAlt, onClick = onCamera)
            GlassSettingRow(title = "Record a voice note", icon = Icons.Outlined.Mic, onClick = onVoiceNote)
            GlassSettingRow(
                title = "Location (placeholder)",
                subtitle = "Adds a local placeholder card — no GPS is used",
                icon = Icons.Outlined.LocationOn,
                onClick = onLocation,
            )
            GlassSettingRow(
                title = "Contact card (placeholder)",
                subtitle = "Shares one of your fictional contacts as text",
                icon = Icons.Outlined.Person,
                onClick = onContactCard,
            )
        }
    }
}

@Composable
fun EmojiSheet(
    onDismiss: () -> Unit,
    onPick: (String) -> Unit,
) {
    val colors = LocalGlassColors.current
    GlassSheet(onDismissRequest = onDismiss) {
        Column(Modifier.padding(bottom = 18.dp)) {
            Text(
                text = "Emoji",
                style = MaterialTheme.typography.headlineSmall,
                color = colors.textPrimary,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp),
            )
            com.glasschat.app.ui.components.EmojiPicker(
                onPick = onPick,
                modifier = Modifier.padding(horizontal = 6.dp),
            )
        }
    }
}

/** Top-bar overflow menu. Every row mirrors an action also reachable elsewhere. */
@Composable
fun ChatMenuSheet(
    muted: Boolean,
    pinned: Boolean,
    simulateTyping: Boolean,
    starredOnly: Boolean,
    onDismiss: () -> Unit,
    onToggleTyping: () -> Unit,
    onToggleStarredOnly: () -> Unit,
    onMarkUnread: () -> Unit,
    onToggleMute: () -> Unit,
    onTogglePin: () -> Unit,
    onArchive: () -> Unit,
    onSearch: () -> Unit,
    onOpenSettings: () -> Unit,
    onClearMessages: () -> Unit,
    onDeleteChat: () -> Unit,
) {
    val colors = LocalGlassColors.current
    GlassSheet(onDismissRequest = onDismiss) {
        Column(Modifier.padding(bottom = 26.dp)) {
            Text(
                text = "Chat options",
                style = MaterialTheme.typography.headlineSmall,
                color = colors.textPrimary,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp),
            )
            GlassSettingRow(
                title = "Simulate typing",
                subtitle = "Shows an animated typing bubble labelled as simulated",
                icon = Icons.Outlined.Mic,
                onClick = onToggleTyping,
                trailing = {
                    GlassSwitch(checked = simulateTyping, onCheckedChange = { onToggleTyping() })
                },
            )
            GlassSettingRow(
                title = "Starred messages",
                subtitle = if (starredOnly) "Showing starred only" else "Filter this conversation",
                icon = Icons.Filled.Star,
                onClick = onToggleStarredOnly,
            )
            GlassSettingRow(title = "Search in chat", icon = Icons.Outlined.Search, onClick = onSearch)
            GlassSettingRow(title = "Mark as unread", icon = Icons.Outlined.Reply, onClick = onMarkUnread)
            GlassSettingRow(
                title = if (muted) "Unmute" else "Mute",
                icon = Icons.Outlined.VolumeOff,
                onClick = onToggleMute,
            )
            GlassSettingRow(
                title = if (pinned) "Unpin" else "Pin",
                icon = Icons.Outlined.PushPin,
                onClick = onTogglePin,
            )
            GlassSettingRow(title = "Archive", icon = Icons.Outlined.Archive, onClick = onArchive)
            GlassSettingRow(
                title = "Chat settings",
                subtitle = "Name, avatar, wallpaper, bubbles, participants",
                icon = Icons.Outlined.Edit,
                onClick = onOpenSettings,
            )
            GlassSettingRow(
                title = "Clear messages",
                icon = Icons.Outlined.Delete,
                iconTint = colors.danger,
                onClick = onClearMessages,
            )
            GlassSettingRow(
                title = "Delete chat",
                icon = Icons.Outlined.Delete,
                iconTint = colors.danger,
                onClick = onDeleteChat,
            )
        }
    }
}

/** Lets group chats pick which fictional participant is speaking. */
@Composable
fun ParticipantPickerSheet(
    participants: List<Participant>,
    onDismiss: () -> Unit,
    onPick: (Participant) -> Unit,
) {
    val colors = LocalGlassColors.current
    GlassSheet(onDismissRequest = onDismiss) {
        Column(Modifier.padding(bottom = 26.dp)) {
            Text(
                text = "Write as",
                style = MaterialTheme.typography.headlineSmall,
                color = colors.textPrimary,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp),
            )
            participants.forEach { participant ->
                GlassSettingRow(
                    title = participant.name,
                    subtitle = if (participant.role == com.glasschat.app.domain.model.ParticipantRole.OWNER) {
                        "Owner"
                    } else {
                        "Member"
                    },
                    onClick = { onPick(participant) },
                )
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Spacer(Modifier.width(4.dp))
                Text(
                    text = "Every participant here is fictional and exists only on this device.",
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.textTertiary,
                )
            }
        }
    }
}
