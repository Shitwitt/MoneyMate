package com.glasschat.app.ui.features.newchat

import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.PersonAdd
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.domain.model.Contact
import com.glasschat.app.ui.components.AccentColorPicker
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassLabeledField
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSearchField
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.theme.LocalGlassColors

@Composable
fun NewChatScreen(
    onBack: () -> Unit,
    onCreated: (String) -> Unit,
    viewModel: NewChatViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current

    GlassScaffold(
        reserveBottomBar = false,
        topBar = {
            GlassTopBar(
                title = "New chat",
                subtitle = if (state.isGroup) "Group · ${state.selectedIds.size} people" else "One-to-one",
                onBack = onBack,
                compact = true,
                actions = {
                    GlassChip(
                        label = if (state.isCreating) "Creating…" else "Create",
                        selected = state.canCreate,
                        onClick = { if (state.canCreate) viewModel.create(onCreated) },
                    )
                },
            )
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 10.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            if (state.selectedIds.isNotEmpty()) {
                item {
                    val selected = state.contacts.filter { it.id in state.selectedIds }
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        items(items = selected, key = { "sel-${it.id}" }) { contact ->
                            GlassChip(
                                label = contact.name.substringBefore(' '),
                                selected = true,
                                onClick = { viewModel.toggleContact(contact.id) },
                            )
                        }
                    }
                }
            }

            item {
                GlassSearchField(
                    query = state.query,
                    onQueryChange = viewModel::onQueryChange,
                    placeholder = "Search or pick contacts",
                )
            }

            item {
                GlassCard(padding = PaddingValues(0.dp)) {
                    Column {
                        GlassSettingRow(
                            title = if (state.showNewContactForm) "Cancel new contact" else "Create a new contact",
                            subtitle = "They will be added to this chat",
                            icon = if (state.showNewContactForm) Icons.Filled.Person else Icons.Outlined.PersonAdd,
                            onClick = viewModel::toggleNewContactForm,
                        )
                        AnimatedVisibility(visible = state.showNewContactForm) {
                            Column(Modifier.padding(horizontal = 16.dp, vertical = 6.dp)) {
                                GlassLabeledField(
                                    label = "Contact name",
                                    value = state.newContactName,
                                    onValueChange = viewModel::onNewContactNameChange,
                                    placeholder = "e.g. Riley Park",
                                )
                                Spacer(Modifier.height(10.dp))
                                Text(
                                    text = "Accent colour",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = colors.textTertiary,
                                )
                                Spacer(Modifier.height(4.dp))
                                AccentColorPicker(
                                    selected = state.newContactAccent,
                                    onSelect = { color ->
                                        color?.let(viewModel::onNewContactAccentChange)
                                    },
                                    allowInherit = false,
                                )
                                Spacer(Modifier.height(10.dp))
                            }
                        }
                    }
                }
            }

            item {
                GlassLabeledField(
                    label = if (state.isGroup) "Group name" else "Chat name (optional)",
                    value = state.title,
                    onValueChange = viewModel::onTitleChange,
                    placeholder = if (state.isGroup) "e.g. Studio trio" else "Defaults to the contact name",
                )
            }

            item {
                Column {
                    GlassSectionHeader(title = "Starting point")
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        items(items = state.templates, key = { it.id }) { template ->
                            GlassChip(
                                label = template.title,
                                selected = state.templateId == template.id,
                                onClick = { viewModel.selectTemplate(template.id) },
                            )
                        }
                    }
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = state.templates.firstOrNull { it.id == state.templateId }?.description.orEmpty(),
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.textTertiary,
                    )
                }
            }

            item { GlassSectionHeader(title = "Contacts") }

            if (state.contacts.isEmpty() && !state.isLoading) {
                item {
                    GlassCard {
                        Text(
                            text = "No contacts yet — create one above to start your first conversation.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = colors.textSecondary,
                        )
                    }
                }
            }

            items(items = state.contacts, key = { it.id }) { contact ->
                ContactSelectRow(
                    contact = contact,
                    selected = contact.id in state.selectedIds,
                    onClick = { viewModel.toggleContact(contact.id) },
                )
            }

            item {
                Spacer(Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                ) {
                    GlassChip(
                        label = if (state.isCreating) "Creating…" else "Create chat",
                        selected = true,
                        leadingIcon = if (state.isGroup) Icons.Outlined.Groups else Icons.Filled.Person,
                        onClick = { if (state.canCreate) viewModel.create(onCreated) },
                    )
                }
                Spacer(Modifier.height(20.dp))
                Text(
                    text = "You can write both sides of every conversation. Nothing is transmitted and no account is created.",
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.textTertiary,
                )
                Spacer(Modifier.height(24.dp))
            }
        }
    }
}

@Composable
private fun ContactSelectRow(
    contact: Contact,
    selected: Boolean,
    onClick: () -> Unit,
) {
    val colors = LocalGlassColors.current
    GlassCard(
        padding = PaddingValues(horizontal = 14.dp, vertical = 11.dp),
        onClick = onClick,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            GlassAvatar(
                name = contact.name,
                accentColor = Color(contact.accentColor),
                avatarUri = contact.avatarUri,
                size = 42.dp,
            )
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    text = contact.name,
                    style = MaterialTheme.typography.titleMedium,
                    color = colors.textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (contact.bio.isNotBlank()) {
                    Text(
                        text = contact.bio,
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.textSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            Box(
                modifier = Modifier
                    .size(26.dp)
                    .clip(CircleShape)
                    .background(
                        if (selected) colors.accent else colors.glassFill,
                    ),
                contentAlignment = Alignment.Center,
            ) {
                if (selected) {
                    Icon(
                        imageVector = Icons.Filled.Check,
                        contentDescription = "Selected",
                        tint = colors.onAccent,
                        modifier = Modifier.size(16.dp),
                    )
                }
            }
        }
    }
}
