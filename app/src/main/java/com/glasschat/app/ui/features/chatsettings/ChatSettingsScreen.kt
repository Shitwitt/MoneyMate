package com.glasschat.app.ui.features.chatsettings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.outlined.VolumeOff
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.ui.components.AccentColorPicker
import com.glasschat.app.ui.components.ColorSwatchRow
import com.glasschat.app.ui.components.toArgbLong
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.components.GlassGroupAvatar
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassDialog
import com.glasschat.app.ui.glass.GlassIconButton
import com.glasschat.app.ui.glass.GlassLabeledField
import com.glasschat.app.ui.glass.GlassLoadingState
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassSheet
import com.glasschat.app.ui.glass.GlassSwitch
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.theme.AccentPalette
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.ui.components.WallpaperPicker

@Composable
fun ChatSettingsScreen(
    onBack: () -> Unit,
    onDeleted: () -> Unit,
    onOpenContact: (String) -> Unit,
    viewModel: ChatSettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    var showRename by remember { mutableStateOf(false) }
    var renameValue by remember { mutableStateOf("") }
    var showAddParticipants by remember { mutableStateOf(false) }
    var confirmClear by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    val chat = state.chat

    GlassScaffold(
        reserveBottomBar = false,
        topBar = {
            GlassTopBar(
                title = "Chat settings",
                subtitle = chat?.title.orEmpty(),
                onBack = onBack,
                compact = true,
            )
        },
    ) { padding ->
        if (state.isLoading || chat == null) {
            GlassLoadingState("Loading settings…")
            return@GlassScaffold
        }
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 10.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            GlassCard {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    if (state.isGroup) {
                        GlassGroupAvatar(
                            name = chat.title,
                            accentColor = Color(state.participants.firstOrNull()?.accentColor ?: 0xFF8C7CFF),
                            size = 76.dp,
                        )
                    } else {
                        GlassAvatar(
                            name = chat.title,
                            accentColor = Color(state.participants.firstOrNull()?.accentColor ?: 0xFF8C7CFF),
                            avatarUri = state.participants.firstOrNull()?.avatarUri,
                            size = 76.dp,
                        )
                    }
                    Spacer(Modifier.height(10.dp))
                    Text(
                        text = chat.title,
                        style = MaterialTheme.typography.headlineSmall,
                        color = colors.textPrimary,
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        GlassChip(
                            label = "Rename",
                            leadingIcon = Icons.Outlined.Edit,
                            onClick = {
                                renameValue = chat.title
                                showRename = true
                            },
                        )
                        if (!state.isGroup) {
                            GlassChip(
                                label = "Contact",
                                onClick = {
                                    state.participants.firstOrNull()?.let { onOpenContact(it.contactId) }
                                },
                            )
                        }
                    }
                }
            }

            GlassSectionHeader(title = "Wallpaper")
            GlassCard {
                WallpaperPicker(
                    selected = chat.wallpaper,
                    onSelect = viewModel::setWallpaper,
                    allowThemeDefault = true,
                )
            }

            GlassSectionHeader(title = "Accent")
            GlassCard {
                AccentColorPicker(
                    selected = chat.accentColor,
                    onSelect = viewModel::setAccent,
                    inheritLabel = "Use app accent",
                )
            }

            GlassSectionHeader(title = "Bubbles")
            GlassCard {
                Column {
                    Text(
                        text = "My messages",
                        style = MaterialTheme.typography.labelMedium,
                        color = colors.textTertiary,
                    )
                    ColorSwatchRow(
                        swatches = AccentPalette.options.map { it.color },
                        selected = chat.bubbleColorMe?.let { Color(it) },
                        onSelect = { color ->
                            viewModel.setBubbleColors(
                                me = color?.toArgbLong(),
                                other = chat.bubbleColorOther,
                            )
                        },
                        defaultLabel = "App accent",
                    )
                    Spacer(Modifier.height(14.dp))
                    Text(
                        text = "Their messages",
                        style = MaterialTheme.typography.labelMedium,
                        color = colors.textTertiary,
                    )
                    ColorSwatchRow(
                        swatches = AccentPalette.options.map { it.color },
                        selected = chat.bubbleColorOther?.let { Color(it) },
                        onSelect = { color ->
                            viewModel.setBubbleColors(
                                me = chat.bubbleColorMe,
                                other = color?.toArgbLong(),
                            )
                        },
                        defaultLabel = "Glass surface",
                    )
                }
            }

            GlassSectionHeader(title = "Participants")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    state.participants.forEach { participant ->
                        GlassSettingRow(
                            title = participant.name,
                            subtitle = if (participant.role == com.glasschat.app.domain.model.ParticipantRole.OWNER) {
                                "Owner"
                            } else {
                                "Member"
                            },
                            onClick = { onOpenContact(participant.contactId) },
                            trailing = {
                                if (state.participants.size > 1) {
                                    GlassIconButton(
                                        icon = Icons.Outlined.Delete,
                                        contentDescription = "Remove ${participant.name}",
                                        background = null,
                                        tint = colors.textTertiary,
                                        onClick = { viewModel.removeParticipant(participant.contactId) },
                                    )
                                }
                            },
                        )
                    }
                    GlassSettingRow(
                        title = "Add participant",
                        subtitle = if (state.isGroup) "Grows this group chat" else "Turns this into a group chat",
                        icon = Icons.Filled.Add,
                        onClick = { showAddParticipants = true },
                    )
                }
            }

            GlassSectionHeader(title = "Behaviour")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Mute",
                        icon = Icons.Outlined.VolumeOff,
                        trailing = {
                            GlassSwitch(checked = chat.isMuted, onCheckedChange = { viewModel.toggleMute(chat.isMuted) })
                        },
                    )
                    GlassSettingRow(
                        title = "Pin to top",
                        icon = Icons.Outlined.PushPin,
                        trailing = {
                            GlassSwitch(checked = chat.isPinned, onCheckedChange = { viewModel.togglePin(chat.isPinned) })
                        },
                    )
                    GlassSettingRow(
                        title = "Archive",
                        icon = Icons.Outlined.Archive,
                        trailing = {
                            GlassSwitch(
                                checked = chat.isArchived,
                                onCheckedChange = { viewModel.toggleArchive(chat.isArchived) },
                            )
                        },
                    )
                }
            }

            GlassSectionHeader(title = "Data")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Clear messages",
                        subtitle = "Keeps the contact and these settings",
                        icon = Icons.Outlined.Delete,
                        onClick = { confirmClear = true },
                    )
                    GlassSettingRow(
                        title = "Delete chat",
                        subtitle = "Removes the conversation and its media",
                        icon = Icons.Outlined.Delete,
                        iconTint = colors.danger,
                        onClick = { confirmDelete = true },
                    )
                }
            }

            Text(
                text = if (state.isGroup) {
                    "Everyone in this group is a local, fictional participant. No invitations are sent."
                } else {
                    "This conversation is a private simulation. Messages are stored only in this app."
                },
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
                modifier = Modifier.padding(vertical = 8.dp),
            )
            Spacer(Modifier.height(24.dp))
        }
    }

    if (showRename) {
        GlassDialog(
            title = "Rename chat",
            confirmLabel = "Save",
            dismissLabel = "Cancel",
            onConfirm = {
                viewModel.rename(renameValue)
                showRename = false
            },
            onDismiss = { showRename = false },
        ) {
            GlassLabeledField(
                label = "Chat name",
                value = renameValue,
                onValueChange = { renameValue = it },
                placeholder = "Name this conversation",
            )
        }
    }

    if (showAddParticipants) {
        GlassSheet(onDismissRequest = { showAddParticipants = false }) {
            Column(Modifier.padding(bottom = 26.dp)) {
                Text(
                    text = "Add participant",
                    style = MaterialTheme.typography.headlineSmall,
                    color = colors.textPrimary,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp),
                )
                if (state.addableContacts.isEmpty()) {
                    Text(
                        text = "Everyone in your contacts is already here. Create another contact first.",
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.textSecondary,
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
                    )
                } else {
                    state.addableContacts.forEach { contact ->
                        GlassSettingRow(
                            title = contact.name,
                            subtitle = contact.bio.take(40),
                            icon = Icons.Outlined.Groups,
                            onClick = {
                                viewModel.addParticipant(contact.id)
                                showAddParticipants = false
                            },
                        )
                    }
                }
            }
        }
    }

    if (confirmClear) {
        GlassDialog(
            title = "Clear all messages?",
            message = "Messages and their media will be deleted. The chat itself stays.",
            confirmLabel = "Clear",
            destructive = true,
            onConfirm = {
                confirmClear = false
                viewModel.clearMessages()
            },
            onDismiss = { confirmClear = false },
        )
    }

    if (confirmDelete) {
        GlassDialog(
            title = "Delete this chat?",
            message = "This permanently removes the conversation, its messages and its media from this device.",
            confirmLabel = "Delete",
            destructive = true,
            onConfirm = {
                confirmDelete = false
                viewModel.deleteChat(onDeleted)
            },
            onDismiss = { confirmDelete = false },
        )
    }
}
