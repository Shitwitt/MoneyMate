import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paisa's type system.
///
/// Every text style in the app runs through [GoogleFonts.outfitTextTheme] so a
/// single change here restyles the whole product. If the Google Fonts CDN (and
/// on-device cache) is unavailable — which does happen on a fully offline first
/// launch — we silently fall back to the platform text theme instead of
/// crashing the splash screen.
class PaisaTypography {
  const PaisaTypography._();

  /// Visual weight tuning applied on top of Outfit's defaults so headings read
  /// like Paisa's: semibold and slightly tightened.
  static const FontWeight _headingWeight = FontWeight.w600;
  static const FontWeight _titleWeight = FontWeight.w600;

  /// Builds the full text theme.
  ///
  /// [base] is the platform text theme (`Typography.material2021().black` /
  /// `.white`) so sizes and metrics stay Material-correct.
  static TextTheme build(
    TextTheme base, {
    Color? bodyColor,
    Color? displayColor,
  }) {
    TextTheme theme = _outfit(base);
    theme = theme.copyWith(
      displayLarge: theme.displayLarge?.copyWith(
        fontWeight: _headingWeight,
        letterSpacing: -0.6,
      ),
      displayMedium: theme.displayMedium?.copyWith(
        fontWeight: _headingWeight,
        letterSpacing: -0.5,
      ),
      displaySmall: theme.displaySmall?.copyWith(
        fontWeight: _headingWeight,
        letterSpacing: -0.4,
      ),
      headlineLarge: theme.headlineLarge?.copyWith(
        fontWeight: _headingWeight,
        letterSpacing: -0.3,
      ),
      headlineMedium: theme.headlineMedium?.copyWith(
        fontWeight: _headingWeight,
        letterSpacing: -0.3,
      ),
      headlineSmall: theme.headlineSmall?.copyWith(
        fontWeight: _headingWeight,
        letterSpacing: -0.2,
      ),
      titleLarge: theme.titleLarge?.copyWith(fontWeight: _titleWeight),
      titleMedium: theme.titleMedium?.copyWith(
        fontWeight: _titleWeight,
        letterSpacing: 0,
      ),
      titleSmall: theme.titleSmall?.copyWith(fontWeight: _titleWeight),
      labelLarge: theme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: theme.labelMedium?.copyWith(letterSpacing: 0.2),
    );

    if (bodyColor != null || displayColor != null) {
      theme = theme.apply(
        bodyColor: bodyColor,
        displayColor: displayColor ?? bodyColor,
      );
    }
    return theme;
  }

  /// Applies Outfit, degrading gracefully when the font cannot be resolved.
  static TextTheme _outfit(TextTheme base) {
    try {
      return GoogleFonts.outfitTextTheme(base);
    } catch (_) {
      // Offline first launch without a warm font cache — keep Material defaults.
      return base;
    }
  }

  /// Styles for tabular, right-aligned money amounts (used by the step 2+
  /// transaction rows and the step 3+ charts).
  static TextStyle amountStyle(
    BuildContext context, {
    double size = 16,
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) {
    final ThemeData theme = Theme.of(context);
    return (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color ?? theme.colorScheme.onSurface,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }
}
