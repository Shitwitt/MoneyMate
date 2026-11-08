package com.glasschat.app.ui.features.chat

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.glasschat.app.domain.model.Attachment
import com.glasschat.app.domain.model.Message
import com.glasschat.app.ui.components.DaySeparator
import com.glasschat.app.ui.components.SimulatedPill
import com.glasschat.app.ui.components.SimulatedStatusTicks
import com.glasschat.app.ui.glass.GlassSurface
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.ui.theme.LocalReduceMotion
import com.glasschat.app.util.TimeFormat

/**
 * A single message bubble. Everything visual is derived from the message itself plus the
 * chat's bubble colours, so themed chats and the global theme stay independent.
 */
@Composable
fun MessageBubble(
    message: Message,
    isGroup: Boolean,
    showSenderName: Boolean,
    tightTop: Boolean,
    showTimestamps: Boolean,
    showSimulatedStatus: Boolean,
    accentColor: Color,
    bubbleColorMe: Color?,
    bubbleColorOther: Color?,
    maxBubbleWidth: Dp,
    onLongPress: () -> Unit,
    onOpenMedia: (Attachment) -> Unit,
    onOpenDocument: (Attachment) -> Unit,
    onToggleReaction: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val haptics = LocalHapticFeedback.current
    val fromMe = message.isFromMe

    val meBase = bubbleColorMe ?: accentColor
    val meStart = meBase
    val meEnd = lerp(meBase, Color.Black, if (colors.isDark) 0.30f else 0.14f)
    val otherFill = bubbleColorOther ?: colors.bubbleOther
    val bubbleTextColor = if (fromMe) {
        if (meBase.luminance() > 0.62f) Color(0xFF11152A) else Color.White
    } else {
        colors.bubbleTextOther
    }
    val metaColor = if (fromMe) bubbleTextColor.copy(alpha = 0.72f) else colors.textTertiary

    val shape = RoundedCornerShape(
        topStart = if (fromMe) 22.dp else if (tightTop) 8.dp else 22.dp,
        topEnd = if (fromMe) (if (tightTop) 8.dp else 22.dp) else 22.dp,
        bottomEnd = if (fromMe) 8.dp else 22.dp,
        bottomStart = if (fromMe) 22.dp else 8.dp,
    )

    val a11y = buildString {
        append(if (fromMe) "You" else message.senderLabel)
        append(" said: ")
        append(if (message.isDeleted) "message deleted" else message.text)
        if (message.attachments.isNotEmpty()) append(", with attachment")
        append(", at ")
        append(TimeFormat.clock(message.createdAt))
        if (fromMe && showSimulatedStatus) append(", simulated ${message.status.name.lowercase().replace("simulated_", "")}")
    }

    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = if (fromMe) Alignment.End else Alignment.Start,
    ) {
        GlassSurface(
            modifier = Modifier
                .widthIn(max = maxBubbleWidth)
                .combinedClickable(
                    onClick = {},
                    onLongClick = {
                        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                        onLongPress()
                    },
                )
                .semantics { contentDescription = a11y },
            shape = shape,
            fill = otherFill,
            borderColor = if (fromMe) Color.White.copy(alpha = 0.18f) else colors.bubbleOtherBorder,
            shadowElevation = 6.dp,
        ) {
            // Gradient overlay for outgoing bubbles (kept as a layer so the border and
            // sheen from GlassSurface still apply on top).
            if (fromMe) {
                Box(
                    Modifier
                        .matchParentSize()
                        .background(Brush.verticalGradient(listOf(meStart, meEnd))),
                )
            }
            Column(Modifier.padding(horizontal = 12.dp, vertical = 9.dp)) {
                message.replyPreview?.let { preview ->
                    ReplyQuote(
                        senderLabel = preview.senderLabel,
                        text = preview.text,
                        fromMe = fromMe,
                        modifier = Modifier.padding(bottom = 6.dp),
                    )
                }
                if (isGroup && !fromMe && showSenderName && !message.isDeleted) {
                    Text(
                        text = message.senderLabel,
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.accent,
                        modifier = Modifier.padding(bottom = 3.dp),
                    )
                }

                if (message.isDeleted) {
                    Text(
                        text = "This message was deleted",
                        style = MaterialTheme.typography.bodyMedium,
                        fontStyle = FontStyle.Italic,
                        color = metaColor,
                    )
                } else {
                    message.attachments.forEach { attachment ->
                        when (attachment.type) {
                            com.glasschat.app.domain.model.AttachmentType.IMAGE,
                            com.glasschat.app.domain.model.AttachmentType.VIDEO,
                            -> {
                                ImageAttachmentView(
                                    attachment = attachment,
                                    isFromMe = fromMe,
                                    onOpen = { onOpenMedia(attachment) },
                                )
                                if (message.text.isNotBlank() || attachment.caption != null) {
                                    Spacer(Modifier.height(6.dp))
                                }
                            }

                            com.glasschat.app.domain.model.AttachmentType.AUDIO -> {
                                AudioAttachmentView(attachment = attachment, isFromMe = fromMe)
                            }

                            com.glasschat.app.domain.model.AttachmentType.DOCUMENT -> {
                                DocumentAttachmentView(
                                    attachment = attachment,
                                    isFromMe = fromMe,
                                    onOpen = { onOpenDocument(attachment) },
                                )
                            }
                        }
                        Spacer(Modifier.height(4.dp))
                    }

                    val bodyText = message.text.ifBlank { message.attachments.firstOrNull()?.caption.orEmpty() }
                    if (bodyText.isNotBlank()) {
                        Text(
                            text = bodyText,
                            style = MaterialTheme.typography.bodyLarge,
                            color = bubbleTextColor,
                        )
                    }

                    Row(
                        modifier = Modifier
                            .align(Alignment.End)
                            .padding(top = 3.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        if (message.isStarred) {
                            Icon(
                                imageVector = Icons.Filled.Star,
                                contentDescription = "Starred",
                                tint = if (fromMe) bubbleTextColor.copy(alpha = 0.8f) else colors.warning,
                                modifier = Modifier.size(12.dp),
                            )
                            Spacer(Modifier.width(4.dp))
                        }
                        if (showTimestamps) {
                            Text(
                                text = TimeFormat.clock(message.createdAt),
                                style = MaterialTheme.typography.labelSmall,
                                color = metaColor,
                            )
                        }
                        if (message.editedAt != null) {
                            Text(
                                text = " · edited",
                                style = MaterialTheme.typography.labelSmall,
                                color = metaColor,
                            )
                        }
                        if (fromMe && showSimulatedStatus) {
                            Spacer(Modifier.width(5.dp))
                            SimulatedStatusTicks(
                                delivered = message.status != com.glasschat.app.domain.model.MessageStatus.SIMULATED_SENT,
                                read = message.status == com.glasschat.app.domain.model.MessageStatus.SIMULATED_READ,
                                tint = bubbleTextColor.copy(alpha = 0.9f),
                            )
                        }
                    }
                    if (fromMe && showSimulatedStatus) {
                        Text(
                            text = "simulated",
                            style = MaterialTheme.typography.labelSmall,
                            color = metaColor.copy(alpha = 0.7f),
                            modifier = Modifier.align(Alignment.End),
                        )
                    }
                }
            }
        }

        if (message.reactions.isNotEmpty()) {
            ReactionChips(
                reactions = message.reactions,
                onToggle = onToggleReaction,
                modifier = Modifier.padding(top = 4.dp),
            )
        }
    }
}

