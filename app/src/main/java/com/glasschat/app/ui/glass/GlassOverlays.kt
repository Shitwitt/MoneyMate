package com.glasschat.app.ui.glass

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.ui.theme.LocalGlassMotion
import com.glasschat.app.ui.theme.MinimumTouchTarget

/**
 * Bottom sheet with a spring-driven drag handle and an opaque-enough container that stays
 * legible over any wallpaper. Content is expected to provide its own padding.
 */
@Composable
fun GlassSheet(
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = LocalGlassColors.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        sheetState = sheetState,
        shape = RoundedCornerShape(topStart = GlassRadius.sheet, topEnd = GlassRadius.sheet),
        containerColor = colors.toMaterialScheme().surfaceContainer,
        contentColor = colors.textPrimary,
        scrimColor = colors.scrim.copy(alpha = if (colors.isDark) 0.62f else 0.42f),
        tonalElevation = 0.dp,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(top = 12.dp, bottom = 4.dp)
                    .width(44.dp)
                    .height(5.dp)
                    .clip(CircleShape)
                    .background(colors.textTertiary.copy(alpha = 0.45f)),
            )
        },
        content = content,
    )
}

/** Glass dialog used for destructive confirmations and simple prompts. */
@Composable
fun GlassDialog(
    title: String,
    confirmLabel: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
    message: String? = null,
    dismissLabel: String? = "Cancel",
    destructive: Boolean = false,
    content: (@Composable ColumnScope.() -> Unit)? = null,
) {
    val colors = LocalGlassColors.current
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
    ) {
        GlassSurface(
            modifier = modifier
                .padding(horizontal = 28.dp)
                .widthIn(max = 460.dp)
                .fillMaxWidth(),
            shape = RoundedCornerShape(GlassRadius.panel),
            fill = if (colors.reduceTransparency) {
                colors.toMaterialScheme().surfaceContainerHigh
            } else {
                colors.toMaterialScheme().surfaceContainer
            },
            shadowElevation = 28.dp,
        ) {
            Column(Modifier.padding(22.dp)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.headlineSmall,
                    color = colors.textPrimary,
                )
                if (message != null) {
                    Spacer(Modifier.height(10.dp))
                    Text(
                        text = message,
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textSecondary,
                    )
                }
                if (content != null) {
                    Spacer(Modifier.height(16.dp))
                    content()
                }
                Spacer(Modifier.height(18.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    if (dismissLabel != null) {
                        TextButton(onClick = onDismiss) {
                            Text(dismissLabel, color = colors.textSecondary)
                        }
                    }
                    Spacer(Modifier.width(6.dp))
                    TextButton(onClick = onConfirm) {
                        Text(
                            text = confirmLabel,
                            color = if (destructive) colors.danger else colors.accent,
                            style = MaterialTheme.typography.labelLarge,
                        )
                    }
                }
            }
        }
    }
}

/** Friendly empty state with an optional call to action. */
@Composable
fun GlassEmptyState(
    icon: ImageVector,
    title: String,
    body: String,
    modifier: Modifier = Modifier,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
) {
    val colors = LocalGlassColors.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 32.dp, vertical = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        GlassSurface(
            modifier = Modifier.size(84.dp),
            shape = CircleShape,
            fill = colors.glassFill,
            shadowElevation = 10.dp,
        ) {
            Box(Modifier.fillMaxWidth().height(84.dp), contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = colors.accent,
                    modifier = Modifier.size(34.dp),
                )
            }
        }
        Spacer(Modifier.height(18.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            color = colors.textPrimary,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = body,
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textSecondary,
            textAlign = TextAlign.Center,
        )
        if (actionLabel != null && onAction != null) {
            Spacer(Modifier.height(18.dp))
            GlassChip(label = actionLabel, selected = true, onClick = onAction)
        }
    }
}

/** Pulsing glass placeholder shown while the first database emission loads. */
@Composable
fun GlassLoadingState(message: String, modifier: Modifier = Modifier) {
    val colors = LocalGlassColors.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 60.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        CircularProgressIndicator(
            color = colors.accent,
            strokeWidth = 2.5.dp,
            modifier = Modifier.size(34.dp),
        )
        Spacer(Modifier.height(14.dp))
        Text(
            text = message,
            style = MaterialTheme.typography.bodySmall,
            color = colors.textSecondary,
        )
    }
}

