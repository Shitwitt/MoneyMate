package com.glasschat.app.ui.features.contacts

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.glasschat.app.domain.model.AttachmentType
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.components.InlineEmptyNote
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassDialog
import com.glasschat.app.ui.glass.GlassIconButton
import com.glasschat.app.ui.glass.GlassLoadingState
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassSwitch
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.util.TimeFormat

@Composable
fun ContactDetailScreen(
    onBack: () -> Unit,
    onEdit: (String) -> Unit,
    onOpenChat: (String) -> Unit,
    onOpenChatSettings: (String) -> Unit,
    onOpenMedia: (String, String) -> Unit,
    viewModel: ContactDetailViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    var confirmDelete by remember { mutableStateOf(false) }
    val contact = state.contact

    GlassScaffold(
        reserveBottomBar = false,
        topBar = {
            GlassTopBar(
                title = contact?.name ?: "Contact",
                subtitle = contact?.phoneLabel?.takeIf { it.isNotBlank() } ?: "Local contact",
                onBack = onBack,
                compact = true,
                actions = {
                    if (contact != null) {
                        GlassIconButton(
                            icon = Icons.Outlined.Edit,
                            contentDescription = "Edit contact",
                            background = null,
                            onClick = { onEdit(contact.id) },
                        )
                    }
                },
            )
        },
    ) { padding ->
        when {
            state.isLoading -> GlassLoadingState("Loading contact…")
            contact == null -> Box(
                Modifier.fillMaxSize().padding(padding),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "This contact has been deleted.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.textSecondary,
                )
            }

            else -> LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                item {
                    GlassCard(padding = PaddingValues(18.dp)) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                            GlassAvatar(
                                name = contact.name,
                                accentColor = Color(contact.accentColor),
                                avatarUri = contact.avatarUri,
                                size = 92.dp,
                            )
                            Spacer(Modifier.height(10.dp))
                            Text(
                                text = contact.name,
                                style = MaterialTheme.typography.headlineSmall,
                                color = colors.textPrimary,
                            )
                            if (contact.bio.isNotBlank()) {
                                Spacer(Modifier.height(2.dp))
                                Text(
                                    text = contact.bio,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = colors.textSecondary,
                                )
                            }
                            if (contact.phoneLabel.isNotBlank()) {
                                Spacer(Modifier.height(4.dp))
                                GlassChip(label = contact.phoneLabel, onClick = {})
                            }
                            Spacer(Modifier.height(14.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                GlassChip(
                                    label = "Message",
                                    selected = true,
                                    onClick = {
                                        viewModel.openChat { chatId -> onOpenChat(chatId) }
                                    },
                                )
                                GlassChip(
                                    label = "Favourite",
                                    selected = contact.isFavorite,
                                    leadingIcon = Icons.Filled.Star,
                                    onClick = { viewModel.setFavorite(contact.isFavorite) },
                                )
                                GlassChip(
                                    label = "Customise chat",
                                    leadingIcon = Icons.Outlined.Palette,
                                    onClick = {
                                        state.chatId?.let(onOpenChatSettings)
                                    },
                                )
                            }
                        }
                    }
                }

                if (contact.notes.isNotBlank()) {
                    item {
                        GlassCard {
                            Column {
                                Text(
                                    text = "Private notes",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = colors.textTertiary,
                                )
                                Spacer(Modifier.height(4.dp))
                                Text(
                                    text = contact.notes,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = colors.textPrimary,
                                )
                            }
                        }
                    }
                }

                item { GlassSectionHeader(title = "Shared media") }
                item {
                    if (state.media.isEmpty()) {
                        GlassCard { InlineEmptyNote("Photos, videos and files shared in this chat appear here.") }
                    } else {
                        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            items(items = state.media, key = { it.attachment.id }) { item ->
                                Box(
                                    modifier = Modifier
                                        .size(84.dp)
                                        .clip(RoundedCornerShape(16.dp))
                                        .background(colors.mediaPlaceholder)
                                        .clickable { onOpenMedia(item.chatId, item.messageId) },
                                    contentAlignment = Alignment.Center,
                                ) {
                                    if (item.attachment.type == AttachmentType.IMAGE ||
                                        item.attachment.type == AttachmentType.VIDEO
                                    ) {
                                        AsyncImage(
                                            model = item.attachment.localUri,
                                            contentDescription = "Shared media",
                                            contentScale = ContentScale.Crop,
                                            modifier = Modifier.size(84.dp),
                                        )
                                    } else {
                                        Text(
                                            text = if (item.attachment.type == AttachmentType.AUDIO) {
                                                "Audio"
                                            } else {
                                                "File"
                                            },
                                            style = MaterialTheme.typography.labelSmall,
                                            color = colors.textSecondary,
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                item { GlassSectionHeader(title = "Starred messages") }
                if (state.starred.isEmpty()) {
                    item { GlassCard { InlineEmptyNote("Long-press a message to star it for later.") } }
                } else {
                    items(items = state.starred, key = { it.message.id }) { starred ->
                        GlassCard(padding = PaddingValues(14.dp)) {
                            Column {
                                Row {
                                    Text(
                                        text = starred.message.senderLabel,
                                        style = MaterialTheme.typography.labelMedium,
                                        color = colors.accent,
                                    )
                                    Spacer(Modifier.weight(1f))
                                    Text(
                                        text = TimeFormat.full(starred.message.createdAt),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = colors.textTertiary,
                                    )
                                }
                                Spacer(Modifier.height(3.dp))
                                Text(
                                    text = starred.message.text.ifBlank { "Attachment" },
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = colors.textPrimary,
                                    maxLines = 4,
                                    overflow = TextOverflow.Ellipsis,
                                )
                                Spacer(Modifier.height(4.dp))
                                Text(
                                    text = starred.chatTitle,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = colors.textTertiary,
                                )
                            }
                        }
                    }
                }

                item { GlassSectionHeader(title = "Settings") }
                item {
                    GlassCard(padding = PaddingValues(0.dp)) {
                        Column {
                            GlassSettingRow(
                                title = "Hide this contact",
                                subtitle = "Hidden contacts are filtered out of new chat suggestions",
                                icon = Icons.Outlined.Edit,
                                trailing = {
                                    GlassSwitch(
                                        checked = contact.isBlocked,
                                        onCheckedChange = { viewModel.setBlocked(contact.isBlocked) },
                                    )
                                },
                            )
                            GlassSettingRow(
                                title = "Delete contact",
                                icon = Icons.Outlined.Delete,
                                iconTint = colors.danger,
                                onClick = { confirmDelete = true },
                            )
                        }
                    }
                }

                item {
                    Text(
                        text = "GlassChat has no account system. This contact exists only in this app's local database.",
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.textTertiary,
                        modifier = Modifier.padding(bottom = 24.dp),
                    )
                }
            }
        }
    }

    if (confirmDelete && contact != null) {
        GlassDialog(
            title = "Delete ${contact.name}?",
            message = "Their messages stay in group chats, but one-to-one conversations will be removed.",
            confirmLabel = "Delete",
            destructive = true,
            onConfirm = {
                confirmDelete = false
                viewModel.deleteContact { onBack() }
            },
            onDismiss = { confirmDelete = false },
        )
    }
}
