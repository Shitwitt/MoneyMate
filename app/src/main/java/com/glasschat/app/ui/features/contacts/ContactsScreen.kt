package com.glasschat.app.ui.features.contacts

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.domain.model.Contact
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassEmptyState
import com.glasschat.app.ui.glass.GlassFAB
import com.glasschat.app.ui.glass.GlassIconButton
import com.glasschat.app.ui.glass.GlassLoadingState
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSearchField
import com.glasschat.app.ui.glass.GlassSnackbarHost
import com.glasschat.app.ui.glass.GlassSurface
import com.glasschat.app.ui.glass.GlassTopBar
import com.glasschat.app.ui.navigation.GlassTab
import com.glasschat.app.ui.navigation.GlassTabBar
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors

@Composable
fun ContactsScreen(
    onOpenContact: (String) -> Unit,
    onAddContact: () -> Unit,
    onSelectTab: (GlassTab) -> Unit,
    viewModel: ContactsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val colors = LocalGlassColors.current

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            snackbarHostState.showSnackbar(event.message, event.actionLabel)
        }
    }

    GlassScaffold(
        topBar = {
            GlassTopBar(
                title = "Contacts",
                subtitle = "${state.totalContacts} people · fictional or real",
                actions = {
                    GlassIconButton(
                        icon = Icons.Filled.Add,
                        contentDescription = "Add contact",
                        onClick = onAddContact,
                    )
                },
            )
        },
        bottomBar = {
            GlassTabBar(selected = GlassTab.CONTACTS, onSelect = onSelectTab)
        },
        snackbarHost = { GlassSnackbarHost(snackbarHostState) },
        floatingActionButton = {
            GlassFAB(
                icon = Icons.Filled.Add,
                contentDescription = "Add contact",
                onClick = onAddContact,
            )
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            Box(Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                GlassSearchField(
                    query = state.query,
                    onQueryChange = viewModel::onQueryChange,
                    placeholder = "Search contacts",
                )
            }
            when {
                state.isLoading -> GlassLoadingState("Loading contacts…")
                state.groups.isEmpty() -> GlassEmptyState(
                    icon = Icons.Filled.Person,
                    title = if (state.query.isBlank()) "No contacts yet" else "No matches",
                    body = if (state.query.isBlank()) {
                        "Add the people you want to write conversations with. They never need to install anything."
                    } else {
                        "Try a different spelling, or add a new contact."
                    },
                    actionLabel = "Add contact",
                    onAction = onAddContact,
                )

                else -> LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    if (state.favorites.isNotEmpty()) {
                        item(key = "favorites") {
                            Column {
                                Text(
                                    text = "Favourites",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = colors.textTertiary,
                                    modifier = Modifier.padding(start = 6.dp, bottom = 6.dp),
                                )
                                LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                    items(items = state.favorites, key = { "fav-${it.id}" }) { contact ->
                                        FavoriteContactTile(
                                            contact = contact,
                                            onClick = { onOpenContact(contact.id) },
                                        )
                                    }
                                }
                            }
                        }
                    }
                    state.groups.forEach { group ->
                        item(key = "header-${group.letter}") {
                            Text(
                                text = group.letter,
                                style = MaterialTheme.typography.labelMedium,
                                color = colors.accent,
                                modifier = Modifier.padding(start = 8.dp, top = 8.dp, bottom = 2.dp),
                            )
                        }
                        items(items = group.contacts, key = { it.id }) { contact ->
                            ContactRow(
                                contact = contact,
                                onClick = { onOpenContact(contact.id) },
                                onToggleFavorite = {
                                    viewModel.toggleFavorite(contact.id, contact.isFavorite)
                                },
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ContactRow(
    contact: Contact,
    onClick: () -> Unit,
    onToggleFavorite: () -> Unit,
) {
    val colors = LocalGlassColors.current
    com.glasschat.app.ui.glass.GlassCard(
        onClick = onClick,
        padding = PaddingValues(horizontal = 14.dp, vertical = 12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            GlassAvatar(
                name = contact.name,
                accentColor = Color(contact.accentColor),
                avatarUri = contact.avatarUri,
                size = 44.dp,
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
                val detail = contact.bio.ifBlank { contact.phoneLabel }
                if (detail.isNotBlank()) {
                    Text(
                        text = detail,
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.textSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            if (contact.isBlocked) {
                GlassChip(label = "Hidden", onClick = onClick)
                Spacer(Modifier.width(4.dp))
            }
            GlassIconButton(
                icon = if (contact.isFavorite) Icons.Filled.Star else Icons.Outlined.Star,
                contentDescription = if (contact.isFavorite) "Remove favourite" else "Add favourite",
                tint = if (contact.isFavorite) colors.warning else colors.textTertiary,
                background = null,
                onClick = onToggleFavorite,
            )
        }
    }
}

@Composable
private fun FavoriteContactTile(contact: Contact, onClick: () -> Unit) {
    val colors = LocalGlassColors.current
    com.glasschat.app.ui.glass.GlassSurface(
        modifier = Modifier.width(78.dp),
        shape = RoundedCornerShape(GlassRadius.card),
        fill = colors.glassFill,
        shadowElevation = 6.dp,
        onClick = onClick,
    ) {
        Column(
            modifier = Modifier
                .width(78.dp)
                .padding(vertical = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            GlassAvatar(
                name = contact.name,
                accentColor = Color(contact.accentColor),
                avatarUri = contact.avatarUri,
                size = 44.dp,
            )
            Spacer(Modifier.width(6.dp))
            Text(
                text = contact.name.substringBefore(' '),
                style = MaterialTheme.typography.labelSmall,
                color = colors.textPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(top = 6.dp, start = 4.dp, end = 4.dp),
            )
        }
    }
}
