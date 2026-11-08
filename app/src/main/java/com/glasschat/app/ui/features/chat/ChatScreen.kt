package com.glasschat.app.ui.features.chat

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibilityScope
import androidx.compose.animation.SharedTransitionScope
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.domain.model.Attachment
import com.glasschat.app.domain.model.Message
import com.glasschat.app.domain.model.PendingCapture
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.ui.common.UiEvent
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.components.GlassGroupAvatar
import com.glasschat.app.ui.components.LocalGlassAudioPlayer
import com.glasschat.app.ui.components.SimulatedPill
import com.glasschat.app.ui.components.rememberGlassAudioPlayer
import com.glasschat.app.ui.features.chats.ChatTimelineItem
import com.glasschat.app.ui.features.chats.buildTimeline
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassDialog
import com.glasschat.app.ui.glass.GlassIconButton
import com.glasschat.app.ui.glass.GlassLoadingState
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSearchField
import com.glasschat.app.ui.glass.GlassSnackbarHost
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.ui.theme.LocalReduceMotion
import com.glasschat.app.util.TimeFormat
import kotlinx.coroutines.launch

/**
 * The conversation screen: sender-switching composer, rich messages, reactions, in-chat
 * search and media handling. It is a fully local editor — there is no transport layer.
 */
@Composable
fun ChatScreen(
    sharedTransitionScope: SharedTransitionScope,
    animatedVisibilityScope: AnimatedVisibilityScope,
    onBack: () -> Unit,
    onOpenSettings: (String) -> Unit,
    onOpenContact: (String) -> Unit,
    onOpenViewer: (String, String) -> Unit,
    onOpenGallery: () -> Unit,
    viewModel: ChatViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val haptics = LocalHapticFeedback.current
    val clipboard = LocalClipboardManager.current
    val snackbarHostState = remember { SnackbarHostState() }
    val audioPlayer = rememberGlassAudioPlayer()
    val listState = rememberLazyListState()
    val reduceMotion = LocalReduceMotion.current

    var showMenu by remember { mutableStateOf(false) }
    var showAttach by remember { mutableStateOf(false) }
    var showEmoji by remember { mutableStateOf(false) }
    var showSenderPicker by remember { mutableStateOf(false) }
    var actionTarget by remember { mutableStateOf<Message?>(null) }
    var confirmClear by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    var pendingScrollTarget by remember { mutableStateOf<String?>(null) }
    var capture by remember { mutableStateOf<PendingCapture?>(null) }

    fun showSnack(message: String, actionLabel: String? = null) {
        scope.launch { snackbarHostState.showSnackbar(message, actionLabel) }
    }

    LaunchedEffect(Unit) {
        viewModel.events.collect { event: UiEvent ->
            val result = snackbarHostState.showSnackbar(event.message, event.actionLabel)
            if (result == androidx.compose.material3.SnackbarResult.ActionPerformed) {
                event.action?.invoke()
            }
        }
    }

    val photoPicker = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia(),
    ) { uri ->
        if (uri != null) viewModel.attach(uri.toString(), context.contentResolver.getType(uri))
    }
    val videoPicker = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia(),
    ) { uri ->
        if (uri != null) viewModel.attach(uri.toString(), context.contentResolver.getType(uri) ?: "video/*")
    }
    val documentPicker = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument(),
    ) { uri ->
        if (uri != null) {
            viewModel.attachDocument(
                uri = uri.toString(),
                fileName = displayNameOf(context, uri),
                mimeType = context.contentResolver.getType(uri),
            )
        }
    }
    val audioPicker = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument(),
    ) { uri ->
        if (uri != null) {
            viewModel.attach(uri.toString(), context.contentResolver.getType(uri) ?: "audio/*")
        }
    }
    val cameraLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicture(),
    ) { success ->
        val target = capture
        if (success && target != null) viewModel.attachCameraResult(target)
        capture = null
    }
    val micPermission = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        if (granted) {
            viewModel.startRecording()
        } else {
            showSnack("Microphone access is needed to record voice notes")
        }
    }

    CompositionLocalProvider(LocalGlassAudioPlayer provides audioPlayer) {
        GlassScaffold(
            wallpaper = state.wallpaper,
            reserveBottomBar = false,
            topBar = {
                ChatTopBar(
                    state = state,
                    sharedTransitionScope = sharedTransitionScope,
                    animatedVisibilityScope = animatedVisibilityScope,
                    onBack = onBack,
                    onOpenDetails = {
                        val contactId = state.contact?.id
                        if (contactId != null && !state.isGroup) {
                            onOpenContact(contactId)
                        } else {
                            onOpenSettings(state.chat?.id.orEmpty())
                        }
                    },
                    onSearch = {
                        if (state.searchQuery.isBlank()) viewModel.onSearchChange(" ") else viewModel.closeSearch()
                    },
                    onMore = { showMenu = true },
                )
            },
            snackbarHost = { GlassSnackbarHost(snackbarHostState) },
        ) { _ ->
            Column(Modifier.fillMaxSize()) {
                if (state.searchQuery.isNotBlank()) {
                    InChatSearchBar(
                        query = state.searchQuery,
                        onQueryChange = viewModel::onSearchChange,
                        onClose = { viewModel.closeSearch() },
                    )
                }
                if (state.starredOnly) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 14.dp, vertical = 4.dp),
                    ) {
                        GlassChip(
                            label = "Starred only · ${state.starredMessages.size}",
                            selected = true,
                            onClick = viewModel::toggleStarredOnly,
                        )
                        Spacer(Modifier.weight(1f))
                        GlassChip(
                            label = "Show all",
                            onClick = viewModel::toggleStarredOnly,
                        )
                    }
                }

                BoxWithConstraints(Modifier.weight(1f)) {
                    val bubbleMaxWidth = minOf(maxWidth * 0.78f, 520.dp)
                    when {
                        state.isLoading -> GlassLoadingState("Opening conversation…")
                        state.notFound -> MissingChatNotice(onBack = onBack)
                        state.searchQuery.isNotBlank() -> SearchResultsList(
                            results = state.searchResults,
                            onSelect = { message ->
                                pendingScrollTarget = message.id
                                viewModel.closeSearch()
                            },
                        )

                        else -> {
                            val items = if (state.starredOnly) {
                                buildTimeline(state.starredMessages)
                            } else {
                                state.timeline
                            }
                            var previousCount by remember { mutableIntStateOf(items.size) }
                            LaunchedEffect(items.size) {
                                if (items.size > previousCount) {
                                    val last = items.lastOrNull()
                                    val lastIsMine = last is ChatTimelineItem.Bubble && last.message.isFromMe
                                    if (!listState.canScrollForward || lastIsMine) {
                                        listState.animateScrollToItem(items.lastIndex)
                                    }
                                }
                                previousCount = items.size
                            }
                            LaunchedEffect(pendingScrollTarget, items.size) {
                                val target = pendingScrollTarget ?: return@LaunchedEffect
                                val index = items.indexOfFirst {
                                    it is ChatTimelineItem.Bubble && it.message.id == target
                                }
                                if (index >= 0) {
                                    listState.animateScrollToItem(index)
                                    pendingScrollTarget = null
                                }
                            }
                            if (items.isEmpty()) {
                                EmptyConversationHint(
                                    contactName = state.contact?.firstName ?: "them",
                                    onOpenSettings = { onOpenSettings(state.chat?.id.orEmpty()) },
                                )
                            } else {
                                LazyColumn(
                                    state = listState,
                                    modifier = Modifier.fillMaxSize(),
                                    contentPadding = PaddingValues(
                                        start = 12.dp,
                                        end = 12.dp,
                                        top = 8.dp,
                                        bottom = 10.dp,
                                    ),
                                    verticalArrangement = Arrangement.spacedBy(3.dp),
                                ) {
                                    items(items = items, key = { it.key }) { item ->
                                        when (item) {
                                            is ChatTimelineItem.Day -> ChatDaySeparator(item.label)
                                            is ChatTimelineItem.Bubble -> {
                                                val index = items.indexOf(item)
                                                val previous = (index - 1)
                                                    .takeIf { it >= 0 }
                                                    ?.let { items[it] as? ChatTimelineItem.Bubble }
                                                MessageBubble(
                                                    message = item.message,
                                                    isGroup = state.isGroup,
                                                    showSenderName = previous?.message?.senderLabel != item.message.senderLabel,
                                                    tightTop = previous != null &&
                                                        previous.message.senderType == item.message.senderType,
                                                    showTimestamps = state.preferences.showTimestamps,
                                                    showSimulatedStatus = state.preferences.showSimulatedStatus,
                                                    accentColor = Color(state.accentColor),
                                                    bubbleColorMe = state.bubbleColorMe?.let { Color(it) },
                                                    bubbleColorOther = state.bubbleColorOther?.let { Color(it) },
                                                    maxBubbleWidth = bubbleMaxWidth,
                                                    onLongPress = { actionTarget = item.message },
                                                    onOpenMedia = {
                                                        onOpenViewer(state.chat?.id.orEmpty(), item.message.id)
                                                    },
                                                    onOpenDocument = { attachment ->
                                                        openDocument(context, viewModel, attachment, ::showSnack)
                                                    },
                                                    onToggleReaction = { emoji ->
                                                        viewModel.toggleReaction(item.message.id, emoji)
                                                    },
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if (state.simulateTyping && state.senderType == SenderType.CONTACT) {
                    Box(Modifier.padding(horizontal = 14.dp, vertical = 4.dp)) {
                        TypingIndicatorBubble(
                            senderName = state.activeSenderName,
                            accentColor = if (reduceMotion) colors.accent else colors.auroraSecondary,
                        )
                    }
                }

                ChatComposer(
                    state = state,
                    onDraftChange = viewModel::onDraftChange,
                    onSend = {
                        if (state.preferences.hapticsEnabled) {
                            haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        }
                        viewModel.onSend()
                    },
                    onSenderSelected = { type, contactId -> viewModel.selectSender(type, contactId) },
                    onPickGroupSender = { showSenderPicker = true },
                    onAttachClick = { showAttach = true },
                    onEmojiClick = { showEmoji = true },
                    onCameraClick = {
                        viewModel.prepareCameraCapture { target ->
                            if (target != null) {
                                capture = target
                                cameraLauncher.launch(Uri.parse(target.contentUri))
                            } else {
                                showSnack("Camera is unavailable on this device")
                            }
                        }
                    },
                    onMicClick = {
                        if (ContextCompat.checkSelfPermission(
                                context,
                                android.Manifest.permission.RECORD_AUDIO,
                            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                        ) {
                            viewModel.startRecording()
                        } else {
                            micPermission.launch(android.Manifest.permission.RECORD_AUDIO)
                        }
                    },
                    onStopRecording = viewModel::stopRecording,
                    onCancelRecording = viewModel::cancelRecording,
                    onCancelReply = viewModel::cancelReply,
                    onCancelEdit = viewModel::cancelEdit,
                    onRemovePending = viewModel::removePendingAttachment,
                    onCaptionChange = viewModel::updatePendingCaption,
                )
            }
        }
    }

    if (showMenu) {
        ChatMenuSheet(
            muted = state.chat?.isMuted == true,
            pinned = state.chat?.isPinned == true,
            simulateTyping = state.simulateTyping,
            starredOnly = state.starredOnly,
            onDismiss = { showMenu = false },
            onToggleTyping = { viewModel.toggleTypingSimulation() },
            onToggleStarredOnly = {
                viewModel.toggleStarredOnly()
                showMenu = false
            },
            onMarkUnread = {
                viewModel.markUnread()
                showMenu = false
                onBack()
            },
            onToggleMute = { viewModel.toggleMute(state.chat?.isMuted == true) },
            onTogglePin = {
                viewModel.togglePin(state.chat?.isPinned == true)
                showMenu = false
            },
            onArchive = {
                viewModel.archive()
                showMenu = false
                onBack()
            },
            onSearch = {
                viewModel.onSearchChange(" ")
                showMenu = false
            },
            onOpenSettings = {
                showMenu = false
                onOpenSettings(state.chat?.id.orEmpty())
            },
            onClearMessages = {
                showMenu = false
                confirmClear = true
            },
            onDeleteChat = {
                showMenu = false
                confirmDelete = true
            },
        )
    }

    if (showAttach) {
        AttachmentSheet(
            onDismiss = { showAttach = false },
            onPhoto = {
                showAttach = false
                photoPicker.launch(
                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly),
                )
            },
            onVideo = {
                showAttach = false
                videoPicker.launch(
                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.VideoOnly),
                )
            },
            onDocument = {
                showAttach = false
                documentPicker.launch(arrayOf("*/*"))
            },
            onAudioFile = {
                showAttach = false
                audioPicker.launch(arrayOf("audio/*"))
            },
            onCamera = {
                showAttach = false
                viewModel.prepareCameraCapture { target ->
                    if (target != null) {
                        capture = target
                        cameraLauncher.launch(Uri.parse(target.contentUri))
                    } else {
                        showSnack("Camera is unavailable on this device")
                    }
                }
            },
            onVoiceNote = {
                showAttach = false
                if (ContextCompat.checkSelfPermission(
                        context,
                        android.Manifest.permission.RECORD_AUDIO,
                    ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                ) {
                    viewModel.startRecording()
                } else {
                    micPermission.launch(android.Manifest.permission.RECORD_AUDIO)
                }
            },
            onLocation = {
                showAttach = false
                viewModel.sendPlaceholderMessage(
                    "📍 Location shared (placeholder)\nAdd a note about this place — no GPS is used.",
                )
            },
            onContactCard = {
                showAttach = false
                val card = state.contact?.let { contact ->
                    "👤 Contact card (placeholder)\n${contact.name}" +
                        contact.phoneLabel.takeIf { it.isNotBlank() }?.let { "\n$it" }.orEmpty()
                } ?: "👤 Contact card (placeholder)"
                viewModel.sendPlaceholderMessage(card)
            },
        )
    }

    if (showEmoji) {
        EmojiSheet(
            onDismiss = { showEmoji = false },
            onPick = { emoji ->
                viewModel.onDraftChange(state.draft + emoji)
                showEmoji = false
            },
        )
    }

    if (showSenderPicker) {
        ParticipantPickerSheet(
            participants = state.participants,
            onDismiss = { showSenderPicker = false },
            onPick = { participant ->
                viewModel.selectSenderParticipant(participant.contactId)
                showSenderPicker = false
            },
        )
    }

    actionTarget?.let { message ->
        MessageActionsSheet(
            message = message,
            meName = state.preferences.displayName.ifBlank { "Me" },
            contactName = state.contact?.name ?: "Contact",
            participants = state.participants,
            onDismiss = { actionTarget = null },
            onReply = {
                viewModel.onReply(message)
                actionTarget = null
            },
            onCopy = {
                clipboard.setText(AnnotatedString(message.text))
                actionTarget = null
                showSnack("Copied to clipboard")
            },
            onToggleStar = {
                viewModel.setStarred(message.id, !message.isStarred)
                actionTarget = null
            },
            onEdit = {
                viewModel.onStartEdit(message)
                actionTarget = null
            },
            onDeleteForMe = {
                viewModel.deleteForMe(message.id)
                actionTarget = null
            },
            onDeleteForEveryone = {
                viewModel.deleteForEveryone(message.id)
                actionTarget = null
            },
            onReact = { emoji, senderType, contactId ->
                viewModel.toggleReaction(message.id, emoji, senderType)
                actionTarget = null
            },
        )
    }

    if (confirmClear) {
        GlassDialog(
            title = "Clear all messages?",
            message = "Every message in this chat will be removed. The contacts and chat settings stay.",
            confirmLabel = "Clear",
            destructive = true,
            onConfirm = {
                viewModel.clearChat()
                confirmClear = false
            },
            onDismiss = { confirmClear = false },
        )
    }

    if (confirmDelete) {
        GlassDialog(
            title = "Delete this chat?",
            message = "The conversation, its media and its messages will be permanently deleted from this device.",
            confirmLabel = "Delete",
            destructive = true,
            onConfirm = {
                confirmDelete = false
                viewModel.deleteChat(onDeleted = onBack)
            },
            onDismiss = { confirmDelete = false },
        )
    }
}

@Composable
private fun ChatTopBar(
    state: ChatUiState,
    sharedTransitionScope: SharedTransitionScope,
    animatedVisibilityScope: AnimatedVisibilityScope,
    onBack: () -> Unit,
    onOpenDetails: () -> Unit,
    onSearch: () -> Unit,
    onMore: () -> Unit,
) {
    val colors = LocalGlassColors.current
    val title = state.chat?.title?.takeIf { it.isNotBlank() }
        ?: state.contact?.name
        ?: "Conversation"
    val subtitle = buildString {
        if (state.isGroup) {
            append("${state.participants.size} fictional participants")
        } else {
            state.contact?.bio?.takeIf { it.isNotBlank() }?.let { append(it.take(42)) }
                ?: append("Private simulation")
        }
        append(" · simulated")
    }
    val avatarModifier = with(sharedTransitionScope) {
        Modifier.sharedElement(
            sharedContentState = rememberSharedContentState(
                key = "chat-avatar-${state.chat?.id.orEmpty()}",
            ),
            animatedVisibilityScope = animatedVisibilityScope,
        )
    }

    GlassTopBar(
        title = title,
        subtitle = subtitle,
        onBack = onBack,
        compact = true,
        leading = {
            Box(Modifier.combinedClickable(onClick = onOpenDetails, onLongClick = onOpenDetails)) {
                if (state.isGroup) {
                    GlassGroupAvatar(
                        name = title,
                        accentColor = Color(state.participants.firstOrNull()?.accentColor ?: 0xFF8C7CFF),
                        modifier = avatarModifier,
                        size = 42.dp,
                    )
                } else {
                    GlassAvatar(
                        name = title,
                        accentColor = state.contact?.accentColor?.let { Color(it) } ?: colors.accent,
                        avatarUri = state.contact?.avatarUri,
                        modifier = avatarModifier,
                        size = 42.dp,
                    )
                }
            }
        },
        actions = {
            GlassIconButton(
                icon = Icons.Outlined.Search,
                contentDescription = "Search in this chat",
                background = null,
                onClick = onSearch,
            )
            GlassIconButton(
                icon = Icons.Filled.MoreVert,
                contentDescription = "More chat options",
                background = null,
                onClick = onMore,
            )
        },
    )
}

@Composable
private fun InChatSearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    onClose: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.weight(1f)) {
            GlassSearchField(
                query = query.trim(),
                onQueryChange = onQueryChange,
                placeholder = "Search messages",
            )
        }
        Spacer(Modifier.width(6.dp))
        GlassChip(label = "Done", onClick = onClose)
    }
}

@Composable
private fun SearchResultsList(
    results: List<Message>,
    onSelect: (Message) -> Unit,
) {
    val colors = LocalGlassColors.current
    if (results.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text(
                text = "No messages match that search",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.textSecondary,
            )
        }
        return
    }
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 14.dp, vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items(items = results, key = { it.id }) { message ->
            com.glasschat.app.ui.glass.GlassCard(
                onClick = { onSelect(message) },
                padding = PaddingValues(12.dp),
            ) {
                Column {
                    Row {
                        Text(
                            text = message.senderLabel,
                            style = MaterialTheme.typography.labelMedium,
                            color = colors.accent,
                        )
                        Spacer(Modifier.weight(1f))
                        Text(
                            text = TimeFormat.full(message.createdAt),
                            style = MaterialTheme.typography.labelSmall,
                            color = colors.textTertiary,
                        )
                    }
                    Spacer(Modifier.height(3.dp))
                    Text(
                        text = message.text.ifBlank { "Attachment" },
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textPrimary,
                        maxLines = 3,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
    }
}

@Composable
private fun MissingChatNotice(onBack: () -> Unit) {
    val colors = LocalGlassColors.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(28.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        SimulatedPill(text = "Chat unavailable")
        Spacer(Modifier.height(10.dp))
        Text(
            text = "This conversation is no longer on the device.",
            style = MaterialTheme.typography.titleLarge,
            color = colors.textPrimary,
        )
        Spacer(Modifier.height(8.dp))
        GlassChip(label = "Go back", selected = true, onClick = onBack)
    }
}

/** Opens a private document copy through the system viewer via a scoped FileProvider URI. */
private fun openDocument(
    context: Context,
    viewModel: ChatViewModel,
    attachment: Attachment,
    onError: (String, String?) -> Unit,
) {
    viewModel.resolveContentUri(attachment.id) { uriString ->
        if (uriString == null) {
            onError("That file is no longer available", null)
            return@resolveContentUri
        }
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.parse(uriString), attachment.mimeType ?: "*/*")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        try {
            context.startActivity(Intent.createChooser(intent, "Open with"))
        } catch (error: ActivityNotFoundException) {
            onError("No app can open this file type", null)
        }
    }
}

/** Reads the human-readable name of a SAF document (used for document bubbles). */
private fun displayNameOf(context: Context, uri: Uri): String? = runCatching {
    context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
        ?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) cursor.getString(index) else null
            } else {
                null
            }
        }
}.getOrNull()
