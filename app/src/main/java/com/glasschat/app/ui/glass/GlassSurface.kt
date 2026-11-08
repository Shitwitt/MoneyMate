package com.glasschat.app.ui.glass

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.ui.theme.MinimumTouchTarget

/**
 * The single primitive every glass surface is built from.
 *
 * Layers, outside in:
 *   1. ambient shadow tinted by the theme (keeps depth grounded on light and dark),
 *   2. translucent fill (or opaque when "reduce transparency" is on),
 *   3. a soft top sheen that mimics light refracting through the panel,
 *   4. a 1dp gradient border with a brighter top edge.
 */
@Composable
fun GlassSurface(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(GlassRadius.card),
    fill: Color = LocalGlassColors.current.glassFill,
    borderColor: Color = LocalGlassColors.current.glassBorder,
    highlight: Color = LocalGlassColors.current.glassHighlight,
    shadowElevation: Dp = 14.dp,
    onClick: (() -> Unit)? = null,
    onClickLabel: String? = null,
    role: Role? = null,
    contentDescription: String? = null,
    content: @Composable BoxScope.() -> Unit,
) {
    val colors = LocalGlassColors.current
    val a11yLabel = contentDescription
    val interactive = if (onClick != null) {
        Modifier.clickable(
            role = role,
            onClickLabel = onClickLabel,
            onClick = onClick,
        )
    } else {
        Modifier
    }
    Box(
        modifier = modifier
            .then(interactive)
            .semantics { if (a11yLabel != null) this.contentDescription = a11yLabel }
            .shadow(
                elevation = shadowElevation,
                shape = shape,
                clip = false,
                ambientColor = colors.glassShadow,
                spotColor = colors.glassShadow,
            )
            .clip(shape)
            .background(
                Brush.linearGradient(
                    colors = listOf(
                        fill,
                        fill,
                        fill.copy(alpha = (fill.alpha * 0.86f).coerceAtLeast(0f)),
                    ),
                    start = Offset.Zero,
                    end = Offset.Infinite,
                ),
            )
            .drawBehind {
                // Top sheen: a soft vertical gradient hugging the upper edge.
                drawRect(
                    brush = Brush.verticalGradient(
                        0f to highlight.copy(alpha = 0.16f),
                        0.45f to Color.Transparent,
                        startY = 0f,
                        endY = size.height,
                    ),
                )
            }
            .border(
                BorderStroke(1.dp, Brush.linearGradient(listOf(borderColor, borderColor.copy(alpha = 0.35f)))),
                shape = shape,
            ),
        content = content,
    )
}

/** Card-like glass panel with comfortable padding. */
@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(GlassRadius.card),
    padding: PaddingValues = PaddingValues(18.dp),
    onClick: (() -> Unit)? = null,
    content: @Composable BoxScope.() -> Unit,
) {
    GlassSurface(
        modifier = modifier.fillMaxWidth(),
        shape = shape,
        onClick = onClick,
        content = {
            Box(Modifier.padding(padding)) { content() }
        },
    )
}

/**
 * Flat-ish glass container used to group list rows. It deliberately keeps the same fill as
 * GlassCard but a smaller shadow so stacked panels don't look heavy.
 */
@Composable
fun GlassPanel(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(GlassRadius.panel),
    content: @Composable BoxScope.() -> Unit,
) {
    GlassSurface(
        modifier = modifier,
        shape = shape,
        shadowElevation = 8.dp,
        content = content,
    )
}

@Composable
fun GlassDivider(modifier: Modifier = Modifier, color: Color = LocalGlassColors.current.divider) {
    Box(
        modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(color),
    )
}

/** Selectable pill used for filters, emoji recents and tag lists. */
@Composable
fun GlassChip(
    label: String,
    modifier: Modifier = Modifier,
    selected: Boolean = false,
    leadingIcon: ImageVector? = null,
    onClick: () -> Unit,
) {
    val colors = LocalGlassColors.current
    val fill = if (selected) colors.accent.copy(alpha = if (colors.reduceTransparency) 1f else 0.28f) else colors.glassFill
    val textColor = if (selected) colors.accent else colors.textSecondary
    GlassSurface(
        modifier = modifier
            .heightIn(min = 36.dp)
            .defaultMinSize(minHeight = 36.dp),
        shape = RoundedCornerShape(GlassRadius.chip),
        fill = fill,
        borderColor = if (selected) colors.accent.copy(alpha = 0.55f) else colors.glassBorder,
        shadowElevation = 0.dp,
        onClick = onClick,
        role = Role.Button,
        content = {
            Row(
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                if (leadingIcon != null) {
                    Icon(
                        imageVector = leadingIcon,
                        contentDescription = null,
                        tint = textColor,
                        modifier = Modifier.size(16.dp),
                    )
                }
                Text(text = label, style = MaterialTheme.typography.labelLarge, color = textColor)
            }
        },
    )
}

