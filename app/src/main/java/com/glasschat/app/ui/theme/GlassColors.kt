package com.glasschat.app.ui.theme

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.luminance

/**
 * Semantic colour tokens for the liquid-glass system.
 *
 * Every surface is described in terms of *layers* rather than raw hex values, so the
 * "reduce transparency" accessibility mode can swap translucent fills for opaque ones
 * without any screen needing to know about it.
 */
@Immutable
data class GlassColors(
    val isDark: Boolean,
    val reduceTransparency: Boolean,
    val backdropTop: Color,
    val backdropBottom: Color,
    val auroraPrimary: Color,
    val auroraSecondary: Color,
    val auroraTertiary: Color,
    val glassFill: Color,
    val glassFillStrong: Color,
    val glassBorder: Color,
    val glassHighlight: Color,
    val glassShadow: Color,
    val glassInset: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val accent: Color,
    val onAccent: Color,
    val bubbleMeStart: Color,
    val bubbleMeEnd: Color,
    val bubbleOther: Color,
    val bubbleOtherBorder: Color,
    val bubbleTextMe: Color,
    val bubbleTextOther: Color,
    val danger: Color,
    val success: Color,
    val warning: Color,
    val scrim: Color,
    val divider: Color,
    val mediaPlaceholder: Color,
) {
    val bubbleGradient: List<Color> get() = listOf(bubbleMeStart, bubbleMeEnd)

    /** Material 3 scheme so stock components (switches, snackbars, sheets) stay coherent. */
    fun toMaterialScheme(): ColorScheme {
        val base = if (isDark) {
            darkColorScheme(
                primary = accent,
                onPrimary = onAccent,
                primaryContainer = accent.copy(alpha = 0.22f),
                onPrimaryContainer = textPrimary,
                secondary = auroraSecondary,
                onSecondary = onAccent,
                tertiary = auroraTertiary,
                background = backdropBottom,
                onBackground = textPrimary,
                surface = surfaceOpaque,
                onSurface = textPrimary,
                surfaceVariant = surfaceOpaqueVariant,
                onSurfaceVariant = textSecondary,
                error = danger,
                onError = Color.White,
                outline = glassBorder,
                outlineVariant = divider,
                scrim = scrim,
                inverseSurface = textPrimary,
                inverseOnSurface = backdropBottom,
                surfaceContainer = surfaceOpaqueVariant,
                surfaceContainerHigh = surfaceOpaque,
                surfaceContainerHighest = surfaceOpaque,
                surfaceContainerLow = surfaceOpaqueVariant,
                surfaceContainerLowest = backdropBottom,
            )
        } else {
            lightColorScheme(
                primary = accent,
                onPrimary = onAccent,
                primaryContainer = accent.copy(alpha = 0.18f),
                onPrimaryContainer = textPrimary,
                secondary = auroraSecondary,
                onSecondary = Color.White,
                tertiary = auroraTertiary,
                background = backdropBottom,
                onBackground = textPrimary,
                surface = surfaceOpaque,
                onSurface = textPrimary,
                surfaceVariant = surfaceOpaqueVariant,
                onSurfaceVariant = textSecondary,
                error = danger,
                onError = Color.White,
                outline = glassBorder,
                outlineVariant = divider,
                scrim = scrim,
                inverseSurface = Color(0xFF18203A),
                inverseOnSurface = Color.White,
                surfaceContainer = surfaceOpaqueVariant,
                surfaceContainerHigh = surfaceOpaque,
                surfaceContainerHighest = surfaceOpaque,
                surfaceContainerLow = surfaceOpaqueVariant,
                surfaceContainerLowest = backdropBottom,
            )
        }
        return base
    }

    private val surfaceOpaque: Color
        get() = when {
            !isDark -> Color(0xFFF7F8FD)
            reduceTransparency -> Color(0xFF121A2E)
            else -> Color(0xFF101728)
        }

    private val surfaceOpaqueVariant: Color
        get() = when {
            !isDark -> Color(0xFFEDF0F9)
            reduceTransparency -> Color(0xFF1A2338)
            else -> Color(0xFF161E33)
        }
}

