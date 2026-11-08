package com.glasschat.app.ui.navigation

/** Single source of truth for every destination in the app. */
object Routes {
    const val ONBOARDING = "onboarding"

    const val CHATS = "chats"
    const val CONTACTS = "contacts"
    const val GALLERY = "gallery"
    const val SETTINGS = "settings"

    const val NEW_CHAT = "new_chat"
    const val ARCHIVED = "archived"
    const val PROFILE = "profile"

    const val CHAT = "chat/{chatId}"
    const val CHAT_SETTINGS = "chat_settings/{chatId}"
    const val CONTACT_DETAIL = "contact/{contactId}"
    const val CONTACT_EDITOR = "contact_editor?contactId={contactId}"
    const val VIEWER = "viewer/{chatId}/{messageId}"

    const val SETTINGS_APPEARANCE = "settings/appearance"
    const val SETTINGS_BEHAVIOUR = "settings/behaviour"
    const val SETTINGS_PRIVACY = "settings/privacy"
    const val SETTINGS_DATA = "settings/data"
    const val SETTINGS_ABOUT = "settings/about"

    fun chat(chatId: String) = "chat/$chatId"
    fun chatSettings(chatId: String) = "chat_settings/$chatId"
    fun contactDetail(contactId: String) = "contact/$contactId"
    fun contactEditor(contactId: String?) =
        if (contactId == null) "contact_editor?contactId=new" else "contact_editor?contactId=$contactId"

    fun viewer(chatId: String, messageId: String) = "viewer/$chatId/$messageId"

    val tabRoutes = setOf(CHATS, CONTACTS, GALLERY, SETTINGS)
}
