package com.glasschat.app.ui.common

/**
 * One-shot message surfaced as a glass snackbar. [action] runs only when the user taps the
 * action label (used for undo), so it stays suspendable and can hit the repositories.
 */
data class UiEvent(
    val message: String,
    val actionLabel: String? = null,
    val action: (suspend () -> Unit)? = null,
)