/** Builds the token set for a mode + accent pairing. */
fun glassColors(isDark: Boolean, accent: Color, reduceTransparency: Boolean): GlassColors {
    val bubbleStart = accent
    val bubbleEnd = if (isDark) lerp(accent, Color.Black, 0.28f) else lerp(accent, Color.Black, 0.12f)
    val onAccent = if (accent.luminance() > 0.62f) Color(0xFF11152A) else Color.White

    return if (isDark) {
        GlassColors(
            isDark = true,
            reduceTransparency = reduceTransparency,
            backdropTop = Color(0xFF070B16),
            backdropBottom = Color(0xFF0B1020),
            auroraPrimary = lerp(accent, Color(0xFF0A0F1F), 0.55f),
            auroraSecondary = lerp(Color(0xFF4FE3D5), Color(0xFF0A0F1F), 0.55f),
            auroraTertiary = lerp(Color(0xFF6EC8FF), Color(0xFF0A0F1F), 0.60f),
            glassFill = if (reduceTransparency) Color(0xFF131B2E) else Color.White.copy(alpha = 0.075f),
            glassFillStrong = if (reduceTransparency) Color(0xFF172036) else Color.White.copy(alpha = 0.12f),
            glassBorder = if (reduceTransparency) Color.White.copy(alpha = 0.14f) else Color.White.copy(alpha = 0.16f),
            glassHighlight = Color.White.copy(alpha = 0.32f),
            glassShadow = Color.Black.copy(alpha = 0.42f),
            glassInset = Color.White.copy(alpha = 0.06f),
            textPrimary = Color(0xFFF2F4FF),
            textSecondary = Color(0xFFB3BBD9),
            textTertiary = Color(0xFF8790B3),
            accent = accent,
            onAccent = onAccent,
            bubbleMeStart = bubbleStart,
            bubbleMeEnd = bubbleEnd,
            bubbleOther = if (reduceTransparency) Color(0xFF1B2438) else Color.White.copy(alpha = 0.10f),
            bubbleOtherBorder = Color.White.copy(alpha = 0.14f),
            bubbleTextMe = onAccent,
            bubbleTextOther = Color(0xFFEDF0FF),
            danger = Color(0xFFFF7A8A),
            success = Color(0xFF63E6A8),
            warning = Color(0xFFFFC46B),
            scrim = Color(0xCC05070F),
            divider = Color.White.copy(alpha = 0.10f),
            mediaPlaceholder = Color(0xFF182033),
        )
    } else {
        GlassColors(
            isDark = false,
            reduceTransparency = reduceTransparency,
            backdropTop = Color(0xFFF1F3FC),
            backdropBottom = Color(0xFFE6EAF8),
            auroraPrimary = lerp(accent, Color.White, 0.42f),
            auroraSecondary = lerp(Color(0xFF4FE3D5), Color.White, 0.42f),
            auroraTertiary = lerp(Color(0xFF6EC8FF), Color.White, 0.48f),
            glassFill = if (reduceTransparency) Color(0xFFFDFDFF) else Color.White.copy(alpha = 0.62f),
            glassFillStrong = if (reduceTransparency) Color(0xFFFFFFFF) else Color.White.copy(alpha = 0.78f),
            glassBorder = if (reduceTransparency) Color(0xFFCBD2E6) else Color.White.copy(alpha = 0.95f),
            glassHighlight = Color.White.copy(alpha = 0.95f),
            glassShadow = Color(0xFF33406B).copy(alpha = 0.18f),
            glassInset = Color.White.copy(alpha = 0.55f),
            textPrimary = Color(0xFF111730),
            textSecondary = Color(0xFF4A5578),
            textTertiary = Color(0xFF6E7797),
            accent = accent,
            onAccent = onAccent,
            bubbleMeStart = bubbleStart,
            bubbleMeEnd = bubbleEnd,
            bubbleOther = if (reduceTransparency) Color.White else Color.White.copy(alpha = 0.86f),
            bubbleOtherBorder = Color(0xFFD5DBEC),
            bubbleTextMe = onAccent,
            bubbleTextOther = Color(0xFF18203A),
            danger = Color(0xFFD93A52),
            success = Color(0xFF17A673),
            warning = Color(0xFFC77A11),
            scrim = Color(0x66101828),
            divider = Color(0xFF1B2340).copy(alpha = 0.10f),
            mediaPlaceholder = Color(0xFFE3E8F6),
        )
    }
}
