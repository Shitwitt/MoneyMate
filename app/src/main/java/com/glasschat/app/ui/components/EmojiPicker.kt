package com.glasschat.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.ui.theme.MinimumTouchTarget

/**
 * Hand-picked emoji catalogue (no external font or keyboard dependency). Categories are
 * intentionally small so the picker stays fast and scrolls inside a sheet.
 */
object EmojiCatalog {

    data class Category(val label: String, val emoji: List<String>)

    val categories: List<Category> = listOf(
        Category(
            label = "Smileys",
            emoji = listOf(
                "🙂", "😊", "😄", "😁", "🥹", "😅", "😂", "🤣", "😉", "😍",
                "🥰", "😘", "😎", "🤓", "🧐", "🤔", "🫠", "😴", "🥱", "😌",
                "😔", "😢", "😭", "😤", "😮", "🤯", "🙃", "😶", "🫡", "🤗",
            ),
        ),
        Category(
            label = "Gestures",
            emoji = listOf(
                "👋", "🤝", "👍", "👎", "🙌", "👏", "🤞", "✌️", "🤟", "🫶",
                "👌", "🤌", "🫰", "👉", "👈", "👆", "👇", "☝️", "✊", "🤙",
                "💪", "🙏", "🫂", "🖖",
            ),
        ),
        Category(
            label = "Hearts",
            emoji = listOf(
                "❤️", "🧡", "💛", "💚", "💙", "💜", "🤎", "🖤", "🤍", "💖",
                "💗", "💓", "💞", "💕", "💘", "💝", "💟", "❣️", "💔", "🫀",
            ),
        ),
        Category(
            label = "Nature",
            emoji = listOf(
                "🌙", "⭐", "✨", "🌟", "☀️", "⛅", "🌧️", "⛈️", "🌈", "❄️",
                "🔥", "💧", "🌊", "🌱", "🌿", "🍃", "🌸", "🌼", "🌻", "🌵",
                "🌳", "🪴", "🐾", "🐈", "🐕", "🦋", "🐝", "🕊️",
            ),
        ),
        Category(
            label = "Food",
            emoji = listOf(
                "☕", "🍵", "🧋", "🥤", "🍫", "🍪", "🎂", "🍰", "🍩", "🥐",
                "🍎", "🍊", "🍋", "🍓", "🫐", "🥑", "🍕", "🍜", "🍣", "🥗",
            ),
        ),
        Category(
            label = "Objects",
            emoji = listOf(
                "📷", "🎧", "🎵", "🎶", "🎨", "📚", "✏️", "📝", "💡", "🔮",
                "🧭", "🗺️", "🎁", "🎈", "🏆", "🧩", "🪄", "🔑", "🕯️", "🛋️",
            ),
        ),
        Category(
            label = "Symbols",
            emoji = listOf(
                "✅", "☑️", "⚠️", "💤", "💬", "🔔", "🔕", "📌", "📍", "🔒",
                "🔓", "♾️", "➡️", "⬅️", "🔄", "⏳", "⏰", "📅", "🫧", "🎯",
            ),
        ),
    )
}

@Composable
fun EmojiPicker(
    onPick: (String) -> Unit,
    modifier: Modifier = Modifier,
    recent: List<String> = emptyList(),
) {
    val scroll = rememberScrollState()
    androidx.compose.foundation.layout.Column(
        modifier = modifier
            .fillMaxWidth()
            .height(340.dp)
            .verticalScroll(scroll),
    ) {
        if (recent.isNotEmpty()) {
            EmojiSection(title = "Recently used", emoji = recent, onPick = onPick)
        }
        EmojiCatalog.categories.forEach { category ->
            EmojiSection(title = category.label, emoji = category.emoji, onPick = onPick)
        }
    }
}

@Composable
private fun EmojiSection(
    title: String,
    emoji: List<String>,
    onPick: (String) -> Unit,
) {
    val colors = LocalGlassColors.current
    Text(
        text = title.uppercase(),
        style = MaterialTheme.typography.labelSmall,
        color = colors.textTertiary,
        modifier = Modifier.padding(start = 18.dp, top = 14.dp, bottom = 6.dp),
    )
    FlowRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        emoji.forEach { symbol ->
            Box(
                modifier = Modifier
                    .size(MinimumTouchTarget)
                    .clip(CircleShape)
                    .clickable {
                        onPick(symbol)
                    }
                    .semantics { contentDescription = "Emoji $symbol" },
                contentAlignment = Alignment.Center,
            ) {
                Text(text = symbol, fontSize = 24.sp)
            }
        }
    }
}

/** Compact emoji row attached to the message action sheet. */
@Composable
fun QuickReactionBar(
    onPick: (String) -> Unit,
    modifier: Modifier = Modifier,
    selection: List<String> = listOf("❤️", "😂", "👍", "😮", "😢", "🙏"),
) {
    val colors = LocalGlassColors.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(colors.glassFill)
            .padding(horizontal = 6.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        selection.forEach { emoji ->
            Box(
                modifier = Modifier
                    .size(MinimumTouchTarget)
                    .clip(CircleShape)
                    .clickable { onPick(emoji) },
                contentAlignment = Alignment.Center,
            ) {
                Text(text = emoji, fontSize = 22.sp)
            }
        }
    }
}

/**
 * Colour swatch picker for accents and bubble colours. Tapping the active swatch again
 * clears the override so the chat inherits the app theme.
 */
@Composable
fun ColorSwatchRow(
    swatches: List<androidx.compose.ui.graphics.Color>,
    selected: androidx.compose.ui.graphics.Color?,
    onSelect: (androidx.compose.ui.graphics.Color?) -> Unit,
    modifier: Modifier = Modifier,
    defaultLabel: String = "Theme",
) {
    val theme = LocalGlassColors.current
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(MinimumTouchTarget)
                .clip(CircleShape)
                .clickable { onSelect(null) },
            contentAlignment = Alignment.Center,
        ) {
            Box(
                modifier = Modifier
                    .size(28.dp)
                    .clip(CircleShape)
                    .background(theme.glassFillStrong)
                    .border(
                        1.dp,
                        if (selected == null) theme.accent else theme.glassBorder,
                        CircleShape,
                    ),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "A",
                    style = MaterialTheme.typography.labelMedium,
                    color = if (selected == null) theme.accent else theme.textTertiary,
                )
            }
        }
        swatches.forEach { color ->
            val isSelected = selected != null && color.value == selected.value
            Box(
                modifier = Modifier
                    .size(MinimumTouchTarget)
                    .clip(CircleShape)
                    .clickable { onSelect(color) },
                contentAlignment = Alignment.Center,
            ) {
                Box(
                    modifier = Modifier
                        .size(if (isSelected) 32.dp else 26.dp)
                        .clip(CircleShape)
                        .background(color)
                        .border(
                            width = if (isSelected) 2.dp else 1.dp,
                            color = if (isSelected) theme.textPrimary else theme.glassBorder,
                            shape = CircleShape,
                        ),
                )
            }
        }
    }
    Text(
        text = defaultLabel,
        style = MaterialTheme.typography.labelSmall,
        color = theme.textTertiary,
        modifier = Modifier.padding(top = 4.dp),
    )
}
