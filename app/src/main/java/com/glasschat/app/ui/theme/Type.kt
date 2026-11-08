package com.glasschat.app.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.sp

/**
 * Typography tuned for translucency: slightly tighter display weights, generous body line
 * height, and tabular-friendly numerals for timestamps. A user font-size multiplier scales
 * every token so Android's own font scaling still applies on top.
 */
private val Sans = FontFamily.SansSerif
private val Rounded = FontFamily.SansSerif

fun buildTypography(scale: Float): Typography {
    fun sp(value: Float) = (value * scale).sp
    val lineHeight = LineHeightStyle(
        alignment = LineHeightStyle.Alignment.Center,
        trim = LineHeightStyle.Trim.None,
    )

    return Typography(
        displayLarge = TextStyle(
            fontFamily = Rounded,
            fontWeight = FontWeight.SemiBold,
            fontSize = sp(40f),
            lineHeight = sp(46f),
            letterSpacing = (-0.8).sp,
            lineHeightStyle = lineHeight,
        ),
        displayMedium = TextStyle(
            fontFamily = Rounded,
            fontWeight = FontWeight.SemiBold,
            fontSize = sp(32f),
            lineHeight = sp(38f),
            letterSpacing = (-0.5).sp,
        ),
        displaySmall = TextStyle(
            fontFamily = Rounded,
            fontWeight = FontWeight.SemiBold,
            fontSize = sp(26f),
            lineHeight = sp(32f),
            letterSpacing = (-0.2).sp,
        ),
        headlineLarge = TextStyle(
            fontFamily = Rounded,
            fontWeight = FontWeight.SemiBold,
            fontSize = sp(24f),
            lineHeight = sp(30f),
            letterSpacing = (-0.2).sp,
        ),
        headlineMedium = TextStyle(
            fontFamily = Rounded,
            fontWeight = FontWeight.SemiBold,
            fontSize = sp(21f),
            lineHeight = sp(27f),
        ),
        headlineSmall = TextStyle(
            fontFamily = Rounded,
            fontWeight = FontWeight.Medium,
            fontSize = sp(19f),
            lineHeight = sp(25f),
        ),
        titleLarge = TextStyle(
            fontFamily = Sans,
            fontWeight = FontWeight.SemiBold,
            fontSize = sp(18f),
            lineHeight = sp(24f),
            letterSpacing = 0.sp,
        ),
        titleMedium = TextStyle(
            fontFamily = Sans,
            fontWeight = FontWeight.Medium,
            fontSize = sp(16f),
            lineHeight = sp(22f),
        ),
        titleSmall = TextStyle(
            fontFamily = Sans,
            fontWeight = FontWeight.Medium,
            fontSize = sp(14f),
            lineHeight = sp(19f),
        ),
        bodyLarge = TextStyle(
            fontFamily = Sans,
            fontWeight = FontWeight.Normal,
            fontSize = sp(16f),
            lineHeight = sp(23f),
            letterSpacing = 0.1.sp,
        ),
        bodyMedium = TextStyle(
            fontFamily = Sans,
            fontWeight = FontWeight.Normal,
            fontSize = sp(14.5f),
            lineHeight = sp(21f),
        ),
        bodySmall = TextStyle(
            fontFamily = Sans,
            fontWeight = FontWeight.Normal,
            fontSize = sp(12.5f),
            lineHeight = sp(17f),
            letterSpacing = 0.1.sp,
        ),
        labelLarge = TextStyle(
            fontFamily = Sans,
            fontWeight = FontWeight.Medium,
            fontSize = sp(13.5f),
            lineHeight = sp(18f),
            letterSpacing = 0.2.sp,
        ),
        labelMedium = TextStyle(
            fontFamily = Sans,
            fontWeight = FontWeight.Medium,
            fontSize = sp(11.5f),
            lineHeight = sp(15f),
            letterSpacing = 0.3.sp,
        ),
        labelSmall = TextStyle(
            fontFamily = Sans,
            fontWeight = FontWeight.Medium,
            fontSize = sp(10.5f),
            lineHeight = sp(14f),
            letterSpacing = 0.4.sp,
        ),
    )
}
