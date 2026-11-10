import 'package:flutter/material.dart';

/// Spacing tokens on a 4-pt grid (blueprint section 4.1).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Screen edge gutter.
  static const double screenGutter = 16;

  /// Inner card padding.
  static const double cardPadding = 12;

  /// Inner gap between stacked elements.
  static const double innerGap = 8;
}

/// Corner-radius tokens (M3: cards 16/20, sheets 28).
abstract final class AppRadius {
  static const double card = 16;
  static const double cardLarge = 20;
  static const double sheet = 28;
  static const double pill = 999;
}

/// Convenience accessors so widgets never hard-code theme values.
extension AppContextX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
