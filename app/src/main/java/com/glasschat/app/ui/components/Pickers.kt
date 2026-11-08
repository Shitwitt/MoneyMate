package com.glasschat.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
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
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.ui.theme.AccentPalette
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.ui.theme.Wallpapers

/** Accent colour grid with an optional "inherit theme" option. */
@Composable
fun AccentColorPicker(
    selected: Long?,
    onSelect: (Long?) -> Unit,
    modifier: Modifier = Modifier,
    allowInherit: Boolean = true,
    inheritLabel: String = "Theme",
) {
    val colors = LocalGlassColors.current
    Column(modifier) {
        Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            AccentPalette.options.forEach { option ->
                val isSelected = selected == option.color.toArgbLong()
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .clickable { onSelect(option.color.toArgbLong()) }
                        .semantics { contentDescription = "${option.label} accent" },
                    contentAlignment = Alignment.Center,
                ) {
                    Box(
                        modifier = Modifier
                            .size(if (isSelected) 30.dp else 24.dp)
                            .clip(CircleShape)
                            .background(option.color)
                            .border(
                                width = if (isSelected) 2.dp else 1.dp,
                                color = if (isSelected) colors.textPrimary else colors.glassBorder,
                                shape = CircleShape,
                            ),
                    )
                }
            }
        }
        if (allowInherit) {
            Spacer(Modifier.height(6.dp))
            com.glasschat.app.ui.glass.GlassChip(
                label = inheritLabel,
                selected = selected == null,
                onClick = { onSelect(null) },
            )
        }
    }
}

/** Wallpaper grid used by Settings → Appearance and per-chat settings. */
@Composable
fun WallpaperPicker(
    selected: String?,
    onSelect: (String?) -> Unit,
    modifier: Modifier = Modifier,
    allowThemeDefault: Boolean = false,
    customPreviewUri: String? = null,
    onPickCustom: (() -> Unit)? = null,
) {
    val colors = LocalGlassColors.current
    val options = Wallpapers.presets
    Column(modifier) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            options.take(3).forEach { option ->
                WallpaperTile(
                    label = option.name,
                    palette = Wallpapers.palette(option.id, colors.isDark),
                    selected = selected == option.id,
                    onClick = { onSelect(option.id) },
                )
            }
        }
        Spacer(Modifier.height(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            options.drop(3).forEach { option ->
                WallpaperTile(
                    label = option.name,
                    palette = Wallpapers.palette(option.id, colors.isDark),
                    selected = selected == option.id,
                    onClick = { onSelect(option.id) },
                )
            }
            if (onPickCustom != null) {
                WallpaperTile(
                    label = if (customPreviewUri != null) "Custom" else "Photo",
                    palette = listOf(colors.glassFillStrong, colors.glassFill, colors.accent),
                    selected = selected?.startsWith(AppPreferences.CUSTOM_PREFIX) == true,
                    onClick = onPickCustom,
                )
            }
        }
        if (allowThemeDefault) {
            Spacer(Modifier.height(8.dp))
            com.glasschat.app.ui.glass.GlassChip(
                label = "Use app default",
                selected = selected == null,
                onClick = { onSelect(null) },
            )
        }
    }
}

@Composable
private fun WallpaperTile(
    label: String,
    palette: List<Color>,
    selected: Boolean,
    onClick: () -> Unit,
) {
    val colors = LocalGlassColors.current
    Column(
        modifier = Modifier
            .width(84.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(Brush.verticalGradient(palette.take(2)))
            .border(
                width = if (selected) 2.dp else 1.dp,
                color = if (selected) colors.accent else colors.glassBorder,
                shape = RoundedCornerShape(16.dp),
            )
            .clickable(onClick = onClick)
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(44.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(Brush.verticalGradient(palette)),
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = colors.textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
        )
    }
}

/** Font-scale stepper with a live sample line. */
@Composable
fun FontScalePicker(
    scale: Float,
    onScaleChange: (Float) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val steps = listOf(0.9f to "S", 1f to "M", 1.1f to "L", 1.2f to "XL", 1.3f to "XXL")
    Column(modifier) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            steps.forEach { (value, label) ->
                Box(
                    modifier = Modifier
                        .size(width = 52.dp, height = 44.dp)
                        .clip(RoundedCornerShape(GlassRadius.chip))
                        .background(
                            if (scale == value) {
                                colors.accent.copy(alpha = 0.22f)
                            } else {
                                colors.glassFill
                            },
                        )
                        .border(
                            1.dp,
                            if (scale == value) colors.accent.copy(alpha = 0.6f) else colors.glassBorder,
                            RoundedCornerShape(GlassRadius.chip),
                        )
                        .clickable { onScaleChange(value) },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelLarge,
                        color = if (scale == value) colors.accent else colors.textSecondary,
                    )
                }
            }
        }
        Spacer(Modifier.height(8.dp))
        Text(
            text = "Preview · ${(scale * 100).toInt()}% text size",
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textSecondary,
        )
    }
}

/** Colour -> 0xAARRGGBB long, the format used for persisted accent/bubble colours. */
fun Color.toArgbLong(): Long = toArgb().toLong() and 0xFFFFFFFFL
