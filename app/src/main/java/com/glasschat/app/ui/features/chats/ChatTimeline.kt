package com.glasschat.app.ui.features.chats

import com.glasschat.app.domain.model.Message
import com.glasschat.app.util.TimeFormat

/** Flat list model for the conversation: day separators plus message rows. */
sealed interface ChatTimelineItem {
    val key: String

    data class Day(val label: String, override val key: String) : ChatTimelineItem

    data class Bubble(val message: Message, override val key: String) : ChatTimelineItem
}

fun buildTimeline(messages: List<Message>): List<ChatTimelineItem> {
    val items = ArrayList<ChatTimelineItem>(messages.size + 4)
    var lastDay: String? = null
    messages.forEach { message ->
        val dayKey = TimeFormat.dayKey(message.createdAt)
        if (dayKey != lastDay) {
            items += ChatTimelineItem.Day(
                label = TimeFormat.daySeparator(message.createdAt),
                key = "day-$dayKey",
            )
            lastDay = dayKey
        }
        items += ChatTimelineItem.Bubble(message = message, key = message.id)
    }
    return items
}
