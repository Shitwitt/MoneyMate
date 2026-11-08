package com.glasschat.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors

/**
 * The simulated delivery ticks. Two checks = delivered + read, one = sent. They are always
 * paired with the word "Simulated" elsewhere on screen so nothing implies real delivery.
 */
@Composable
fun SimulatedStatusTicks(
    delivered: Boolean,
    read: Boolean,
    tint: Color,
    modifier: Modifier = Modifier,
) {
    val label = when {
        read -> "✓✓"
        delivered -> "✓"
        else -> "·"
    }
    Text(
        text = label,
        style = MaterialTheme.typography.labelSmall,
        color = if (read) tint else tint.copy(alpha = 0.7f),
        modifier = modifier,
    )
}

/** Small pill that marks a chat as simulated — shown in headers and message footers. */
@Composable
fun SimulatedPill(
    text: String = "Simulated",
    modifier: Modifier = Modifier,
    tint: Color = LocalGlassColors.current.textTertiary,
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(GlassRadius.chip))
            .background(tint.copy(alpha = 0.14f))
            .padding(horizontal = 7.dp, vertical = 2.dp),
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            color = tint,
        )
    }
}

/** Centred day divider used between message groups. */
@Composable
fun DaySeparator(label: String, modifier: Modifier = Modifier) {
    val colors = LocalGlassColors.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = Modifier
                .clip(CircleShape)
                .background(colors.glassFill)
                .border(1.dp, colors.glassBorder, CircleShape)
                .padding(horizontal = 12.dp, vertical = 5.dp),
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = colors.textSecondary,
                textAlign = TextAlign.Center,
            )
        }
    }
}

/** Thin, low-key label used under section headers in lists. */
@Composable
fun ListCaption(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelSmall,
        color = LocalGlassColors.current.textTertiary,
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 20.dp)
            .padding(horizontal = 18.dp, vertical = 4.dp),
        textAlign = TextAlign.Start,
    )
}

/** Centred inline "nothing here yet" note for small subsections. */
@Composable
fun InlineEmptyNote(text: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp, vertical = 22.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.bodySmall,
            color = LocalGlassColors.current.textTertiary,
            textAlign = TextAlign.Center,
        )
    }
}
