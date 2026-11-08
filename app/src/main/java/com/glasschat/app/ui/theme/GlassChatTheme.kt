package com.glasschat.app.ui.theme

import androidx.compose.animation.core.AnimationSpec
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.spring
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.domain.model.ThemeMode

val LocalGlassColors = staticCompositionLocalOf {
    glassColors(isDark = true, accent = AccentPalette.Iris, reduceTransparency = false)
}

/** `true` when the user asked for fewer translucent surfaces (accessibility). */
val LocalReduceTransparency = staticCompositionLocalOf { false }

/** `true` when the system or the app asks animations to be effectively instant. */
val LocalReduceMotion = staticCompositionLocalOf { false }

/** Motion tokens resolved against the reduced-motion preference. */
@Immutable
data class GlassMotion(
    val reduceMotion: Boolean,
    val quick: Int = if (reduceMotion) 0 else 140,
    val medium: Int = if (reduceMotion) 0 else 260,
    val slow: Int = if (reduceMotion) 0 else 420,
    val springBouncy: AnimationSpec<Float> =
        if (reduceMotion) snap() else spring(dampingRatio = 0.62f, stiffness = 620f),
    val springGentle: AnimationSpec<Float> =
        if (reduceMotion) snap() else spring(dampingRatio = 0.86f, stiffness = 380f),
    /** Alpha/scale spec for taps and message reveals. */
    val springSnappy: AnimationSpec<Float> =
        if (reduceMotion) snap() else spring(dampingRatio = 0.9f, stiffness = 900f),
)

val LocalGlassMotion = staticCompositionLocalOf { GlassMotion(reduceMotion = false) }

/** Mirrors the 48dp minimum touch target we enforce across the app. */
val MinimumTouchTarget = 48.dp

@Composable
fun GlassChatTheme(
    preferences: AppPreferences,
    content: @Composable () -> Unit,
) {
    val systemDark = isSystemInDarkTheme()
    val isDark = when (preferences.themeMode) {
        ThemeMode.SYSTEM -> systemDark
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
    }
    val accent = Color(preferences.accent)
    val colors = remember(isDark, accent, preferences.reduceTransparency) {
        glassColors(isDark, accent, preferences.reduceTransparency)
    }
    val typography = remember(preferences.fontScale) { buildTypography(preferences.fontScale) }
    val motion = remember(preferences.reduceMotion) { GlassMotion(preferences.reduceMotion) }

    val view = LocalView.current
    val darkStatusIcons = !isDark
    androidx.compose.runtime.SideEffect {
        val window = (view.context as? android.app.Activity)?.window ?: return@SideEffect
        WindowCompat.getInsetsController(window, view).apply {
            isAppearanceLightStatusBars = darkStatusIcons
            isAppearanceLightNavigationBars = darkStatusIcons
        }
    }

    CompositionLocalProvider(
        LocalGlassColors provides colors,
        LocalReduceTransparency provides preferences.reduceTransparency,
        LocalReduceMotion provides preferences.reduceMotion,
        LocalGlassMotion provides motion,
    ) {
        MaterialTheme(
            colorScheme = colors.toMaterialScheme(),
            typography = typography,
            shapes = GlassShapes,
            content = content,
        )
    }
}
