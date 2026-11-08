package com.glasschat.app.ui.features.chats

import androidx.compose.animation.AnimatedVisibilityScope
import androidx.compose.animation.SharedTransitionScope
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.outlined.VolumeOff
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
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.domain.model.ChatSummary
import com.glasschat.app.ui.components.ListCaption
import com.glasschat.app.ui.glass.GlassFAB
import com.glasschat.app.ui.glass.GlassIconButton
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSearchField
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassSheet
import com.glasschat.app.ui.glass.GlassSnackbarHost
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.navigation.GlassTab
import com.glasschat.app.ui.navigation.GlassTabBar
import com.glasschat.app.ui.theme.LocalGlassColors

@Composable
fun ChatsScreen(
    sharedTransitionScope: SharedTransitionScope,
    animatedVisibilityScope: AnimatedVisibilityScope,
    onOpenChat: (String) -> Unit,
    onNewChat: () -> Unit,
    onOpenArchived: () -> Unit,
    onSelectTab: (GlassTab) -> Unit,
    viewModel: ChatsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    var menuTarget by remember { mutableStateOf<ChatSummary?>(null) }
    val haptics = LocalHapticFeedback.current
    val colors = LocalGlassColors.current

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            val result = snackbarHostState.showSnackbar(
                message = event.message,
                actionLabel = event.actionLabel,
            )
            if (result == androidx.compose.material3.SnackbarResult.ActionPerformed) {
                event.action?.invoke()
            }
        }
    }

    val unreadTotal = state.chats.sumOf { it.unreadCount }
    val subtitle = when {
        state.chats.isEmpty() -> "Everything stays on this device"
        unreadTotal > 0 -> "$unreadTotal unread · offline only"
        else -> "${state.chats.size} conversations · offline only"
    }

    GlassScaffold(
        topBar = {
            GlassTopBar(
                title = "Chats",
                subtitle = subtitle,
                actions = {
                    if (state.archivedCount > 0) {
                        GlassIconButton(
                            icon = Icons.Outlined.Archive,
                            contentDescription = "Archived chats (${state.archivedCount})",
                            onClick = onOpenArchived,
                        )
                    }
                    GlassIconButton(
                        icon = Icons.Filled.Add,
                        contentDescription = "Start a new chat",
                        onClick = onNewChat,
                    )
                },
            )
        },
        bottomBar = {
            GlassTabBar(
                selected = GlassTab.CHATS,
                unreadCount = unreadTotal,
                onSelect = onSelectTab,
            )
        },
        snackbarHost = { GlassSnackbarHost(snackbarHostState) },
        floatingActionButton = {
            GlassFAB(
                icon = Icons.Filled.Add,
                contentDescription = "Start a new chat",
                onClick = onNewChat,
            )
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            Box(Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                GlassSearchField(
                    query = state.query,
                    onQueryChange = viewModel::onQueryChange,
                    placeholder = "Search chats",
                )
            }
            if (state.archivedCount > 0) {
                ListCaption("${state.archivedCount} archived")
            }
            when {
                state.isLoading -> com.glasschat.app.ui.glass.GlassLoadingState(
                    message = "Loading chats…",
                )

                state.chats.isEmpty() -> EmptyChatsPlaceholder(
                    hasChats = state.hasChats,
                    onNewChat = onNewChat,
                )

                else -> LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(9.dp),
                ) {
                    items(items = state.chats, key = { it.chat.id }) { summary ->
                        ChatRow(
                            summary = summary,
                            sharedTransitionScope = sharedTransitionScope,
                            animatedVisibilityScope = animatedVisibilityScope,
                            blurMedia = state.blurMedia,
                            onClick = { onOpenChat(summary.chat.id) },
                            onLongClick = {
                                haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                                menuTarget = summary
                            },
                            onTogglePin = { viewModel.togglePin(summary.chat.id, summary.chat.isPinned) },
                            onArchive = { viewModel.archive(summary.chat.id) },
                            onDelete = { viewModel.delete(summary.chat.id) },
                        )
                    }
                }
            }
            Spacer(Modifier.height(2.dp))
        }
    }

    menuTarget?.let { summary ->
        ChatRowMenuSheet(
            summary = summary,
            onDismiss = { menuTarget = null },
            onPin = {
                viewModel.togglePin(summary.chat.id, summary.chat.isPinned)
                menuTarget = null
            },
            onMute = {
                viewModel.toggleMute(summary.chat.id, summary.chat.isMuted)
                menuTarget = null
            },
            onArchive = {
                viewModel.archive(summary.chat.id)
                menuTarget = null
            },
            onDelete = {
                viewModel.delete(summary.chat.id)
                menuTarget = null
            },
        )
    }
}

@Composable
private fun ChatRowMenuSheet(
    summary: ChatSummary,
    onDismiss: () -> Unit,
    onPin: () -> Unit,
    onMute: () -> Unit,
    onArchive: () -> Unit,
    onDelete: () -> Unit,
) {
    val colors = LocalGlassColors.current
    GlassSheet(onDismissRequest = onDismiss) {
        Column(Modifier.padding(bottom = 24.dp)) {
            Text(
                text = summary.displayTitle,
                style = MaterialTheme.typography.titleLarge,
                color = colors.textPrimary,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp),
            )
            GlassSettingRow(
                title = if (summary.chat.isPinned) "Unpin from top" else "Pin to top",
                icon = Icons.Outlined.PushPin,
                onClick = onPin,
            )
            GlassSettingRow(
                title = if (summary.chat.isMuted) "Unmute" else "Mute",
                icon = Icons.Outlined.VolumeOff,
                onClick = onMute,
            )
            GlassSettingRow(
                title = "Archive",
                icon = Icons.Outlined.Archive,
                onClick = onArchive,
            )
            GlassSettingRow(
                title = "Delete chat",
                icon = Icons.Outlined.Delete,
                iconTint = colors.danger,
                onClick = onDelete,
            )
        }
    }
}
