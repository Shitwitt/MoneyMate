package com.glasschat.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.util.initialsOf

/**
 * Contact avatar: a photo when one exists, otherwise generated initials on a soft gradient
 * derived from the contact's accent colour. Always drawn inside a glass ring so avatars feel
 * embedded in the surface behind them.
 */
@Composable
fun GlassAvatar(
    name: String,
    accentColor: Color,
    modifier: Modifier = Modifier,
    avatarUri: String? = null,
    size: Dp = 48.dp,
    shape: Shape = CircleShape,
    initials: String = initialsOf(name),
    withRing: Boolean = true,
) {
    val colors = LocalGlassColors.current
    val onAccent = if (accentColor.luminance() > 0.62f) Color(0xFF11152A) else Color.White
    Box(
        modifier = modifier
            .size(size)
            .clip(shape)
            .background(
                Brush.linearGradient(
                    listOf(
                        accentColor.copy(alpha = 0.95f),
                        accentColor.copy(alpha = 0.62f),
                    ),
                ),
            )
            .then(
                if (withRing) {
                    Modifier.border(1.dp, colors.glassHighlight.copy(alpha = 0.45f), shape)
                } else {
                    Modifier
                },
            ),
        contentAlignment = Alignment.Center,
    ) {
        if (avatarUri != null) {
            AsyncImage(
                model = avatarUri,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(size)
                    .clip(shape),
            )
        } else {
            Text(
                text = initials,
                style = when {
                    size >= 64.dp -> MaterialTheme.typography.headlineMedium
                    size >= 48.dp -> MaterialTheme.typography.titleMedium
                    else -> MaterialTheme.typography.labelLarge
                },
                color = onAccent,
            )
        }
    }
}

/** Rounded-square variant used for groups and the user's own profile. */
@Composable
fun GlassGroupAvatar(
    name: String,
    accentColor: Color,
    modifier: Modifier = Modifier,
    size: Dp = 48.dp,
    avatarUri: String? = null,
) {
    GlassAvatar(
        name = name,
        accentColor = accentColor,
        modifier = modifier,
        avatarUri = avatarUri,
        size = size,
        shape = RoundedCornerShape(size * 0.32f),
        initials = initialsOf(name).take(1).ifBlank { "#" },
    )
}

/** Two overlapping avatars for group chats without a custom image. */
@Composable
fun GlassStackedAvatars(
    names: List<String>,
    accents: List<Color>,
    modifier: Modifier = Modifier,
    size: Dp = 46.dp,
) {
    Box(modifier = modifier.size(size)) {
        names.take(2).forEachIndexed { index, name ->
            GlassAvatar(
                name = name,
                accentColor = accents.getOrElse(index) { accents.firstOrNull() ?: Color.Gray },
                size = if (names.size > 1) size * 0.74f else size,
                modifier = Modifier.align(
                    if (index == 0) Alignment.TopStart else Alignment.BottomEnd,
                ),
                initials = initialsOf(name).take(1),
            )
        }
    }
}
