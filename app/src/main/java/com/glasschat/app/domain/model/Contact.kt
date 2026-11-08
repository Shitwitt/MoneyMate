package com.glasschat.app.domain.model

/**
 * A person you chat with inside GlassChat. Contacts are fictional by design: they exist
 * only on this device and never map to a real phone number or account.
 */
data class Contact(
    val id: String,
    val name: String,
    val avatarUri: String?,
    val accentColor: Long,
    val bio: String,
    val phoneLabel: String,
    val notes: String,
    val isFavorite: Boolean,
    val isBlocked: Boolean,
    val createdAt: Long,
) {
    val firstName: String get() = name.trim().substringBefore(' ').ifBlank { name }
}
