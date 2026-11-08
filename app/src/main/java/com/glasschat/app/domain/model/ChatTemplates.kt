package com.glasschat.app.domain.model

/**
 * Optional starting points offered in the New Chat flow. Templates only seed plain text
 * messages that the user can edit or delete afterwards — no data is invented at runtime.
 */
object ChatTemplates {

    val all: List<ChatTemplate> = listOf(
        ChatTemplate(
            id = "blank",
            title = "Empty chat",
            description = "Start from nothing and write both sides yourself.",
            seeds = emptyList(),
        ),
        ChatTemplate(
            id = "weekend",
            title = "Weekend plans",
            description = "A short back-and-forth about meeting up.",
            seeds = listOf(
                SeedMessage(fromMe = false, text = "Are we still on for Saturday?", minutesAgo = 184),
                SeedMessage(fromMe = true, text = "Definitely. Noon at the usual place?", minutesAgo = 176),
                SeedMessage(fromMe = false, text = "Perfect. I'll bring the camera.", minutesAgo = 172),
            ),
        ),
        ChatTemplate(
            id = "checkin",
            title = "Check-in",
            description = "A gentle catch-up thread with a friend abroad.",
            seeds = listOf(
                SeedMessage(fromMe = true, text = "Landed safely. It's beautiful here.", minutesAgo = 2880),
                SeedMessage(fromMe = false, text = "So glad! Send pictures when you can.", minutesAgo = 2870),
                SeedMessage(fromMe = true, text = "Tonight, once the sun sets.", minutesAgo = 2866),
            ),
        ),
        ChatTemplate(
            id = "project",
            title = "Group project",
            description = "A three-person thread with a clear next step.",
            seeds = listOf(
                SeedMessage(fromMe = false, text = "I pushed the draft notes.", minutesAgo = 600),
                SeedMessage(fromMe = true, text = "Reading them now — the outline is strong.", minutesAgo = 596),
                SeedMessage(fromMe = false, text = "Great. Can we review at 4?", minutesAgo = 592),
            ),
        ),
    )

    fun byId(id: String?): ChatTemplate = all.firstOrNull { it.id == id } ?: all.first()
}
