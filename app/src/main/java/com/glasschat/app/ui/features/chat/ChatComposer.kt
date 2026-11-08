package com.glasschat.app.ui.features.chat

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.AttachFile
import androidx.compose.material.icons.outlined.Backspace
import androidx.compose.material.icons.outlined.CameraAlt
import androidx.compose.material.icons.outlined.EmojiEmotions
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.Stop
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardOptions
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.domain.model.Participant
import com.glasschat.app.domain.model.PendingAttachment
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.glass.GlassIconButton
import com.glasschat.app.ui.glass.GlassSegmentedControl
import com.glasschat.app.ui.glass.GlassSurface
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.util.formatDuration

private sealed interface SenderOption {
    data object Me : SenderOption
    data class Other(val participant: Participant?) : SenderOption
}

/**
 * The composer. Three ideas keep the "who am I writing as" question unmistakable:
 *  * a segmented Me / contact switch directly above the field,
 *  * the field border and send button adopt the active sender's colour,
 *  * the placeholder spells out the identity ("Message as Maya").
 */
@Composable
fun ChatComposer(
    state: ChatUiState,
    onDraftChange: (String) -> Unit,
    onSend: () -> Unit,
    onSenderSelected: (SenderType, String?) -> Unit,
    onPickGroupSender: () -> Unit,
    onAttachClick: () -> Unit,
    onEmojiClick: () -> Unit,
    onCameraClick: () -> Unit,
    onMicClick: () -> Unit,
    onStopRecording: () -> Unit,
    onCancelRecording: () -> Unit,
    onCancelReply: () -> Unit,
    onCancelEdit: () -> Unit,
    onRemovePending: (Int) -> Unit,
    onCaptionChange: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val prefs = state.preferences
    val activeParticipant = state.participants.firstOrNull { it.contactId == state.senderContactId }
    val senderAccent = when (state.senderType) {
        SenderType.ME -> Color(state.accentColor).takeIf { it != Color(0L) } ?: colors.accent
        SenderType.CONTACT -> activeParticipant?.accentColor?.let { Color(it) } ?: colors.accent
    }
    val canSend = state.draft.isNotBlank() || state.pendingAttachments.isNotEmpty()
    val options = listOf(
        SenderOption.Me,
        SenderOption.Other(activeParticipant ?: state.contact?.let {
            Participant(it.id, it.name, it.avatarUri, it.accentColor, com.glasschat.app.domain.model.ParticipantRole.MEMBER)
        }),
    )
    val selected = if (state.senderType == SenderType.ME) {
        SenderOption.Me
    } else {
        options[1]
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .imePadding()
            .navigationBarsPadding()
            .padding(horizontal = 10.dp, vertical = 8.dp),
    ) {
        AnimatedVisibility(
            visible = state.replyTo != null || state.editing != null,
            enter = fadeIn() + expandVertically(),
            exit = fadeOut() + shrinkVertically(),
        ) {
            ComposerBanner(
                title = if (state.editing != null) "Editing message" else "Replying to ${state.replyTo?.senderLabel.orEmpty()}",
                body = (state.editing ?: state.replyTo)?.text.orEmpty().ifBlank { "Attachment" },
                tint = senderAccent,
                onCancel = { if (state.editing != null) onCancelEdit() else onCancelReply() },
            )
        }

        if (state.pendingAttachments.isNotEmpty()) {
            PendingAttachmentStrip(
                attachments = state.pendingAttachments,
                onRemove = onRemovePending,
                onCaptionChange = onCaptionChange,
            )
        }

        if (state.isRecording) {
            RecordingBanner(
                elapsedMs = state.recordingElapsedMs,
                onCancel = onCancelRecording,
                onStop = onStopRecording,
            )
        } else {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                GlassSegmentedControl(
                    options = options,
                    selected = selected,
                    onSelect = { option ->
                        when (option) {
                            is SenderOption.Me -> onSenderSelected(SenderType.ME, null)
                            is SenderOption.Other -> {
                                if (state.isGroup) {
                                    onPickGroupSender()
                                } else {
                                    onSenderSelected(SenderType.CONTACT, option.participant?.contactId)
                                }
                            }
                        }
                    },
                    label = { option ->
                        when (option) {
                            is SenderOption.Me -> prefs.displayName.ifBlank { "Me" }
                            is SenderOption.Other -> option.participant?.name?.substringBefore(' ') ?: "Contact"
                        }
                    },
                    accentFor = { option ->
                        when (option) {
                            is SenderOption.Me -> colors.accent
                            is SenderOption.Other -> option.participant?.accentColor?.let { Color(it) }
                                ?: colors.accent
                        }
                    },
                )
                Spacer(Modifier.weight(1f))
                Text(
                    text = if (state.isGroup) {
                        "Sending as ${state.activeSenderName}"
                    } else {
                        "Sending as ${state.activeSenderName}"
                    },
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.textTertiary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Spacer(Modifier.height(7.dp))
        }

        Row(verticalAlignment = Alignment.Bottom) {
            GlassSurface(
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(GlassRadius.field),
                fill = colors.glassFillStrong,
                borderColor = senderAccent.copy(alpha = 0.45f),
                shadowElevation = 8.dp,
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 52.dp)
                        .padding(horizontal = 4.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.Bottom,
                ) {
                    GlassIconButton(
                        icon = Icons.Outlined.AttachFile,
                        contentDescription = "Attach a file",
                        background = null,
                        tint = colors.textSecondary,
                        onClick = onAttachClick,
                    )
                    BasicTextField(
                        value = state.draft,
                        onValueChange = onDraftChange,
                        modifier = Modifier
                            .weight(1f)
                            .padding(vertical = 12.dp)
                            .semantics { contentDescription = "Message field" },
                        textStyle = MaterialTheme.typography.bodyLarge.copy(color = colors.textPrimary),
                        cursorBrush = SolidColor(senderAccent),
                        maxLines = 6,
                        keyboardOptions = KeyboardOptions(
                            capitalization = KeyboardCapitalization.Sentences,
                            imeAction = if (prefs.enterToSend) ImeAction.Send else ImeAction.Default,
                        ),
                        keyboardActions = KeyboardActions(
                            onSend = { if (prefs.enterToSend) onSend() },
                        ),
                        decorationBox = { inner ->
                            Box {
                                if (state.draft.isEmpty()) {
                                    Text(
                                        text = if (state.editing != null) {
                                            "Edit message"
                                        } else {
                                            "Message as ${state.activeSenderName}"
                                        },
                                        style = MaterialTheme.typography.bodyLarge,
                                        color = colors.textTertiary,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis,
                                    )
                                }
                                inner()
                            }
                        },
                    )
                    GlassIconButton(
                        icon = Icons.Outlined.EmojiEmotions,
                        contentDescription = "Open emoji picker",
                        background = null,
                        tint = colors.textSecondary,
                        onClick = onEmojiClick,
                    )
                    GlassIconButton(
                        icon = Icons.Outlined.CameraAlt,
                        contentDescription = "Take a photo",
                        background = null,
                        tint = colors.textSecondary,
                        onClick = onCameraClick,
                    )
                }
            }
            Spacer(Modifier.width(8.dp))
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .clip(CircleShape)
                    .background(senderAccent)
                    .border(1.dp, Color.White.copy(alpha = 0.28f), CircleShape)
                    .semantics {
                        contentDescription = if (canSend) "Send message" else "Record a voice note"
                    },
                contentAlignment = Alignment.Center,
            ) {
                GlassIconButton(
                    icon = if (canSend) Icons.AutoMirrored.Filled.Send else Icons.Outlined.Mic,
                    contentDescription = if (canSend) "Send message" else "Record a voice note",
                    tint = colors.onAccent,
                    background = null,
                    size = 50.dp,
                    onClick = { if (canSend) onSend() else onMicClick() },
                )
            }
        }
        if (prefs.showSimulatedStatus) {
            Spacer(Modifier.height(4.dp))
            Text(
                text = "Messages are stored only on this device · delivery indicators are simulated",
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
                modifier = Modifier.padding(start = 6.dp),
            )
        }
    }
}

