package com.glasschat.app.ui.features.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassSwitch
import com.glasschat.app.ui.theme.LocalGlassColors

@Composable
fun BehaviourScreen(
    onBack: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    val prefs = state.preferences

    GlassScaffold(
        reserveBottomBar = false,
        topBar = { SettingsSubHeader("Chat behaviour", null, onBack) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            GlassSectionHeader(title = "Composer")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Enter sends the message",
                        subtitle = "When off, Enter inserts a new line",
                        trailing = {
                            GlassSwitch(
                                checked = prefs.enterToSend,
                                onCheckedChange = viewModel::setEnterToSend,
                            )
                        },
                    )
                    GlassSettingRow(
                        title = "Haptic feedback",
                        subtitle = "A light tick when a message is sent",
                        trailing = {
                            GlassSwitch(
                                checked = prefs.hapticsEnabled,
                                onCheckedChange = viewModel::setHaptics,
                            )
                        },
                    )
                }
            }

            GlassSectionHeader(title = "Bubbles")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Show timestamps",
                        subtitle = "Time under every message and in the chat list",
                        trailing = {
                            GlassSwitch(
                                checked = prefs.showTimestamps,
                                onCheckedChange = viewModel::setShowTimestamps,
                            )
                        },
                    )
                    GlassSettingRow(
                        title = "Show simulated delivery ticks",
                        subtitle = "Marks your messages as delivered/read — always labelled simulated",
                        trailing = {
                            GlassSwitch(
                                checked = prefs.showSimulatedStatus,
                                onCheckedChange = viewModel::setShowSimulatedStatus,
                            )
                        },
                    )
                }
            }

            GlassSectionHeader(title = "Typing indicator")
            GlassCard {
                Text(
                    text = "Typing dots are never invented automatically. Open a chat, use its menu and turn on “Simulate typing” to preview how the other participant would look while writing.",
                    style = androidx.compose.material3.MaterialTheme.typography.bodyMedium,
                    color = colors.textSecondary,
                )
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}
