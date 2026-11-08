package com.glasschat.app.ui.features.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.domain.model.ThemeMode
import com.glasschat.app.ui.components.AccentColorPicker
import com.glasschat.app.ui.components.ColorSwatchRow
import com.glasschat.app.ui.components.FontScalePicker
import com.glasschat.app.ui.components.WallpaperPicker
import com.glasschat.app.ui.components.toArgbLong
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.glass.GlassSegmentedControl
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassSwitch
import com.glasschat.app.ui.theme.AccentPalette
import com.glasschat.app.ui.theme.LocalGlassColors

@Composable
fun AppearanceScreen(
    onBack: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    val prefs = state.preferences

    GlassScaffold(
        reserveBottomBar = false,
        topBar = { SettingsSubHeader("Appearance", "Make it feel like yours", onBack) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            GlassSectionHeader(title = "Theme")
            GlassCard {
                Column {
                    GlassSegmentedControl(
                        options = ThemeMode.entries.toList(),
                        selected = prefs.themeMode,
                        onSelect = viewModel::setThemeMode,
                        label = { mode ->
                            when (mode) {
                                ThemeMode.SYSTEM -> "System"
                                ThemeMode.LIGHT -> "Light"
                                ThemeMode.DARK -> "Dark"
                            }
                        },
                    )
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = "Accent colour",
                        style = MaterialTheme.typography.labelMedium,
                        color = colors.textTertiary,
                    )
                    Spacer(Modifier.height(4.dp))
                    AccentColorPicker(
                        selected = prefs.accent,
                        onSelect = { color -> color?.let(viewModel::setAccent) },
                        allowInherit = false,
                    )
                }
            }

            GlassSectionHeader(title = "Chat bubbles")
            GlassCard {
                Column {
                    Text(
                        text = "Applies when a chat has no custom colour",
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.textTertiary,
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = "My messages",
                        style = MaterialTheme.typography.labelMedium,
                        color = colors.textTertiary,
                    )
                    ColorSwatchRow(
                        swatches = AccentPalette.options.map { it.color },
                        selected = prefs.bubbleColorMe?.let { Color(it) },
                        onSelect = { color ->
                            viewModel.setBubbleColors(color?.toArgbLong(), prefs.bubbleColorOther)
                        },
                        defaultLabel = "Follows accent",
                    )
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = "Their messages",
                        style = MaterialTheme.typography.labelMedium,
                        color = colors.textTertiary,
                    )
                    ColorSwatchRow(
                        swatches = AccentPalette.options.map { it.color },
                        selected = prefs.bubbleColorOther?.let { Color(it) },
                        onSelect = { color ->
                            viewModel.setBubbleColors(prefs.bubbleColorMe, color?.toArgbLong())
                        },
                        defaultLabel = "Frosted glass",
                    )
                }
            }

            GlassSectionHeader(title = "Wallpaper")
            GlassCard {
                WallpaperPicker(
                    selected = prefs.wallpaper,
                    onSelect = { id -> id?.let(viewModel::setWallpaper) },
                )
            }

            GlassSectionHeader(title = "Text size")
            GlassCard {
                FontScalePicker(scale = prefs.fontScale, onScaleChange = viewModel::setFontScale)
            }

            GlassSectionHeader(title = "Accessibility")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Reduce transparency",
                        subtitle = "Uses solid panels instead of frosted glass",
                        trailing = {
                            GlassSwitch(
                                checked = prefs.reduceTransparency,
                                onCheckedChange = viewModel::setReduceTransparency,
                            )
                        },
                    )
                    GlassSettingRow(
                        title = "Reduce motion",
                        subtitle = "Turns off drifting backgrounds and spring animations",
                        trailing = {
                            GlassSwitch(
                                checked = prefs.reduceMotion,
                                onCheckedChange = viewModel::setReduceMotion,
                            )
                        },
                    )
                }
            }

            Spacer(Modifier.height(10.dp))
            Text(
                text = "GlassChat follows your system font size on top of the slider above, so text can grow as large as you need.",
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
            )
            Spacer(Modifier.height(24.dp))
        }
    }
}
