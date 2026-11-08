package com.glasschat.app.ui.features.contacts

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.ui.components.AccentColorPicker
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassDialog
import com.glasschat.app.ui.glass.GlassLabeledField
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.glass.GlassSnackbarHost
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.theme.LocalGlassColors

@Composable
fun ContactEditorScreen(
    onBack: () -> Unit,
    viewModel: ContactEditorViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    val snackbarHostState = remember { SnackbarHostState() }
    var confirmDelete by remember { mutableStateOf(false) }

    val photoPicker = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia(),
    ) { uri -> if (uri != null) viewModel.onAvatarPicked(uri.toString()) }

    LaunchedEffect(Unit) {
        viewModel.events.collect { snackbarHostState.showSnackbar(it.message) }
    }

    GlassScaffold(
        reserveBottomBar = false,
        topBar = {
            GlassTopBar(
                title = if (state.isNew) "New contact" else "Edit contact",
                subtitle = if (state.isNew) "Lives only on this device" else state.name,
                onBack = onBack,
                compact = true,
                actions = {
                    GlassChip(
                        label = if (state.isSaving) "Saving…" else "Save",
                        selected = true,
                        onClick = { if (!state.isSaving) viewModel.save { onBack() } },
                    )
                },
            )
        },
        snackbarHost = { GlassSnackbarHost(snackbarHostState) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            GlassCard(padding = PaddingValues(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    GlassAvatar(
                        name = state.name.ifBlank { "New contact" },
                        accentColor = Color(state.accentColor),
                        avatarUri = state.avatarUri,
                        size = 68.dp,
                    )
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        GlassChip(
                            label = if (state.avatarUri == null) "Add photo" else "Change photo",
                            leadingIcon = Icons.Filled.Add,
                            onClick = {
                                photoPicker.launch(
                                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly),
                                )
                            },
                        )
                        if (state.avatarUri != null) {
                            Spacer(Modifier.height(6.dp))
                            GlassChip(label = "Remove photo", onClick = viewModel::clearAvatar)
                        }
                    }
                }
            }

            GlassLabeledField(
                label = "Name",
                value = state.name,
                onValueChange = viewModel::onNameChange,
                placeholder = "e.g. Maya Chen",
                supportingText = if (state.nameError) "A name is required" else null,
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words),
            )
            GlassLabeledField(
                label = "Phone label (optional)",
                value = state.phoneLabel,
                onValueChange = viewModel::onPhoneLabelChange,
                placeholder = "mobile · work · none",
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Text),
            )
            GlassLabeledField(
                label = "Bio (optional)",
                value = state.bio,
                onValueChange = viewModel::onBioChange,
                placeholder = "A line about them",
                singleLine = false,
                maxLines = 3,
                supportingText = "${state.bio.length}/140",
            )
            GlassLabeledField(
                label = "Private notes",
                value = state.notes,
                onValueChange = viewModel::onNotesChange,
                placeholder = "Only visible to you",
                singleLine = false,
                maxLines = 4,
            )

            GlassSectionHeader(title = "Accent colour")
            AccentColorPicker(selected = state.accentColor, onSelect = { color ->
                color?.let(viewModel::onAccentChange)
            })

            if (!state.isNew) {
                GlassSectionHeader(title = "Danger zone")
                GlassCard(
                    padding = PaddingValues(14.dp),
                    onClick = { confirmDelete = true },
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        androidx.compose.material3.Icon(
                            imageVector = Icons.Outlined.Delete,
                            contentDescription = null,
                            tint = colors.danger,
                            modifier = Modifier.size(20.dp),
                        )
                        Spacer(Modifier.width(12.dp))
                        Column {
                            Text(
                                text = "Delete contact",
                                style = MaterialTheme.typography.bodyLarge,
                                color = colors.danger,
                            )
                            Text(
                                text = "Chats that only include this contact are removed too",
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.textSecondary,
                            )
                        }
                    }
                }
            }

            Spacer(Modifier.height(80.dp))
            Text(
                text = "Contacts are local records. GlassChat never reads your address book, and no phone number is dialled or verified.",
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
            )
        }
    }

    if (confirmDelete) {
        GlassDialog(
            title = "Delete ${state.name}?",
            message = "This cannot be undone. Any chat with only this contact will be removed as well.",
            confirmLabel = "Delete",
            destructive = true,
            onConfirm = {
                confirmDelete = false
                viewModel.delete { onBack() }
            },
            onDismiss = { confirmDelete = false },
        )
    }
}