/** Circular icon button with an enforced 48dp touch target. */
@Composable
fun GlassIconButton(
    icon: ImageVector,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    tint: Color = LocalGlassColors.current.textPrimary,
    background: Color? = LocalGlassColors.current.glassFill,
    size: Dp = 42.dp,
    onClick: () -> Unit,
) {
    val shape = CircleShape
    Box(
        modifier = modifier
            .size(size)
            .defaultMinSize(MinimumTouchTarget, MinimumTouchTarget)
            .clip(shape)
            .then(if (background != null) Modifier.background(background, shape) else Modifier)
            .clickable(onClick = onClick, role = Role.Button),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = tint,
            modifier = Modifier.size(size * 0.48f),
        )
    }
}

/** Accent gradient FAB — the app's primary creation affordance. */
@Composable
fun GlassFAB(
    icon: ImageVector,
    contentDescription: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val colors = LocalGlassColors.current
    val shape = RoundedCornerShape(22.dp)
    Box(
        modifier = modifier
            .size(60.dp)
            .shadow(
                elevation = 18.dp,
                shape = shape,
                clip = false,
                ambientColor = colors.accent.copy(alpha = 0.55f),
                spotColor = colors.accent.copy(alpha = 0.65f),
            )
            .clip(shape)
            .background(Brush.linearGradient(colors.bubbleGradient))
            .drawBehind {
                drawRect(
                    Brush.verticalGradient(
                        0f to Color.White.copy(alpha = 0.35f),
                        0.55f to Color.Transparent,
                        startY = 0f,
                        endY = size.height,
                    ),
                )
            }
            .border(1.dp, Color.White.copy(alpha = 0.35f), shape)
            .clickable(onClick = onClick, role = Role.Button),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = colors.onAccent,
            modifier = Modifier.size(26.dp),
        )
    }
}

/** Small glass count badge used for unread messages. */
@Composable
fun GlassBadge(
    count: Int,
    modifier: Modifier = Modifier,
    muted: Boolean = false,
) {
    if (count <= 0) return
    val colors = LocalGlassColors.current
    val label = if (count > 99) "99+" else count.toString()
    val background = if (muted) colors.textTertiary else colors.accent
    val fg = if (muted) colors.textPrimary else colors.onAccent
    Box(
        modifier = modifier
            .heightIn(min = 20.dp)
            .defaultMinSize(minWidth = 20.dp)
            .clip(CircleShape)
            .background(background)
            .padding(horizontal = 6.dp, vertical = 2.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = fg,
            maxLines = 1,
        )
    }
}

/** Section title used above grouped settings. */
@Composable
fun GlassSectionHeader(
    title: String,
    modifier: Modifier = Modifier,
    trailing: @Composable (() -> Unit)? = null,
) {
    val colors = LocalGlassColors.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 6.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(
            text = title.uppercase(),
            style = MaterialTheme.typography.labelMedium,
            color = colors.textTertiary,
        )
        trailing?.invoke()
    }
}

/** Horizontal divider inset to align with row text. */
@Composable
fun GlassRowDivider(startPadding: Dp = 0.dp) {
    Row(Modifier.fillMaxWidth()) {
        if (startPadding > 0.dp) Spacer(Modifier.width(startPadding))
        Box(
            Modifier
                .weight(1f)
                .height(1.dp)
                .background(LocalGlassColors.current.divider),
        )
    }
}

/** A bottom-anchored, translucent label used for "simulated" disclaimers. */
@Composable
fun GlassFootnote(text: String, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(GlassRadius.chip),
        color = LocalGlassColors.current.glassFill,
        contentColor = LocalGlassColors.current.textSecondary,
        border = BorderStroke(1.dp, LocalGlassColors.current.glassBorder),
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
        )
    }
}
