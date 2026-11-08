package com.glasschat.app.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * GlassChat's accent palette. Deliberately not borrowed from any messaging product:
 * cool violets and teals with a couple of warm counterpoints for personalisation.
 */
data class AccentOption(
    val id: String,
    val label: String,
    val color: Color,
)

object AccentPalette {

    val Iris = Color(0xFF8C7CFF)
    val Aqua = Color(0xFF4FE3D5)
    val Sky = Color(0xFF6EC8FF)
    val Coral = Color(0xFFFF8A7A)
    val Amber = Color(0xFFFFC46B)
    val Rose = Color(0xFFFF7EB6)
    val Lime = Color(0xFFA8E063)
    val Ultramarine = Color(0xFF5B7BFF)

    val options: List<AccentOption> = listOf(
        AccentOption("iris", "Iris", Iris),
        AccentOption("aqua", "Aqua", Aqua),
        AccentOption("sky", "Sky", Sky),
        AccentOption("ultramarine", "Ultramarine", Ultramarine),
        AccentOption("rose", "Rose", Rose),
        AccentOption("coral", "Coral", Coral),
        AccentOption("amber", "Amber", Amber),
        AccentOption("lime", "Lime", Lime),
    )

    /** Deterministic accent for a contact that has not chosen one. */
    fun forKey(key: String): Color {
        if (key.isBlank()) return Iris
        val index = (key.hashCode().toLong() and 0x7FFFFFFF).rem(options.size.toLong()).toInt()
        return options[index].color
    }
}