@Composable
private fun ComposerBanner(
    title: String,
    body: String,
    tint: Color,
    onCancel: () -> Unit,
) {
    val colors = LocalGlassColors.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 6.dp)
            .clip(RoundedCornerShape(GlassRadius.chip))
            .background(colors.glassFill)
            .border(1.dp, colors.glassBorder, RoundedCornerShape(GlassRadius.chip))
            .padding(start = 12.dp, end = 4.dp, top = 6.dp, bottom = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier
                .width(3.dp)
                .height(30.dp)
                .clip(CircleShape)
                .background(tint),
        )
        Spacer(Modifier.width(9.dp))
        Column(Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.labelMedium,
                color = tint,
            )
            Text(
                text = body,
                style = MaterialTheme.typography.labelSmall,
                color = colors.textSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        GlassIconButton(
            icon = Icons.Filled.Close,
            contentDescription = "Cancel",
            background = null,
            tint = colors.textSecondary,
            size = 34.dp,
            onClick = onCancel,
        )
    }
}

@Composable
private fun PendingAttachmentStrip(
    attachments: List<PendingAttachment>,
    onRemove: (Int) -> Unit,
    onCaptionChange: (String) -> Unit,
) {
    val colors = LocalGlassColors.current
    Column(Modifier.padding(bottom = 6.dp)) {
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            itemsIndexed(attachments) { index, pending ->
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(RoundedCornerShape(14.dp))
                        .background(colors.glassFillStrong),
                ) {
                    if (pending.type == com.glasschat.app.domain.model.AttachmentType.IMAGE ||
                        pending.type == com.glasschat.app.domain.model.AttachmentType.VIDEO
                    ) {
                        AsyncImage(
                            model = pending.localUri,
                            contentDescription = "Pending attachment",
                            contentScale = ContentScale.Crop,
                            modifier = Modifier.fillMaxWidth().height(64.dp),
                        )
                    } else {
                        Box(Modifier.size(64.dp), contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = if (pending.type == com.glasschat.app.domain.model.AttachmentType.DOCUMENT) {
                                    Icons.Outlined.AttachFile
                                } else {
                                    Icons.Outlined.Mic
                                },
                                contentDescription = null,
                                tint = colors.textSecondary,
                                modifier = Modifier.size(22.dp),
                            )
                        }
                    }
                    GlassIconButton(
                        icon = Icons.Filled.Close,
                        contentDescription = "Remove attachment",
                        tint = Color.White,
                        background = Color.Black.copy(alpha = 0.45f),
                        size = 24.dp,
                        modifier = Modifier.align(Alignment.TopEnd),
                        onClick = { onRemove(index) },
                    )
                }
            }
        }
        if (attachments.size == 1 && attachments.first().type == com.glasschat.app.domain.model.AttachmentType.IMAGE) {
            BasicTextField(
                value = attachments.first().caption.orEmpty(),
                onValueChange = onCaptionChange,
                textStyle = MaterialTheme.typography.bodySmall.copy(color = colors.textPrimary),
                cursorBrush = SolidColor(colors.accent),
                maxLines = 2,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 6.dp)
                    .clip(RoundedCornerShape(GlassRadius.chip))
                    .background(colors.glassFill)
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                decorationBox = { inner ->
                    Box {
                        if (attachments.first().caption.isNullOrBlank()) {
                            Text(
                                text = "Add a caption…",
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.textTertiary,
                            )
                        }
                        inner()
                    }
                },
            )
        }
    }
}

@Composable
private fun RecordingBanner(
    elapsedMs: Long,
    onCancel: () -> Unit,
    onStop: () -> Unit,
) {
    val colors = LocalGlassColors.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .clip(RoundedCornerShape(GlassRadius.field))
            .background(colors.glassFillStrong)
            .border(1.dp, colors.danger.copy(alpha = 0.5f), RoundedCornerShape(GlassRadius.field))
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier
                .size(10.dp)
                .clip(CircleShape)
                .background(colors.danger),
        )
        Spacer(Modifier.width(10.dp))
        Text(
            text = "Recording · ${formatDuration(elapsedMs)}",
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textPrimary,
            modifier = Modifier.weight(1f),
        )
        GlassIconButton(
            icon = Icons.Outlined.Backspace,
            contentDescription = "Cancel recording",
            background = null,
            tint = colors.textSecondary,
            onClick = onCancel,
        )
        GlassIconButton(
            icon = Icons.Outlined.Stop,
            contentDescription = "Stop recording",
            tint = colors.onAccent,
            background = colors.danger,
            onClick = onStop,
        )
    }
}
