package com.glasschat.app.ui.features.archived

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Unarchive
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
import com.glasschat.app.domain.model.ChatSummary
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.glass.GlassDialog
import com.glasschat.app.ui.glass.GlassEmptyState
import com.glasschat.app.ui.glass.GlassIconButton
import com.glasschat.app.ui.glass.GlassLoadingState
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSnackbarHost
import com.glasschat.app.ui.glass.GlassSurface
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors
import androidx.compose.foundation.shape.RoundedCornerShape

@Composable
fun ArchivedChatsScreen(
    onBack: () -> Unit,
    onOpenChat: (String) -> Unit,
    viewModel: ArchivedChatsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    val snackbarHostState = remember { SnackbarHostState() }
    var deleteTarget by remember { mutableStateOf<ChatSummary?>(null) }

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            val result = snackbarHostState.showSnackbar(event.message, event.actionLabel)
            if (result == androidx.compose.material3.SnackbarResult.ActionPerformed) {
                event.action?.invoke()
            }
        }
    }

    GlassScaffold(
        reserveBottomBar = false,
        topBar = {
            GlassTopBar(
                title = "Archived",
                subtitle = "${state.chats.size} conversations",
                onBack = onBack,
                compact = true,
            )
        },
        snackbarHost = { GlassSnackbarHost(snackbarHostState) },
    ) { padding ->
        when {
            state.isLoading -> GlassLoadingState("Loading archive…")
            state.chats.isEmpty() -> GlassEmptyState(
                icon = Icons.Outlined.Archive,
                title = "No archived chats",
                body = "Swipe a conversation to the left in the chat list to archive it.",
            )

            else -> LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 10.dp),
                verticalArrangement = Arrangement.spacedBy(9.dp),
            ) {
                items(items = state.chats, key = { it.chat.id }) { summary ->
                    GlassSurface(
                        modifier = Modifier.fillMaxSize(),
                        shape = RoundedCornerShape(GlassRadius.card),
                        shadowElevation = 6.dp,
                        onClick = { onOpenChat(summary.chat.id) },
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            GlassAvatar(
                                name = summary.displayTitle,
                                accentColor = summary.primaryContact?.accentColor?.let { Color(it) }
                                    ?: colors.accent,
                                avatarUri = summary.primaryContact?.avatarUri,
                                size = 44.dp,
                            )
                            Spacer(Modifier.width(12.dp))
                            Column(Modifier.weight(1f)) {
                                Text(
                                    text = summary.displayTitle,
                                    style = MaterialTheme.typography.titleMedium,
                                    color = colors.textPrimary,
                                )
                                Text(
                                    text = summary.lastMessagePreview,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = colors.textSecondary,
                                    maxLines = 1,
                                )
                            }
                            GlassIconButton(
                                icon = Icons.Outlined.Unarchive,
                                contentDescription = "Restore ${summary.displayTitle}",
                                tint = colors.accent,
                                background = null,
                                onClick = { viewModel.restore(summary.chat.id) },
                            )
                            GlassIconButton(
                                icon = Icons.Outlined.Delete,
                                contentDescription = "Delete ${summary.displayTitle}",
                                tint = colors.danger,
                                background = null,
                                onClick = { deleteTarget = summary },
                            )
                        }
                    }
                }
            }
        }
    }

    deleteTarget?.let { summary ->
        GlassDialog(
            title = "Delete ${summary.displayTitle}?",
            message = "This permanently removes the archived conversation and its media.",
            confirmLabel = "Delete",
            destructive = true,
            onConfirm = {
                viewModel.delete(summary.chat.id)
                deleteTarget = null
            },
            onDismiss = { deleteTarget = null },
        )
    }
}
