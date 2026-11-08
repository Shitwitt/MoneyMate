package com.glasschat.app.util

import java.util.UUID

/** Stable, collision-free identifiers for locally created rows. */
fun newId(): String = UUID.randomUUID().toString()

/** Short id used for transient UI keys (never persisted). */
fun newShortId(): String = UUID.randomUUID().toString().take(8)
