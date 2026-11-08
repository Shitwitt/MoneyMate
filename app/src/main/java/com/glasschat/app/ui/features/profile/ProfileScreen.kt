package com.glasschat.app.ui.features.profile

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.ui.components.AccentColorPicker
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassLabeledField
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.glass.GlassSnackbarHost
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.theme.LocalGlassColors

@Composable
fun ProfileScreen(
    onBack: () -> Unit,
    viewModel: ProfileViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    val snackbarHostState = remember { SnackbarHostState() }
    val prefs = state.preferences

    var name by remember(prefs.displayName) { mutableStateOf(prefs.displayName) }
    var about by remember(prefs.about) { mutableStateOf(prefs.about) }
    var accent by remember(prefs.profileAccent) { mutableStateOf(prefs.profileAccent) }

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
                title = "My profile",
                subtitle = "How you appear in your own chats",
                onBack = onBack,
                compact = true,
                actions = {
                    GlassChip(
                        label = if (state.isSaving) "Saving…" else "Save",
                        selected = true,
                        onClick = { viewModel.save(name, about, accent) },
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
                .padding(horizontal = 16.dp, vertical = 10.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            GlassCard(padding = PaddingValues(18.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    GlassAvatar(
                        name = name.ifBlank { "Me" },
                        accentColor = Color(accent),
                        avatarUri = prefs.avatarUri,
                        size = 78.dp,
                    )
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        GlassChip(
                            label = if (prefs.avatarUri == null) "Add photo" else "Change photo",
                            leadingIcon = Icons.Filled.Add,
                            onClick = {
                                photoPicker.launch(
                                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly),
                                )
                            },
                        )
                        Spacer(Modifier.height(6.dp))
                        Text(
                            text = "${state.chatCount} chats · ${state.contactCount} contacts",
                            style = MaterialTheme.typography.labelSmall,
                            color = colors.textTertiary,
                        )
                    }
                }
            }

            GlassLabeledField(
                label = "Display name",
                value = name,
                onValueChange = { name = it.take(30) },
                placeholder = "Me",
                supportingText = "Shown on your own messages and in the composer switch",
            )
            GlassLabeledField(
                label = "About / status",
                value = about,
                onValueChange = { about = it.take(140) },
                placeholder = "A short line",
                singleLine = false,
                maxLines = 3,
                supportingText = "${about.length}/140",
            )

            GlassSectionHeader(title = "Profile accent")
            AccentColorPicker(
                selected = accent,
                onSelect = { value -> value?.let { accent = it } },
                allowInherit = false,
            )

            GlassSectionHeader(title = "Backups")
            GlassCard {
                Text(
                    text = "Export or import your whole library from Settings → Data & backups. Backups include this profile.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.textSecondary,
                )
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}
