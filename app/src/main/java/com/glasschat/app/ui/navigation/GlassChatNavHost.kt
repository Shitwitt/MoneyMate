package com.glasschat.app.ui.navigation

import androidx.compose.animation.SharedTransitionScope
import androidx.compose.animation.SharedTransitionLayout
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.glasschat.app.ui.features.archived.ArchivedChatsScreen
import com.glasschat.app.ui.features.chat.ChatScreen
import com.glasschat.app.ui.features.chats.ChatsScreen
import com.glasschat.app.ui.features.chatsettings.ChatSettingsScreen
import com.glasschat.app.ui.features.contacts.ContactDetailScreen
import com.glasschat.app.ui.features.contacts.ContactEditorScreen
import com.glasschat.app.ui.features.contacts.ContactsScreen
import com.glasschat.app.ui.features.gallery.GalleryScreen
import com.glasschat.app.ui.features.newchat.NewChatScreen
import com.glasschat.app.ui.features.onboarding.OnboardingScreen
import com.glasschat.app.ui.features.profile.ProfileScreen
import com.glasschat.app.ui.features.settings.AboutScreen
import com.glasschat.app.ui.features.settings.AppearanceScreen
import com.glasschat.app.ui.features.settings.BehaviourScreen
import com.glasschat.app.ui.features.settings.DataScreen
import com.glasschat.app.ui.features.settings.PrivacyScreen
import com.glasschat.app.ui.features.settings.SettingsScreen
import com.glasschat.app.ui.features.viewer.MediaViewerScreen

private const val OVERLAY_MS = 320

