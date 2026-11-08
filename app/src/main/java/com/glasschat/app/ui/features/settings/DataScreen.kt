package com.glasschat.app.ui.features.settings

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material.icons.outlined.Upload
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassDialog
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassSnackbarHost
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.util.TimeFormat
import com.glasschat.app.util.formatBytes

@Composable
fun DataScreen(
    onBack: () -> Unit,
    onDataDeleted: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    val snackbarHostState = remember { SnackbarHostState() }
    var confirmDeleteAll by remember { mutableStateOf(false) }

    val exportLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.CreateDocument("application/zip"),
    ) { uri ->
        if (uri != null) {
            viewModel.exportBackup(uri.toString())
        }
    }
    val importLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument(),
    ) { uri ->
        if (uri != null) {
            viewModel.importBackup(uri.toString())
        }
    }

    LaunchedEffect(Unit) {
        viewModel.events.collect { snackbarHostState.showSnackbar(it.message) }
    }

    GlassScaffold(
        reserveBottomBar = false,
        topBar = { SettingsSubHeader("Data & backups", "Yours to move", onBack) },
        snackbarHost = { GlassSnackbarHost(snackbarHostState) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            GlassSectionHeader(title = "Backup")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Export everything",
                        subtitle = "ZIP with a JSON manifest plus every media file",
                        icon = Icons.Outlined.Upload,
                        onClick = {
                            if (!state.isBusy) exportLauncher.launch("glasschat-backup.zip")
                        },
                    )
                    GlassSettingRow(
                        title = "Import a backup",
                        subtitle = "Merges by id; existing chats are kept",
                        icon = Icons.Outlined.Download,
                        onClick = {
                            if (!state.isBusy) {
                                importLauncher.launch(
                                    arrayOf("application/zip", "application/octet-stream", "*/*"),
                                )
                            }
                        },
                    )
                }
            }
            Spacer(Modifier.height(4.dp))
            Text(
                text = state.preferences.lastBackupAt?.let {
                    "Last export: ${TimeFormat.full(it)}"
                } ?: "No export yet. The backup is written to the folder you choose.",
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
                modifier = Modifier.padding(horizontal = 6.dp),
            )

            GlassSectionHeader(title = "Storage")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Clear image cache",
                        subtitle = "Currently ${formatBytes(state.cacheBytes)} of temporary thumbnails",
                        icon = Icons.Outlined.Storage,
                        onClick = viewModel::clearCache,
                    )
                    GlassSettingRow(
                        title = "Delete all data",
                        subtitle = "${state.chatCount} chats, ${state.contactCount} contacts and all media",
                        icon = Icons.Outlined.Delete,
                        iconTint = colors.danger,
                        onClick = { confirmDeleteAll = true },
                    )
                }
            }

            Spacer(Modifier.height(12.dp))
            Text(
                text = "Backups are unencrypted ZIP files. Store them somewhere you trust — GlassChat cannot recover a lost backup.",
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
            )
            Spacer(Modifier.height(24.dp))
        }
    }

    if (confirmDeleteAll) {
        GlassDialog(
            title = "Delete everything?",
            message = "Every chat, message, contact, attachment and preference on this device will be removed. Export a backup first if you want to keep anything.",
            confirmLabel = "Delete all",
            destructive = true,
            onConfirm = {
                confirmDeleteAll = false
                viewModel.deleteAllData { onDataDeleted() }
            },
            onDismiss = { confirmDeleteAll = false },
        )
    }
}
