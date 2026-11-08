package com.glasschat.app.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.PersonOutline
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.glasschat.app.ui.glass.GlassBottomBar
import com.glasschat.app.ui.glass.GlassNavItem

enum class GlassTab(val route: String, val label: String) {
    CHATS(Routes.CHATS, "Chats"),
    CONTACTS(Routes.CONTACTS, "Contacts"),
    GALLERY(Routes.GALLERY, "Media"),
    SETTINGS(Routes.SETTINGS, "Settings"),
}

@Composable
fun GlassTabBar(
    selected: GlassTab,
    unreadCount: Int = 0,
    onSelect: (GlassTab) -> Unit,
    modifier: Modifier = Modifier,
) {
    val items = listOf(
        GlassNavItem(
            label = GlassTab.CHATS.label,
            icon = Icons.Outlined.ChatBubbleOutline,
            selectedIcon = Icons.Filled.ChatBubble,
            badgeCount = unreadCount,
        ),
        GlassNavItem(
            label = GlassTab.CONTACTS.label,
            icon = Icons.Outlined.PersonOutline,
            selectedIcon = Icons.Filled.Person,
        ),
        GlassNavItem(
            label = GlassTab.GALLERY.label,
            icon = Icons.Outlined.PhotoLibrary,
            selectedIcon = Icons.Filled.PhotoLibrary,
        ),
        GlassNavItem(
            label = GlassTab.SETTINGS.label,
            icon = Icons.Outlined.Settings,
            selectedIcon = Icons.Filled.Settings,
        ),
    )
    GlassBottomBar(
        items = items,
        selectedIndex = GlassTab.entries.indexOf(selected),
        onSelect = { index -> onSelect(GlassTab.entries[index]) },
        modifier = modifier,
    )
}