/** All destinations, wrapped so the chat avatar can animate between list and header. */
@Composable
fun GlassChatNavHost(
    navController: NavHostController,
    startDestination: String,
    modifier: Modifier = Modifier,
) {
    SharedTransitionLayout {
        NavHost(
            navController = navController,
            startDestination = startDestination,
            modifier = modifier,
            enterTransition = {
                fadeIn(tween(220)) + slideInHorizontally(tween(OVERLAY_MS)) { it / 12 }
            },
            exitTransition = { fadeOut(tween(160)) },
            popEnterTransition = { fadeIn(tween(200)) },
            popExitTransition = {
                fadeOut(tween(200)) + slideOutHorizontally(tween(OVERLAY_MS)) { it / 12 }
            },
        ) {
            composable(Routes.ONBOARDING) {
                OnboardingScreen(
                    onFinished = {
                        navController.navigate(Routes.CHATS) {
                            popUpTo(Routes.ONBOARDING) { inclusive = true }
                        }
                    },
                )
            }

            composable(Routes.CHATS) {
                ChatsScreen(
                    sharedTransitionScope = this@SharedTransitionLayout,
                    animatedVisibilityScope = this,
                    onOpenChat = { chatId -> navController.navigate(Routes.chat(chatId)) },
                    onNewChat = { navController.navigate(Routes.NEW_CHAT) },
                    onOpenArchived = { navController.navigate(Routes.ARCHIVED) },
                    onSelectTab = { tab -> navController.switchTab(tab) },
                )
            }

            composable(Routes.CONTACTS) {
                ContactsScreen(
                    onOpenContact = { id -> navController.navigate(Routes.contactDetail(id)) },
                    onAddContact = { navController.navigate(Routes.contactEditor(null)) },
                    onSelectTab = { tab -> navController.switchTab(tab) },
                )
            }

            composable(Routes.GALLERY) {
                GalleryScreen(
                    onOpenMedia = { chatId, messageId ->
                        navController.navigate(Routes.viewer(chatId, messageId))
                    },
                    onSelectTab = { tab -> navController.switchTab(tab) },
                )
            }

            composable(Routes.SETTINGS) {
                SettingsScreen(
                    onSelectTab = { tab -> navController.switchTab(tab) },
                    onOpenProfile = { navController.navigate(Routes.PROFILE) },
                    onOpenAppearance = { navController.navigate(Routes.SETTINGS_APPEARANCE) },
                    onOpenBehaviour = { navController.navigate(Routes.SETTINGS_BEHAVIOUR) },
                    onOpenPrivacy = { navController.navigate(Routes.SETTINGS_PRIVACY) },
                    onOpenData = { navController.navigate(Routes.SETTINGS_DATA) },
                    onOpenAbout = { navController.navigate(Routes.SETTINGS_ABOUT) },
                    onOpenArchived = { navController.navigate(Routes.ARCHIVED) },
                )
            }

            composable(
                route = Routes.CHAT,
                arguments = listOf(navArgument("chatId") { type = NavType.StringType }),
            ) {
                ChatScreen(
                    sharedTransitionScope = this@SharedTransitionLayout,
                    animatedVisibilityScope = this,
                    onBack = { navController.popBackStack() },
                    onOpenSettings = { chatId -> navController.navigate(Routes.chatSettings(chatId)) },
                    onOpenContact = { id -> navController.navigate(Routes.contactDetail(id)) },
                    onOpenViewer = { chatId, messageId ->
                        navController.navigate(Routes.viewer(chatId, messageId))
                    },
                    onOpenGallery = { navController.navigate(Routes.GALLERY) },
                )
            }

            composable(Routes.NEW_CHAT) {
                NewChatScreen(
                    onBack = { navController.popBackStack() },
                    onCreated = { chatId ->
                        navController.navigate(Routes.chat(chatId)) {
                            popUpTo(Routes.NEW_CHAT) { inclusive = true }
                        }
                    },
                )
            }

            composable(
                route = Routes.CONTACT_DETAIL,
                arguments = listOf(navArgument("contactId") { type = NavType.StringType }),
            ) {
                ContactDetailScreen(
                    onBack = { navController.popBackStack() },
                    onEdit = { id -> navController.navigate(Routes.contactEditor(id)) },
                    onOpenChat = { chatId ->
                        navController.navigate(Routes.chat(chatId)) {
                            popUpTo(Routes.CONTACTS)
                        }
                    },
                    onOpenMedia = { chatId, messageId ->
                        navController.navigate(Routes.viewer(chatId, messageId))
                    },
                    onOpenChatSettings = { chatId -> navController.navigate(Routes.chatSettings(chatId)) },
                )
            }

            composable(
                route = Routes.CONTACT_EDITOR,
                arguments = listOf(
                    navArgument("contactId") {
                        type = NavType.StringType
                        defaultValue = "new"
                    },
                ),
            ) {
                ContactEditorScreen(onBack = { navController.popBackStack() })
            }

            composable(
                route = Routes.CHAT_SETTINGS,
                arguments = listOf(navArgument("chatId") { type = NavType.StringType }),
            ) {
                ChatSettingsScreen(
                    onBack = { navController.popBackStack() },
                    onDeleted = {
                        navController.navigate(Routes.CHATS) {
                            popUpTo(Routes.CHATS) { inclusive = true }
                        }
                    },
                    onOpenContact = { id -> navController.navigate(Routes.contactDetail(id)) },
                )
            }

            composable(Routes.ARCHIVED) {
                ArchivedChatsScreen(
                    onBack = { navController.popBackStack() },
                    onOpenChat = { chatId -> navController.navigate(Routes.chat(chatId)) },
                )
            }

            composable(Routes.PROFILE) {
                ProfileScreen(onBack = { navController.popBackStack() })
            }

            composable(Routes.SETTINGS_APPEARANCE) {
                AppearanceScreen(onBack = { navController.popBackStack() })
            }

            composable(Routes.SETTINGS_BEHAVIOUR) {
                BehaviourScreen(onBack = { navController.popBackStack() })
            }

            composable(Routes.SETTINGS_PRIVACY) {
                PrivacyScreen(onBack = { navController.popBackStack() })
            }

            composable(Routes.SETTINGS_DATA) {
                DataScreen(
                    onBack = { navController.popBackStack() },
                    onDataDeleted = {
                        navController.navigate(Routes.ONBOARDING) {
                            popUpTo(0) { inclusive = true }
                        }
                    },
                )
            }

            composable(Routes.SETTINGS_ABOUT) {
                AboutScreen(onBack = { navController.popBackStack() })
            }

            composable(
                route = Routes.VIEWER,
                arguments = listOf(
                    navArgument("chatId") { type = NavType.StringType },
                    navArgument("messageId") { type = NavType.StringType },
                ),
            ) {
                MediaViewerScreen(onBack = { navController.popBackStack() })
            }
        }
    }
}

/** Tab switching never stacks duplicate copies of a tab. */
private fun NavHostController.switchTab(tab: GlassTab) {
    if (currentDestination?.route == tab.route) return
    navigate(tab.route) {
        popUpTo(Routes.CHATS) { saveState = true }
        launchSingleTop = true
        restoreState = true
    }
}
