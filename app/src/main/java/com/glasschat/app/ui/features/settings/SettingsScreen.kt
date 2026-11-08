package com.glasschat.app.ui.features.settings

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
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.navigation.GlassTab
import com.glasschat.app.ui.navigation.GlassTabBar
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.util.formatBytes

@Composable
fun SettingsScreen(
    onSelectTab: (GlassTab) -> Unit,
    onOpenProfile: () -> Unit,
    onOpenAppearance: () -> Unit,
    onOpenBehaviour: () -> Unit,
    onOpenPrivacy: () -> Unit,
    onOpenData: () -> Unit,
    onOpenAbout: () -> Unit,
    onOpenArchived: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    val prefs = state.preferences

    GlassScaffold(
        topBar = {
            GlassTopBar(
                title = "Settings",
                subtitle = "${state.chatCount} chats · ${state.contactCount} contacts",
            )
        },
        bottomBar = { GlassTabBar(selected = GlassTab.SETTINGS, onSelect = onSelectTab) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            GlassCard(
                padding = PaddingValues(16.dp),
                onClick = onOpenProfile,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    GlassAvatar(
                        name = prefs.displayName,
                        accentColor = Color(prefs.profileAccent),
                        avatarUri = prefs.avatarUri,
                        size = 62.dp,
                    )
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Text(
                            text = prefs.displayName,
                            style = MaterialTheme.typography.headlineSmall,
                            color = colors.textPrimary,
                        )
                        Text(
                            text = prefs.about.ifBlank { "Offline and on purpose." },
                            style = MaterialTheme.typography.bodySmall,
                            color = colors.textSecondary,
                            maxLines = 2,
                        )
                    }
                    Icon(
                        imageVector = Icons.Filled.KeyboardArrowRight,
                        contentDescription = null,
                        tint = colors.textTertiary,
                        modifier = Modifier.size(20.dp),
                    )
                }
            }

            GlassSectionHeader(title = "Personalise")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Appearance",
                        subtitle = "Theme, accent, wallpaper, text size",
                        icon = Icons.Outlined.Palette,
                        onClick = onOpenAppearance,
                    )
                    GlassSettingRow(
                        title = "Chat behaviour",
                        subtitle = "Enter to send, timestamps, simulated ticks",
                        icon = Icons.Outlined.Tune,
                        onClick = onOpenBehaviour,
                    )
                    GlassSettingRow(
                        title = "Privacy",
                        subtitle = "App lock, recents preview, media blur",
                        icon = Icons.Outlined.Lock,
                        onClick = onOpenPrivacy,
                    )
                }
            }

            GlassSectionHeader(title = "Library")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Archived chats",
                        subtitle = if (state.archivedChats == 0) {
                            "Nothing archived"
                        } else {
                            "${state.archivedChats} archived"
                        },
                        icon = Icons.Outlined.Archive,
                        onClick = onOpenArchived,
                    )
                    GlassSettingRow(
                        title = "Data & backups",
                        subtitle = "Export, import, cache · ${formatBytes(state.cacheBytes)}",
                        icon = Icons.Outlined.Storage,
                        onClick = onOpenData,
                    )
                }
            }

            GlassSectionHeader(title = "About")
            GlassCard(padding = PaddingValues(0.dp)) {
                GlassSettingRow(
                    title = "About GlassChat",
                    subtitle = "Version, licenses, what this app is",
                    icon = Icons.Outlined.Info,
                    onClick = onOpenAbout,
                )
            }

            Spacer(Modifier.height(10.dp))
            Text(
                text = "GlassChat is an offline workspace for writing conversations. It has no servers, no accounts and no internet permission.",
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
                modifier = Modifier.padding(horizontal = 4.dp, vertical = 6.dp),
            )
            Spacer(Modifier.height(20.dp))
        }
    }
}

/** Shared header used by every settings sub-screen. */
@Composable
fun SettingsSubHeader(title: String, subtitle: String?, onBack: () -> Unit) {
    GlassTopBar(
        title = title,
        subtitle = subtitle,
        onBack = onBack,
        compact = true,
    )
}

@Composable
fun SettingsSectionCard(content: @Composable () -> Unit) {
    Box(Modifier.fillMaxWidth()) {
        GlassCard(padding = PaddingValues(0.dp)) { content() }
    }
}
