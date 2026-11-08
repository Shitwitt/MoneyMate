package com.glasschat.app.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

val GlassShapes = Shapes(
    extraSmall = RoundedCornerShape(10.dp),
    small = RoundedCornerShape(14.dp),
    medium = RoundedCornerShape(20.dp),
    large = RoundedCornerShape(26.dp),
    extraLarge = RoundedCornerShape(34.dp),
)

/** Shared corner radii so every glass layer rounds consistently. */
object GlassRadius {
    val chip = 18.dp
    val field = 22.dp
    val card = 24.dp
    val panel = 28.dp
    val sheet = 32.dp
    val bar = 30.dp
    val bubble = 22.dp
    val bubbleTight = 8.dp
}