@Composable
private fun ReplyQuote(
    senderLabel: String,
    text: String,
    fromMe: Boolean,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val tint = if (fromMe) colors.bubbleTextMe.copy(alpha = 0.9f) else colors.accent
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(9.dp))
            .background(Color.Black.copy(alpha = if (fromMe) 0.12f else 0.05f))
            .padding(vertical = 5.dp, horizontal = 7.dp),
    ) {
        Box(
            Modifier
                .width(3.dp)
                .height(28.dp)
                .clip(CircleShape)
                .background(tint),
        )
        Spacer(Modifier.width(7.dp))
        Column {
            Text(
                text = senderLabel,
                style = MaterialTheme.typography.labelSmall,
                color = tint,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = text,
                style = MaterialTheme.typography.labelSmall,
                color = tint.copy(alpha = 0.85f),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun ReactionChips(
    reactions: List<com.glasschat.app.domain.model.Reaction>,
    onToggle: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val grouped = remember(reactions) {
        reactions.groupBy { it.emoji }.mapValues { it.value.size }
    }
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        grouped.forEach { (emoji, count) ->
            val reactedByMe = reactions.any {
                it.emoji == emoji && it.senderType == com.glasschat.app.domain.model.SenderType.ME
            }
            Row(
                modifier = Modifier
                    .clip(CircleShape)
                    .background(
                        if (reactedByMe) {
                            colors.accent.copy(alpha = 0.22f)
                        } else {
                            colors.glassFill
                        },
                    )
                    .combinedClickable(onClick = { onToggle(emoji) }, onLongClick = { onToggle(emoji) })
                    .padding(horizontal = 8.dp, vertical = 3.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(text = emoji, style = MaterialTheme.typography.labelMedium)
                if (count > 1) {
                    Spacer(Modifier.width(3.dp))
                    Text(
                        text = count.toString(),
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.textSecondary,
                    )
                }
            }
        }
    }
}

/** Three-dot typing bubble, only shown when the user explicitly turns simulation on. */
@Composable
fun TypingIndicatorBubble(
    senderName: String,
    accentColor: Color,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val reduceMotion = LocalReduceMotion.current
    val transition = if (reduceMotion) null else rememberInfiniteTransition(label = "typing")
    val phases = (0..2).map { index ->
        if (transition == null) {
            1f
        } else {
            val value by transition.animateFloat(
                initialValue = 0.35f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(700, delayMillis = index * 140, easing = LinearEasing),
                    repeatMode = RepeatMode.Reverse,
                ),
                label = "dot-$index",
            )
            value
        }
    }

    Column(modifier = modifier.fillMaxWidth(), horizontalAlignment = Alignment.Start) {
        GlassSurface(
            shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp, bottomEnd = 20.dp, bottomStart = 8.dp),
            fill = colors.bubbleOther,
            shadowElevation = 4.dp,
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                phases.forEach { alpha ->
                    Box(
                        Modifier
                            .size(7.dp)
                            .clip(CircleShape)
                            .background(accentColor.copy(alpha = alpha)),
                    )
                    Spacer(Modifier.width(4.dp))
                }
                Spacer(Modifier.width(2.dp))
                Text(
                    text = "$senderName is typing (simulated)",
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.textTertiary,
                )
            }
        }
    }
}

/** Day separator variant that also exposes the "simulated" nature of the thread. */
@Composable
fun ChatDaySeparator(label: String, modifier: Modifier = Modifier) {
    DaySeparator(label = label, modifier = modifier)
}

/** Row shown when a chat has no messages yet. */
@Composable
fun EmptyConversationHint(
    contactName: String,
    modifier: Modifier = Modifier,
    onOpenSettings: () -> Unit,
) {
    val colors = LocalGlassColors.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 32.dp, vertical = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        SimulatedPill(text = "Private simulation", tint = colors.accent)
        Spacer(Modifier.height(12.dp))
        Text(
            text = "This is a blank canvas",
            style = MaterialTheme.typography.titleLarge,
            color = colors.textPrimary,
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = "Write the first line as yourself or as $contactName. Both sides are yours to author, and nothing is sent anywhere.",
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textSecondary,
        )
        Spacer(Modifier.height(14.dp))
        com.glasschat.app.ui.glass.GlassChip(
            label = "Chat settings",
            onClick = onOpenSettings,
        )
    }
}
