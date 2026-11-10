import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'tokens.dart';

/// Material 3 theme factory (blueprint section 4.1).
///
/// - Seed-based colour (`ColorScheme.fromSeed`) so dynamic colour can be
///   layered on later without changing call sites.
/// - Money figures use tabular figures so digits do not jitter.
/// - Tonal surfaces instead of shadows; M3 shapes (cards 16/20, sheets 28).
abstract final class AppTheme {
  static ColorScheme schemeFor(Brightness brightness, {Color? seed}) {
    return ColorScheme.fromSeed(
      seedColor: seed ?? AppColors.seed,
      brightness: brightness,
    );
  }

  static ThemeData light({ColorScheme? scheme}) {
    final ColorScheme colorScheme = scheme ?? schemeFor(Brightness.light);
    return _build(colorScheme);
  }

  static ThemeData dark({ColorScheme? scheme}) {
    final ColorScheme colorScheme = scheme ?? schemeFor(Brightness.dark);
    return _build(colorScheme);
  }

  /// AMOLED variant: dark scheme with a pure-black surface.
  static ThemeData amoled({ColorScheme? scheme}) {
    final ColorScheme base = scheme ?? schemeFor(Brightness.dark);
    final ColorScheme colorScheme = base.copyWith(
      surface: AppColors.amoledSurface,
      surfaceContainerLowest: AppColors.amoledSurface,
      surfaceContainerLow: AppColors.amoledSurface,
    );
    return _build(colorScheme);
  }

  static ThemeData _build(ColorScheme colorScheme) {
    final TextTheme textTheme = _textTheme(colorScheme);
    return ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      listTileTheme: ListTileThemeData(
        minLeadingWidth: 48,
        minVerticalPadding: AppSpacing.sm,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    const List<FontFeature> tabular = <FontFeature>[
      FontFeature.tabularFigures(),
    ];
    final TextTheme base = ThemeData.light().textTheme;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: colorScheme.onSurface,
        fontFeatures: tabular,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: colorScheme.onSurface,
        fontFeatures: tabular,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontFeatures: tabular,
      ),
      titleLarge: base.titleLarge?.copyWith(color: colorScheme.onSurface),
      bodyLarge: base.bodyLarge?.copyWith(color: colorScheme.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: colorScheme.onSurface),
      labelLarge: base.labelLarge?.copyWith(color: colorScheme.onSurface),
    );
  }
}