/** Single settings row: icon, title/subtitle and a trailing slot. */
@Composable
fun GlassSettingRow(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    icon: ImageVector? = null,
    iconTint: Color = LocalGlassColors.current.accent,
    onClick: (() -> Unit)? = null,
    trailing: @Composable (RowScope.() -> Unit)? = null,
) {
    val colors = LocalGlassColors.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .then(
                if (onClick != null) {
                    Modifier.clickable(role = Role.Button, onClick = onClick)
                } else {
                    Modifier
                },
            )
            .heightIn(min = 56.dp)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) {
            Box(
                modifier = Modifier
                    .size(34.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(iconTint.copy(alpha = 0.16f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = iconTint,
                    modifier = Modifier.size(18.dp),
                )
            }
            Spacer(Modifier.width(14.dp))
        }
        Column(Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = colors.textPrimary,
            )
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.textSecondary,
                )
            }
        }
        trailing?.let { Row(verticalAlignment = Alignment.CenterVertically) { it() } }
    }
}

/** Switch with accent-tinted track and a comfortable 48dp target. */
@Composable
fun GlassSwitch(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    label: String? = null,
) {
    val colors = LocalGlassColors.current
    Switch(
        checked = checked,
        onCheckedChange = onCheckedChange,
        enabled = enabled,
        modifier = modifier.heightIn(min = MinimumTouchTarget),
        colors = SwitchDefaults.colors(
            checkedThumbColor = colors.onAccent,
            checkedTrackColor = colors.accent,
            checkedBorderColor = colors.accent,
            uncheckedThumbColor = colors.textTertiary,
            uncheckedTrackColor = colors.glassFill,
            uncheckedBorderColor = colors.glassBorder,
        ),
    )
}

/**
 * Segmented glass control. Used by the composer to make the active sender unmistakable.
 * Each option can carry an accent dot so "Me" and the contact read differently at a glance.
 */
@Composable
fun <T> GlassSegmentedControl(
    options: List<T>,
    selected: T,
    onSelect: (T) -> Unit,
    label: (T) -> String,
    modifier: Modifier = Modifier,
    accentFor: ((T) -> Color)? = null,
) {
    val colors = LocalGlassColors.current
    val motion = LocalGlassMotion.current
    val resolvedAccent: (T) -> Color = accentFor ?: { colors.accent }
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(GlassRadius.chip))
            .background(colors.glassFill)
            .border(1.dp, colors.glassBorder, RoundedCornerShape(GlassRadius.chip))
            .padding(4.dp),
    ) {
        Row {
            options.forEach { option ->
                val isSelected = option == selected
                val background by animateColorAsState(
                    targetValue = if (isSelected) {
                        resolvedAccent(option).copy(alpha = if (colors.reduceTransparency) 0.30f else 0.22f)
                    } else {
                        Color.Transparent
                    },
                    animationSpec = tween(motion.quick),
                    label = "segmented-bg",
                )
                val textColor by animateColorAsState(
                    targetValue = if (isSelected) colors.textPrimary else colors.textSecondary,
                    animationSpec = tween(motion.quick),
                    label = "segmented-text",
                )
                Row(
                    modifier = Modifier
                        .clip(RoundedCornerShape(GlassRadius.chip - 4.dp))
                        .background(background)
                        .clickable(role = Role.Tab) { onSelect(option) }
                        .heightIn(min = 38.dp)
                        .padding(horizontal = 12.dp, vertical = 7.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(
                        Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(resolvedAccent(option)),
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(
                        text = label(option),
                        style = MaterialTheme.typography.labelLarge,
                        color = textColor,
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

/**
 * Thin indeterminate-free progress line used for audio playback and import progress.
 */
@Composable
fun GlassProgressBar(
    progress: Float,
    modifier: Modifier = Modifier,
    onSeek: ((Float) -> Unit)? = null,
) {
    val colors = LocalGlassColors.current
    val animated by animateFloatAsState(
        targetValue = progress.coerceIn(0f, 1f),
        label = "glass-progress",
    )
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(if (onSeek != null) 28.dp else 6.dp)
            .clickable(enabled = onSeek != null) {
                onSeek?.invoke(progress)
            },
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .align(Alignment.CenterStart)
                .clip(CircleShape)
                .background(colors.textTertiary.copy(alpha = 0.22f)),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(animated)
                    .height(6.dp)
                    .clip(CircleShape)
                    .background(colors.accent),
            )
        }
    }
}

/** Small helper that keeps row dividers aligned under leading icons. */
@Composable
fun GlassSpacer(width: Int = 0, height: Int = 0) {
    if (width > 0) Spacer(Modifier.width(width.dp))
    if (height > 0) Spacer(Modifier.height(height.dp))
}

/** Screen-reader friendly override for compound rows. */
@Composable
fun MergedSemanticsText(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        modifier = modifier.clearAndSetSemantics { },
    )
}
